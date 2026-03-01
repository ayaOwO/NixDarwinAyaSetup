#!/usr/bin/env python3
"""
Fetch ICS calendar feed, parse events (including recurrences), extract conference
URLs, and write next meetings to JSON for SketchyBar next_meeting plugin.

Usage:
  fetch_meetings.py [ICS_URL_OR_PATH]
  MEETINGS_ICAL_URL=https://... fetch_meetings.py

Reads MEETINGS_ICAL_URL from env if not passed. If empty, also checks
~/.calendar/*.ics. Output: /tmp/next_meetings.json
"""

import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from urllib.request import urlopen, Request

# Optional deps: icalendar, recurring_ical_events
try:
    import icalendar
    from recurring_ical_events import of_components
except ImportError as e:
    print("Install: pip install -r scripts/requirements.txt", file=sys.stderr)
    raise SystemExit(1) from e

OUTPUT_PATH = "/tmp/next_meetings.json"
LOOKAHEAD_HOURS = 12
MAX_EVENTS = 10
WORKING_HOURS = (6, 23)  # optional: (start_hour, end_hour) 24h; None = no filter

# Regex for conference URLs (order doesn't matter; first match wins per field)
CONFERENCE_PATTERNS = [
    r"https?://meet\.google\.com/[a-z]{3}-[a-z]{4}-[a-z]{3}",
    r"https?://[^/\s]+\.zoom\.us/j/\d+\?pwd=[^\s\)\"]+",
    r"https?://[^/\s]+\.zoom\.us/j/\d+",
    r"https?://teams\.microsoft\.com/l/meetup-join/[^\s\)\"]+",
    r"https?://[^/\s]+\.web\.zoom\.us/j/[^\s\)\"]+",
    r"https?://(?:www\.)?whereby\.com/[^\s\)\"]+",
    r"https?://(?:www\.)?around\.co/[^\s\)\"]+",
]

def get_ics_content(source: str) -> bytes:
    """Fetch ICS from URL or read from local path."""
    source = source.strip()
    if not source:
        raise ValueError("Empty ICS source")
    if source.startswith("http://") or source.startswith("https://"):
        req = Request(source, headers={"User-Agent": "SketchyBar-Calendar/1.0"})
        with urlopen(req, timeout=15) as r:
            return r.read()
    path = Path(source).expanduser().resolve()
    if not path.exists():
        raise FileNotFoundError(f"ICS path not found: {path}")
    return path.read_bytes()

def collect_ics_sources() -> list[str]:
    """Return list of ICS URLs/paths from env and default paths."""
    env_url = os.environ.get("MEETINGS_ICAL_URL", "").strip()
    if env_url:
        return [env_url]
    local = Path.home() / ".calendar"
    if local.is_dir():
        return [str(p) for p in local.glob("*.ics")]
    return []

def extract_conference_url(component) -> str | None:
    """Extract conference/join URL from event component."""
    # 1) CONFERENCE property (Google Calendar Meet)
    for prop in ("CONFERENCE", "X-GOOGLE-CONFERENCE", "X-APPLE-CONFERENCE-URL"):
        val = component.get(prop)
        if val is None:
            continue
        if isinstance(val, icalendar.vText):
            val = str(val).strip()
        elif isinstance(val, list):
            for part in val:
                if isinstance(part, dict) and part.get("VALUE") == "URI":
                    uri = part.get("URI")
                    if uri:
                        return uri.strip()
            continue
        if isinstance(val, str) and val.startswith("http"):
            return val
    # 2) URL property
    url_prop = component.get("URL")
    if url_prop is not None:
        u = str(url_prop).strip()
        if u.startswith("http") and any(re.search(p, u) for p in CONFERENCE_PATTERNS):
            return u
    # 3) Scan DESCRIPTION and LOCATION
    for field in ("DESCRIPTION", "LOCATION"):
        raw = component.get(field)
        if raw is None:
            continue
        text = str(raw)
        for pat in CONFERENCE_PATTERNS:
            m = re.search(pat, text, re.IGNORECASE)
            if m:
                return m.group(0)
    return None

