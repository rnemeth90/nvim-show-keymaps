#!/usr/bin/env bash
set -euo pipefail

PLUGIN_NAME="nvim-show-keymaps"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# NVIM_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/${NVIM_APPNAME:-nvim}"
NVIM_DATA_DIR="${XDG_DATA_HOME:-$HOME}/.local/share/nvim-lazy"
PACK_DIR="$NVIM_DATA_DIR/site/pack/$PLUGIN_NAME/start/$PLUGIN_NAME"

echo "Installing $PLUGIN_NAME..."

if [[ ! -d "$PACK_DIR" ]]; then
  mkdir -p "$(dirname "$PACK_DIR")"
  ln -s "$REPO_DIR" "$PACK_DIR"
  echo "Symlinked plugin to: $PACK_DIR"
else
  echo "Plugin already installed at: $PACK_DIR"
fi

echo "Done. Restart Neovim and run :Keymaps or :KeymapsMode <mode> (e.g. :KeymapsMode n)"
