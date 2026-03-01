#!/bin/bash
# Updates the "current_window" sketchybar item with the focused window title.

source "$HOME/.config/sketchybar/themes/env.sh"
if ! command -v "$AEROSPACE" &>/dev/null; then
  for p in /opt/homebrew/bin /usr/local/bin; do
    [ -x "$p/aerospace" ] && AEROSPACE="$p/aerospace" && break
  done
fi

MAX_LEN=40
title="$($AEROSPACE list-windows --focused --format '%{window-title}' 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
if [ -z "$title" ]; then
  title="$($AEROSPACE list-windows --focused --format '%{app-name}' 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
fi
if [ -z "$title" ]; then
  title="—"
fi

if [ ${#title} -gt "$MAX_LEN" ]; then
  keep=$((MAX_LEN - 3))
  start_keep=$((keep / 2))
  end_keep=$((keep - start_keep))
  title="${title:0:start_keep}...${title: -end_keep}"
fi

sketchybar --set "$NAME" label="$title"
