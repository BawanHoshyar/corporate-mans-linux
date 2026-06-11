#!/usr/bin/env bash
# Final tweaks + the manual-TODO banner.
set -euo pipefail

# Make brew zsh the login shell.
BREW_ZSH="$(brew --prefix)/bin/zsh"
if [[ -x "$BREW_ZSH" ]]; then
  if ! grep -qx "$BREW_ZSH" /etc/shells; then
    echo "Adding $BREW_ZSH to /etc/shells (needs sudo)…"
    echo "$BREW_ZSH" | sudo tee -a /etc/shells >/dev/null
  fi
  if [[ "${SHELL:-}" != "$BREW_ZSH" ]]; then
    chsh -s "$BREW_ZSH" || echo "chsh failed — run it manually."
  fi
fi

cat <<'BANNER'

╔══════════════════════════════════════════════════════════════════════╗
║                         ALMOST DONE                                  ║
╚══════════════════════════════════════════════════════════════════════╝

The script can't grant permissions or sign you in. Do these by hand:

  1. Log out and back in (Fn-keys, chsh, and Aerospace need a fresh session).

  2. System Settings → Privacy & Security:
     - Accessibility    : enable AeroSpace, Hammerspoon, Sketchybar
     - Screen Recording : enable AeroSpace, Hammerspoon, Sketchybar

  3. Auth + sync:
       atuin login   (or `atuin register`)
       gh auth login
       ssh-keygen -t ed25519 -C "you@example.com"
       # paste the .pub into https://github.com/settings/keys
     Then in Claude Code: /login
     Postman: open, sign in.

  4. Ghostty → Settings → "Make Default Terminal".

  5. Hermes:
       cp ~/.hermes/config.yaml.example ~/.hermes/config.yaml
       # fill in API keys, model paths, etc.

  6. ytermusic — YouTube Music cookie:
       see the "YouTube Music cookie" section in the repo README.
       https://github.com/BawanHoshyar/corporate-mans-linux

  7. (Optional) extra Ollama models beyond the four pulled:
       ollama pull <name>

Log: ~/.corporate-mans-linux.log
BANNER
