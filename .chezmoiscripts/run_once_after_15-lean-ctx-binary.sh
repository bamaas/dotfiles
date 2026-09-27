#!/bin/sh
# Repair the lean-ctx native binary when mise's npm backend skipped the package's
# postinstall step. Runs on BOTH macOS host and Linux (VMs, dev containers).
#
# `npm:lean-ctx-bin` ships a thin node wrapper (bin/lean-ctx.js) plus a
# postinstall that fetches the ~84MB native binary next to it as bin/lean-ctx.
# mise's built-in npm implementation does not run npm lifecycle scripts, so on a
# fresh box the mise shim exists while the binary does not: every lean-ctx hook in
# ~/.claude/settings.json dies with "lean-ctx binary not found. Run: npm rebuild
# lean-ctx-bin" and its MCP server never starts.
#
# The shim's existence is therefore NOT a usable check — run the thing. Placed at
# 15 so the binary is fixed before script 40 wires the MCP server and calls
# `lean-ctx init`, and before any interactive session loads the hooks.
set -eu

# ~/.local/bin ahead of the shims: see the PATH note in run_once_after_40.
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

LEANCTX_BIN="$HOME/.local/share/mise/shims/lean-ctx"

# Not installed at all (mise install skipped, or the tool was dropped from
# config.toml) — nothing to repair.
[ -x "$LEANCTX_BIN" ] || exit 0

if "$LEANCTX_BIN" --version >/dev/null 2>&1; then
  exit 0
fi

echo ">> lean-ctx native binary missing, running its postinstall..."
if ! command -v node >/dev/null 2>&1; then
  echo ">> node not on PATH; cannot repair lean-ctx."
  exit 0
fi

# Unmatched globs stay literal, hence the -f test. Only repair installs that are
# actually missing the binary, so this never re-downloads 84MB for nothing.
for pi in "$HOME"/.local/share/mise/installs/npm-lean-ctx-bin/*/node_modules/.mise/lean-ctx-bin@*/node_modules/lean-ctx-bin/postinstall.js; do
  if [ -f "$pi" ]; then
    pkg="$(dirname "$pi")"
    if [ ! -x "$pkg/bin/lean-ctx" ]; then
      (cd "$pkg" && node postinstall.js) >/dev/null 2>&1 || true
    fi
  fi
done

if "$LEANCTX_BIN" --version >/dev/null 2>&1; then
  echo ">> lean-ctx binary repaired."
else
  echo ">> lean-ctx binary still missing — its hooks and MCP server will not work."
fi
