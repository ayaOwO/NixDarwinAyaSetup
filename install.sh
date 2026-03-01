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

# Fetch latest icon_map.sh from sketchybar-app-font release (for workspace app icons)
echo "Fetching sketchybar-app-font icon_map.sh from latest release..."
TAG=$(curl -sL "https://api.github.com/repos/kvndrsslr/sketchybar-app-font/releases/latest" 2>/dev/null | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)
if [ -n "$TAG" ]; then
  curl -sL "https://github.com/kvndrsslr/sketchybar-app-font/releases/download/${TAG}/icon_map.sh" -o "$REPO_ROOT/sketchybar/icon_map.sh" && echo "  Installed icon_map.sh (${TAG})" || echo "  Warning: could not download icon_map.sh"
else
  echo "  Warning: could not determine latest release (skip or add icon_map.sh manually)"
fi

echo "Reloading AeroSpace config..."
if command -v aerospace &>/dev/null; then
  aerospace reload-config 2>/dev/null || true
fi

# Wallpaper
echo "Setting wallpaper..."
osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$REPO_ROOT/wallpaper.jpg\""

# Sketchybar (brew services only; remove custom LaunchAgent if present)
echo "Starting sketchybar..."
brew services restart sketchybar
