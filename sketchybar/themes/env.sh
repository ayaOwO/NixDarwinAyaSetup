# Shared env for sketchybar config and plugins

# Load secrets from sketchybar/.env if present (MEETINGS_ICAL_URL, etc.)
CONFIG_DIR="$(dirname "${THEME_DIR:-$HOME/.config/sketchybar/themes}")"
[ -r "$CONFIG_DIR/.env" ] && source "$CONFIG_DIR/.env"

# AeroSpace CLI (used by workspace plugin)
AEROSPACE=aerospace
MEETINGS_ICAL_URL="${MEETINGS_ICAL_URL:-}"

THEME="catppuccin-latte"

FONT="Maple Mono NF"
# SF Symbols / battery (use for battery item when using pasted SF Symbol glyphs)
MAC_SF_SYMBOLS="SF Pro:Regular:13.0"
# App icons (sketchybar-app-font); plugins use this for icon glyphs
[ -f "$HOME/Library/Fonts/sketchybar-app-font.ttf" ] && ICON_FONT="sketchybar-app-font" || ICON_FONT="$FONT"