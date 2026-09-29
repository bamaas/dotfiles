<!-- lucidvault:start -->
## Web research

The vault (`~/lucidvault/lucidvault/`) and the web are two ways in, not a ranking —
blend them as the question warrants. Vault rules live in its `AGENTS.md`: read that
first, it is the source of truth and auto-generated, so never copy it here. Not
present on this machine → say so, don't guess.

Web: Tavily MCP, never the built-in WebSearch. A URL I hand you →
`curl -s "https://r.jina.ai/<URL>"` first, Tavily only if Jina fails.
<!-- lucidvault:end -->

## Context store routing

Four stores. Pick one per question; never search two for the same thing.

| Question | Store | How |
|---|---|---|
| Where is X / what calls Y / current code structure | the code | `ctx_search`, `ctx_compose` |
| Architecture, multi-hop call paths, code+docs+SQL in one view | graphify | `/graphify query "..."` |
| Why we chose X / rejected Y / my preferences / past gotcha | mem0 | `mcp__mem0-mcp__search_memories` |
| My notes, bookmarks, saved articles, research | lucidvault | read the vault directly |

- Search mem0 before answering or acting. Don't repeat a mistake it records; don't
  make me re-explain a decision.
- mem0 holds only: decisions + why, rejected options, env quirks, my preferences,
  mistakes with their cause. Store a mistake the moment it costs real time.
- Never store in mem0 anything re-derivable from a repo (paths, signatures,
  structure, past fixes). Code moves; mem0 does not notice.
- On conflict about current code: the code wins over graphify's index, which wins
  over mem0. Rebuild the graphify index after a large refactor.
- mem0 = `mem0-mcp` (hosted HTTP) only. The `mem0@mem0-plugins` plugin is
  deliberately not installed — two backends split writes across two stores.

## Changing my system

My machine config lives in `~/git/dotfiles`. Anything written straight into `$HOME`
gets overwritten from there, so any change meant to survive goes through that repo —
read its `AGENTS.md` first.

## How I want you to work

- Lead with the answer, in 4 lines of prose or fewer. Tables, diffs and commands
  don't count. No preamble, no restating my question, no closing summary. Longer
  only when I ask — if you think I need more, offer it in one line.
- Report what happened in one line, not what you are about to do. Evidence only if
  I ask or if it changes my decision.
- Prefer concrete examples over abstract theory.
- If something is not clear, keep asking me until you have no questions left.
- Decisions: present the options one by one, with your weight on each.
- You decide the effort level for subagents.

## Verification

- Don't weaken, skip, or delete tests to make them pass.
- Never claim something works without having run it. Separate "verified" from
  "unverified" explicitly.
- Before saying "done": run the project's typecheck, lint, and relevant tests (find
  the commands in the project CLAUDE.md, package.json, Makefile, etc.).

## Code

- Boring and obvious over clever. A junior should understand it at a glance.
- Stop at the first level that applies: skip (YAGNI) → reuse codebase → stdlib →
  native platform → installed dep → one-line → minimum code. Never skip validation,
  security, or error handling.
- No comments restating the code. Comment only non-obvious "why."
- No placeholder code, stubs, fake data, or TODOs presented as finished work.
- Commit in small logical steps with conventional commit messages. Never force-push
  or rewrite shared history.

<!-- lean-ctx -->
<!-- lean-ctx-claude-v9 -->
## lean-ctx

The MCP server states its own `ctx_*` mapping — not repeated here. Two things it
leaves out: native `Read` is for the edit gate only (`ctx_read(mode="anchored")` →
`ctx_patch` to edit), and Claude's file memory under `~/.claude/projects/<slug>/`
uses native Read/Edit — never `resources/read` with a `file://` URI.
<!-- /lean-ctx -->
