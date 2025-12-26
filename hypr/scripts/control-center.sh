#!/usr/bin/env bash
set -euo pipefail

# =========================
# Control Center (PRO)
# - Hyprland + Wofi
# - No hangs (timeouts)
# - Logs to ~/.cache/cc/cc.log
# =========================

CC_DIR="$HOME/.config/hypr/scripts/cc"
CACHE_DIR="$HOME/.cache/cc"
LOG="$CACHE_DIR/cc.log"

mkdir -p "$CACHE_DIR"

# Log everything (stdout+stderr) to file + terminal
exec > >(tee -a "$LOG") 2>&1

echo "---- control-center start: $(date) ----"
echo "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-} DISPLAY=${DISPLAY:-} XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-}"
echo "CC_DIR=$CC_DIR"

# ---------- helpers ----------
# Run a command with a short timeout and never hang the UI
run_quick() {
  # usage: run_quick <seconds> <cmd...>
  local t="$1"; shift
  timeout "${t}s" "$@" 2>/dev/null || true
}

wifi_state() {
  local out
  out="$(run_quick 0.8 nmcli -t -f WIFI g | head -n1)"
  [[ -n "${out:-}" ]] && echo "$out" || echo "unknown"
}

wifi_ssid() {
  # returns active ssid or empty
  run_quick 0.8 nmcli -t -f active,ssid dev wifi \
    | awk -F: '$1=="yes"{print $2; exit}' || true
}

bt_state() {
  # if bluetoothd is down/hung, this would hang → guarded
  local out
  out="$(run_quick 0.8 bluetoothctl show | awk -F': ' '/Powered/{print tolower($2)}')"
  [[ -n "${out:-}" ]] && echo "$out" || echo "unknown"
}

dnd_state() {
  if command -v swaync-client >/dev/null 2>&1; then
    local out
    out="$(run_quick 0.8 swaync-client -D | tr '[:upper:]' '[:lower:]')"
    [[ -n "${out:-}" ]] && echo "$out" || echo "unknown"
    return 0
  fi

  if command -v makoctl >/dev/null 2>&1; then
    if run_quick 0.8 makoctl mode | grep -qi "do-not-disturb"; then
      echo "true"
    else
      echo "false"
    fi
    return 0
  fi

  echo "unknown"
}

vol_human() {
  local out
  out="$(run_quick 0.5 pamixer --get-volume-human)"
  [[ -n "${out:-}" ]] && echo "$out" || echo "?"
}

bri_human() {
  local out
  out="$(run_quick 0.5 brightnessctl -m | awk -F, '{print $4}')"
  [[ -n "${out:-}" ]] && echo "$out" || echo "?"
}

wofi_menu() {
  command -v wofi >/dev/null 2>&1 || { echo "ERROR: wofi not found"; exit 1; }
  export GDK_BACKEND=wayland

  # If your wofi CSS breaks visibility, uncomment for a quick test:
  # wofi --dmenu --prompt "Control Center" --width 560 --height 420 --cache-file /dev/null --style /dev/null

  wofi --dmenu --prompt "Control Center" --width 560 --height 420 --cache-file /dev/null
}

# ---------- collect status (never hang) ----------
echo "collecting status…"
wifi="$(wifi_state)"
ssid="$(wifi_ssid)"; [[ -z "${ssid:-}" ]] && ssid="—"
bt="$(bt_state)"
dnd="$(dnd_state)"
vol="$(vol_human)"
bri="$(bri_human)"

echo "status: wifi=$wifi ssid=$ssid bt=$bt dnd=$dnd vol=$vol bri=$bri"

# Icons
WIFI_ICON="󰖪"; [[ "$wifi" == "enabled" ]] && WIFI_ICON="󰖩"
BT_ICON="󰂲";   [[ "$bt" == "yes" || "$bt" == "true" || "$bt" == "on" ]] && BT_ICON=""
DND_ICON="󰂚";  [[ "$dnd" == "true" ]] && DND_ICON="󰂛"

# ---------- build menu ----------
echo "building menu…"
MENU="$(printf "%s\n" \
  "$WIFI_ICON  Wi-Fi            [$wifi]  ($ssid)" \
  "$BT_ICON  Bluetooth       [$bt]" \
  "$DND_ICON  Do Not Disturb   [$dnd]" \
  "  Audio            [$vol]" \
  "󰃠  Brightness       [$bri]" \
  "󰎈  Media" \
  "  Screenshot" \
  "  Clipboard" \
  "  Apps" \
  "󰐥  Lock" \
  "󰍃  Logout" \
  "󰜉  Reboot" \
  "  Shutdown")"

echo "opening wofi…"
choice="$(printf "%s\n" "$MENU" | wofi_menu || true)"
echo "wofi returned. choice=[$choice]"

[[ -z "${choice:-}" ]] && exit 0

# ---------- dispatch ----------
case "$choice" in
  *"Wi-Fi"*)            exec "$CC_DIR/wifi.sh" ;;
  *"Bluetooth"*)        exec "$CC_DIR/bluetooth.sh" ;;
  *"Do Not Disturb"*)   exec "$CC_DIR/dnd.sh" ;;
  *"Audio"*)            exec "$CC_DIR/audio.sh" ;;
  *"Brightness"*)       exec "$CC_DIR/brightness.sh" ;;
  *"Media"*)            exec "$CC_DIR/media.sh" ;;
  *"Screenshot"*)       exec "$CC_DIR/screenshoot.sh" ;;  # rename to screenshot.sh if you prefer
  *"Clipboard"*)        exec "$CC_DIR/clipboard.sh" ;;
  *"Apps"*)             exec "$CC_DIR/apps.sh" ;;
  *"Lock"*)             exec "$CC_DIR/lock.sh" ;;
  *"Logout"*)           hyprctl dispatch exit ;;
  *"Reboot"*)           systemctl reboot ;;
  *"Shutdown"*)         systemctl poweroff ;;
esac

