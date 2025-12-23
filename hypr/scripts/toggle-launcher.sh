#!/usr/bin/env bash

LAUNCHER="wofi"

# Si wofi ya está corriendo → lo matamos
if pgrep -x "$LAUNCHER" > /dev/null; then
    pkill "$LAUNCHER"
else
    wofi --show drun
fi

