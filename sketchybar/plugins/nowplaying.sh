#!/usr/bin/env bash
# Now Playing indicator for SketchyBar.
# Uses nowplaying-cli if available; otherwise falls back to frontmost app+title.

THEME_DIR="$HOME/.config/sketchybar/themes"
source "$THEME_DIR/catppuccin-latte.sh"
source "$THEME_DIR/helpers.sh"
source "$THEME_DIR/env.sh"

LABEL=""
ICON="󰝚" # generic media icon (Nerd Font)

if command -v nowplaying-cli &>/dev/null; then
  # Prefer system Now Playing center (works for Music, Spotify, browser media, etc.)
  # nowplaying-cli outputs one value per line: title, then artist, then app
  mapfile -t NP < <(nowplaying-cli get title artist app 2>/dev/null)
  TITLE="${NP[0]:-}"
  ARTIST="${NP[1]:-}"
  APP="${NP[2]:-}"

  if [ -n "$TITLE" ]; then
    if [ -n "$ARTIST" ] && [ "$ARTIST" != "Unknown Artist" ]; then
      LABEL="$TITLE — $ARTIST"
    else
      LABEL="$TITLE"
    fi
  fi

  # Optional: tweak icon per app
  case "$APP" in
    "Spotify") ICON="" ;;       # Spotify
    "Music") ICON="" ;;         # Apple Music
    "Safari"|"Google Chrome"|"Arc"|"Brave Browser"|"Firefox") ICON="󰖟" ;; # browser media
  esac
fi

if [ -z "$LABEL" ]; then
  # Fallback: show active app and window title
  APP_NAME="$(osascript -e 'tell application "System Events" to get name of first process whose frontmost is true' 2>/dev/null || true)"
  WIN_TITLE="$(osascript -e 'tell application "System Events" to tell (first process whose frontmost is true) to get name of front window' 2>/dev/null || true)"

  if [ -n "$APP_NAME" ] && [ -n "$WIN_TITLE" ]; then
    LABEL="$APP_NAME — $WIN_TITLE"
  elif [ -n "$APP_NAME" ]; then
    LABEL="$APP_NAME"
  fi
fi

if [ -z "$LABEL" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

sketchybar --set "$NAME" \
  drawing=on \
  icon="$ICON" \
  icon.color=$(c "$GREEN") \
  label="$LABEL" \
  label.color=$(c "$TEXT")

