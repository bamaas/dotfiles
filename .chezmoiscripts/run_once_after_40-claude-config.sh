#!/bin/sh
# Configure Claude Code tooling (lean-ctx, claude-hud, rtk, caveman).
# Runs on BOTH macOS host and Linux dev containers.
# Container-only: pre-seed theme + onboarding so Claude doesn't prompt on first launch.
set -eu

# mise shims (node / lean-ctx / claude / yq) must be resolvable here. Script 10
# already ran `mise install`, so the shims exist by now.
export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"

mkdir -p "$HOME/.claude"

# --- container-only: seed theme + onboarding --------------------------------
if [ -n "${DEVCONTAINER:-}" ] || [ -f /.dockerenv ]; then
  # theme (only if not already set)
  [ -f "$HOME/.claude/settings.json" ] || printf '{\n  "theme": "dark"\n}\n' > "$HOME/.claude/settings.json"
  # onboarding flag (only if missing / not already accepted)
  if ! grep -q hasCompletedOnboarding "$HOME/.claude.json" 2>/dev/null; then
    printf '{\n  "hasCompletedOnboarding": true\n}\n' > "$HOME/.claude.json"
  fi
fi

# --- lean-ctx MCP server (npm:lean-ctx-bin, installed via mise) --------------
# Registers the same stdio server the host uses. Local config only (no API/auth
# needed at build time). Absolute binary path via `mise which` so the MCP launch
# doesn't depend on PATH. `lean-ctx init` seeds the agent instructions + skill.
if command -v lean-ctx >/dev/null 2>&1 && command -v claude >/dev/null 2>&1; then
  LEANCTX_BIN="$(mise which lean-ctx 2>/dev/null || command -v lean-ctx)"
  claude mcp add -s user -e "LEAN_CTX_DATA_DIR=$HOME/.lean-ctx" \
    lean-ctx "$LEANCTX_BIN" >/dev/null 2>&1 || true
  lean-ctx init --agent claude >/dev/null 2>&1 || true
fi

# --- claude-hud statusline plugin (github.com/jarrodwatts/claude-hud) --------
# Add the marketplace + install the plugin (git clone / file copy, no API auth),
# then wire the statusLine command. `/claude-hud:setup` is interactive, so we
# write the statusLine ourselves — same shape as the host, but resolving `node`
# off PATH (mise shim) and picking the newest cached plugin build.
if command -v claude >/dev/null 2>&1 && command -v yq >/dev/null 2>&1; then
  claude plugin marketplace add jarrodwatts/claude-hud >/dev/null 2>&1 || true
  claude plugin install claude-hud@claude-hud -s user >/dev/null 2>&1 || true

  HUD_CMD="$(cat <<'EOF'
bash -c 'd=$(ls -dt "$HOME"/.claude/plugins/cache/claude-hud/claude-hud/*/ 2>/dev/null | head -1); exec node "${d}dist/index.js"'
EOF
)"
  export HUD_CMD
  yq -i -oj '
    .statusLine.type = "command" |
    .statusLine.command = strenv(HUD_CMD) |
    .enabledPlugins["claude-hud@claude-hud"] = true
  ' "$HOME/.claude/settings.json" 2>/dev/null || true
fi

# --- rtk context engine (github.com/rtk-ai/rtk) -----------------------------
# Installed via mise (lean set). `rtk init -g` creates a global config that
# wires RTK into Claude Code as a context provider.
if command -v rtk >/dev/null 2>&1; then
  rtk init -g >/dev/null 2>&1 || true
fi

# --- caveman prompt skill (github.com/juliusbrussee/caveman) -----------------
# Claude Code plugin — ultra-compressed communication mode.
if command -v claude >/dev/null 2>&1; then
  claude plugin marketplace add JuliusBrussee/caveman >/dev/null 2>&1 || true
  claude plugin install caveman@caveman -s user >/dev/null 2>&1 || true
fi
