#!/bin/bash

HEX="$1"
HEX="${HEX#\#}"

if [[ -z "$HEX" ]]; then
  echo "Usage: set-accent.sh RRGGBB"
  exit 1
fi

if [[ ! "$HEX" =~ ^[0-9a-fA-F]{6}$ ]]; then
  echo "Invalid hex: $HEX"
  exit 1
fi

HOME_DIR="$HOME"

# Waybar
mkdir -p "$HOME_DIR/.config/waybar"
printf "@define-color accent #%s;\n" "$HEX" > "$HOME_DIR/.config/waybar/colors.css"

# Wofi
# Wofi (replace tokens)
if [[ -f "$HOME/.config/wofi/style.css" ]]; then
  sed -i "s/__ACCENT__/#${HEX}/g" "$HOME/.config/wofi/style.css"
fi

# Hyprland (re-escribe SOLO el accent, sin sed)
mkdir -p "$HOME_DIR/.config/hypr/conf"
if grep -q '^\$accent' "$HOME_DIR/.config/hypr/conf/colors.conf" 2>/dev/null; then
  # reconstruimos el archivo cambiando la línea $accent
  awk -v hex="$HEX" '
    BEGIN{done=0}
    /^\$accent/ {print "$accent    = rgb(" hex ")"; done=1; next}
    {print}
    END{ if(!done) print "$accent    = rgb(" hex ")" }
  ' "$HOME_DIR/.config/hypr/conf/colors.conf" > "$HOME_DIR/.config/hypr/conf/colors.conf.tmp" \
  && mv "$HOME_DIR/.config/hypr/conf/colors.conf.tmp" "$HOME_DIR/.config/hypr/conf/colors.conf"
else
  printf "\$accent    = rgb(%s)\n" "$HEX" >> "$HOME_DIR/.config/hypr/conf/colors.conf"
fi

# Mako (border)
mkdir -p "$HOME_DIR/.config/mako"
if [[ -f "$HOME_DIR/.config/mako/config" ]]; then
  if grep -q '^border-color=' "$HOME_DIR/.config/mako/config"; then
    sed -i "s/^border-color=.*/border-color=#${HEX}/" "$HOME_DIR/.config/mako/config"
  else
    printf "border-color=#%s\n" "$HEX" >> "$HOME_DIR/.config/mako/config"
  fi
fi

# Reload
hyprctl reload >/dev/null 2>&1
pkill waybar >/dev/null 2>&1; waybar >/dev/null 2>&1 &
pkill mako >/dev/null 2>&1; mako >/dev/null 2>&1 &

echo "Accent applied: #$HEX"
