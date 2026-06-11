#!/usr/bin/env bash
# Pull the local LLMs I use. Tags below are best-effort — adjust to taste.
set -euo pipefail

if ! command -v ollama >/dev/null; then
  echo "ollama CLI not on PATH yet (the cask installs the GUI which provides it)."
  echo "Open Ollama.app once so it registers, then re-run this script."
  exit 0
fi

# Start the daemon if it isn't already (the .app usually does this for you).
if ! ollama list >/dev/null 2>&1; then
  open -a Ollama || true
  sleep 3
fi

MODELS=(
  "hermes3"                         # Nous Hermes 3
  "qwen2.5-coder"                   # coding model
  "huihui_ai/gpt-oss-20b-abliterated"  # closest registry hit for "gpt-oss-abliterated"
  "whiterabbitneo/whiterabbitneo"   # chat-only, no tool support (per project memory)
)

for m in "${MODELS[@]}"; do
  echo "==> ollama pull $m"
  ollama pull "$m" || echo "  (skipped/failed — adjust the tag in scripts/50-ollama-models.sh)"
done

echo
echo "Current models:"
ollama list
