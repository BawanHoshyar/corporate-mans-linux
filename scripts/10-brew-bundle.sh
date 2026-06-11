#!/usr/bin/env bash
# Install everything in the Brewfile.
set -euo pipefail
brew bundle --file="${REPO_DIR:-$(pwd)}/Brewfile"
