#!/usr/bin/env bash
# Pull the encrypted backup made by backup.sh from the private GitHub repo,
# decrypt it with your passphrase, unpack into $HOME (projects, ~/.claude,
# ssh, auth, Obsidian, ...), then rebuild venvs/node_modules.
set -uo pipefail

BACKUP_REPO="${CML_BACKUP_REPO:-BawanDawood/mac-backup}"
read -rp "$(printf '\033[1;35m? Restore your backup from github.com/%s? [Y/n] \033[0m' "$BACKUP_REPO")" reply </dev/tty
case "${reply:-y}" in n|N|no|No) echo "Skipping restore."; exit 0 ;; esac

if ! gh auth status &>/dev/null; then
  echo "Log into GitHub as ${BACKUP_REPO%%/*} (the account that owns the backup):"
  gh auth login --hostname github.com --git-protocol https --web </dev/tty
fi
gh auth setup-git

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
git clone --depth 1 -q "https://github.com/$BACKUP_REPO.git" "$WORK/repo" || { echo "[err] clone failed"; exit 1; }

echo "Decrypting — enter your backup passphrase:"
until cat "$WORK"/repo/backup.tgz.enc.part-* \
  | /usr/bin/openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 \
  | tar -xzpf - -C "$HOME"; do
  echo "[warn] wrong passphrase or corrupt download — try again (Ctrl-C to skip)"
done
chmod 700 "$HOME/.ssh" 2>/dev/null && chmod 600 "$HOME"/.ssh/id_* 2>/dev/null
chmod 644 "$HOME"/.ssh/*.pub 2>/dev/null || true

# Re-load custom LaunchAgents.
for p in "$HOME"/Library/LaunchAgents/com.bawan.*.plist; do
  [[ -f "$p" ]] && launchctl bootstrap "gui/$(id -u)" "$p" 2>/dev/null || true
done

# Rebuild per-project deps that the backup excluded (.venv, node_modules).
for root in claude_projects personal_projects apps; do
  [[ -d "$HOME/$root" ]] || continue
  while IFS= read -r f; do
    d="$(dirname "$f")"
    case "$(basename "$f")" in
      uv.lock)      echo "uv sync: $d";     (cd "$d" && uv sync -q) || echo "[warn] uv sync failed in $d" ;;
      .venv-requirements.txt)
        echo "venv: $d"
        (cd "$d" && uv venv -q --python "$(cat .venv-python-version 2>/dev/null || echo 3)" .venv \
          && uv pip install -q --python .venv/bin/python -r .venv-requirements.txt) || echo "[warn] venv rebuild failed in $d" ;;
      package.json) echo "npm install: $d"; (cd "$d" && npm install --silent) || echo "[warn] npm install failed in $d" ;;
    esac
  done < <(find "$HOME/$root" -maxdepth 4 \( -name node_modules -o -name .venv \) -prune -o \
             \( -name uv.lock -o -name package.json -o -name .venv-requirements.txt \) -print)
done
echo "Restore done."
