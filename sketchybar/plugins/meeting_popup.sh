#!/bin/bash
# meeting_popup.sh — on click of next_meeting: refresh calendar JSON, fill popup slots, toggle popup.

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
THEME_DIR="${THEME_DIR:-$CONFIG_DIR/themes}"
JSON="/tmp/next_meetings.json"
PARENT="${1:-next_meeting}"
NUM_SLOTS=4
[ -x "$CONFIG_DIR/scripts/.venv/bin/python" ] && PYTHON="$CONFIG_DIR/scripts/.venv/bin/python" || PYTHON=python3

[ -r "$THEME_DIR/env.sh" ] && source "$THEME_DIR/env.sh"

# Refresh data
MEETINGS_ICAL_URL="${MEETINGS_ICAL_URL:-}" "$PYTHON" "$CONFIG_DIR/scripts/fetch_meetings.py" 2>/dev/null || true

if [ ! -r "$JSON" ]; then
  sketchybar --set "$PARENT" popup.drawing=toggle
  exit 0
fi

# Fill slots from JSON (labels + join URLs)
for i in $(seq 1 $NUM_SLOTS); do
  slot_data=$("$PYTHON" -c "
import json
try:
    d = json.load(open('$JSON'))
    events = d.get('events') or []
    i = $i - 1
    if i < len(events):
        e = events[i]
        title = (e.get('title') or '').replace('\t', ' ').replace('\n', ' ').replace('\"', '\\\\\"')[:40]
        start = e.get('start_local') or ''
        end = e.get('end_local') or ''
        url = (e.get('conference_url') or '').replace('\t', ' ').replace('\n', ' ')
        print(f\"{start}-{end} {title}\t{url}\")
    else:
        print(\"\t\")
except Exception:
    print(\"\t\")
" 2>/dev/null)
  line_label="${slot_data%$'\t'*}"
  line_url="${slot_data#*$'\t'}"

  if [ -z "$line_label" ]; then
    sketchybar --set "${PARENT}.$i" label="—" drawing=off click_script=""
  else
    # Store URL for join_meeting.sh slot lookup
    printf '%s' "$line_url" > "/tmp/meeting_${i}_url"
    esc_url=$(printf '%s' "$line_url" | sed "s/'/'\\\\''/g")
    sketchybar --set "${PARENT}.$i" \
      label="$line_label" \
      drawing=on \
      click_script="bash $CONFIG_DIR/plugins/join_meeting.sh $i"
  fi
done

sketchybar --set "$PARENT" popup.drawing=toggle
