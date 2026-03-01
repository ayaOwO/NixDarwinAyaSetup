#!/usr/bin/env bash
# One-time bootstrap: Homebrew, Brewfile, Rosetta, symlinks, wallpaper, sketchybar agent.
# Run from repo root: ./install.sh  (or: cd /private/etc/nix-darwin && ./install.sh)
set -e

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_ROOT"

# Install Homebrew if missing
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Ensure Homebrew is in PATH (needed after fresh install or when run from non-interactive shell)
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)"

# Skip auto-update during bundle (avoids long hang); run `brew update` separately if you want latest
# export HOMEBREW_NO_AUTO_UPDATE=1
echo "Running brew bundle..."
brew bundle install --file=Brewfile

# Rosetta
echo "Checking Rosetta..."
if ! /usr/bin/pgrep -q oahd; then
  /usr/sbin/softwareupdate --install-rosetta --agree-to-license
fi

# Symlink configs
echo "Linking configs (using sudo)..."
USER_HOME="$HOME"
mkdir -p "$USER_HOME/.config/aerospace"
sudo ln -sfn "$REPO_ROOT/aerospace.toml" "$USER_HOME/.config/aerospace/aerospace.toml"
mkdir -p "$USER_HOME/.config"
# If sketchybar is a directory, remove it so we can symlink the whole folder from the repo
if [ -d "$USER_HOME/.config/sketchybar" ] && [ ! -L "$USER_HOME/.config/sketchybar" ]; then
  sudo rm -rf "$USER_HOME/.config/sketchybar"
fi
sudo ln -sfn "$REPO_ROOT/sketchybar" "$USER_HOME/.config/sketchybar"

echo "Reloading AeroSpace config..."
if command -v aerospace &>/dev/null; then
  aerospace reload-config 2>/dev/null || true
fi

# Wallpaper
echo "Setting wallpaper..."
osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$REPO_ROOT/wallpaper.jpg\""

# Sketchybar launchd agent
echo "Installing sketchybar LaunchAgent..."
mkdir -p "$USER_HOME/Library/LaunchAgents"
PLIST="$USER_HOME/Library/LaunchAgents/com.felixkratz.sketchybar.plist"
launchctl unload "$PLIST" 2>/dev/null || true
rm -f "$PLIST"
cp "$REPO_ROOT/sketchybar/com.felixkratz.sketchybar.plist" "$USER_HOME/Library/LaunchAgents/"
launchctl load "$PLIST"

echo "Restarting sketchybar..."
launchctl kickstart -k "gui/$(id -u)/com.felixkratz.sketchybar" 2>/dev/null || true
