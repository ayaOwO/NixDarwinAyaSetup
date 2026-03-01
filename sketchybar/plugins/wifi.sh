#!/usr/bin/env bash
# Wi-Fi indicator for SketchyBar (uses airport -I)

THEME_DIR="$HOME/.config/sketchybar/themes"
source "$THEME_DIR/catppuccin-latte.sh"
source "$THEME_DIR/helpers.sh"
source "$THEME_DIR/env.sh"

AIRPORT="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"

SSID=""
RATE=""

if [ -x "$AIRPORT" ]; then
  WIFI_INFO="$("$AIRPORT" -I 2>/dev/null)"
  SSID="$(echo "$WIFI_INFO" | awk -F': ' '/ SSID/ {print $2; exit}')"
  RATE="$(echo "$WIFI_INFO" | awk -F': ' '/ lastTxRate/ {print $2; exit}')"
fi

if [ -z "$SSID" ]; then
  # Disconnected
  sketchybar --set "$NAME" \
    icon="󰤭" \
    icon.color=$(c "$OVERLAY1") \
    label="Offline" \
    label.color=$(c "$OVERLAY1")
else
  LABEL="$SSID"
  if [ -n "$RATE" ]; then
    LABEL="$SSID (${RATE}Mbps)"
  fi

  sketchybar --set "$NAME" \
    icon="󰤨" \
    icon.color=$(c "$BLUE") \
    label="$LABEL" \
    label.color=$(c "$TEXT")
fi

