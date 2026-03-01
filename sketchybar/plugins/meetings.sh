#!/usr/bin/env bash
# Upcoming meetings from an iCal/ICS feed.
# Shows next event in the bar, more details in a popup on hover.

THEME_DIR="$HOME/.config/sketchybar/themes"
source "$THEME_DIR/catppuccin-latte.sh"
source "$THEME_DIR/helpers.sh"
source "$THEME_DIR/env.sh"

# Handle hover events separately: just toggle popup visibility.
case "$SENDER" in
  "mouse.entered")
    sketchybar --set "$NAME" popup.drawing=on
    exit 0
    ;;
  "mouse.exited"|"mouse.exited.global")
    sketchybar --set "$NAME" popup.drawing=off
    exit 0
    ;;
esac

URL="${MEETINGS_ICAL_URL:-}"

if [ -z "$URL" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

TMP="$(mktemp -t meetings.ics.XXXXXX)"
if ! curl -fsSL "$URL" -o "$TMP" 2>/dev/null; then
  rm -f "$TMP"
  sketchybar --set "$NAME" \
    drawing=on \
    icon="" \
    icon.color=$(c "$YELLOW") \
    label="Calendar error" \
    label.color=$(c "$OVERLAY1")
  exit 0
fi

LINES="$(python3 - "$TMP" << 'PY'
import sys, datetime, zoneinfo

path = sys.argv[1]
now = datetime.datetime.now().astimezone()

events = []
in_evt = False
dt = None
summary = None

with open(path, encoding="utf-8", errors="ignore") as f:
    for raw in f:
        line = raw.strip()
        if line == "BEGIN:VEVENT":
            in_evt = True
            dt = None
            summary = None
            continue
        if line == "END:VEVENT":
            if in_evt and dt and summary:
                events.append((dt, summary))
            in_evt = False
            continue
        if not in_evt:
            continue
        if line.startswith("DTSTART"):
            try:
                _, value = line.split(":", 1)
            except ValueError:
                continue
            v = value.strip()
            try:
                if v.endswith("Z"):
                    dt_utc = datetime.datetime.strptime(v, "%Y%m%dT%H%M%SZ").replace(tzinfo=datetime.timezone.utc)
                    dt = dt_utc.astimezone()
                elif len(v) == 8:
                    dt = datetime.datetime.strptime(v, "%Y%m%d").replace(tzinfo=now.tzinfo)
                else:
                    dt = datetime.datetime.strptime(v, "%Y%m%dT%H%M%S").replace(tzinfo=now.tzinfo)
            except Exception:
                dt = None
        elif line.startswith("SUMMARY"):
            try:
                _, value = line.split(":", 1)
            except ValueError:
                continue
            summary = value.strip()

events = [e for e in events if e[0] >= now]
events.sort(key=lambda e: e[0])

out = []
for dt, summary in events[:4]:
    if dt.date() == now.date():
        prefix = dt.strftime("%H:%M")
    else:
        prefix = dt.strftime("%a %d %b %H:%M")
    out.append(f"{prefix} — {summary}")

sys.stdout.write("\\n".join(out))
PY
)"

rm -f "$TMP"

if [ -z "$LINES" ]; then
  sketchybar --set "$NAME" \
    drawing=on \
    icon="" \
    icon.color=$(c "$LAVENDER") \
    label="No upcoming events" \
    label.color=$(c "$OVERLAY1")
  # Clear any old popup items
  sketchybar --remove '/^meetings\./'
  exit 0
fi

mapfile -t EVENTS <<< "$LINES"

MAIN="${EVENTS[0]}"
SHORT_MAIN="$MAIN"
MAX_LEN=40
if [ "${#SHORT_MAIN}" -gt "$MAX_LEN" ]; then
  SHORT_MAIN="${SHORT_MAIN:0:$MAX_LEN}…"
fi

sketchybar --set "$NAME" \
  drawing=on \
  icon="" \
  icon.color=$(c "$PEACH") \
  label="$SHORT_MAIN" \
  label.color=$(c "$TEXT")

# Rebuild popup items with all upcoming events (up to 4)
sketchybar --remove '/^meetings\./'

idx=0
for ev in "${EVENTS[@]}"; do
  item="meetings.$idx"
  sketchybar --add item "$item" "popup.$NAME" \
    --set "$item" \
      label="$ev" \
      label.color=$(c "$TEXT") \
      label.padding_left=8 \
      label.padding_right=8
  idx=$((idx + 1))
done

