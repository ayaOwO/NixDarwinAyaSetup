#!/usr/bin/env bash
# ram.sh — show system memory used percentage in sketchybar

sketchybar -m --set "$NAME" label="$(memory_pressure | grep "System-wide memory free percentage:" | awk '{ gsub(/%/,"",$5); printf("%02.0f", 100-$5) }')%"
