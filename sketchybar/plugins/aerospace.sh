#!/bin/bash
# Called when aerospace_workspace_change event fires.
# $1 = workspace name for this item
# $NAME = SketchyBar item name (set by SketchyBar in environment)

THEME_DIR="$HOME/.config/sketchybar/themes"
source "$THEME_DIR/catppuccin-latte.sh"
source "$THEME_DIR/helpers.sh"

# homebrew cask installs the CLI here; not on sketchybar's default PATH
AEROSPACE=/opt/homebrew/bin/aerospace

WS="$1"
# FOCUSED/PREV from exec-on-workspace-change (see https://nikitabobko.github.io/AeroSpace/guide#callbacks)
FOCUSED="${FOCUSED:-$($AEROSPACE list-workspaces --focused 2>/dev/null | tr -d '[:space:]')}"

if [ "$WS" = "$FOCUSED" ]; then
  # Focused: blue pill, dark label
  sketchybar --animate tanh 20 --set "$NAME" \
    background.drawing=on \
    background.color=$(c "$BLUE") \
    label.color=$(c "$BASE")
else
  WIN_COUNT=$($AEROSPACE list-windows --workspace "$WS" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$WIN_COUNT" -gt "0" ]; then
    # Visible (has windows): green pill
    sketchybar --animate tanh 20 --set "$NAME" \
      background.drawing=on \
      background.color=$(c "$GREEN") \
      label.color=$(c "$BASE")
  else
    # Empty: no pill, subtle label (Overlay 1 = Subtle per style guide)
    sketchybar --animate tanh 20 --set "$NAME" \
      background.drawing=off \
      label.color=$(c "$OVERLAY1")
  fi
fi
