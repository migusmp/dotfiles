#!/usr/bin/env bash
set -euo pipefail

WARP="warp-cli --accept-tos"

# asegura daemon
if ! systemctl is-active --quiet warp-svc.service; then
  sudo systemctl enable --now warp-svc.service
fi

status="$($WARP status 2>/dev/null | awk -F': ' 'tolower($1) ~ /status/ {print $2; exit}' || true)"

if [[ "$status" == "Connected" ]]; then
  $WARP disconnect
  notify-send "VPN" "Cloudflare WARP: OFF"
else
  $WARP registration show >/dev/null 2>&1 || $WARP registration new
  $WARP mode warp
  $WARP connect
  notify-send "VPN" "Cloudflare WARP: ON"
fi
