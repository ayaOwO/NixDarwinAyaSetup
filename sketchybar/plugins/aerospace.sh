#!/bin/bash
# aerospace.sh — update workspace item on aerospace_workspace_change
# Args: $1 = workspace name. $NAME = SketchyBar item (set by SketchyBar).
# Icons: icon_map.sh / sketchybar-app-font when present. See themes/env.sh.

THEME_DIR="${THEME_DIR:-$HOME/.config/sketchybar/themes}"
source "$THEME_DIR/env.sh"
source "$THEME_DIR/${THEME}.sh"
source "$THEME_DIR/helpers.sh"

CONFIG_DIR="$(dirname "$THEME_DIR")"
for f in "$CONFIG_DIR/icon_map.sh" "$CONFIG_DIR/helpers/icon_map.sh"; do
  [ -r "$f" ] && source "$f" && break
done

WORKSPACE="$1"
FOCUSED="${FOCUSED:-$($AEROSPACE list-workspaces --focused 2>/dev/null | tr -d '[:space:]')}"
WIN_COUNT=$($AEROSPACE list-windows --workspace "$WORKSPACE" 2>/dev/null | wc -l | tr -d ' ')

app_icon() {
  if declare -f __icon_map &>/dev/null; then
    __icon_map "$1"
    [ -n "${icon_result:-}" ] && printf '%s' "$icon_result"
  fi
}

ICONS=""
while IFS= read -r app; do
  [ -z "$app" ] && continue
  icon="$(app_icon "$app")"
  [ -z "$icon" ] && continue
  ICONS="$ICONS $icon"
done < <($AEROSPACE list-windows --workspace "$WORKSPACE" 2>/dev/null | awk -F '|' '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sort -u)
ICONS="${ICONS# }"

if [ "$WORKSPACE" = "$FOCUSED" ]; then
  drawing=on
  bg_color="$BLUE"
  fg_color="$BASE"
elif [ "$WIN_COUNT" -gt 0 ]; then
  drawing=on
  bg_color="$GREEN"
  fg_color="$BASE"
else
  drawing=off
  bg_color="$BASE"
  fg_color="$OVERLAY1"
fi

# Display label: strip leading "N-" from workspace name (e.g. 1-Work -> Work, 9-chat -> chat)
display_label="$WORKSPACE"
[[ "$WORKSPACE" =~ ^[0-9]+-(.+)$ ]] && display_label="${BASH_REMATCH[1]}"

sketchybar --animate tanh 20 --set "$NAME" \
  padding_left=8 \
  background.drawing=$drawing \
  background.color=$(c "$bg_color") \
  icon="$ICONS" \
  icon.color=$(c "$fg_color") \
  label="$display_label" \
  label.color=$(c "$fg_color")
