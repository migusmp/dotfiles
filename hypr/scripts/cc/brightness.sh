#!/usr/bin/env bash
set -euo pipefail
menu() { wofi --dmenu --prompt "Brightness" --width 560 --height 300 --cache-file /dev/null; }

bri="$(brightnessctl -m 2>/dev/null | awk -F, '{print $4}' || echo "?")"

choice="$(
  printf "%s\n" \
    "󰃠  +5%   (now: $bri)" \
    "󰃠  -5%" \
    "󰃠  +1% (fine)" \
    "󰃠  -1% (fine)" \
  | menu
)"

case "${choice:-}" in
  *"+5%"*) brightnessctl set +5% ;;
  *"-5%"*) brightnessctl set 5%- ;;
  *"+1%"*) brightnessctl set +1% ;;
  *"-1%"*) brightnessctl set 1%- ;;
esac

