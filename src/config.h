#ifndef CONFIG_H
#define CONFIG_H

#include <stddef.h>
#include <stdbool.h>

typedef enum {
  COPY_ALL = 0,
  COPY_INCLUDE = 1,
  COPY_EXCLUDE = 2
} copy_mode_t;

typedef struct {
  char *cics_base;
  char **cics_list;
  size_t cics_count;

  int poll_ms;
  bool start_from_eof;

  copy_mode_t copy_mode;

  char **include_codes;
  size_t include_count;

  char **exclude_codes;
  size_t exclude_count;

  char *output_dir;
  char *output_tag;

  long rotate_lines;
  int rotate_max;

  char *daemon_log_dir;

  char *config_path;
} config_t;

int  config_load(const char *path, config_t *out, char *errbuf, size_t errlen);
void config_free(config_t *cfg);

#endif
