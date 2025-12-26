#!/usr/bin/env bash
set -euo pipefail
menu() { wofi --dmenu --prompt "Bluetooth" --width 560 --height 420 --cache-file /dev/null; }

powered="$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered/{print $2}' || echo "no")"
powered_lc="$(echo "$powered" | tr '[:upper:]' '[:lower:]')"

choice="$(
  printf "%s\n" \
    "  Toggle Bluetooth (now: $powered_lc)" \
    "󰂱  Devices…" \
    "󰑓  Scan 10s" \
  | menu
)"

case "${choice:-}" in
  *"Toggle"*)
    if [[ "$powered_lc" == "yes" ]]; then bluetoothctl power off; else bluetoothctl power on; fi
    ;;
  *"Scan"*)
    bluetoothctl power on >/dev/null 2>&1 || true
    bluetoothctl scan on >/dev/null 2>&1 &
    sleep 10
    bluetoothctl scan off >/dev/null 2>&1 || true
    ;;
  *"Devices…"*)
    bluetoothctl power on >/dev/null 2>&1 || true
    list="$(bluetoothctl devices | sed 's/^Device //')"
    dev="$(printf "%s\n" "$list" | wofi --dmenu --prompt "Select device" --width 700 --height 520 --cache-file /dev/null || true)"
    mac="$(printf "%s" "$dev" | awk '{print $1}')"
    name="$(printf "%s" "$dev" | cut -d' ' -f2-)"
    [[ -z "${mac:-}" ]] && exit 0

    sub="$(
      printf "%s\n" \
        "󰒓  Connect: $name" \
        "󰒔  Disconnect: $name" \
        "󰓛  Pair: $name" \
        "󰗼  Remove: $name" \
      | wofi --dmenu --prompt "Action" --width 560 --height 320 --cache-file /dev/null
    )"

    case "${sub:-}" in
      *"Connect"*) bluetoothctl connect "$mac" ;;
      *"Disconnect"*) bluetoothctl disconnect "$mac" ;;
      *"Pair"*) bluetoothctl pair "$mac" ;;
      *"Remove"*) bluetoothctl remove "$mac" ;;
    esac
    ;;
esac

