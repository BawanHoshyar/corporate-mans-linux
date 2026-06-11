#!/usr/bin/env bash
# Start background services and the GUI helpers.
set -euo pipefail

# Sketchybar + Borders run as brew services.
brew services start sketchybar 2>/dev/null || true
brew services start borders    2>/dev/null || true

# AeroSpace, Hammerspoon, Ghostty: launch once so they prompt for permissions.
open -a AeroSpace   2>/dev/null || true
open -a Hammerspoon 2>/dev/null || true
open -a Ghostty     2>/dev/null || true

# Rehydrate the opencode node_modules (vendored package.json, gitignored deps).
if [[ -f "$HOME/.config/opencode/package.json" ]]; then
  ( cd "$HOME/.config/opencode" && npm install --silent ) || true
fi
