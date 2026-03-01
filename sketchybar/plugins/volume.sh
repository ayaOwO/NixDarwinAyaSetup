#!/usr/bin/env bash
# Volume indicator: icon and padding by level, label shows percentage.

THEME_DIR="$HOME/.config/sketchybar/themes"
source "$THEME_DIR/catppuccin-latte.sh"
source "$THEME_DIR/helpers.sh"
source "$THEME_DIR/env.sh"

# Use INFO if set (e.g. from volume_change), else read current output volume
if [ -z "${INFO:-}" ]; then
  INFO="$(osascript -e 'output volume of (get volume settings)' 2>/dev/null || echo "0")"
fi

# Nerd Font: U+F026 = volume mute, U+F028 = volume high
case "${INFO}" in
  0)
    ICON=$'\uF026'
    ICON_PADDING_RIGHT=21
    ;;
  [0-9])
    ICON=$'\uF028'
    ICON_PADDING_RIGHT=12
    ;;
  *)
    ICON=$'\uF028'
    ICON_PADDING_RIGHT=6
    ;;
esac

sketchybar --set "$NAME" \
  icon="$ICON" \
  icon.padding_right="$ICON_PADDING_RIGHT" \
  icon.color=$(c "$TEXT") \
  label="${INFO}%" \
  label.color=$(c "$TEXT")
