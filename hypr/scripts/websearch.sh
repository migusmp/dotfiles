#!/usr/bin/env bash
set -euo pipefail

# Elige tu buscador
# ENGINE="https://www.google.com/search?q="
ENGINE="https://duckduckgo.com/?q="

query="$(printf "" | wofi --dmenu --prompt "Search web" --width 600 --lines 1)"
[[ -z "${query// }" ]] && exit 0

# Encode mínimo (espacios -> +). Suficiente para uso normal.
q="${query// /+}"

# Abre en el navegador por defecto
xdg-open "${ENGINE}${q}" >/dev/null 2>&1 &

