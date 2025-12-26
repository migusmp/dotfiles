#!/usr/bin/env bash
set -euo pipefail

if command -v swaync-client >/dev/null 2>&1; then
  # toggle
  swaync-client -dn
  exit 0
fi

if command -v makoctl >/dev/null 2>&1; then
  # toggle do-not-disturb mode
  if makoctl mode | grep -qi "do-not-disturb"; then
    makoctl mode -r do-not-disturb
  else
    makoctl mode -a do-not-disturb
  fi
  exit 0
fi

wofi --dmenu --prompt "DND" --width 520 --height 160 <<<"Install swaync or mako to use DND"

