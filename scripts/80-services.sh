#!/usr/bin/env bash
# Start background services and the GUI helpers.
set -euo pipefail

# Sketchybar + Borders run as brew services.
brew services start sketchybar 2>/dev/null || true
brew services start borders    2>/dev/null || true
brew services start postgresql@16 2>/dev/null || true
brew services start herdr 2>/dev/null || true

# AeroSpace, Hammerspoon, Ghostty: launch once so they prompt for permissions.
open -a AeroSpace   2>/dev/null || true
open -a Hammerspoon 2>/dev/null || true
open -a Ghostty     2>/dev/null || true

# Custom screensaver (Ctrl+Cmd+Q in Hammerspoon launches it).
bash "$REPO_DIR/screensaver/install.sh" || true
