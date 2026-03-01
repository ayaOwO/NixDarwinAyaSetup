#!/usr/bin/env bash
# Run on AppleInterfaceThemeChangedNotification: reload theme (DARK_THEME/LIGHT_THEME)
# and update bar + defaults in place; then refresh all items so plugins use new colors.
# See: https://github.com/FelixKratz/SketchyBar/discussions/159

THEME_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}/themes"
source "$THEME_DIR/env.sh"
source "$THEME_DIR/${THEME}.sh"
source "$THEME_DIR/helpers.sh"

# Bar and default colors (--bar for bar properties, not --set bar)
sketchybar --bar color=$(c "$BASE") border_color=$(c "$SURFACE1")
sketchybar --default icon.color=$(c "$TEXT") label.color=$(c "$TEXT")

# Force all item scripts to re-run so they source the new theme and update their colors
sketchybar --update
