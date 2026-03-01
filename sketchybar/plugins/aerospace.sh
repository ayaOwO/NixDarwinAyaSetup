#!/bin/bash
# Called when aerospace_workspace_change event fires.
# $1 = workspace name for this item
# $NAME = SketchyBar item name (set by SketchyBar in environment)
#
# App icons: if sketchybar-app-font is installed (icon_map.sh present), its mapping
# is used first. Set ICON_FONT="sketchybar-app-font" in env so ligatures render.
# See: https://github.com/kvndrsslr/sketchybar-app-font

THEME_DIR="${THEME_DIR:-$HOME/.config/sketchybar/themes}"
source "$THEME_DIR/env.sh"
source "$THEME_DIR/${THEME}.sh"
source "$THEME_DIR/helpers.sh"

CONFIG_DIR="$(dirname "$THEME_DIR")"
for ICON_MAP_SH in "$CONFIG_DIR/icon_map.sh" "$CONFIG_DIR/helpers/icon_map.sh"; do
  [ -r "$ICON_MAP_SH" ] && source "$ICON_MAP_SH" && break
done

WORKSPACE="$1"
# FOCUSED/PREV from exec-on-workspace-change (see https://nikitabobko.github.io/AeroSpace/guide#callbacks)
FOCUSED="${FOCUSED:-$($AEROSPACE list-workspaces --focused 2>/dev/null | tr -d '[:space:]')}"

app_icon() {
  if declare -f __icon_map &>/dev/null; then
    __icon_map "$1"
    [ -n "${icon_result:-}" ] && printf '%s' "$icon_result"
  fi
}

# Build icon string (app icons only, uses ICON_FONT) and label (workspace name only, uses FONT)
ICONS=""
WINDOW_APPS="$($AEROSPACE list-windows --workspace "$WORKSPACE" 2>/dev/null | awk -F '|' '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

if [ -n "$WINDOW_APPS" ]; then
  while IFS= read -r app; do
    [ -z "$app" ] && continue
    icon="$(app_icon "$app")"
    [ -z "$icon" ] && continue
    ICONS="$ICONS $icon"
  done <<EOF
$(printf '%s\n' "$WINDOW_APPS" | sort -u)
EOF
  ICONS="${ICONS# }"
fi

# Two items: name (FONT) with pill, icons (ICON_FONT) with no background
ICONS_ITEM="${NAME}.icons"
if [ "$WORKSPACE" = "$FOCUSED" ]; then
  sketchybar --animate tanh 20 --set "$NAME" \
    background.drawing=on \
    background.color=$(c "$BLUE") \
    label="$WORKSPACE" \
    label.color=$(c "$BASE")
  sketchybar --animate tanh 20 --set "$ICONS_ITEM" \
    icon="$ICONS" \
    icon.color=$(c "$BASE")
else
  WIN_COUNT=$($AEROSPACE list-windows --workspace "$WORKSPACE" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$WIN_COUNT" -gt "0" ]; then
    sketchybar --animate tanh 20 --set "$NAME" \
      background.drawing=on \
      background.color=$(c "$GREEN") \
      label="$WORKSPACE" \
      label.color=$(c "$BASE")
    sketchybar --animate tanh 20 --set "$ICONS_ITEM" \
      icon="$ICONS" \
      icon.color=$(c "$BASE")
  else
    sketchybar --animate tanh 20 --set "$NAME" \
      background.drawing=off \
      label="$WORKSPACE" \
      label.color=$(c "$OVERLAY1")
    sketchybar --animate tanh 20 --set "$ICONS_ITEM" \
      icon="$ICONS" \
      icon.color=$(c "$OVERLAY1")
  fi
fi
