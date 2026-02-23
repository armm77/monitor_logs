#define _POSIX_C_SOURCE 200809L
#define _XOPEN_SOURCE 700

#include "watcher.h"
#include "logging.h"
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <sys/stat.h>
#include <errno.h>
#include <unistd.h> 

static int is_console_num(const char *name, int *num_out) {
  // console. + 6 digits
  const char *pfx = "console.";
  size_t n = strlen(pfx);
  if (strncmp(name, pfx, n) != 0) return 0;
  const char *d = name + n;
  if (strlen(d) != 6) return 0;
  int v = 0;
  for (int i = 0; i < 6; i++) {
    if (d[i] < '0' || d[i] > '9') return 0;
    v = v*10 + (d[i]-'0');
  }
  *num_out = v;
  return 1;
}

static int find_highest_console(const char *dirpath, int *best_num, char best_name[256]) {
  DIR *dp = opendir(dirpath);
  if (!dp) return -1;

  int best = -1;
  char bestn[256] = {0};

  struct dirent *de;
  while ((de = readdir(dp)) != NULL) {
    int num = 0;
    if (is_console_num(de->d_name, &num)) {
      if (num > best) {
        best = num;
	snprintf(bestn, sizeof(bestn), "%s", de->d_name);
      }
    }
  }
  closedir(dp);

  if (best < 0) return -1;
  *best_num = best;
  strncpy(best_name, bestn, 256);
  return 0;
}

static long long file_size_path(const char *path) {
  struct stat st;
  if (stat(path, &st) != 0) return -1;
  return (long long)st.st_size;
}

static void build_path(char out[1024], const config_t *cfg, const char *cics, int num) {
  // /var/cics_regions/<CICS>/console.%06d
  snprintf(out, 1024, "%s/%s/console.%06d", cfg->cics_base, cics, num);
}

int watcher_init(cics_watcher_t *w, const config_t *cfg, const char *cics_name) {
  memset(w, 0, sizeof(*w));
  strncpy(w->cics_name, cics_name, sizeof(w->cics_name)-1);

  char cics_dir[1024];
  snprintf(cics_dir, sizeof(cics_dir), "%s/%s", cfg->cics_base, cics_name);

  int best_num = -1;
  char best_name[256];
  if (find_highest_console(cics_dir, &best_num, best_name) != 0) {
    log_info("PID:%d - No se encontro console.NNNNNN para CICS %s en %s", (int)getpid(), cics_name, cics_dir);
    return -1;
  }

  w->current_num = best_num;
  build_path(w->current_path, cfg, cics_name, best_num);

  w->fp = fopen(w->current_path, "r");
  if (!w->fp) {
    log_info("PID:%d - No se pudo abrir %s (CICS %s)", (int)getpid(), w->current_path, cics_name);
    return -1;
  }

  // ir a EOF si aplica
  if (cfg->start_from_eof) {
    fseeko(w->fp, 0, SEEK_END);
  }
  w->eof_initialized = 1;
  w->last_size = file_size_path(w->current_path);

  log_info("PID:%d - Inicia el monitoreo del CICS - %s - con el archivo del logs %s",
           (int)getpid(), cics_name, w->current_path);
  return 0;
}

void watcher_close(cics_watcher_t *w) {
  if (w->fp) fclose(w->fp);
  w->fp = NULL;
}

static int try_switch_to_next(cics_watcher_t *w, const config_t *cfg) {
  int next = w->current_num + 1;
  char next_path[1024];
  build_path(next_path, cfg, w->cics_name, next);

  struct stat st;
  if (stat(next_path, &st) != 0) return 0; // no existe aun

  // existe => cambiar
  FILE *fp = fopen(next_path, "r");
  if (!fp) {
    log_info("CICS - %s - Se detecto nuevo log %s pero no se pudo abrir (permiso/ruta).", w->cics_name, next_path);
    return 0;
  }

  if (cfg->start_from_eof) fseeko(fp, 0, SEEK_END);

  if (w->fp) fclose(w->fp);
  w->fp = fp;
  w->current_num = next;
  snprintf(w->current_path, sizeof(w->current_path), "%s", next_path);
  w->last_size = file_size_path(next_path);

  log_info("CICS - %s - Se detecto cambio en el nombre del log de eventos - Nuevo nombre del archivo: %s",
           w->cics_name, w->current_path);
  return 1;
}

void watcher_tick(cics_watcher_t *w, const config_t *cfg, line_cb_t cb, void *ud) {
  if (!w->fp) return;

  // Leer todas las lineas disponibles
  char buf[4096 + 4];
  int read_any = 0;

  while (fgets(buf, sizeof(buf), w->fp)) {
    read_any = 1;
    cb(w->cics_name, buf, ud);
  }

  if (!read_any) {
    // EOF: limpiar eof y evaluar rotacion
    clearerr(w->fp);

    // si el archivo fue movido/ya no crece, probablemente aparece next
    // intentamos cambio si existe next
    (void)try_switch_to_next(w, cfg);
  }
}
