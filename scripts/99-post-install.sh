#!/usr/bin/env bash
# Guided post-install. Walks the user through every step that can't be done
# silently — runs commands where possible, opens the right System Settings
# panel where it must, and pauses only when the OS or a browser blocks us.
set -uo pipefail   # not -e: optional steps may fail and that's fine

# --- helpers -----------------------------------------------------------------
pause() { read -rp "$(printf '\n\033[1;33m↩ Press ENTER when done (Ctrl-C to abort) \033[0m')" _ </dev/tty; }

ask() {
  local prompt="$1" reply
  read -rp "$(printf '\033[1;35m? %s [Y/n] \033[0m' "$prompt")" reply </dev/tty
  case "${reply:-y}" in n|N|no|No) return 1 ;; *) return 0 ;; esac
}

heading() { printf '\n\033[1;36m═══ %s ═══\033[0m\n\n' "$*"; }
say()     { printf '  %s\n' "$*"; }
skip()    { printf '  \033[2m(skipped: %s)\033[0m\n' "$*"; }

# --- 1: ssh key -------------------------------------------------------------
heading "1. SSH key for GitHub"
SSH_KEY="$HOME/.ssh/id_ed25519"
if [[ -f "$SSH_KEY" ]]; then
  skip "$SSH_KEY already exists"
else
  if ask "Generate an ed25519 SSH key now?"; then
    read -rp "  Email for the key: " ssh_email </dev/tty
    mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "$ssh_email" -f "$SSH_KEY" -N "" </dev/tty
    eval "$(ssh-agent -s)" >/dev/null && ssh-add --apple-use-keychain "$SSH_KEY" 2>/dev/null || true
  fi
fi

# --- 2: gh auth -------------------------------------------------------------
heading "2. GitHub CLI auth"
if gh auth status &>/dev/null; then
  skip "gh already authenticated"
else
  say "Running gh auth login — copy the one-time code, then authorize in the browser."
  gh auth login --hostname github.com --git-protocol https --web </dev/tty || say "gh auth failed — re-run: gh auth login"
fi

# --- 3: upload pubkey to GitHub ---------------------------------------------
heading "3. Upload SSH key to GitHub"
if [[ -f "$SSH_KEY.pub" ]] && gh auth status &>/dev/null; then
  TITLE="$(scutil --get ComputerName 2>/dev/null || hostname)"
  if gh ssh-key list 2>/dev/null | grep -qF "$(cat "$SSH_KEY.pub" | awk '{print $2}' | cut -c1-20)"; then
    skip "this key is already on GitHub"
  elif ask "Upload $SSH_KEY.pub to github.com as '$TITLE'?"; then
    gh ssh-key add "$SSH_KEY.pub" --title "$TITLE" || say "Upload failed — paste it at https://github.com/settings/keys"
  fi
else
  skip "no SSH key or gh not authed"
fi

# --- 4: atuin --------------------------------------------------------------
heading "4. Atuin history sync"
if [[ -f "$HOME/.local/share/atuin/session" ]]; then
  skip "atuin session already exists"
elif command -v atuin >/dev/null; then
  if ask "Set up Atuin sync now?"; then
    echo "    Pick one:"
    echo "      [r] register a new account"
    echo "      [l] login to existing account"
    echo "      [s] skip"
    read -rp "    > " atuin_choice </dev/tty
    case "$atuin_choice" in
      r|R) atuin register </dev/tty ;;
      l|L) atuin login </dev/tty ;;
      *)   skip "atuin sync deferred" ;;
    esac
  fi
fi

# --- 5: Accessibility + Screen Recording permissions ------------------------
heading "5. macOS permissions (Accessibility + Screen Recording)"
say "AeroSpace, Hammerspoon and Sketchybar need both permissions to function."
say "Opening Accessibility settings now — find each app and enable the toggle."
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" 2>/dev/null
pause
say "Now Screen Recording — same three apps."
open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture" 2>/dev/null
pause

# --- 6: Claude Code login ---------------------------------------------------
heading "6. Claude Code"
say "Open Claude Code, run /login to use your Pro/Max subscription."
if ask "Open Claude Code now?"; then
  open -a "Claude" 2>/dev/null || open -a "Claude Code" 2>/dev/null || say "Couldn't open it — start it from Launchpad."
  pause
fi

# --- 7: Ghostty as default terminal ----------------------------------------
heading "7. Ghostty as default terminal"
say "In Ghostty: Ghostty menu → Settings → 'Make Default Terminal'."
if ask "Open Ghostty now?"; then
  open -a Ghostty 2>/dev/null
  pause
fi

# --- 8: ytermusic cookie ---------------------------------------------------
heading "8. ytermusic — YouTube Music cookie"
say "ytermusic needs a session cookie exported from a logged-in browser."
say "Full instructions:"
say "  https://github.com/BawanHoshyar/corporate-mans-linux#youtube-music-cookie-for-ytermusic"
if ask "Have you saved cookies.txt to ~/.config/ytermusic/cookies.txt yet?"; then
  if [[ -f "$HOME/.config/ytermusic/cookies.txt" ]]; then
    say "Found it. ytermusic should work."
  else
    say "File not found at expected path — run ytermusic once to see the exact path it wants."
  fi
fi

# --- DONE -------------------------------------------------------------------
cat <<'BANNER'

╔══════════════════════════════════════════════════════════════════════╗
║                              ALL DONE                                ║
║              Corporate Man's Linux  ·  Bawan A. Dawood               ║
╚══════════════════════════════════════════════════════════════════════╝

Log out and back in (or reboot) to lock in:
  • Fn-keys as F1–F12
  • Accessibility / Screen Recording grants

Cheatsheet:  hold ⌘⌥/ once Hammerspoon is granted Accessibility.
Log:         ~/.corporate-mans-linux.log
BANNER
