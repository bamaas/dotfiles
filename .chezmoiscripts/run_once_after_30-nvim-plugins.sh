#!/bin/sh
# Pre-install NvChad/lazy.nvim plugins so nvim doesn't clone them on first launch.
# Containers only — skipped on real machines (guarded by /.dockerenv) to avoid
# messing with an interactive user's editor state.
set -eu

[ -f /.dockerenv ] || exit 0
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
command -v nvim >/dev/null 2>&1 || exit 0

echo ">> Pre-installing nvim (NvChad) plugins..."
nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
# compile the base46 theme cache so the first launch is instant
nvim --headless "+lua pcall(function() require('base46').load_all_highlights() end)" +qa 2>/dev/null || true
echo ">> nvim plugins ready."
