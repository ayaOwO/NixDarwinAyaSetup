#!/bin/bash
# caffeinate.sh — show coffee icon when caffeinate is active; click to toggle (macOS)

THEME_DIR="${THEME_DIR:-$HOME/.config/sketchybar/themes}"
[ -r "$THEME_DIR/catppuccin-latte.sh" ] && source "$THEME_DIR/catppuccin-latte.sh"
[ -r "$THEME_DIR/helpers.sh" ] && source "$THEME_DIR/helpers.sh"

COFFEE=''   # Nerd Font coffee icon

if [ "${1:-}" = "toggle" ]; then
  if pgrep -x caffeinate >/dev/null; then
    pkill -x caffeinate
  else
    caffeinate -d &
  fi
  sleep 0.3
fi

if pgrep -x caffeinate >/dev/null; then
  sketchybar --set "$NAME" icon="$COFFEE" icon.color=$(c "${PEACH:-#fe640b}") label=""
else
  sketchybar --set "$NAME" icon="$COFFEE" icon.color=$(c "${OVERLAY1:-#8c8fa1}") label=""
fi
