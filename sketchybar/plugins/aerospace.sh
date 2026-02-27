#!/bin/bash
# Called when aerospace_workspace_change event fires.
# $1 = workspace name for this item
# $NAME = SketchyBar item name (set by SketchyBar in environment)

WS="$1"
FOCUSED=$(aerospace list-workspaces --focused 2>/dev/null | tr -d '[:space:]')

if [ "$WS" = "$FOCUSED" ]; then
  sketchybar --animate tanh 20 --set "$NAME" \
    background.drawing=on \
    background.color=0xff89b4fa \
    label.color=0xff1e1e2e
else
  WIN_COUNT=$(aerospace list-windows --workspace "$WS" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$WIN_COUNT" -gt "0" ]; then
    sketchybar --animate tanh 20 --set "$NAME" \
      background.drawing=off \
      label.color=0xffcdd6f4
  else
    sketchybar --animate tanh 20 --set "$NAME" \
      background.drawing=off \
      label.color=0xff585b70
  fi
fi
