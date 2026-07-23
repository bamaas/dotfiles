<!-- @RTK.md -->

<!-- lean-ctx -->
<!-- lean-ctx-claude-v2 -->
## lean-ctx — Context Runtime

Always prefer lean-ctx MCP tools over native equivalents:
- `ctx_read` instead of `Read` / `cat` (cached, 10 modes, re-reads ~13 tokens)
- `ctx_shell` instead of `bash` / `Shell` (95+ compression patterns)
- `ctx_search` instead of `Grep` / `rg` (compact results)
- `ctx_tree` instead of `ls` / `find` (compact directory maps)
- Native Edit/StrReplace stay unchanged. If Edit requires Read and Read is unavailable, use `ctx_edit(path, old_string, new_string)` instead.
- Write, Delete, Glob — use normally.

Full rules: @rules/lean-ctx.md

Verify setup: run `/mcp` to check lean-ctx is connected, `/memory` to confirm this file loaded.
<!-- /lean-ctx -->

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
