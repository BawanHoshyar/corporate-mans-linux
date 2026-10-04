#!/usr/bin/env bash
# Pack everything personal that must NOT live in this public repo — projects,
# Claude Code + desktop config/memory/skills/plugins, ssh keys, git/gh auth,
# shell history, Obsidian, LaunchAgents — encrypt it with your passphrase and
# force-push it as ONE commit to a private GitHub repo (old backups are
# replaced, so the repo doesn't grow forever).
#
#   bash backup.sh                    (prompts for the passphrase twice)
#   CML_PASSPHRASE=... bash backup.sh (non-interactive)
#
# setup.sh pulls + decrypts it on the new Mac (scripts/15-restore-backup.sh).
set -euo pipefail

BACKUP_REPO="${CML_BACKUP_REPO:-BawanDawood/mac-backup}"   # private, work account
GH_USER="${BACKUP_REPO%%/*}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Paths relative to $HOME. Edit this list to add/remove things.
ITEMS=(
  claude_projects personal_projects apps code bawan_docs second_brain
  Desktop Documents Downloads Pictures Movies Music
  .claude .claude.json
  .ssh .gitconfig .config/gh .config/gcloud
  .zsh_history .local/share/atuin .local/share/opencode
  'Library/Application Support/Claude'
  'Library/Application Support/obsidian/obsidian.json'
  'Library/Application Support/obsidian/f7a415d44e7bed09.json'
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
  'Library/Application Support/Claude/vm_bundles' 'Library/Application Support/Claude/claude-code-vm' 'Library/Application Support/Claude/claude-code' 'Library/Application Support/Claude/Cache' 'Library/Application Support/Claude/Code Cache' 'Library/Application Support/Claude/GPUCache'
  'Library/Application Support/Claude/DawnGraphiteCache' 'Library/Application Support/Claude/DawnWebGPUCache' 'Library/Application Support/Claude/Crashpad' 'Library/Application Support/Claude/Singleton*'
  '.local/share/opencode/log' '.local/share/opencode/tool-output'
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

PASS_ARGS=()
[[ -n "${CML_PASSPHRASE:-}" ]] && PASS_ARGS=(-pass env:CML_PASSPHRASE)

echo "==> Packing + encrypting (AES-256, your passphrase) into 45MB parts"
mkdir -p "$WORK/repo"
tar -czf - "${args[@]}" "${present[@]}" \
  | /usr/bin/openssl enc -aes-256-cbc -pbkdf2 -iter 200000 -salt ${PASS_ARGS[@]+"${PASS_ARGS[@]}"} \
  | split -b 45m - "$WORK/repo/backup.tgz.enc.part-"
echo "    $(du -sh "$WORK/repo" | cut -f1) in $(ls "$WORK/repo" | wc -l | tr -d ' ') parts"

echo "==> Pushing to private repo github.com/$BACKUP_REPO"
TOKEN="$(gh auth token --user "$GH_USER")" || { echo "gh is not logged in as $GH_USER — run: gh auth login" >&2; exit 1; }
if ! GH_TOKEN="$TOKEN" gh repo view "$BACKUP_REPO" &>/dev/null; then
  GH_TOKEN="$TOKEN" gh repo create "$BACKUP_REPO" --private --description "Encrypted Mac backup (corporate-mans-linux)" >/dev/null
fi
cd "$WORK/repo"
date '+Backup of %Y-%m-%d %H:%M — restore with corporate-mans-linux setup.sh' > README.md
git init -q -b main
URL="https://$GH_USER:$TOKEN@github.com/$BACKUP_REPO.git"
commit_push() {  # $1 = message, rest = extra push flags; 3 tries per batch
  git -c user.name="$GH_USER" -c user.email="$GH_USER@users.noreply.github.com" commit -q -m "$1"
  shift
  for try in 1 2 3; do
    git -c http.postBuffer=524288000 push -q "$@" "$URL" main 2>&1 | sed "s/$TOKEN/***/g" && return 0
    echo "    push failed (try $try/3), retrying…"; sleep 5
  done
  return 1
}
# Fresh history each time (--force on the first commit) so the repo doesn't
# grow forever; parts go up in ~270MB batches because one 1GB+ push tends to drop.
git add README.md && commit_push "backup $(date +%F-%H%M)" --force
parts=(backup.tgz.enc.part-*)
for ((i = 0; i < ${#parts[@]}; i += 6)); do
  git add "${parts[@]:i:6}"
  commit_push "parts $((i + 1))-$((i + 6 > ${#parts[@]} ? ${#parts[@]} : i + 6)) of ${#parts[@]}"
  echo "    pushed $((i + 6 > ${#parts[@]} ? ${#parts[@]} : i + 6))/${#parts[@]}"
done
echo "==> Done. Backup is at https://github.com/$BACKUP_REPO (encrypted)."
echo "    Don't forget the passphrase — without it the backup is unreadable."
