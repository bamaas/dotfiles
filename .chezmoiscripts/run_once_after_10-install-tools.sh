#!/bin/sh
# Runs once (per content hash) after chezmoi applies files.
# chezmoi installs mise; mise installs everything else from ~/.config/mise/config.toml.
set -eu

# Pinned here, not in config.toml: mise must never manage itself (see AGENTS.md).
# `mise self-update` would move it off the pin until the next change to this script.
MISE_VERSION="2026.8.2"

export PATH="$HOME/.local/bin:$PATH"

installed="$(mise version 2>/dev/null | head -n1 | cut -d' ' -f1 || true)"
if [ "$installed" != "$MISE_VERSION" ]; then
  echo ">> Installing mise $MISE_VERSION (found: ${installed:-none})..."
  curl -fsSL https://mise.run | MISE_VERSION="v$MISE_VERSION" sh
fi

echo ">> Trusting + installing tools via mise..."
mise trust "$HOME/.config/mise/config.toml" 2>/dev/null || true
mise install

echo ">> Tools installed."
