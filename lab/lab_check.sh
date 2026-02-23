#!/usr/bin/env bash
set -euo pipefail

LAB=/tmp/cics_lab
LOG_DIR="$LAB/var/log/monitor_logs"
DAY="$(date +%Y%m%d)"

OUT="$LOG_DIR/${DAY}-console_error_s21.log"

echo "Archivo output esperado: $OUT"
ls -lh "$LOG_DIR" || true
echo

if [[ -f "$OUT" ]]; then
  echo "Primeras 10 lineas:"
  head -n 10 "$OUT"
  echo
  echo "Validando prefijo 'CICSRPR1 -' / 'CICSFTD1 -'..."
  grep -E '^(CICSRPR1|CICSFTD1) - ' "$OUT" | head -n 5
else
  echo "No existe output aun. Verifica que el daemon este corriendo y que copy_mode/include_codes coincida."
fi

echo
echo "Log interno del daemon (hoy):"
ls -lh "$LOG_DIR/${DAY}-monitor_logs.log" 2>/dev/null || true
