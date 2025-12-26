#!/usr/bin/env bash
set -euo pipefail
menu() { wofi --dmenu --prompt "Clipboard" --width 560 --height 240 --cache-file /dev/null; }

choice="$(
  printf "%s\n" \
    "  Paste (Ctrl+V in app)" \
    "󰅙  Clear clipboard" \
  | menu
)"

case "${choice:-}" in
  *"Clear"*) printf "" | wl-copy ;;
esac

