#!/usr/bin/env bash
set -euo pipefail

LAB=/tmp/cics_lab
CICS_BASE="$LAB/var/cics_regions"
LOG_DIR="$LAB/var/log/monitor_logs"
CFG_DIR="$LAB/etc/monitor_logs"
CFG="$CFG_DIR/config.cfg"

mkdir -p "$CICS_BASE" "$LOG_DIR" "$CFG_DIR"

# Dos CICS de prueba
for c in CICSRPR1 CICSFTD1; do
  mkdir -p "$CICS_BASE/$c"
  : > "$CICS_BASE/$c/console.000001"
done

cat > "$CFG" <<'EOF'
cics_base=/tmp/cics_lab/var/cics_regions
cics_list=CICSRPR1,CICSFTD1
poll_ms=1000
start_from_eof=true

copy_mode=include
include_codes=ERZ030022E,ERZ014016E,ERZ014040E
exclude_codes=ERZ010075E,ERZ014048E

output_dir=/tmp/cics_lab/var/log/monitor_logs
output_tag=s21

rotate_lines=20
rotate_max=999

daemon_log_dir=/tmp/cics_lab/var/log/monitor_logs
EOF

echo "LAB listo:"
echo "  CICS_BASE=$CICS_BASE"
echo "  LOG_DIR=$LOG_DIR"
echo "  CFG=$CFG"
echo
echo "Tip: ejecuta el daemon asi:"
echo "  ./monitor_logs -c $CFG"
