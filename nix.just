#!/usr/bin/env just --justfile

# Nix-darwin management tasks

# Show available tasks
default:
    @just --list

# Apply the nix-darwin configuration
switch:
    bash switch.sh

# Clean up old generations and run garbage collection
clean:
    bash clean.sh

# Update flake inputs and apply configuration
upgrade:
    bash upgrade.sh

# Apply configuration and clean up (common workflow)
rebuild: switch clean
    @echo "✅ Rebuild complete!"
