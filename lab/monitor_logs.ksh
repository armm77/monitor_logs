#!/bin/ksh 
# monitor_logs.ksh - v2.2 (AIX-friendly)
# Uso:
# monitor_logs.ksh start|stop|status|reload|run [-c /etc/monitor_logs/config.cfg]

umask 022

PATH=/usr/bin:/usr/sbin:/bin:/usr/local/bin:/opt/freeware/bin

CONFIG_FILE="/backup/scripts/monitor_logs/config.cfg"
PID_FILE="/var/run/monitor_logs.pid"

RUNNING=1
RELOAD_CFG=0

# -------- Config globals --------
cics_base=""
poll_ms=1000
start_from_eof="true"
copy_mode="include"
output_dir=""
output_tag="s21"
rotate_lines=2000
rotate_max=999
daemon_log_dir=""
cics_list=""
include_codes=""
exclude_codes=""

# -------- Runtime state --------
OUT_DAY=""
OUT_LINE_COUNT=0
OUT_ROT_IDX=0

# Watcher state (archivos temporales por simplicidad/portabilidad)
STATE_DIR="/tmp/monitor_logs_state.$$"

# ==============================
# Utilidades
# ==============================

trim() {
  # trim espacios
  echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

day_now() {
  date '+%Y%m%d'
}

ts_now() {
  date '+%Y%m%d-%H:%M:%S'
}

ensure_dir() {
  [ -d "$1" ] || mkdir -p "$1"
}

log_info() {
  d=$(day_now)
  ensure_dir "$daemon_log_dir"
  lf="$daemon_log_dir/${d}-monitor_logs.log"
  echo "$(ts_now) - $1" >> "$lf"
}

file_size_bytes() {
  f="$1"
  [ -f "$f" ] || { echo 0; return; }
  wc -c < "$f" 2>/dev/null | tr -d ' '
}

# sleep en ms con perl/python si existe; si no, fallback 1s
sleep_ms() {
  ms="$1"
  if [ "$ms" -ge 1000 ]; then
    sec=$(expr "$ms" / 1000)
    [ "$sec" -lt 1 ] && sec=1
    sleep "$sec"
    return
  fi

  # Intento fino (opcional) si hay perl
  if command -v perl >/dev/null 2>&1; then
    perl -e "select(undef,undef,undef,$ms/1000)"
  else
    sleep 1
  fi
}

contains_code_list() {
  line="$1"
  list="$2" # CSV
  OLDIFS="$IFS"
  IFS=,
  for code in $list; do
    code=$(trim "$code")
    [ -z "$code" ] && continue
    echo "$line" | grep "$code" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      IFS="$OLDIFS"
      return 0
    fi
  done
  IFS="$OLDIFS"
  return 1
}

should_copy_line() {
  line="$1"
  case "$copy_mode" in
    all) return 0 ;;
    include)
      contains_code_list "$line" "$include_codes"
      return $?
      ;;
    exclude)
      contains_code_list "$line" "$exclude_codes"
      if [ $? -eq 0 ]; then
        return 1
      else
        return 0
      fi
      ;;
    *)
      contains_code_list "$line" "$include_codes"
      return $?
      ;;
  esac
}

# ==============================
# Output principal (console_error)
# ==============================

output_reopen_if_day_changed() {
  d=$(day_now)
  if [ "$d" != "$OUT_DAY" ]; then
    OUT_DAY="$d"
    OUT_LINE_COUNT=0
    OUT_ROT_IDX=0
    ensure_dir "$output_dir"
    log_info "Output abierto: $output_dir/${OUT_DAY}-console_error_${output_tag}.log"
  fi
}

rotate_output_if_needed() {
  [ "$OUT_LINE_COUNT" -lt "$rotate_lines" ] && return

  OUT_ROT_IDX=$(expr "$OUT_ROT_IDX" + 1)
  if [ "$OUT_ROT_IDX" -gt "$rotate_max" ]; then
    OUT_ROT_IDX=1
    log_info "Rotacion output: se alcanzo rotate_max=$rotate_max, reiniciando a 001 (sobrescribe)."
  fi

  src="$output_dir/${OUT_DAY}-console_error_${output_tag}.log"
  idx=$(printf "%06d" "$OUT_ROT_IDX")
  dst="$output_dir/${OUT_DAY}-console_error_${output_tag}.${idx}"

  [ -f "$dst" ] && rm -f "$dst"
  [ -f "$src" ] && mv "$src" "$dst"

  log_info "Rotacion output: $src -> $dst"
  OUT_LINE_COUNT=0
}

