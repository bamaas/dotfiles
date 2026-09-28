#!/usr/bin/env bash
# vault-write-guard — PreToolUse hook.
# Blocks WRITE actions against the LucidVault vault so all mutations are forced
# through the lucidvault MCP server (add_note/add_bookmark/update_wiki/delete_page).
# Reads are left untouched (native-first retrieval, ADR-023).
#
# Covers the holes that path-scoped permission deny rules cannot:
#   - Bash write commands / redirections targeting the vault
#   - lean-ctx ctx_shell (same, post-rewrite)
#   - lean-ctx ctx_edit (always a write; matched by path arg)
# Native Edit/Write/MultiEdit/NotebookEdit are already denied via settings.json.
#
# Exit 2 = block the tool call and surface the reason to the model.
set -euo pipefail

# --- KILL SWITCH ---------------------------------------------------------
GUARD_ENABLED=1
[ "$GUARD_ENABLED" = "1" ] || exit 0
# -------------------------------------------------------------------------

VAULT="$HOME/lucidvault/lucidvault"
# No vault on this machine (dev containers; the VM before sync is up) -> no-op.
[ -d "$VAULT" ] || exit 0

deny() {
  printf '%s\n' "$1" >&2
  exit 2
}

# Without jq the guard cannot inspect the payload. Exit 2 (block) rather than
# letting `set -e` exit 127, which Claude Code treats as NON-blocking -- i.e.
# the vault write would be allowed while the hook still looks wired.
command -v jq >/dev/null 2>&1 || \
  deny "vault-write-guard: jq unavailable; refusing to allow an unchecked vault write."

input="$(cat)"
tool="$(printf '%s' "$input" | jq -r '.tool_name // empty')" \
  || deny "vault-write-guard: unparseable hook payload; refusing to allow an unchecked vault write."
[ -n "$tool" ] \
  || deny "vault-write-guard: hook payload has no tool_name; refusing to allow an unchecked vault write."

refs_vault() {
  case "$1" in
    *"$VAULT"*) return 0 ;;
    *"~/lucidvault/lucidvault"*) return 0 ;;
    *'$HOME/lucidvault/lucidvault'*) return 0 ;;
    *'${HOME}/lucidvault/lucidvault'*) return 0 ;;
  esac
  return 1
}

case "$tool" in
  mcp__lean-ctx__ctx_edit | mcp__lean-ctx__ctx_patch)
    path="$(printf '%s' "$input" | jq -r '.tool_input.path // empty')"
    if refs_vault "$path"; then
      deny "Vault is read-only for direct edits. Write via the lucidvault MCP tools (update_wiki / add_note / add_bookmark / delete_page)."
    fi
    ;;
  Bash | mcp__lean-ctx__ctx_shell | mcp__lean-ctx__shell)
    cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty')"
    if refs_vault "$cmd"; then
      # Discarding or duplicating a descriptor is not a write, but the bare `>`
      # in `2>/dev/null` / `2>&1` looked like one and denied plain reads. Strip
      # exactly those forms first; a real target (`2> vault/err.log`) survives.
      # The /dev/null strip must fire wherever the redirection ends -- before any
      # shell metacharacter (`;` `)` `|` `&` `}` backtick), whitespace, or EOL --
      # otherwise `... 2>/dev/null; echo x` keeps a bare `>` and denies a read.
      probe="$(printf '%s' "$cmd" | sed -E \
        -e 's@[0-9]+>[[:space:]]*/dev/null([[:space:];)|&}`]|$)@\1@g' \
        -e 's/[0-9]*>&[0-9]+//g' \
        -e 's/[0-9]*>&-//g')"
      # Write verbs / redirections. Conservative: a read that redirects elsewhere
      # while merely referencing the vault path is also blocked (err toward deny).
      if printf '%s' "$probe" | grep -Eq '(>>?|(^|[[:space:]])(tee|mv|cp|rm|rmdir|touch|mkdir|ln|dd|truncate|unlink|chmod|chown)[[:space:]]|sed[[:space:]][^|]*-i)'; then
        deny "Direct writes to the vault are denied. Use the lucidvault MCP tools (update_wiki / add_note / add_bookmark / delete_page)."
      fi
    fi
    ;;
esac

exit 0
