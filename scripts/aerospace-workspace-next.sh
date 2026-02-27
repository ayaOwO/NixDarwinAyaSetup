#!/usr/bin/env bash
# AeroSpace goodies #6: switch to next workspace on the monitor under the mouse.
# Assign to a trackpad gesture (e.g. swipe left) via BetterTouchTool, aerospace-swipe, or SwipeAeroSpace.
# https://nikitabobko.github.io/AeroSpace/goodness#use-trackpad-gestures-to-switch-workspaces

AEROSPACE="${AEROSPACE:-/opt/homebrew/bin/aerospace}"
"$AEROSPACE" workspace "$("$AEROSPACE" list-workspaces --monitor mouse --visible)" && "$AEROSPACE" workspace next
