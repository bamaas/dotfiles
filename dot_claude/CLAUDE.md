<!-- lucidvault:start -->
## My personal knowledge vault

When I ask about my own notes, bookmarks, or saved articles (or say "vault"), read it
directly from `~/lucidvault/lucidvault/` — start with that folder's `AGENTS.md` and
follow it (source of truth for how to search and cite).
If that directory does not exist, the vault is not present on this machine: say so
rather than guessing. The `lucidvault` MCP server can still help with discovery via
`related_notes` and `expand_graph`.
<!-- lucidvault:end -->

## Web research

Use these tools according to intent.

### Reading a provided URL

- Fetch it first with `curl -s "https://r.jina.ai/<URL>"`.
- Use the returned Markdown as the source.
- Do not use Tavily for URLs I already provided unless Jina fails.

### Web search

Any substantive or factual question runs two lanes in parallel:

1. **Vault** — retrieval strategy lives in `~/lucidvault/lucidvault/AGENTS.md`;
   follow it. No hit → say "nothing in your vault covers this" before answering
   from the web.
2. **Web** — Tavily MCP (`tavily-search` / `tavily-extract`), never the built-in
   WebSearch. Search, then Jina extract. Prefer Tavily over general browsing.

Neither lane leads by default — weigh them per question, and say which parts came
from where. Cite each lane separately; a vault answer must carry the page's
`source:` URL verbatim. Flag a vault page as possibly stale when the web has
something newer than its `last_updated`.

### Multiple sources

Tavily to discover the URLs, Jina to extract each one.

## Where knowledge goes

Three layers. Route by what a fact **binds**, not by how important it is.

| Binds | Goes in | Why |
|---|---|---|
| The repo / anyone who touches it | `docs/adr/NNN-*.md`, git-versioned | survives me leaving; reviewable in PR; tool-agnostic |
| Every agent, every session, unconditionally | `AGENTS.md` (+ thin `CLAUDE.md`) | loaded every turn — so invariants only |
| Only me | mem0 | my taste, my mistakes, cross-repo habits |

ADRs are the system of record; `AGENTS.md` / `CLAUDE.md` are a delivery format. Write
a decision once in `docs/adr/`, link to it from the agent file — four copies across
README, wiki, `CLAUDE.md` and `AGENTS.md` disagree within months.

Test any fact, in order:

1. Would a teammate be annoyed not to know this? → ADR.
2. Must it be obeyed on every single task? → `AGENTS.md`.
3. Is it about me? → mem0.
4. Can `ctx_search` re-derive it from the code? → nowhere.

In a repo I own: `AGENTS.md` at the root, `CLAUDE.md` = `@AGENTS.md` plus Claude-only
bits (teammates on Cursor or Copilot read `AGENTS.md` too). `docs/adr/` holds "why X,
rejected Y" — format: Context / Decision / Rejected / Verify-with, where Verify-with
is a grep, lint rule or command. An ADR nobody checks is a comment.

## Context store routing

Where to look, per question. Pick one; never search two for the same thing.

| Question | Store | How |
|---|---|---|
| Where is X / current code structure | the code | `ctx_search`, `ctx_compose` |
| What calls Y / what breaks if I change Y | the code | `ctx_callgraph` |
| Architecture, multi-hop paths, code+docs+SQL in one view | graphify | `/graphify query "..."` — only where `graphify-out/` exists and is current |
| Why this repo does X / what it rejected | `docs/adr/` | read it; git history for the rest |
| My preferences / my past gotcha / a decision only I hold | mem0 | `mcp__mem0-mcp__search_memories` |
| My notes, bookmarks, saved articles, research | lucidvault | read the vault directly |

- Search mem0 before answering or acting. Don't repeat a mistake it records; don't
  make me re-explain a decision.
- mem0 holds only what binds me: my preferences, env quirks, mistakes with their
  cause, decisions nobody else needs. Store a mistake the moment it costs real time.
  A decision that binds a repo goes in that repo's `docs/adr/`; mem0 keeps a pointer
  ("auth queue → ADR-0012"), never the only copy.
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
## lean-ctx — Replace Mode (native Grep/Glob denied by policy)

Native Grep/Glob are denied by policy. Prefer `ctx_*` MCP tools for project work:
- `ctx_read` for exploration reads (cached, 10 modes, unchanged full/auto re-reads ~13 tokens)
- `ctx_shell` for shell commands (95+ compression patterns)
- `ctx_search` instead of Grep/rg (compact results)
- `ctx_tree` instead of ls/find (compact directory maps)
- `ctx_glob` instead of Glob (file pattern matching)
- Project edits: `ctx_read(mode="anchored")` → `ctx_patch` (line+hash anchors; `op=create` for new files).

Native `Read` is reserved for the edit gate (read-before-write) only.
For exploration, orientation, and code understanding: ALWAYS use `ctx_read`.
Claude auto memory (`~/.claude/projects/<slug>/memory/` — MEMORY.md and topic
files) uses native Read/Edit internally; do NOT call MCP `resources/read` with
file:// URIs (lean-ctx resources are `lean-ctx://context/*` only). Native Delete is fine.

Read modes: anchored (edit), full (verbatim), map (overview), signatures (API), diff (post-edit), lines:N-M (range), auto.
Details live in the `lean-ctx` skill (loads on demand — keep this file lean).
<!-- /lean-ctx -->

<!-- lean-ctx-solution -->
SOLUTION EFFICIENCY: stop at first level that applies:
skip (YAGNI) → reuse codebase → stdlib → native platform → installed dep → one-line → minimum code.
Never skip: validation, security, error handling.
<!-- /lean-ctx-solution -->
