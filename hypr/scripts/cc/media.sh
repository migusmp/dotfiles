#!/usr/bin/env bash
set -euo pipefail
menu() { wofi --dmenu --prompt "Media" --width 560 --height 300 --cache-file /dev/null; }

choice="$(
  printf "%s\n" \
    "󰎈  Play/Pause" \
    "󰒭  Next" \
    "󰒮  Prev" \
    "󰎈  Stop" \
  | menu
)"

case "${choice:-}" in
  *"Play/Pause"*) playerctl play-pause ;;
  *"Next"*) playerctl next ;;
  *"Prev"*) playerctl previous ;;
  *"Stop"*) playerctl stop ;;
esac

