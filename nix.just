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

# Update flake inputs and apply configuration
upgrade:
    @bash upgrade.sh

# Apply configuration and clean up
rebuild: switch clean
