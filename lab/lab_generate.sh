#!/usr/bin/env bash
set -euo pipefail

LAB=/tmp/cics_lab
CICS_BASE="$LAB/var/cics_regions"

# Escribe N lineas con mezcla de normal/errores
write_burst() {
  local cics="$1" file="$2" n="${3:-30}"
  for i in $(seq 1 "$n"); do
    # cada 5 lineas, mete un error incluido
    if (( i % 5 == 0 )); then
      echo "ERZ030022E/2604 10/06/25 15:34:22.495170365 $cics 20185478/0001 : Unable to allocate storage for incoming data ($i)" >> "$file"
    else
      echo "INFO 10/06/25 15:34:22.495170365 $cics Normal line $i" >> "$file"
    fi
    sleep 0.05
  done
}

# Simula rotacion: console.000001 -> console.000002
rotate_console() {
  local cics="$1" from="$2" to="$3"
  local dir="$CICS_BASE/$cics"

  # “CICS reinicia”: mueve el anterior a backup y crea el siguiente
  mkdir -p "$dir/backup"
  mv "$dir/$from" "$dir/backup/$from.$(date +%s)"
  : > "$dir/$to"
  echo "[ROTATE] $cics: $from -> $to"
}

# Ciclo de prueba
for c in CICSRPR1 CICSFTD1; do
  echo "== Generando burst inicial para $c =="
  write_burst "$c" "$CICS_BASE/$c/console.000001" 25
done

echo "== Simulando reinicio de CICSRPR1 (rotacion console) =="
rotate_console "CICSRPR1" "console.000001" "console.000002"
write_burst "CICSRPR1" "$CICS_BASE/CICSRPR1/console.000002" 30

echo "== Simulando reinicio de CICSFTD1 (rotacion console) =="
rotate_console "CICSFTD1" "console.000001" "console.000002"
write_burst "CICSFTD1" "$CICS_BASE/CICSFTD1/console.000002" 30

echo "Listo. Revisa outputs en:"
echo "  $LAB/var/log/monitor_logs/"
