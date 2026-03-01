#!/usr/bin/env bash
# ram.sh — show system memory used percentage in sketchybar

RAM_ICON=''
pct=$(memory_pressure | grep "System-wide memory free percentage:" | awk '{ gsub(/%/,"",$5); printf("%02.0f", 100-$5) }')
sketchybar -m --set "$NAME" icon="$RAM_ICON" label="${pct}%"