def sanitize_title(title: str) -> str:
    """Strip common prefixes/tags from meeting titles."""
    if not title:
        return title
    # Remove [Zoom], [External], [Video call], etc.
    title = re.sub(r"\s*\[(?:Zoom|External|Video call|Meet|Google Meet)\]\s*", " ", title, flags=re.I)
    title = re.sub(r"^\s*\[[^\]]+\]\s*", "", title)
    return title.strip() or "Meeting"

def event_in_working_hours(dt: datetime) -> bool:
    if WORKING_HOURS is None:
        return True
    local = dt.astimezone() if getattr(dt, "tzinfo", None) else dt
    hour = getattr(local, "hour", 12)
    return WORKING_HOURS[0] <= hour < WORKING_HOURS[1]

def main():
    sources = collect_ics_sources()
    if not sources:
        out = {"events": [], "updated": datetime.now(timezone.utc).isoformat()}
        Path(OUTPUT_PATH).write_text(json.dumps(out, indent=2))
        return

    now = datetime.now(timezone.utc)
    end = now.replace(hour=23, minute=59, second=59) if LOOKAHEAD_HOURS >= 24 else None
    if end is None:
        from datetime import timedelta
        end = now + timedelta(hours=LOOKAHEAD_HOURS)

    all_events = []
    for ics_source in sources:
        try:
            raw = get_ics_content(ics_source)
        except Exception as e:
            print(f"Warning: could not load {ics_source}: {e}", file=sys.stderr)
            continue
        try:
            cal = icalendar.Calendar.from_ical(raw)
        except Exception as e:
            print(f"Warning: could not parse ICS {ics_source}: {e}", file=sys.stderr)
            continue
        components = cal.walk("VEVENT")
        for component in of_components(components, start=now, end=end):
            start_dt = component.get("DTSTART").dt
            end_dt = component.get("DTEND").dt
            # Skip all-day events (date only)
            if type(start_dt).__name__ == "date":
                continue
            if getattr(start_dt, "tzinfo", None) is None:
                start_dt = start_dt.replace(tzinfo=timezone.utc)
            if getattr(end_dt, "tzinfo", None) is None:
                end_dt = end_dt.replace(tzinfo=timezone.utc)
            if start_dt.tzinfo is None:
                start_dt = start_dt.replace(tzinfo=timezone.utc)
            if end_dt.tzinfo is None:
                end_dt = end_dt.replace(tzinfo=timezone.utc)
            # Skip all-day or outside window
            if start_dt >= end or end_dt <= now:
                continue
            if not event_in_working_hours(start_dt):
                continue
            title = str(component.get("SUMMARY", "") or "Untitled").strip()
            title = sanitize_title(title)
            attendees = []
            for a in component.get("ATTENDEE", []) or []:
                if isinstance(a, list):
                    continue
                email = getattr(a, "params", {}).get("CN", [str(a)])[0] if hasattr(a, "params") else str(a)
                attendees.append(email)
            desc = str(component.get("DESCRIPTION", "") or "")
            conf_url = extract_conference_url(component)
            color = None
            if hasattr(component.get("COLOR"), "params"):
                # COLOR can be a vColor
                pass
            try:
                color_val = component.get("COLOR")
                if color_val is not None:
                    color = str(color_val).strip()
            except Exception:
                pass
            all_events.append({
                "title": title,
                "start_iso": start_dt.isoformat(),
                "end_iso": end_dt.isoformat(),
                "start_local": start_dt.astimezone().strftime("%H:%M"),
                "end_local": end_dt.astimezone().strftime("%H:%M"),
                "attendees": attendees[:5],
                "description": desc[:500] if desc else "",
                "conference_url": conf_url,
                "color": color,
            })

    # Sort by start, dedupe by (start, title), take up to MAX_EVENTS
    all_events.sort(key=lambda e: e["start_iso"])
    seen = set()
    events = []
    for e in all_events:
        key = (e["start_iso"], e["title"])
        if key in seen:
            continue
        seen.add(key)
        events.append(e)
        if len(events) >= MAX_EVENTS:
            break

    out = {
        "events": events,
        "updated": datetime.now(timezone.utc).isoformat(),
    }
    Path(OUTPUT_PATH).write_text(json.dumps(out, indent=2))

if __name__ == "__main__":
    main()
