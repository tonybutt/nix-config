#!/usr/bin/env bash

DISK="${1:-/dev/nvme0n1}"

echo "=============================================="
echo " DRIVE IDENTITY"
echo "=============================================="
nvme id-ctrl "$DISK" 2>/dev/null | grep -E "^(mn|sn|fr|tnvmcap|oacs)" || true
lsblk -d -o NAME,SIZE,MODEL,SERIAL,ROTA,TRAN "$DISK" || true

echo
echo "=============================================="
echo " SMART HEALTH  (the numbers that decide)"
echo "=============================================="
nvme smart-log "$DISK" 2>/dev/null | grep -Ei \
  "critical_warning|percentage_used|available_spare|media_errors|unsafe_shutdowns|power_on_hours|data_units_written" || true

echo
echo "=============================================="
echo " FULL SMART"
echo "=============================================="
smartctl -a "$DISK" || true

echo
echo "=============================================="
echo " CONTROLLER ERROR LOG"
echo "=============================================="
nvme error-log "$DISK" 2>/dev/null | head -40 || true

echo
echo "=============================================="
echo " HARDWARE  (for sourcing a replacement)"
echo "=============================================="
lspci -nn | grep -i "non-volatile" || true
dmidecode -s system-manufacturer 2>/dev/null || true
dmidecode -s system-product-name 2>/dev/null || true
dmidecode -s baseboard-product-name 2>/dev/null || true
lshw -quiet -class disk -class storage 2>/dev/null || true
