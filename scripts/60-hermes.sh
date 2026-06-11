#!/usr/bin/env bash
# Clone NousResearch/hermes-agent into ~/.hermes/hermes-agent.
# Config is per-user (API keys etc.) — printed as a manual TODO at the end.
set -euo pipefail

HERMES_DIR="$HOME/.hermes"
AGENT_DIR="$HERMES_DIR/hermes-agent"

mkdir -p "$HERMES_DIR"

if [[ -d "$AGENT_DIR/.git" ]]; then
  echo "hermes-agent already cloned — pulling latest"
  git -C "$AGENT_DIR" pull --ff-only || true
else
  git clone https://github.com/NousResearch/hermes-agent "$AGENT_DIR"
fi

if [[ ! -f "$HERMES_DIR/config.yaml" ]] && [[ -f "$AGENT_DIR/cli-config.yaml.example" ]]; then
  cp "$AGENT_DIR/cli-config.yaml.example" "$HERMES_DIR/config.yaml.example"
  echo "Sample config copied to $HERMES_DIR/config.yaml.example — fill it in and save as config.yaml."
fi
