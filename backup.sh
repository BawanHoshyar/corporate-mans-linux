#!/usr/bin/env bash
# Pack everything personal that must NOT live in this public repo into one
# archive: projects, Claude Code config/memory/skills/plugins, ssh keys, git/gh
# auth, shell history, custom LaunchAgents. Run this BEFORE wiping the Mac,
# then copy the archive to a USB drive / Google Drive.
#
#   bash backup.sh [dest-dir]        (default: ~)
#
# setup.sh restores it automatically (scripts/15-restore-backup.sh).
set -euo pipefail

DEST_DIR="${1:-$HOME}"
OUT="$DEST_DIR/cml-backup-$(date +%Y%m%d-%H%M%S).tar.gz"

# Paths relative to $HOME. Edit this list to add/remove things.
ITEMS=(
  claude_projects personal_projects apps code bawan_docs second_brain
  Desktop Documents Downloads Pictures Movies Music
  .claude .claude.json
  .ssh .gitconfig .config/gh .config/gcloud
  .zsh_history .local/share/atuin
  .grok .vibehost .vibehost-template .mitmproxy .docker/config.json
  Library/LaunchAgents/com.bawan.aerospace-heal.plist
  Library/LaunchAgents/com.bawan.topvendors.refresh.plist
)

# Rebuildable / machine-local junk. Deps are reinstalled on restore.
EXCLUDES=(
  node_modules .venv venv __pycache__ .gradle .DS_Store '.ssh/agent' '*.sock'
  '*/android/build' '*/android/app/build' '*/.dart_tool'
  '.claude/cache' '.claude/paste-cache' '.claude/shell-snapshots'
  '.claude/session-env' '.claude/telemetry' '.claude/downloads'
)

cd "$HOME"

# venvs are excluded, so snapshot what's in them; restore rebuilds from this.
while IFS= read -r v; do
  d="$(dirname "$v")"
  uv pip freeze --python "$v/bin/python" > "$d/.venv-requirements.txt" 2>/dev/null || continue
  sed -n 's/^version[_info]* = \([0-9]*\.[0-9]*\).*/\1/p' "$v/pyvenv.cfg" | head -1 > "$d/.venv-python-version"
  echo "froze $d/.venv"
done < <(find claude_projects personal_projects apps -maxdepth 4 -name node_modules -prune -o -type d -name .venv -print 2>/dev/null)

present=()
for i in "${ITEMS[@]}"; do
  if [[ -e "$i" ]]; then present+=("$i"); else echo "[skip] ~/$i (missing)"; fi
done
args=()
for e in "${EXCLUDES[@]}"; do args+=(--exclude "$e"); done

echo "==> Writing $OUT"
tar -czf "$OUT" "${args[@]}" "${present[@]}"
tar -tzf "$OUT" >/dev/null   # verify it reads back
echo "==> Done: $(du -h "$OUT" | cut -f1)  $OUT"
echo "    Copy it OFF this Mac (USB / Google Drive) before formatting."
echo "    On the new Mac:  bash setup.sh --restore /path/to/$(basename "$OUT")"
