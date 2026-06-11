#!/usr/bin/env bash
# Symlink dotfiles into $HOME. Anything already there is backed up
# under ~/.dotfiles-backup-<timestamp>/.
set -euo pipefail

REPO_DIR="${REPO_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)}"
SRC="$REPO_DIR/dotfiles"
BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

[[ -d "$SRC" ]] || { echo "No dotfiles/ in $REPO_DIR — nothing to do." >&2; exit 0; }

mkdir -p "$BACKUP"

link() {
  local src="$1" dest="$2"
  if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
    return  # already pointed at the right thing
  fi
  if [[ -e "$dest" || -L "$dest" ]]; then
    mkdir -p "$BACKUP/$(dirname "${dest#$HOME/}")"
    mv "$dest" "$BACKUP/${dest#$HOME/}"
  fi
  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  echo "linked $dest -> $src"
}

# Top-level home files
for f in zshrc zprofile tmux.conf; do
  [[ -e "$SRC/$f" ]] && link "$SRC/$f" "$HOME/.$f"
done

# Hammerspoon
if [[ -d "$SRC/hammerspoon" ]]; then
  link "$SRC/hammerspoon" "$HOME/.hammerspoon"
fi

# ~/.config subdirs (symlink each top-level dir/file individually so we
# don't clobber things the user adds later that aren't in this repo).
if [[ -d "$SRC/config" ]]; then
  mkdir -p "$HOME/.config"
  for item in "$SRC/config/"*; do
    name="$(basename "$item")"
    link "$item" "$HOME/.config/$name"
  done
fi

# Ghostty also reads from ~/Library/Application Support/com.mitchellh.ghostty/config
# on macOS. Mirror the symlink there so the GUI sees it too.
if [[ -e "$SRC/config/ghostty/config" ]]; then
  GHOSTTY_APP_SUPPORT="$HOME/Library/Application Support/com.mitchellh.ghostty"
  mkdir -p "$GHOSTTY_APP_SUPPORT"
  link "$SRC/config/ghostty/config" "$GHOSTTY_APP_SUPPORT/config"
fi

if [[ -z "$(ls -A "$BACKUP")" ]]; then
  rmdir "$BACKUP"
else
  echo "Replaced files backed up to $BACKUP"
fi
