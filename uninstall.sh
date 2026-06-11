#!/usr/bin/env bash
# Corporate-man's Linux — UNINSTALL.
# Reverses every step setup.sh took. Best-effort "exactly back to before".
#
# What it does (in reverse of setup.sh):
#   99 ← chsh back to /bin/zsh (optional)
#   80 ← stop sketchybar/borders, quit AeroSpace/Hammerspoon/Ghostty,
#        rm ~/.config/opencode/node_modules
#   70 ← rm ~/.tmux/plugins/tpm and ~/.tmux/plugins (if empty)
#   60 ← rm -rf ~/.hermes
#   50 ← ollama rm each model installed by 50-ollama-models.sh
#   40 ← cargo uninstall ytermusic
#   30 ← defaults delete every key written by 30-macos-defaults.sh
#   20 ← remove symlinks pointing into the install dir, restore the
#        most recent ~/.dotfiles-backup-* into place
#   10 ← brew uninstall every formula/cask in Brewfile, then untap
#   00 ← (--nuke only) uninstall Homebrew itself
#   *  ← rm ~/.local/share/corporate-mans-linux and ~/.corporate-mans-linux.log
#
# Kept by default (pass --nuke to also remove):
#   • Homebrew itself  (may have pre-existed)
#   • Xcode Command Line Tools  (NEVER auto-removed; too disruptive)
#   • ~/.ssh/id_ed25519, gh auth, atuin account  (yours, not ours)
#
# Usage:
#   uninstall.sh [--yes] [--nuke] [--dry-run]
#
#     --yes / -y   Don't ask; just do it.
#     --nuke       Also uninstall Homebrew and revoke gh/atuin auth.
#     --dry-run    Print actions without running them.

set -uo pipefail

YES=0
NUKE=0
DRY=0
for arg in "$@"; do
  case "$arg" in
    --yes|-y)   YES=1 ;;
    --nuke)     NUKE=1 ;;
    --dry-run)  DRY=1 ;;
    -h|--help)
      sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

[[ "$OSTYPE" == darwin* ]] || { echo "macOS only." >&2; exit 1; }
[[ $EUID -ne 0 ]] || { echo "Do not run as root." >&2; exit 1; }

log()  { printf '\n\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
skip() { printf '  \033[2m(skipped: %s)\033[0m\n' "$*"; }
do_()  { if [[ $DRY -eq 1 ]]; then printf '  [dry] %s\n' "$*"; else eval "$@"; fi; }

ask() {
  [[ $YES -eq 1 ]] && return 0
  local prompt="$1" reply
  read -rp "$(printf '\033[1;35m? %s [y/N] \033[0m' "$prompt")" reply </dev/tty || return 1
  case "${reply:-n}" in y|Y|yes|Yes) return 0 ;; *) return 1 ;; esac
}

if [[ $DRY -eq 0 ]] && [[ $YES -eq 0 ]]; then
  cat <<EOF

This will uninstall everything corporate-mans-linux installed:
  • All brew formulae + casks in the Brewfile
  • ytermusic (cargo)
  • Ollama models: hermes3, qwen2.5-coder, gpt-oss-abliterated, whiterabbitneo
  • ~/.hermes, ~/.tmux/plugins/tpm
  • Dotfile symlinks  (originals restored from ~/.dotfiles-backup-*/)
  • macOS defaults this setup wrote
$( [[ $NUKE -eq 1 ]] && echo "  • Homebrew itself, gh auth, atuin account  (--nuke)" )

Kept (unless --nuke): Homebrew, Xcode CLT, ~/.ssh, gh/atuin auth.

EOF
  ask "Continue?" || { echo "Aborted."; exit 0; }
fi

# --- locate brew + repo -----------------------------------------------------
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Find the install dir for Brewfile + script-derived facts.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" &>/dev/null && pwd)" || SCRIPT_DIR=""
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/share/corporate-mans-linux}"
if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/Brewfile" ]]; then
  REPO_DIR="$SCRIPT_DIR"
elif [[ -d "$INSTALL_DIR/.git" ]]; then
  REPO_DIR="$INSTALL_DIR"
elif [[ -d "$HOME/code/corporate-mans-linux/.git" ]]; then
  REPO_DIR="$HOME/code/corporate-mans-linux"
else
  REPO_DIR=""
fi
[[ -n "$REPO_DIR" ]] && log "Using repo at $REPO_DIR"

# --- 99 ← login shell -------------------------------------------------------
log "99 ← Login shell"
BREW_ZSH="$(brew --prefix 2>/dev/null)/bin/zsh"
SYSTEM_ZSH="/bin/zsh"
if [[ "${SHELL:-}" == "$BREW_ZSH" ]] && [[ -x "$SYSTEM_ZSH" ]]; then
  if ask "Change login shell back to $SYSTEM_ZSH?"; then
    do_ "chsh -s '$SYSTEM_ZSH'" || warn "chsh failed"
  else skip "kept brew zsh as login shell"; fi
