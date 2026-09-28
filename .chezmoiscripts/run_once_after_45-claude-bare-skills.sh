#!/bin/sh
# Bare-name Claude Code skills sourced from the installed dx@ykdojo plugin.
#
# `handoff` and `reddit-fetch` ship in the dx@ykdojo plugin
# (github.com/ykdojo/claude-code-tips) and are already reachable as /dx:handoff
# and /dx:reddit-fetch. This materialises them under ~/.claude/skills/ too, so
# the bare /handoff and /reddit-fetch names work as well.
#
# Copied from the installed plugin, never vendored: that plugin is
# "All Rights Reserved", so its files must not be redistributed in this public
# repo. Same reasoning as the caveman hooks in script 40.
#
# Separate from run_once_after_40-claude-config.sh on purpose: 40 is
# hash-recorded, so folding two `cp`s into it would re-run its whole body —
# plugin installs, `lean-ctx init`, the settings.json save/restore dance — on
# every machine, for no gain.
set -eu

# mise shims must be resolvable: `claude` comes from there. Same PATH order as
# script 40 (~/.local/bin ahead of the shims, see the note there).
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

MARKETPLACE="$HOME/.claude/plugins/marketplaces/ykdojo/skills"

# settings.json already lists ykdojo in extraKnownMarketplaces and sets
# enabledPlugins["dx@ykdojo"], but Claude only clones the marketplace on its
# first launch — which has not happened yet when chezmoi runs on a fresh
# machine. This script is run_once_, so a no-op now is permanent; install the
# marketplace here instead, guarded so it costs nothing once registered.
if command -v claude >/dev/null 2>&1 \
   && ! grep -q '"dx@ykdojo"' "$HOME/.claude/plugins/installed_plugins.json" 2>/dev/null; then
  claude plugin marketplace add ykdojo/claude-code-tips >/dev/null 2>&1 || true
  claude plugin install dx@ykdojo -s user >/dev/null 2>&1 || true
fi

# Create-only, never overwrite. An existing directory is either an identical
# copy of the plugin file (nothing to do) or a hand-edited one — and a hand edit
# is the only reason it would differ, so it wins. That also makes re-runs a
# no-op. Missing plugin is not an error: the /dx:-prefixed skills still work.
for skill in handoff reddit-fetch; do
  src="$MARKETPLACE/$skill/SKILL.md"
  dst="$HOME/.claude/skills/$skill"
  if [ -f "$src" ] && [ ! -e "$dst" ]; then
    mkdir -p "$dst"
    cp "$src" "$dst/SKILL.md"
  fi
done
