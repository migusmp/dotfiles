#!/usr/bin/env bash

WALLPAPERS="$HOME/Pictures/Wallpapers"
IMG=$(find "$WALLPAPERS" -type f | shuf -n 1)

swww img "$IMG" \
    --transition-type wipe \
    --transition-duration 1