else
  skip "not on brew zsh"
fi

# --- 80 ← services + GUI apps ----------------------------------------------
log "80 ← Stop services and GUI apps"
if command -v brew >/dev/null; then
  for s in sketchybar borders; do
    do_ "brew services stop $s 2>/dev/null || true"
  done
fi
for app in AeroSpace Hammerspoon Ghostty Sketchybar Borders Ollama; do
  do_ "osascript -e 'quit app \"$app\"' 2>/dev/null || true"
done
if [[ -d "$HOME/.config/opencode/node_modules" ]]; then
  do_ "rm -rf '$HOME/.config/opencode/node_modules'"
fi

# --- 70 ← tmux tpm ---------------------------------------------------------
log "70 ← tmux plugin manager"
if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
  do_ "rm -rf '$HOME/.tmux/plugins/tpm'"
  do_ "rmdir '$HOME/.tmux/plugins' 2>/dev/null || true"
  do_ "rmdir '$HOME/.tmux' 2>/dev/null || true"
else skip "no tpm dir"; fi

# --- 60 ← hermes -----------------------------------------------------------
log "60 ← Hermes"
if [[ -d "$HOME/.hermes" ]]; then
  if [[ -f "$HOME/.hermes/config.yaml" ]] && ! ask "Delete ~/.hermes (includes config.yaml with API keys)?"; then
    skip "kept ~/.hermes"
  else
    do_ "rm -rf '$HOME/.hermes'"
  fi
else skip "no ~/.hermes"; fi

# --- 50 ← ollama models ----------------------------------------------------
log "50 ← Ollama models"
if command -v ollama >/dev/null; then
  for m in hermes3 qwen2.5-coder huihui_ai/gpt-oss-20b-abliterated whiterabbitneo/whiterabbitneo; do
    do_ "ollama rm '$m' 2>/dev/null || true"
  done
else skip "ollama CLI not on PATH (will be removed with cask anyway)"; fi

# --- 40 ← cargo installs ---------------------------------------------------
log "40 ← Cargo-installed tools"
if command -v cargo >/dev/null && cargo install --list 2>/dev/null | grep -q '^ytermusic '; then
  do_ "cargo uninstall ytermusic || true"
else skip "ytermusic not installed via cargo"; fi

# --- 30 ← macOS defaults ---------------------------------------------------
log "30 ← Revert macOS defaults"
# Keys to delete = exactly the ones 30-macos-defaults.sh wrote.
GLOBAL_KEYS=(
  com.apple.keyboard.fnState
  KeyRepeat
  InitialKeyRepeat
  ApplePressAndHoldEnabled
  NSAutomaticSpellingCorrectionEnabled
  NSAutomaticCapitalizationEnabled
  NSAutomaticQuoteSubstitutionEnabled
  NSAutomaticDashSubstitutionEnabled
  NSAutomaticPeriodSubstitutionEnabled
  AppleShowAllExtensions
  com.apple.mouse.tapBehavior
  NSNavPanelExpandedStateForSaveMode
)
for k in "${GLOBAL_KEYS[@]}"; do
  do_ "defaults delete -g '$k' 2>/dev/null || true"
done

# Finder
for k in AppleShowAllFiles ShowPathbar ShowStatusBar FXPreferredViewStyle FXDefaultSearchScope; do
  do_ "defaults delete com.apple.finder '$k' 2>/dev/null || true"
done
for k in DSDontWriteNetworkStores DSDontWriteUSBStores; do
  do_ "defaults delete com.apple.desktopservices '$k' 2>/dev/null || true"
done

# Dock
for k in autohide show-recents tilesize launchanim expose-animation-duration; do
  do_ "defaults delete com.apple.dock '$k' 2>/dev/null || true"
done

# Screenshots
for k in location type disable-shadow; do
  do_ "defaults delete com.apple.screencapture '$k' 2>/dev/null || true"
done

# Trackpad
do_ "defaults delete com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking 2>/dev/null || true"
do_ "defaults delete com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag 2>/dev/null || true"

# Misc
do_ "defaults delete com.apple.frameworks.diskimages skip-verify 2>/dev/null || true"

do_ "killall Dock Finder SystemUIServer 2>/dev/null || true"

# --- 20 ← dotfiles ---------------------------------------------------------
log "20 ← Dotfiles"
# Remove any symlink in $HOME / ~/.config / ~/Library/.../ghostty that points
# into the repo or install dir, then restore the most recent backup.
HOME_LINKS=(
  "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.tmux.conf" "$HOME/.hammerspoon"
)
if [[ -d "$HOME/.config" ]]; then
  while IFS= read -r -d '' link; do
    HOME_LINKS+=("$link")
  done < <(find "$HOME/.config" -mindepth 1 -maxdepth 1 -type l -print0 2>/dev/null)
