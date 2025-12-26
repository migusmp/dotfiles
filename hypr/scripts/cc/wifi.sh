#!/usr/bin/env bash
set -euo pipefail

menu() { wofi --dmenu --prompt "Wi-Fi" --width 560 --height 420 --cache-file /dev/null; }

state="$(nmcli -t -f WIFI g | head -n1 || echo unknown)"
ssid="$(nmcli -t -f active,ssid dev wifi | awk -F: '$1=="yes"{print $2; exit}' || true)"
[[ -z "${ssid:-}" ]] && ssid="—"

choice="$(
  printf "%s\n" \
    "󰖩  Toggle Wi-Fi  (now: $state)" \
    "󰖩  Connect…" \
    "󰖪  Disconnect" \
    "󰑓  Rescan" \
  | menu
)"

case "${choice:-}" in
  *"Toggle"*)
    if [[ "$state" == "enabled" ]]; then nmcli radio wifi off; else nmcli radio wifi on; fi
    ;;
  *"Connect…"*)
    # list networks
    net="$(
      nmcli -t -f ssid,signal,security dev wifi list --rescan yes \
      | awk -F: 'NF{printf "%s\t%s%%\t%s\n",$1,$2,$3}' \
      | sort -k2 -nr \
      | wofi --dmenu --prompt "Select SSID" --width 560 --height 520 --cache-file /dev/null
    )"
    ssid_sel="$(printf "%s" "$net" | awk -F'\t' '{print $1}')"
    [[ -z "${ssid_sel:-}" ]] && exit 0

    # try connect (will use saved creds if exists)
    if ! nmcli dev wifi connect "$ssid_sel" >/dev/null 2>&1; then
      pass="$(wofi --dmenu --password --prompt "Password for $ssid_sel" --width 420 --height 120 --cache-file /dev/null || true)"
      [[ -z "${pass:-}" ]] && exit 0
      nmcli dev wifi connect "$ssid_sel" password "$pass"
    fi
    ;;
  *"Disconnect"*)
    active="$(nmcli -t -f active,ssid dev wifi | awk -F: '$1=="yes"{print $2; exit}')"
    [[ -n "${active:-}" ]] && nmcli con down "Wi-Fi connection" >/dev/null 2>&1 || nmcli dev disconnect wlan0 2>/dev/null || true
    ;;
  *"Rescan"*) nmcli dev wifi rescan ;;
esac

