sudo -E nix run nix-darwin/nix-darwin-25.11#darwin-rebuild -- switch

# Reload AeroSpace so the running process picks up the new aerospace.toml
aerospace reload-config 2>/dev/null || true

# Restart sketchybar so it runs with the new config (new store path after switch)
launchctl kickstart -k gui/$(id -u)/org.nixos.sketchybar 2>/dev/null || true
