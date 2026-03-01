# Shared env for sketchybar config and plugins

# Load secrets from sketchybar/.env if present (MEETINGS_ICAL_URL, etc.)
CONFIG_DIR="$(dirname "${THEME_DIR:-$HOME/.config/sketchybar/themes}")"
[ -r "$CONFIG_DIR/.env" ] && source "$CONFIG_DIR/.env"

# AeroSpace CLI (used by workspace plugin)
AEROSPACE=aerospace
MEETINGS_ICAL_URL="${MEETINGS_ICAL_URL:-}"

THEME="catppuccin-latte"