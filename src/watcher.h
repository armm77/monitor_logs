#ifndef WATCHER_H
#define WATCHER_H

#include "config.h"
#include <stdio.h>

typedef struct {
  char cics_name[128];
  char current_path[1024];
  int  current_num;      // NNNNNN actual
  FILE *fp;
  long long last_size;   // ultimo size observado
  int  eof_initialized;  // 0/1
} cics_watcher_t;

int watcher_init(cics_watcher_t *w, const config_t *cfg, const char *cics_name);
void watcher_close(cics_watcher_t *w);

// procesa nuevas lineas, llama callback por cada linea
typedef void (*line_cb_t)(const char *cics, const char *line, void *ud);

void watcher_tick(cics_watcher_t *w, const config_t *cfg, line_cb_t cb, void *ud);

#endif
