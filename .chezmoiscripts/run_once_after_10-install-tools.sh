#!/bin/sh
# Runs once (per content hash) after chezmoi applies files.
# chezmoi installs mise; mise installs everything else from ~/.config/mise/config.toml.
set -eu

if ! command -v mise >/dev/null 2>&1; then
  echo ">> Installing mise..."
  curl -fsSL https://mise.run | sh
fi

export PATH="$HOME/.local/bin:$PATH"

echo ">> Trusting + installing tools via mise..."
mise trust "$HOME/.config/mise/config.toml" 2>/dev/null || true
mise install

echo ">> Tools installed."
