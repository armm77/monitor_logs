#define _POSIX_C_SOURCE 200809L
#define _XOPEN_SOURCE 700

#include "config.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <ctype.h>

static char *xstrdup(const char *s) {
  if (!s) return NULL;
  size_t n = strlen(s);
  char *p = (char*)malloc(n + 1);
  if (!p) return NULL;
  memcpy(p, s, n + 1);
  return p;
}

static void trim_inplace(char *s) {
  if (!s) return;
  size_t n = strlen(s);
  while (n && isspace((unsigned char)s[n-1])) s[--n] = 0;
  size_t i = 0;
  while (s[i] && isspace((unsigned char)s[i])) i++;
  if (i) memmove(s, s+i, strlen(s+i)+1);
}

static char **split_csv(const char *val, size_t *count_out) {
  *count_out = 0;
  if (!val) return NULL;

  // copy and tokenize
  char *tmp = xstrdup(val);
  if (!tmp) return NULL;

  // first pass count
  size_t count = 0;
  for (char *p = tmp; *p; p++) if (*p == ',') count++;
  count++; // items = commas+1

  char **arr = (char**)calloc(count, sizeof(char*));
  if (!arr) { free(tmp); return NULL; }

  size_t idx = 0;
  char *save = NULL;
  char *tok = strtok_r(tmp, ",", &save);
  while (tok) {
    trim_inplace(tok);
    if (*tok) {
      arr[idx++] = xstrdup(tok);
    }
    tok = strtok_r(NULL, ",", &save);
  }

  free(tmp);

  // compact empty
  size_t real = 0;
  for (size_t i = 0; i < idx; i++) if (arr[i]) arr[real++] = arr[i];
  *count_out = real;
  return arr;
}

static void free_strv(char **v, size_t n) {
  if (!v) return;
  for (size_t i = 0; i < n; i++) free(v[i]);
  free(v);
}

static copy_mode_t parse_copy_mode(const char *v) {
  if (!v) return COPY_INCLUDE;
  if (strcasecmp(v, "all") == 0) return COPY_ALL;
  if (strcasecmp(v, "include") == 0) return COPY_INCLUDE;
  if (strcasecmp(v, "exclude") == 0) return COPY_EXCLUDE;
  return COPY_INCLUDE;
}

static bool parse_bool(const char *v, bool defv) {
  if (!v) return defv;
  if (strcasecmp(v, "true") == 0 || strcmp(v, "1") == 0 || strcasecmp(v, "yes") == 0) return true;
  if (strcasecmp(v, "false") == 0 || strcmp(v, "0") == 0 || strcasecmp(v, "no") == 0) return false;
  return defv;
}

static void cfg_init_defaults(config_t *c) {
  memset(c, 0, sizeof(*c));
  c->poll_ms = 1000;
  c->start_from_eof = true;
  c->copy_mode = COPY_INCLUDE;
  c->rotate_lines = 2000;
  c->rotate_max = 999;
}

void config_free(config_t *c) {
  if (!c) return;
  free(c->cics_base);
  free_strv(c->cics_list, c->cics_count);
  free_strv(c->include_codes, c->include_count);
  free_strv(c->exclude_codes, c->exclude_count);
  free(c->output_dir);
  free(c->output_tag);
  free(c->daemon_log_dir);
  free(c->config_path);
  memset(c, 0, sizeof(*c));
}

int config_load(const char *path, config_t *out, char *errbuf, size_t errlen) {
  cfg_init_defaults(out);
  out->config_path = xstrdup(path);

  FILE *f = fopen(path, "r");
  if (!f) {
    snprintf(errbuf, errlen, "No se pudo abrir config: %s", path);
    return -1;
  }

  char line[2048];
  while (fgets(line, sizeof(line), f)) {
    trim_inplace(line);
    if (!line[0]) continue;
    if (line[0] == '#' || line[0] == ';') continue;

    char *eq = strchr(line, '=');
    if (!eq) continue;
    *eq = 0;
    char *key = line;
    char *val = eq + 1;
    trim_inplace(key);
    trim_inplace(val);

    if (strcasecmp(key, "cics_base") == 0) {
      free(out->cics_base);
      out->cics_base = xstrdup(val);
    } else if (strcasecmp(key, "cics_list") == 0) {
      free_strv(out->cics_list, out->cics_count);
      out->cics_list = split_csv(val, &out->cics_count);
    } else if (strcasecmp(key, "poll_ms") == 0) {
      out->poll_ms = atoi(val);
      if (out->poll_ms < 50) out->poll_ms = 50;
    } else if (strcasecmp(key, "start_from_eof") == 0) {
      out->start_from_eof = parse_bool(val, true);
    } else if (strcasecmp(key, "copy_mode") == 0) {
      out->copy_mode = parse_copy_mode(val);
    } else if (strcasecmp(key, "include_codes") == 0) {
      free_strv(out->include_codes, out->include_count);
      out->include_codes = split_csv(val, &out->include_count);
    } else if (strcasecmp(key, "exclude_codes") == 0) {
      free_strv(out->exclude_codes, out->exclude_count);
      out->exclude_codes = split_csv(val, &out->exclude_count);
    } else if (strcasecmp(key, "output_dir") == 0) {
      free(out->output_dir);
      out->output_dir = xstrdup(val);
    } else if (strcasecmp(key, "output_tag") == 0) {
      free(out->output_tag);
      out->output_tag = xstrdup(val);
    } else if (strcasecmp(key, "rotate_lines") == 0) {
      out->rotate_lines = atol(val);
      if (out->rotate_lines < 1) out->rotate_lines = 2000;
    } else if (strcasecmp(key, "rotate_max") == 0) {
      out->rotate_max = atoi(val);
      if (out->rotate_max < 1) out->rotate_max = 999;
      if (out->rotate_max > 999999) out->rotate_max = 999999;
    } else if (strcasecmp(key, "daemon_log_dir") == 0) {
      free(out->daemon_log_dir);
      out->daemon_log_dir = xstrdup(val);
    }
  }

  fclose(f);

  if (!out->cics_base || !out->output_dir || !out->output_tag || !out->daemon_log_dir) {
    snprintf(errbuf, errlen, "Config incompleta: requiere cics_base, output_dir, output_tag, daemon_log_dir");
    return -1;
  }
  if (!out->cics_list || out->cics_count == 0) {
    snprintf(errbuf, errlen, "Config incompleta: cics_list debe tener al menos 1 CICS");
    return -1;
  }

  return 0;
}
