#define _POSIX_C_SOURCE 200809L
#define _XOPEN_SOURCE 700

#include "logging.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/stat.h>
#include <errno.h>

static FILE *g_fp = NULL;
static char  g_dir[1024];
static char  g_day[9]; // YYYYMMDD

static void ensure_dir(const char *d) {
  struct stat st;
  if (stat(d, &st) == 0 && S_ISDIR(st.st_mode)) return;
  mkdir(d, 0755); // best effort
}

static void yyyymmdd_now(char out[9]) {
  time_t t = time(NULL);
  struct tm tmv;
  localtime_r(&t, &tmv);
  strftime(out, 9, "%Y%m%d", &tmv);
}

static void open_for_day(const char *day) {
  ensure_dir(g_dir);
  char path[2048];
  snprintf(path, sizeof(path), "%s/%s-monitor_logs.log", g_dir, day);
  FILE *fp = fopen(path, "a");
  if (!fp) return;
  if (g_fp) fclose(g_fp);
  g_fp = fp;
  strncpy(g_day, day, sizeof(g_day));
  g_day[8] = 0;
}

int log_init(const char *dir) {
  memset(g_dir, 0, sizeof(g_dir));
  strncpy(g_dir, dir, sizeof(g_dir)-1);
  char day[9]; yyyymmdd_now(day);
  open_for_day(day);
  return g_fp ? 0 : -1;
}

void log_close(void) {
  if (g_fp) fclose(g_fp);
  g_fp = NULL;
  g_day[0] = 0;
}

void log_reopen_if_day_changed(void) {
  char day[9]; yyyymmdd_now(day);
  if (strncmp(day, g_day, 8) != 0) open_for_day(day);
}

static void ts_now(char out[32]) {
  time_t t = time(NULL);
  struct tm tmv;
  localtime_r(&t, &tmv);
  strftime(out, 32, "%Y%m%d-%H:%M:%S", &tmv);
}

void log_info(const char *fmt, ...) {
  if (!g_fp) return;
  char ts[32]; ts_now(ts);

  fprintf(g_fp, "%s - ", ts);

  va_list ap;
  va_start(ap, fmt);
  vfprintf(g_fp, fmt, ap);
  va_end(ap);

  fputc('\n', g_fp);
  fflush(g_fp);
}
