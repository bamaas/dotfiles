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