fi
HOME_LINKS+=("$HOME/Library/Application Support/com.mitchellh.ghostty/config")

for path in "${HOME_LINKS[@]}"; do
  if [[ -L "$path" ]]; then
    target="$(readlink "$path")"
    case "$target" in
      "$REPO_DIR"/*|"$INSTALL_DIR"/*|*/corporate-mans-linux/dotfiles/*)
        do_ "rm '$path'"
        ;;
      *) skip "$path links elsewhere ($target)" ;;
    esac
  fi
done

# Restore most recent backup, if any.
LATEST_BACKUP="$(ls -1dt "$HOME"/.dotfiles-backup-* 2>/dev/null | head -1 || true)"
if [[ -n "$LATEST_BACKUP" && -d "$LATEST_BACKUP" ]]; then
  log "Restoring from $LATEST_BACKUP"
  # rsync would be simpler but isn't guaranteed; use cp -R.
  while IFS= read -r -d '' src; do
    rel="${src#$LATEST_BACKUP/}"
    dest="$HOME/$rel"
    do_ "mkdir -p '$(dirname "$dest")'"
    do_ "cp -R '$src' '$dest'"
  done < <(find "$LATEST_BACKUP" -mindepth 1 -maxdepth 1 -print0)
  do_ "rm -rf '$LATEST_BACKUP'"
else
  skip "no ~/.dotfiles-backup-* to restore"
fi

# --- 10 ← brew bundle ------------------------------------------------------
log "10 ← Uninstall everything in Brewfile"
BREWFILE=""
if [[ -n "$REPO_DIR" && -f "$REPO_DIR/Brewfile" ]]; then
  BREWFILE="$REPO_DIR/Brewfile"
fi

if [[ -z "$BREWFILE" ]] || ! command -v brew >/dev/null; then
  warn "no Brewfile or brew — skipping bundle removal"
else
  # Uninstall casks first (they may depend on formulae like font managers).
  CASKS=$(awk '/^cask /{gsub(/"/,"",$2); print $2}' "$BREWFILE")
  for c in $CASKS; do
    do_ "brew uninstall --cask --zap '$c' 2>/dev/null || true"
  done
  # Then formulae.
  FORMULAE=$(awk '/^brew /{gsub(/"/,"",$2); print $2}' "$BREWFILE")
  for f in $FORMULAE; do
    # The bundle uses tap/name for some; brew uninstall accepts either.
    do_ "brew uninstall --ignore-dependencies '$f' 2>/dev/null || true"
  done
  # Then untap.
  TAPS=$(awk '/^tap /{gsub(/"/,"",$2); print $2}' "$BREWFILE")
  for t in $TAPS; do
    do_ "brew untap '$t' 2>/dev/null || true"
  done
  do_ "brew autoremove 2>/dev/null || true"
  do_ "brew cleanup --prune=all 2>/dev/null || true"
fi

# --- 00 ← Homebrew itself (only with --nuke) -------------------------------
if [[ $NUKE -eq 1 ]]; then
  log "00 ← Homebrew itself (--nuke)"
  if command -v brew >/dev/null && ask "Run the official Homebrew uninstaller?"; then
    do_ 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)" -- --force'
  fi

  log "** ← gh / atuin auth (--nuke)"
  command -v gh    >/dev/null && do_ "gh auth logout --hostname github.com 2>/dev/null || true"
  command -v atuin >/dev/null && do_ "atuin logout 2>/dev/null || true"
  [[ -d "$HOME/.local/share/atuin" ]] && ask "Delete ~/.local/share/atuin?" && do_ "rm -rf '$HOME/.local/share/atuin'"
fi

# --- cleanup repo + log ----------------------------------------------------
log "Cleanup"
[[ -d "$INSTALL_DIR" ]] && do_ "rm -rf '$INSTALL_DIR'"
[[ -f "$HOME/.corporate-mans-linux.log" ]] && do_ "rm -f '$HOME/.corporate-mans-linux.log'"

cat <<'BANNER'

╔══════════════════════════════════════════════════════════════════════╗
║                              UNDONE                                  ║
╚══════════════════════════════════════════════════════════════════════╝

Log out + back in (or reboot) to reset:
  • Login shell  (if you opted to chsh back)
  • macOS keyboard / Finder / Dock defaults
  • Accessibility / Screen Recording grants are NOT auto-revoked —
    remove them under System Settings → Privacy & Security if you want.

Kept (because they may pre-date this setup):
  • Xcode Command Line Tools
  • ~/.ssh
  • Anything not listed in the original Brewfile

If you ran without --nuke, Homebrew is still installed.
BANNER
