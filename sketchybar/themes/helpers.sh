#!/usr/bin/env sh
# Sketchybar color helpers
# Usage: source this file after sourcing a Catppuccin theme

# Convert #rrggbb → 0xffrrggbb   e.g.  c "$BLUE"
c()  { echo "0xff${1#\#}"; }

# Convert with custom alpha        e.g.  ca cc "$BASE"  → 0xcc303446
ca() { echo "0x${1}${2#\#}"; }
