#!/usr/bin/env bash
# Battery indicator for SketchyBar (uses pmset -g batt)

THEME_DIR="$HOME/.config/sketchybar/themes"
source "$THEME_DIR/catppuccin-latte.sh"
source "$THEME_DIR/helpers.sh"
source "$THEME_DIR/env.sh"

RAW="$(pmset -g batt 2>/dev/null | grep -E 'InternalBattery')"
PCT="$(echo "$RAW" | grep -Eo '[0-9]+%' | head -n1 | tr -d '%')"
CHARGING="$(echo "$RAW" | grep 'AC Power' || true)"

if [ -z "$PCT" ]; then
  # No battery (desktop), hide item
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

sketchybar --set "$NAME" drawing=on

# Pick icon by level (Nerd Font battery icons)
ICON="" # empty
COLOR=$(c "$RED")

if [ "$PCT" -ge 80 ]; then
  ICON=""
  COLOR=$(c "$GREEN")
elif [ "$PCT" -ge 60 ]; then
  ICON=""
  COLOR=$(c "$GREEN")
elif [ "$PCT" -ge 40 ]; then
  ICON=""
  COLOR=$(c "$YELLOW")
elif [ "$PCT" -ge 20 ]; then
  ICON=""
  COLOR=$(c "$ORANGE")
fi

if [ -n "$CHARGING" ]; then
  # On AC: use a charging glyph and accent color
  ICON=""
  COLOR=$(c "$GREEN")
fi

sketchybar --set "$NAME" \
  icon="$ICON" \
  icon.color="$COLOR" \
  label="${PCT}%" \
  label.color=$(c "$TEXT")

