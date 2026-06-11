#!/usr/bin/env bash
# Cargo-installed tools that aren't on brew.
set -euo pipefail

# Rust toolchain comes from brew install rust (handled in 10-brew-bundle.sh).
command -v cargo >/dev/null || { echo "cargo missing — did brew install rust succeed?"; exit 1; }

# Custom ytermusic fork — TUI YouTube Music player with my patches.
# Source: https://github.com/BawanHoshyar/ytermusic
if ! command -v ytermusic >/dev/null; then
  echo "Installing ytermusic from BawanHoshyar fork…"
  cargo install --git https://github.com/BawanHoshyar/ytermusic --bin ytermusic
else
  echo "ytermusic already installed at $(command -v ytermusic) — skipping (run \`cargo install --git ... --force\` to refresh)"
fi
