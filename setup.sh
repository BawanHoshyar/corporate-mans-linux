#!/usr/bin/env bash
# Corporate-man's Linux — turn any Mac into mine in one command.
# https://github.com/BawanHoshyar/corporate-mans-linux

set -euo pipefail

REPO_URL="https://github.com/BawanHoshyar/corporate-mans-linux.git"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/share/corporate-mans-linux}"
LOG="$HOME/.corporate-mans-linux.log"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --restore) export CML_BACKUP="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"; shift ;;
    -h|--help)
      cat <<EOF
Usage: setup.sh [--restore cml-backup-XXXX.tar.gz] [--dry-run]

Bootstraps a Mac to match the corporate-mans-linux dotfiles + tooling setup.

  --restore F  Restore the private archive made by backup.sh (projects,
               ~/.claude, ssh, auth). Auto-detected on /Volumes/*, ~/Downloads, ~.
  --dry-run    Print what would happen without touching the system.
EOF
      exit 0
      ;;
  esac
  shift
done

log() { printf '\n\033[1;36m==>\033[0m %s\n' "$*" | tee -a "$LOG"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*" | tee -a "$LOG"; }
die() { printf '\033[1;31m[err ]\033[0m %s\n' "$*" | tee -a "$LOG" >&2; exit 1; }

[[ "$OSTYPE" == darwin* ]] || die "macOS only. You are on $OSTYPE."
[[ $EUID -ne 0 ]] || die "Do not run as root."

mkdir -p "$(dirname "$LOG")"
: > "$LOG"
log "Logging to $LOG"

if [[ $DRY_RUN -eq 1 ]]; then
  log "DRY RUN — no changes will be made."
  log "Would clone $REPO_URL into $INSTALL_DIR (if not already there)"
  log "Would run scripts/00-preflight.sh through 99-post-install.sh"
  exit 0
fi

# If this script was piped from curl, clone the repo and re-exec from disk.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" &>/dev/null && pwd)" || SCRIPT_DIR=""
if [[ -z "$SCRIPT_DIR" || ! -d "$SCRIPT_DIR/scripts" ]]; then
  log "Cloning $REPO_URL → $INSTALL_DIR"
  if [[ ! -d "$INSTALL_DIR/.git" ]]; then
    if ! command -v git &>/dev/null; then
      log "Installing Xcode Command Line Tools (needed for git)…"
      xcode-select --install 2>/dev/null || true
      until command -v git &>/dev/null; do
        sleep 5
        printf '.'
      done
      echo
    fi
    git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
  else
    git -C "$INSTALL_DIR" pull --ff-only
  fi
  exec bash "$INSTALL_DIR/setup.sh"
fi

cd "$SCRIPT_DIR"
export REPO_DIR="$SCRIPT_DIR"

run() {
  local script="$1"
  if [[ ! -x "$script" ]]; then
    warn "Skipping $script (not executable)"
    return
  fi
  log "Running $(basename "$script")"
  # Each script is its own process; keep brew + user bins on PATH for all.
  [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.rbenv/shims:$PATH"
  # 99-post-install is interactive — don't pipe through tee or it'll
  # buffer prompts and break `read`. Other scripts can stream to the log.
  if [[ "$(basename "$script")" == 99-* ]]; then
    bash "$script"
  else
    bash "$script" 2>&1 | tee -a "$LOG"
  fi
}

for script in scripts/[0-9][0-9]-*.sh; do
  run "$script"
done

log "All done. Read the manual TODO list above. A summary is also in $LOG."
