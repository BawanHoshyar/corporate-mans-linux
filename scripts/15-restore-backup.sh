#!/usr/bin/env bash
# Restore the private archive made by backup.sh (projects, ~/.claude, ssh,
# git/gh auth, history, LaunchAgents). Uses $CML_BACKUP (setup.sh --restore),
# else the newest cml-backup-*.tar.gz on a mounted volume, ~/Downloads or ~.
set -uo pipefail

ARCHIVE="${CML_BACKUP:-}"
if [[ -z "$ARCHIVE" ]]; then
  ARCHIVE="$(ls -t /Volumes/*/cml-backup-*.tar.gz "$HOME"/Downloads/cml-backup-*.tar.gz \
    "$HOME"/cml-backup-*.tar.gz 2>/dev/null | head -1)"
fi
if [[ -z "$ARCHIVE" || ! -f "$ARCHIVE" ]]; then
  echo "[warn] No backup archive found — skipping restore. Re-run later with:"
  echo "       CML_BACKUP=/path/to/cml-backup-....tar.gz bash $0"
  exit 0
fi

echo "Restoring $ARCHIVE → $HOME"
tar -xzpf "$ARCHIVE" -C "$HOME"
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
