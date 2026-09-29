#!/bin/sh
# ~/.claude/CLAUDE.md is loaded in full at the start of every session, in every
# project, so its size is a per-session tax. Nothing else in this repo evicts from
# it: sections only ever get appended, by me or by an installer.
#
# Hard ceiling, checked on every apply (no run_once — the point is that it keeps
# holding). Over the limit means move the content to where it is paid for on
# demand: a skill, a repo's own AGENTS.md, or mem0.
set -eu

# 80 lines today, so this leaves ~10 for deliberate growth and no more.
MAX_LINES=90
SRC="${CHEZMOI_SOURCE_DIR:-}/dot_claude/CLAUDE.md"

[ -f "$SRC" ] || exit 0

lines=$(wc -l < "$SRC" | tr -d ' ')
if [ "$lines" -gt "$MAX_LINES" ]; then
  echo "dot_claude/CLAUDE.md is $lines lines, over the $MAX_LINES-line ceiling." >&2
  echo "Cut it, or raise MAX_LINES in $0 on purpose." >&2
  exit 1
fi
