#!/bin/bash
# Updates the "current_window" sketchybar item with the focused window title.
# Uses --format to avoid parsing issues when title contains "|".

THEME_DIR="${THEME_DIR:-$HOME/.config/sketchybar/themes}"
[ -r "$THEME_DIR/env.sh" ] && source "$THEME_DIR/env.sh"
AEROSPACE="${AEROSPACE:-aerospace}"
# Ensure aerospace is found when run by LaunchAgent (PATH may be minimal)
if ! command -v "$AEROSPACE" &>/dev/null; then
  for p in /opt/homebrew/bin /usr/local/bin; do
    [ -x "$p/aerospace" ] && AEROSPACE="$p/aerospace" && break
  done
fi

MAX_LEN=40
# Get window title only (no pipe parsing); fallback to app name if title empty
title="$($AEROSPACE list-windows --focused --format '%{window-title}' 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
if [ -z "$title" ]; then
  title="$($AEROSPACE list-windows --focused --format '%{app-name}' 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
fi
if [ -z "$title" ]; then
  title="—"
fi

# Truncate middle: "very long app name" -> "very lo...name" (macOS-style)
if [ ${#title} -gt "$MAX_LEN" ]; then
  keep=$((MAX_LEN - 3))
  start_keep=$((keep / 2))
  end_keep=$((keep - start_keep))
  title="${title:0:start_keep}...${title: -end_keep}"
fi

sketchybar --set "$NAME" label="$title"
