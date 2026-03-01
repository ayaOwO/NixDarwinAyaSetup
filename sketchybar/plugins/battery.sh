#!/usr/bin/env bash
# battery.sh — KDE Plasma–style battery thresholds; use .AppleSystemUIFont for this item

# Icon variables (SF Symbols)
BATT_100="􀛨"
BATT_75="􀺸"
BATT_50="􀺶"
BATT_25="􀛩"
BATT_0="􀛪"
BATT_CHARGING="􀢋"

THEME_DIR="${THEME_DIR:-$HOME/.config/sketchybar/themes}"
[ -r "$THEME_DIR/env.sh" ] && source "$THEME_DIR/env.sh"
[ -r "$THEME_DIR/${THEME}.sh" ] && source "$THEME_DIR/${THEME}.sh"
[ -r "$THEME_DIR/helpers.sh" ] && source "$THEME_DIR/helpers.sh"

ORANGE="${ORANGE:-$PEACH}"

BATT_PERCENT=$(pmset -g batt 2>/dev/null | grep -Eo "[0-9]+%" | head -1 | cut -d% -f1)
BATT_PERCENT="${BATT_PERCENT:-0}"
CHARGING=$(pmset -g batt 2>/dev/null | grep 'AC Power')
# Low Power Mode (macOS: pmset -g; no devicestatus on macOS)
LOW_POWER=$(pmset -g 2>/dev/null | grep -i lowpowermode)

# --- Prioritize states ---
if [[ -n "${CHARGING}" ]]; then
    ICON="$BATT_CHARGING"
    COLOR="$GREEN"
else
    # KDE Plasma–style thresholds (numerical)
    if [[ "$BATT_PERCENT" -gt 87 ]]; then
        ICON="$BATT_100"
        COLOR="$GREEN"
    elif [[ "$BATT_PERCENT" -gt 62 ]]; then
        ICON="$BATT_75"
        COLOR="$GREEN"
    elif [[ "$BATT_PERCENT" -gt 37 ]]; then
        ICON="$BATT_50"
        COLOR="$YELLOW"
    elif [[ "$BATT_PERCENT" -gt 12 ]]; then
        ICON="$BATT_25"
        COLOR="$ORANGE"
    else
        ICON="$BATT_0"
        COLOR="$RED"
    fi
    # Low Power Mode: use a distinct color (not used in battery gradient)
    if [[ "$LOW_POWER" == *"1"* ]]; then
        COLOR="${SKY:-$BLUE}"
    fi
fi

sketchybar --set "${NAME}" \
  icon="${ICON}" \
  icon.color=$(c "$COLOR") \
  label="${BATT_PERCENT}%"
