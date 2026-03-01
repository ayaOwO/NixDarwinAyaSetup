#!/usr/bin/env just --justfile

# Nix-darwin management tasks
nix_justfile := "/private/etc/nix-darwin/nix.just"

# Show available tasks
list:
    @just --justfile {{nix_justfile}} --list

# Apply the nix-darwin configuration
switch:
    @bash switch.sh

# Clean up old generations and run garbage collection
clean:
    @bash clean.sh

# Run install script and update flake inputs + apply configuration
upgrade:
    @bash install.sh
    @bash upgrade.sh

# Reload SketchyBar after config change (uses running instance)
sketchybar:
    sketchybar --reload
