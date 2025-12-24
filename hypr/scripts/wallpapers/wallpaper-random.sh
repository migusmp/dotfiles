#!/usr/bin/env bash
set -euo pipefail

WALLPAPERS="$HOME/Pictures/Wallpapers"

# Crear carpeta si no existe
mkdir -p "$WALLPAPERS"

# Comprobar que hay imágenes
IMG=$(find "$WALLPAPERS" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \
\) | shuf -n 1)

# Si no hay imágenes, salir sin error
[ -z "${IMG:-}" ] && exit 0

# Cambiar wallpaper con transición
swww img "$IMG" \
  --transition-type wipe \
  --transition-duration 1

