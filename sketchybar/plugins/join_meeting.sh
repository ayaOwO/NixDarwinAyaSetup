#!/bin/bash
# join_meeting.sh — open conference URL (Google Meet, Zoom, Teams, etc.)
# Usage: join_meeting.sh "https://meet.google.com/..."   OR   join_meeting.sh 1  (slot 1 = /tmp/meeting_1_url)

arg="${1:-}"
if [ -z "$arg" ]; then
  exit 0
fi
if [ -f "/tmp/meeting_${arg}_url" ]; then
  url=$(cat "/tmp/meeting_${arg}_url")
else
  url="$arg"
fi
[ -n "$url" ] && open "$url"
