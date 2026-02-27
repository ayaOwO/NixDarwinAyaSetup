sudo -E nix run nix-darwin/nix-darwin-25.05#darwin-rebuild -- switch

# Reload AeroSpace config (symlinked from this repo)
/opt/homebrew/bin/aerospace reload-config 2>/dev/null || true

# Reload sketchybar so the bar picks up the new config (and workspace state if AeroSpace started first)
/run/current-system/sw/bin/sketchybar --reload 2>/dev/null || true
