#!/bin/sh
# Configure Claude Code tooling (lean-ctx, claude-hud, caveman).
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


# --- caveman prompt skill (github.com/juliusbrussee/caveman) -----------------
# Claude Code plugin — ultra-compressed communication mode.
if command -v claude >/dev/null 2>&1; then
  claude plugin marketplace add JuliusBrussee/caveman >/dev/null 2>&1 || true
  claude plugin install caveman@caveman -s user >/dev/null 2>&1 || true
fi

# --- mem0 memory MCP (hosted: https://mcp.mem0.ai/mcp) ----------------------
# One memory backend on purpose. The `mem0@mem0-plugins` Claude Code plugin is
# deliberately NOT installed: two mem0 backends split writes across two stores.
# MEM0_API_KEY comes from ~/.config/mise/conf.d/secrets.local.toml (never committed);
# skipped silently when the secret is not in the env (e.g. dev containers).
if command -v claude >/dev/null 2>&1 && [ -n "${MEM0_API_KEY:-}" ]; then
  claude mcp add -s user --transport http mem0-mcp https://mcp.mem0.ai/mcp \
    --header "Authorization: Bearer $MEM0_API_KEY" >/dev/null 2>&1 || true
fi

# --- graphify codebase knowledge graph (pipx:graphifyy, installed by mise) ---
# Registers the /graphify skill in ~/.claude/skills/graphify. The installer also
# appends a marker block to ~/.claude/CLAUDE.md; that block already lives in
# dot_claude/CLAUDE.md and the installer is idempotent, so it will not duplicate.
if command -v graphify >/dev/null 2>&1 && [ ! -f "$HOME/.claude/skills/graphify/SKILL.md" ]; then
  graphify install --platform claude >/dev/null 2>&1 || true
fi
