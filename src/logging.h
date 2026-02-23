#ifndef LOGGING_H
#define LOGGING_H

#include <stdarg.h>

int  log_init(const char *dir);     // dir base para logs diarios
void log_close(void);
void log_reopen_if_day_changed(void);
void log_info(const char *fmt, ...);

#endif
