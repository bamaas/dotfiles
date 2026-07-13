#!/bin/sh
# Pre-seed Claude Code config in containers so it doesn't prompt for onboarding /
# theme on first launch. Works on BOTH the baked-image path and the --dotfiles
# path (both run `chezmoi apply` inside the container). Containers only — never
# touches a real machine's ~/.claude (guarded by DEVCONTAINER / /.dockerenv).
set -eu

if [ -z "${DEVCONTAINER:-}" ] && [ ! -f /.dockerenv ]; then exit 0; fi

mkdir -p "$HOME/.claude"
# theme (only if not already set)
[ -f "$HOME/.claude/settings.json" ] || printf '{\n  "theme": "dark"\n}\n' > "$HOME/.claude/settings.json"
# onboarding flag (only if missing / not already accepted)
if ! grep -q hasCompletedOnboarding "$HOME/.claude.json" 2>/dev/null; then
  printf '{\n  "hasCompletedOnboarding": true\n}\n' > "$HOME/.claude.json"
fi

# mise shims (node / lean-ctx / claude / yq) must be resolvable here. Script 10
# already ran `mise install`, so the shims exist by now.
export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"

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
