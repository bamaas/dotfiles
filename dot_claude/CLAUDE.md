<!-- @RTK.md -->

<!-- lucidvault:start -->
 ## My personal knowledge vault
When I ask about my own notes, bookmarks, or saved articles (or say "vault"), read it directly from `/Users/bas/lucidvault/lucidvault/` — start with that folder's `AGENTS.md` and follow it (source of truth for how to search and cite). 
Search broadly: expand the query with adjacent terms, then do a second pass following [[wikilinks]] and shared tags before concluding. For any web search, use the Tavily MCP tools (tavily-search / tavily-extract), not the built-in WebSearch.
<!-- lucidvault:end -->

## Web research

Use these tools according to intent:

### Reading a provided URL
When the user provides a URL and asks about its contents:
- Fetch it first with:
  curl -s "https://r.jina.ai/<URL>"
- Use the returned Markdown as the source.
- Do not use Tavily for URLs the user already provided unless Jina fails.

### Web search
When the user asks to find, research, compare, or discover information:
- Use Tavily search.
- Prefer Tavily over general web browsing.

### Multiple sources
For research tasks requiring multiple sources:
- Use Tavily to discover relevant URLs.
- Use Jina to extract the content of those URLs.

## How I want you to work

- Keep answers short and to the point.
- Prefer concrete examples over abstract theory.
- If something is not clear, keep asking me until you have no questions left.
- You decide the needed effort level for subagents.
- When a decision needs to be made, present the options one by one, and state your weight/preference for each option.

## Verification 
- Don't weaken, skip, or delete tests to make them pass.
- Never claim something works without having run it. Clearly separate "verified" from "unverified."
- Before saying "done": run the project's typecheck, lint, and relevant tests (find the commands in the project CLAUDE.md, package.json, Makefile, etc.).

## Anti-slop
- No comments restating the code. Comment only non-obvious "why."
- No placeholder code, stubs, fake data, or TODOs presented as finished work.

## Simplicity
- Prefer boring, obvious code over clever code. A junior should understand it at a glance.

## Autonomy
- Commit in small logical steps (if in a git repo) with conventional commit messages. Never force-push or rewrite shared history.

## Final report
- 3–5 lines: what changed, what was verified, open risks or assumptions.


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
