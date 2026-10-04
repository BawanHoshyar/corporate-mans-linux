#!/usr/bin/env bash
# Tools that are not on brew: ytermusic (cargo), Claude Code, Ruby, uv tools.
set -euo pipefail

# Rust toolchain comes from brew install rust (handled in 10-brew-bundle.sh).
command -v cargo >/dev/null || { echo "cargo missing — did brew install rust succeed?"; exit 1; }

# Custom ytermusic fork — TUI YouTube Music player with my patches.
# Source: https://github.com/BawanHoshyar/ytermusic
if ! command -v ytermusic >/dev/null; then
  echo "Installing ytermusic from BawanHoshyar fork…"
  cargo install --git https://github.com/BawanHoshyar/ytermusic --branch bawan/custom --bin ytermusic
else
  echo "ytermusic already installed at $(command -v ytermusic) — skipping (run \`cargo install --git ... --force\` to refresh)"
fi

# Claude Code CLI — native installer (lands in ~/.local/bin/claude, auto-updates).
if ! command -v claude >/dev/null && [[ ! -x "$HOME/.local/bin/claude" ]]; then
  curl -fsSL https://claude.ai/install.sh | bash
fi

# Ruby via rbenv (rails projects).
RUBY_VERSION=3.4.10
if ! rbenv versions --bare 2>/dev/null | grep -qx "$RUBY_VERSION"; then
  rbenv install "$RUBY_VERSION"
fi
rbenv global "$RUBY_VERSION"

# uv-managed Python + tools.
uv python install 3.11
uv tool install --from "git+https://github.com/github/spec-kit.git@v0.11.1" specify-cli 2>/dev/null || true