write_output_line() {
  cics="$1"
  line="$2"

  output_reopen_if_day_changed
  ensure_dir "$output_dir"

  out="$output_dir/${OUT_DAY}-console_error_${output_tag}.log"
  echo "${cics} - ${line}" >> "$out"

  OUT_LINE_COUNT=$(expr "$OUT_LINE_COUNT" + 1)
  rotate_output_if_needed
}

# ==============================
# Parser INI simple
# ==============================

load_config() {
  cfg="$1"
  [ -f "$cfg" ] || {
    echo "No existe config: $cfg" >&2
    return 1
  }

  # defaults
  cics_base=""
  poll_ms=1000
  start_from_eof="true"
  copy_mode="include"
  output_dir=""
  output_tag="s21"
  rotate_lines=2000
  rotate_max=999
  daemon_log_dir=""
  cics_list=""
  include_codes=""
  exclude_codes=""

  while IFS= read line || [ -n "$line" ]; do
    line=$(trim "$line")
    [ -z "$line" ] && continue
    firstchar=$(echo "$line" | cut -c1)
    [ "$firstchar" = "#" ] && continue
    [ "$firstchar" = ";" ] && continue

    echo "$line" | grep '=' >/dev/null 2>&1 || continue

    key=$(echo "$line" | awk -F= '{print $1}')
    val=$(echo "$line" | cut -d= -f2-)
    key=$(trim "$key")
    val=$(trim "$val")

    case "$key" in
      cics_base) cics_base="$val" ;;
      cics_list) cics_list="$val" ;;
      poll_ms) poll_ms="$val" ;;
      start_from_eof) start_from_eof=$(echo "$val" | tr '[:upper:]' '[:lower:]') ;;
      copy_mode) copy_mode=$(echo "$val" | tr '[:upper:]' '[:lower:]') ;;
      include_codes) include_codes="$val" ;;
      exclude_codes) exclude_codes="$val" ;;
      output_dir) output_dir="$val" ;;
      output_tag) output_tag="$val" ;;
      rotate_lines) rotate_lines="$val" ;;
      rotate_max) rotate_max="$val" ;;
      daemon_log_dir) daemon_log_dir="$val" ;;
    esac
  done < "$cfg"

  # sane defaults
  echo "$poll_ms" | grep '^[0-9][0-9]*$' >/dev/null 2>&1 || poll_ms=1000
  [ "$poll_ms" -lt 50 ] && poll_ms=50

  echo "$rotate_lines" | grep '^[0-9][0-9]*$' >/dev/null 2>&1 || rotate_lines=2000
  [ "$rotate_lines" -lt 1 ] && rotate_lines=2000

  echo "$rotate_max" | grep '^[0-9][0-9]*$' >/dev/null 2>&1 || rotate_max=999
  [ "$rotate_max" -lt 1 ] && rotate_max=999
  [ "$rotate_max" -gt 999 ] && rotate_max=999

  # validate
  [ -n "$cics_base" ] || { echo "config: falta cics_base" >&2; return 1; }
  [ -n "$cics_list" ] || { echo "config: falta cics_list" >&2; return 1; }
  [ -n "$output_dir" ] || { echo "config: falta output_dir" >&2; return 1; }
  [ -n "$daemon_log_dir" ] || { echo "config: falta daemon_log_dir" >&2; return 1; }

  return 0
}

# ==============================
# Estado por CICS (en archivos)
# ==============================
# Por portabilidad en ksh viejo, guardamos estado en archivos:
# $STATE_DIR/<CICS>.num
# $STATE_DIR/<CICS>.path
# $STATE_DIR/<CICS>.off
# $STATE_DIR/<CICS>.active

state_set() {
  cics="$1"
  key="$2"
  val="$3"
  echo "$val" > "$STATE_DIR/${cics}.${key}"
}

state_get() {
  cics="$1"
  key="$2"
  f="$STATE_DIR/${cics}.${key}"
  [ -f "$f" ] && cat "$f"
}

find_highest_console_num() {
  dir="$1"
  [ -d "$dir" ] || { echo -1; return; }

  # Lista solo console.######, ordena y toma el mayor
  # awk extrae número
  ls "$dir"/console.* 2>/dev/null | \
    awk -F/ '
      {
        n=$NF
        if (n ~ /^console\.[0-9][0-9][0-9][0-9][0-9][0-9]$/) {
          split(n,a,".")
          print a[2]
        }
      }' | sort | tail -1 | awk '{ if (NF) print $1; else print "-1"; }'
}

