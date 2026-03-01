#!/bin/bash
# next_meeting.sh — show next meeting in bar (Notion Calendar style). Reads from
# /tmp/next_meetings.json (written by scripts/fetch_meetings.py).

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
THEME_DIR="${THEME_DIR:-$CONFIG_DIR/themes}"
PLUGIN_DIR="${PLUGIN_DIR:-$CONFIG_DIR/plugins}"
JSON="/tmp/next_meetings.json"
FETCH_SCRIPT="$CONFIG_DIR/scripts/fetch_meetings.py"
[ -x "$CONFIG_DIR/scripts/.venv/bin/python" ] && PYTHON="$CONFIG_DIR/scripts/.venv/bin/python" || PYTHON=python3
STALE_SEC=55

[ -r "$THEME_DIR/catppuccin-latte.sh" ] && source "$THEME_DIR/catppuccin-latte.sh"
[ -r "$THEME_DIR/helpers.sh" ] && source "$THEME_DIR/helpers.sh"
[ -r "$THEME_DIR/env.sh" ] && source "$THEME_DIR/env.sh"

# Icon: play/meeting (Nerd Font)
ICON="󰃰"

# If no calendar configured, show nothing distinctive
if [ -z "${MEETINGS_ICAL_URL:-}" ] && [ ! -d "$HOME/.calendar" ]; then
  sketchybar --set "$NAME" icon="$ICON" icon.color=$(c "${OVERLAY1:-#8c8fa1}") label="" drawing=on
  exit 0
fi

# Refresh JSON if missing or stale
if [ ! -f "$JSON" ] || [ $(($(date +%s) - $(stat -f %m "$JSON" 2>/dev/null || stat -c %Y "$JSON" 2>/dev/null))) -gt $STALE_SEC ]; then
  MEETINGS_ICAL_URL="${MEETINGS_ICAL_URL:-}" "$PYTHON" "$FETCH_SCRIPT" 2>/dev/null || true
fi

if [ ! -r "$JSON" ]; then
  sketchybar --set "$NAME" icon="$ICON" icon.color=$(c "${OVERLAY1:-#8c8fa1}") label="—" drawing=on
  exit 0
fi

# Parse next event and compute label/color (single Python call; output: label TAB color or empty)
out=$("$PYTHON" << 'PY'
import json
import sys
from datetime import datetime, timezone

try:
    with open("/tmp/next_meetings.json") as f:
        data = json.load(f)
except Exception:
    sys.exit(0)

events = data.get("events") or []
if not events:
    sys.exit(0)

e = events[0]
event_title = (e.get("title") or "").replace("\t", " ").replace("\n", " ").strip()
event_start_local = e.get("start_local") or ""
event_start_iso = e.get("start_iso") or ""
event_end_iso = e.get("end_iso") or ""
has_join = bool(e.get("conference_url"))

now = datetime.now(timezone.utc).timestamp()
def parse_iso(s):
    if not s:
        return now
    s = s.replace("Z", "+00:00").replace("+0000", "+00:00")
    try:
        if "+" in s or (len(s) > 19 and s[-6] in "-+"):
            return datetime.strptime(s[:25], "%Y-%m-%dT%H:%M:%S%z").timestamp()
        return datetime.strptime(s[:19], "%Y-%m-%dT%H:%M:%S").replace(tzinfo=timezone.utc).timestamp()
    except Exception:
        return now

start_ts = parse_iso(event_start_iso)
end_ts = parse_iso(event_end_iso)
mins_left = int((start_ts - now) / 60)
ongoing = start_ts <= now < end_ts

if ongoing or mins_left < 0:
    rel = "now"
    color = "#d20f39"
elif mins_left == 0:
    rel = "now"
    color = "#d20f39"
elif mins_left < 15:
    rel = f"in {mins_left} min"
    color = "#df8e1d"
else:
    rel = f"in {mins_left} min"
    color = "#40a02b"

time_part = event_start_local if mins_left >= 60 else rel
label = f" {event_title} · {time_part}"
if has_join:
    label += "  󰒋"
if len(label) > 35:
    label = label[:32] + "..."
# Tab is our delimiter; ensure no tab in label
label = label.replace("\t", " ")
print(f"{label}\t{color}")
PY
)"

if [ -z "$out" ]; then
  sketchybar --set "$NAME" icon="$ICON" icon.color=$(c "${OVERLAY1:-#8c8fa1}") label="" drawing=on
  exit 0
fi

label="${out%$'\t'*}"
color="${out#*$'\t'}"

sketchybar --set "$NAME" \
  icon="$ICON" \
  icon.color=$(c "$color") \
  label="$label" \
  drawing=on
