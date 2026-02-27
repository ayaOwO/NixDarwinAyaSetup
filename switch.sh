sudo -E nix run nix-darwin/nix-darwin-25.05#darwin-rebuild -- switch

# Reload sketchybar so the bar picks up the new config (and workspace state if AeroSpace started first)
/run/current-system/sw/bin/sketchybar --reload 2>/dev/null || true
