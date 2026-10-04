#!/usr/bin/env bash
# Install everything in the Brewfile. Non-fatal: one bad cask/mas app (e.g.
# already pushed by MDM, or not signed into the App Store) shouldn't stop setup.
set -uo pipefail
brew bundle --file="${REPO_DIR:-$(pwd)}/Brewfile" || echo "[warn] some Brewfile entries failed — re-run: brew bundle --file=$REPO_DIR/Brewfile"
