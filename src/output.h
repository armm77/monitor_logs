#ifndef OUTPUT_H
#define OUTPUT_H

#include "config.h"

int  output_init(const config_t *cfg);
void output_close(void);
void output_reopen_if_day_changed(const config_t *cfg);

// escribe una linea al output principal (y rota por lineas)
int  output_write_line(const config_t *cfg, const char *cics, const char *line);
//int  output_write_line(const config_t *cfg, const char *line);

#endif
