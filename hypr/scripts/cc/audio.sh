#!/usr/bin/env bash
set -euo pipefail
menu() { wofi --dmenu --prompt "Audio" --width 560 --height 360 --cache-file /dev/null; }

vol="$(pamixer --get-volume 2>/dev/null || echo 0)"
mute="$(pamixer --get-mute 2>/dev/null || echo false)"

choice="$(
  printf "%s\n" \
    "  Volume +5   (now: ${vol}%)" \
    "  Volume -5" \
    "󰖁  Toggle Mute (now: $mute)" \
    "󰍂  Open Mixer (pavucontrol)" \
  | menu
)"

case "${choice:-}" in
  *"+5"*) pamixer -i 5 ;;
  *"-5"*) pamixer -d 5 ;;
  *"Mute"*) pamixer -t ;;
  *"Mixer"*) pavucontrol ;;
esac

