#!/usr/bin/env bash
set -euo pipefail
menu() { wofi --dmenu --prompt "Screenshot" --width 560 --height 300 --cache-file /dev/null; }

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
FILE="$DIR/shot_$(date +%Y-%m-%d_%H-%M-%S).png"

choice="$(
  printf "%s\n" \
    "  Area (select)" \
    "  Full screen" \
    "  Area to clipboard" \
  | menu
)"

case "${choice:-}" in
  *"Area (select)"*) grim -g "$(slurp)" "$FILE" ;;
  *"Full screen"*) grim "$FILE" ;;
  *"Area to clipboard"*) grim -g "$(slurp)" - | wl-copy ;;
esac

