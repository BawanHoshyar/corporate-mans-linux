#!/usr/bin/env bash
# Preflight: Xcode CLT + Homebrew
set -euo pipefail

if ! xcode-select -p &>/dev/null; then
  echo "Installing Xcode Command Line Tools (a GUI dialog will appear)…"
  xcode-select --install || true
  echo "Waiting for the install to finish…"
  until xcode-select -p &>/dev/null; do sleep 5; printf '.'; done
  echo
fi

if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew…"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Ensure brew is on PATH for the rest of this run.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

brew --version
