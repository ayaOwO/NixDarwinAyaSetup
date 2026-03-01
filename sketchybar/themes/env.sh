# Shared env for sketchybar config and plugins

# Load secrets from sketchybar/.env if present (MEETINGS_ICAL_URL, etc.)
THEME_DIR="$HOME/.config/sketchybar/themes"
CONFIG_DIR="$(dirname "$THEME_DIR")"
[ -r "$CONFIG_DIR/.env" ] && source "$CONFIG_DIR/.env"

# AeroSpace CLI (used by workspace plugin)
AEROSPACE=aerospace
# set in secrets.sh MEETINGS_ICAL_URL

# Theme by system appearance (set THEME from these when env.sh is sourced)
DARK_THEME="catppuccin-macchiato"
LIGHT_THEME="catppuccin-latte"
if [ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" = "Dark" ]; then
  THEME="$DARK_THEME"
else
  THEME="$LIGHT_THEME"
fi

FONT="Maple Mono NF"
# SF Symbols / battery (use for battery item when using pasted SF Symbol glyphs)
MAC_SF_SYMBOLS="SF Pro:Regular:13.0"
# App icons (sketchybar-app-font); plugins use this for icon glyphs
[ -f "$HOME/Library/Fonts/sketchybar-app-font.ttf" ] && ICON_FONT="sketchybar-app-font" || ICON_FONT="$FONT"

##### Layout constants (shared by sketchybarrc and plugins) #####
BAR_HEIGHT=38
BAR_PADDING=10
BAR_BORDER_WIDTH=1
BAR_BLUR_RADIUS=0
PADDING_DEFAULT=4
PADDING_ICON_RIGHT=4
FONT_SIZE=13.0
FONT_SIZE_SMALL=12.0
FONT_SIZE_LARGE=14.0
PILL_HEIGHT=22
PILL_CORNER_RADIUS=4
SPACE_PADDING_LEFT=8
SPACE_PADDING_RIGHT=0
SPACE_ICON_PADDING_LEFT=10
SPACE_LABEL_PADDING_RIGHT=4
SPACE_ICONS_PADDING_LEFT=2
SPACE_ICONS_PADDING_RIGHT=8
POPUP_HEIGHT=22
SPACE_LABEL_FONT="$FONT:Regular:$FONT_SIZE"
SPACE_ICON_FONT="$ICON_FONT:Regular:$FONT_SIZE"
UPDATE_FREQ_FAST=2
UPDATE_FREQ_MED=5
UPDATE_FREQ_SLOW=10
UPDATE_FREQ_MINUTE=60