build_console_path() {
  cics="$1"
  num="$2"
  # convertir a decimal seguro (evitar octal)
  dec=$(echo "$num" | sed 's/^0*//')
  [ -z "$dec" ] && dec=0
  printf "%s/%s/console.%06d\n" "$cics_base" "$cics" "$dec"
}

watchers_init() {
  ensure_dir "$STATE_DIR"
  rm -f "$STATE_DIR"/* 2>/dev/null

  pid="$$"

  OLDIFS="$IFS"
  IFS=,
  for cics in $cics_list; do
    cics=$(trim "$cics")
    [ -z "$cics" ] && continue

    dir="$cics_base/$cics"
    max=$(find_highest_console_num "$dir")

    if [ "$max" = "-1" ] || [ -z "$max" ]; then
      state_set "$cics" num "000000"
      state_set "$cics" path ""
      state_set "$cics" off "0"
      state_set "$cics" active "0"
      log_info "PID:$pid - No se encontro console.NNNNNN para CICS $cics en $dir"
      continue
    fi

    path="$dir/console.$max"
    if [ ! -r "$path" ]; then
      state_set "$cics" num "$max"
      state_set "$cics" path "$path"
      state_set "$cics" off "0"
      state_set "$cics" active "0"
      log_info "PID:$pid - No se pudo abrir $path (CICS $cics)"
      continue
    fi

    if [ "$start_from_eof" = "true" ]; then
      sz=$(file_size_bytes "$path")
    else
      sz=0
    fi

    state_set "$cics" num "$max"
    state_set "$cics" path "$path"
    state_set "$cics" off "$sz"
    state_set "$cics" active "1"

    log_info "PID:$pid - Inicia el monitoreo del CICS - $cics - con el archivo del logs $path"
  done
  IFS="$OLDIFS"
}

watcher_try_rotate() {
  cics="$1"
  cur_num=$(state_get "$cics" num)
  [ -z "$cur_num" ] && cur_num="000000"

  # incrementar decimal conservando width 6
  cur_dec=$(echo "$cur_num" | sed 's/^0*//')
  [ -z "$cur_dec" ] && cur_dec=0
  next_dec=$(expr "$cur_dec" + 1)
  next_num=$(printf "%06d" "$next_dec")

  next_path="$cics_base/$cics/console.$next_num"
  if [ -r "$next_path" ]; then
    if [ "$start_from_eof" = "true" ]; then
      sz=$(file_size_bytes "$next_path")
    else
      sz=0
    fi

    state_set "$cics" num "$next_num"
    state_set "$cics" path "$next_path"
    state_set "$cics" off "$sz"
    state_set "$cics" active "1"

    log_info "CICS - $cics - Se detecto cambio en el nombre del log de eventos - Nuevo nombre del archivo: $next_path"
  fi
}

watcher_read_appended() {
  cics="$1"

  active=$(state_get "$cics" active)
  path=$(state_get "$cics" path)
  off=$(state_get "$cics" off)

  [ "$active" = "1" ] || return

  if [ ! -r "$path" ]; then
    log_info "CICS - $cics - No se puede leer archivo actual: $path"
    state_set "$cics" active "0"
    watcher_try_rotate "$cics"
    return
  fi

  size=$(file_size_bytes "$path")
  [ -z "$size" ] && size=0
  [ -z "$off" ] && off=0

  if [ "$size" -gt "$off" ]; then
    start=$(expr "$off" + 1)

    # Leer solo bytes nuevos y procesar línea por línea
    tail -c +"$start" "$path" 2>/dev/null | while IFS= read line || [ -n "$line" ]; do
      should_copy_line "$line"
      if [ $? -eq 0 ]; then
        write_output_line "$cics" "$line"
      fi
    done

    state_set "$cics" off "$size"
  fi

  watcher_try_rotate "$cics"
}

watchers_tick() {
  OLDIFS="$IFS"
  IFS=,
  for cics in $cics_list; do
    cics=$(trim "$cics")
    [ -z "$cics" ] && continue

    active=$(state_get "$cics" active)
    if [ "$active" = "1" ]; then
      watcher_read_appended "$cics"
    else
      # reintento si estaba inactivo
      dir="$cics_base/$cics"
      max=$(find_highest_console_num "$dir")
      if [ "$max" != "-1" ] && [ -n "$max" ]; then
        path="$dir/console.$max"
        if [ -r "$path" ]; then
          if [ "$start_from_eof" = "true" ]; then
            sz=$(file_size_bytes "$path")
          else
            sz=0
          fi
          state_set "$cics" num "$max"
          state_set "$cics" path "$path"
          state_set "$cics" off "$sz"
          state_set "$cics" active "1"
          log_info "PID:$$ - Reanuda monitoreo de CICS - $cics - con archivo $path"
        fi
      fi
    fi
  done
  IFS="$OLDIFS"
}

