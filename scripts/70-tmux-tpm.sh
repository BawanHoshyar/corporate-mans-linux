#!/usr/bin/env bash
# Bootstrap tmux plugin manager and install plugins declared in .tmux.conf.
set -euo pipefail

TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

if [[ -x "$TPM_DIR/bin/install_plugins" ]]; then
  "$TPM_DIR/bin/install_plugins" || true
fi
