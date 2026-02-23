#define _POSIX_C_SOURCE 200809L
#define _XOPEN_SOURCE 700

#include "output.h"
#include "logging.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/stat.h>

static FILE *g_out = NULL;
static long  g_lines = 0;
static int   g_rot_idx = 0;
static char  g_day[9];

static void ensure_dir(const char *d) {
  struct stat st;
  if (stat(d, &st) == 0 && S_ISDIR(st.st_mode)) return;
  mkdir(d, 0755);
}

static void yyyymmdd_now(char out[9]) {
  time_t t = time(NULL);
  struct tm tmv;
  localtime_r(&t, &tmv);
  strftime(out, 9, "%Y%m%d", &tmv);
}

static void out_open_for_day(const config_t *cfg, const char *day) {
  ensure_dir(cfg->output_dir);

  char path[2048];
  snprintf(path, sizeof(path), "%s/%s-console_error_%s.log",
           cfg->output_dir, day, cfg->output_tag);

  FILE *fp = fopen(path, "a");
  if (!fp) return;

  if (g_out) fclose(g_out);
  g_out = fp;
  strncpy(g_day, day, sizeof(g_day));
  g_day[8] = 0;

  // al abrir, no recalculamos linecount (caro). empezamos en 0 cada dia.
  g_lines = 0;
  g_rot_idx = 0;

  log_info("Output abierto: %s", path);
}

int output_init(const config_t *cfg) {
  char day[9]; yyyymmdd_now(day);
  out_open_for_day(cfg, day);
  return g_out ? 0 : -1;
}

void output_close(void) {
  if (g_out) fclose(g_out);
  g_out = NULL;
  g_day[0] = 0;
}

void output_reopen_if_day_changed(const config_t *cfg) {
  char day[9]; yyyymmdd_now(day);
  if (strncmp(day, g_day, 8) != 0) out_open_for_day(cfg, day);
}

static void rotate_output(const config_t *cfg) {
  if (!g_out) return;

  // close current
  fflush(g_out);
  fclose(g_out);
  g_out = NULL;

  g_rot_idx++;
  if (g_rot_idx > cfg->rotate_max) {
    g_rot_idx = 1; // wrap
    log_info("Rotacion: se alcanzo rotate_max=%d, reiniciando a 001 (sobrescribe).", cfg->rotate_max);
  }

  char src[2048], dst[2048];
  snprintf(src, sizeof(src), "%s/%s-console_error_%s.log",
           cfg->output_dir, g_day, cfg->output_tag);
  snprintf(dst, sizeof(dst), "%s/%s-console_error_%s.%06d",
           cfg->output_dir, g_day, cfg->output_tag, g_rot_idx);

  // rename (sobrescribe si existe)
  remove(dst);
  rename(src, dst);

  log_info("Rotacion output: %s -> %s", src, dst);

  // reopen new
  char path[2048];
  snprintf(path, sizeof(path), "%s/%s-console_error_%s.log",
           cfg->output_dir, g_day, cfg->output_tag);
  g_out = fopen(path, "a");
  g_lines = 0;
}
/*
int output_write_line(const config_t *cfg, const char *line) {
  if (!g_out) return -1;

  // escribe exacto (sin modificar)
  fputs(line, g_out);
  if (line[0] && line[strlen(line)-1] != '\n') fputc('\n', g_out);
  g_lines++;
  fflush(g_out);

  if (g_lines >= cfg->rotate_lines) rotate_output(cfg);
  return 0;
}
*/
int output_write_line(const config_t *cfg, const char *cics, const char *line) {
  if (!g_out) return -1;

  // Formato requerido: "<CICS> - <linea exacta>"
  fputs(cics, g_out);
  fputs(" - ", g_out);

  fputs(line, g_out);
  if (line[0] && line[strlen(line)-1] != '\n') fputc('\n', g_out);

  g_lines++;
  fflush(g_out);

  if (g_lines >= cfg->rotate_lines) rotate_output(cfg);
  return 0;
}