# ==============================
# Señales
# ==============================

on_term() {
  RUNNING=0
}

on_hup() {
  RELOAD_CFG=1
}

# ==============================
# PID file / daemon control
# ==============================

pid_running() {
  pid="$1"
  [ -z "$pid" ] && return 1
  kill -0 "$pid" >/dev/null 2>&1
  return $?
}

read_pidfile() {
  [ -f "$PID_FILE" ] || return 1
  cat "$PID_FILE" 2>/dev/null
}

write_pidfile() {
  ensure_dir "$(dirname "$PID_FILE")"
  echo "$$" > "$PID_FILE"
}

remove_pidfile() {
  [ -f "$PID_FILE" ] && rm -f "$PID_FILE"
}

do_status() {
  pid=$(read_pidfile)
  if [ -n "$pid" ] && pid_running "$pid"; then
    echo "monitor_logs: RUNNING (PID $pid)"
    return 0
  fi
  echo "monitor_logs: STOPPED"
  return 1
}

do_stop() {
  pid=$(read_pidfile)
  if [ -z "$pid" ]; then
    echo "No PID file"
    return 1
  fi
  if pid_running "$pid"; then
    kill -TERM "$pid"
    sleep 1
    if pid_running "$pid"; then
      echo "No se detuvo aun, enviando SIGKILL..."
      kill -KILL "$pid" 2>/dev/null
    fi
    echo "Detenido"
  else
    echo "PID stale ($pid)"
  fi
  remove_pidfile
}

do_reload() {
  pid=$(read_pidfile)
  if [ -z "$pid" ]; then
    echo "No PID file"
    return 1
  fi
  if pid_running "$pid"; then
    kill -HUP "$pid"
    echo "Reload enviado a PID $pid"
    return 0
  fi
  echo "PID no activo"
  return 1
}

do_start() {
  pid=$(read_pidfile)
  if [ -n "$pid" ] && pid_running "$pid"; then
    echo "Ya esta corriendo (PID $pid)"
    return 0
  fi

  # start en background
  "$0" run -c "$CONFIG_FILE" >/dev/null 2>&1 &
  sleep 1

  pid=$(read_pidfile)
  if [ -n "$pid" ] && pid_running "$pid"; then
    echo "Iniciado (PID $pid)"
    return 0
  fi

  echo "Fallo al iniciar"
  return 1
}

# ==============================
# Loop principal
# ==============================

run_foreground() {
  load_config "$CONFIG_FILE" || exit 2

  trap on_term TERM INT
  trap on_hup HUP

  ensure_dir "$daemon_log_dir"
  ensure_dir "$output_dir"
  ensure_dir "$STATE_DIR"

  write_pidfile

  OUT_DAY=$(day_now)
  OUT_LINE_COUNT=0
  OUT_ROT_IDX=0

  log_info "PID:$$ - Inicio daemon de monitoreo de logs CICS"

  watchers_init

  while [ "$RUNNING" -eq 1 ]; do
    output_reopen_if_day_changed
    watchers_tick

    if [ "$RELOAD_CFG" -eq 1 ]; then
      RELOAD_CFG=0
      log_info "PID:$$ - Recargando configuracion (SIGHUP)..."
      if load_config "$CONFIG_FILE"; then
        watchers_init
        OUT_DAY=$(day_now)
        OUT_LINE_COUNT=0
        OUT_ROT_IDX=0
        log_info "PID:$$ - Configuracion recargada OK."
      else
        log_info "PID:$$ - Recarga fallida de configuracion."
      fi
    fi

    sleep_ms "$poll_ms"
  done

  log_info "Se detiene el daemon de monitoreo de logs CICS"
  remove_pidfile
  rm -rf "$STATE_DIR" 2>/dev/null
}

usage() {
  echo "Uso: $0 {start|stop|status|reload|run} [-c /ruta/config.cfg]"
}

# ==============================
# Entrada
# ==============================

ACTION="$1"
[ -z "$ACTION" ] && { usage; exit 1; }
shift

# parse opcional -c
while [ $# -gt 0 ]; do
  case "$1" in
    -c)
      shift
      CONFIG_FILE="$1"
      ;;
    *)
      ;;
  esac
  shift
done

case "$ACTION" in
  start) do_start ;;
  stop) do_stop ;;
  status) do_status ;;
  reload) do_reload ;;
  run) run_foreground ;;
  *) usage; exit 1 ;;
esac
