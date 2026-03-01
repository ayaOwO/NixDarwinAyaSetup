#!/usr/bin/env bash
# Prevent-sleep toggle for SketchyBar, using caffeinate.

THEME_DIR="$HOME/.config/sketchybar/themes"
source "$THEME_DIR/catppuccin-latte.sh"
source "$THEME_DIR/helpers.sh"
source "$THEME_DIR/env.sh"

ACTION="$1"

is_active() {
  pgrep -qx caffeinate
}

if [ "$ACTION" = "toggle" ]; then
  if is_active; then
    pkill -x caffeinate || true
  else
    # Keep system awake until explicitly turned off
    caffeinate -dimsu >/dev/null 2>&1 &
  fi
fi

if is_active; then
  ICON="󰤄"   # "no sleep" / wake icon
  COLOR=$(c "$GREEN")
  LABEL="Awake"
else
  ICON="󰒲"   # moon / sleep icon
  COLOR=$(c "$OVERLAY1")
  LABEL="Sleep OK"
fi

sketchybar --set "$NAME" \
  drawing=on \
  icon="$ICON" \
  icon.color="$COLOR" \
  label="$LABEL" \
  label.color=$(c "$TEXT")

