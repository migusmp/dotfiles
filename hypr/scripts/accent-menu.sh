#!/bin/bash
set -euo pipefail

choices=$(
  cat <<'LIST'
Blanco|ffffff
Azul|7aa2f7
Cian|00ffcc
Verde|00ff66
Amarillo|ffd166
Naranja|ff8a00
Rojo|ff3355
Morado|a78bfa
LIST
)

picked="$(echo "$choices" | cut -d'|' -f1 | wofi --dmenu --prompt 'Accent' --width 420 --height 320)"
[[ -z "$picked" ]] && exit 0

hex="$(echo "$choices" | awk -F'|' -v p="$picked" '$1==p{print $2}')"
"$HOME/.config/hypr/scripts/set-accent.sh" "$hex"
