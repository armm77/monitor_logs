#define _POSIX_C_SOURCE 200809L

#include "config.h"
#include "watcher.h"
#include "output.h"
#include "logging.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <unistd.h>
#include <time.h>

#ifdef __linux__
#include <getopt.h>
#endif

static volatile sig_atomic_t g_stop = 0;
static volatile sig_atomic_t g_reload = 0;

static void on_sigterm(int s) { (void)s; g_stop = 1; }
static void on_sighup(int s)  { (void)s; g_reload = 1; }

static int line_matches_any(const char *line, char **codes, size_t n) {
  if (!codes || n == 0) return 0;
  for (size_t i = 0; i < n; i++) {
    if (codes[i] && strstr(line, codes[i])) return 1;
  }
  return 0;
}

typedef struct {
  const config_t *cfg;
} cb_ctx_t;

static void on_line(const char *cics, const char *line, void *ud) {
  (void)cics; // por defecto copiamos linea exacta sin prefijos
  cb_ctx_t *ctx = (cb_ctx_t*)ud;
  const config_t *cfg = ctx->cfg;

  int pass = 0;
  if (cfg->copy_mode == COPY_ALL) {
    pass = 1;
  } else if (cfg->copy_mode == COPY_INCLUDE) {
    pass = line_matches_any(line, cfg->include_codes, cfg->include_count);
  } else if (cfg->copy_mode == COPY_EXCLUDE) {
    pass = !line_matches_any(line, cfg->exclude_codes, cfg->exclude_count);
  }

  if (pass) {
    //output_write_line(cfg, line);
    output_write_line(cfg, cics, line);
  }
}

static void sleep_ms(int ms) {
  struct timespec ts;
  ts.tv_sec = ms / 1000;
  ts.tv_nsec = (ms % 1000) * 1000000L;
  nanosleep(&ts, NULL);
}

static int setup_signals(void) {
  struct sigaction sa;
  memset(&sa, 0, sizeof(sa));
  sa.sa_handler = on_sigterm;
  sigaction(SIGTERM, &sa, NULL);
  sigaction(SIGINT,  &sa, NULL);

  struct sigaction sh;
  memset(&sh, 0, sizeof(sh));
  sh.sa_handler = on_sighup;
  sigaction(SIGHUP, &sh, NULL);

  return 0;
}

int main(int argc, char **argv) {
  const char *cfg_path = "/etc/monitor_logs/config.cfg";
  int opt;
  while ((opt = getopt(argc, argv, "c:")) != -1) {
    if (opt == 'c') cfg_path = optarg;
  }

  setup_signals();

  config_t cfg;
  char err[512];
  if (config_load(cfg_path, &cfg, err, sizeof(err)) != 0) {
    fprintf(stderr, "Error config: %s\n", err);
    return 2;
  }

  if (log_init(cfg.daemon_log_dir) != 0) {
    fprintf(stderr, "No se pudo abrir log interno en %s\n", cfg.daemon_log_dir);
    config_free(&cfg);
    return 2;
  }

  log_info("PID:%d - Inicio daemon de monitoreo de logs CICS", (int)getpid());

  if (output_init(&cfg) != 0) {
    log_info("PID:%d - No se pudo abrir output en %s", (int)getpid(), cfg.output_dir);
    log_close();
    config_free(&cfg);
    return 2;
  }

  // watchers
  cics_watcher_t *watchers = (cics_watcher_t*)calloc(cfg.cics_count, sizeof(cics_watcher_t));
  int *active = (int*)calloc(cfg.cics_count, sizeof(int));

  for (size_t i = 0; i < cfg.cics_count; i++) {
    if (watcher_init(&watchers[i], &cfg, cfg.cics_list[i]) == 0) {
      active[i] = 1;
    } else {
      active[i] = 0;
      log_info("PID:%d - No se pudo iniciar monitoreo de %s (ver permisos/ruta).",
               (int)getpid(), cfg.cics_list[i]);
    }
  }

  cb_ctx_t ctx = { .cfg = &cfg };

  while (!g_stop) {
    // rotación diaria de logs internos / output
    log_reopen_if_day_changed();
    output_reopen_if_day_changed(&cfg);

    // tick watchers
    for (size_t i = 0; i < cfg.cics_count; i++) {
      if (!active[i]) continue;
      watcher_tick(&watchers[i], &cfg, on_line, &ctx);
    }

    // recarga config
    if (g_reload) {
      g_reload = 0;
      log_info("PID:%d - Recargando configuracion (SIGHUP)...", (int)getpid());

      config_t newcfg;
      char e2[512];
      if (config_load(cfg_path, &newcfg, e2, sizeof(e2)) != 0) {
        log_info("PID:%d - Recarga fallida: %s", (int)getpid(), e2);
      } else {
        // cerrar watchers actuales
        for (size_t i = 0; i < cfg.cics_count; i++) {
          if (active[i]) watcher_close(&watchers[i]);
        }
        free(watchers);
        free(active);

        // aplicar cfg nuevo
        config_free(&cfg);
        cfg = newcfg;
        ctx.cfg = &cfg;

        // re-init output/log dirs si cambiaron
        output_close();
        output_init(&cfg);

        // re-init watchers
        watchers = (cics_watcher_t*)calloc(cfg.cics_count, sizeof(cics_watcher_t));
        active = (int*)calloc(cfg.cics_count, sizeof(int));
        for (size_t i = 0; i < cfg.cics_count; i++) {
          if (watcher_init(&watchers[i], &cfg, cfg.cics_list[i]) == 0) active[i] = 1;
          else {
            active[i] = 0;
            log_info("PID:%d - No se pudo iniciar monitoreo de %s en recarga.", (int)getpid(), cfg.cics_list[i]);
          }
        }

        log_info("PID:%d - Configuracion recargada OK.", (int)getpid());
      }
    }

    sleep_ms(cfg.poll_ms);
  }

  log_info("Se detiene el daemon de monitoreo de logs CICS");

  // cleanup
  for (size_t i = 0; i < cfg.cics_count; i++) {
    if (active[i]) watcher_close(&watchers[i]);
  }
  free(watchers);
  free(active);

  output_close();
  log_close();
  config_free(&cfg);
  return 0;
}
