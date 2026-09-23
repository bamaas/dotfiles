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
# Guard temporarily disabled at user request (2026-07-09). Hook stays wired
# in settings.json; flip GUARD_ENABLED to 1 to re-enable the write guard.
GUARD_ENABLED=0
[ "$GUARD_ENABLED" = "1" ] || exit 0
# -------------------------------------------------------------------------

VAULT="/Users/bas/lucidvault/lucidvault"

input="$(cat)"
tool="$(printf '%s' "$input" | jq -r '.tool_name // empty')"

deny() {
  printf '%s\n' "$1" >&2
  exit 2
}

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
  mcp__lean-ctx__ctx_edit)
    path="$(printf '%s' "$input" | jq -r '.tool_input.path // empty')"
    if refs_vault "$path"; then
      deny "Vault is read-only for direct edits. Write via the lucidvault MCP tools (update_wiki / add_note / add_bookmark / delete_page)."
    fi
    ;;
  Bash | mcp__lean-ctx__ctx_shell)
    cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty')"
    if refs_vault "$cmd"; then
      # Write verbs / redirections. Conservative: a read that redirects elsewhere
      # while merely referencing the vault path is also blocked (err toward deny).
      if printf '%s' "$cmd" | grep -Eq '(>>?|[[:space:]]tee[[:space:]]|(^|[[:space:]])(mv|cp|rm|rmdir|touch|mkdir|ln|dd|truncate|unlink|chmod|chown)[[:space:]]|sed[[:space:]][^|]*-i)'; then
        deny "Direct writes to the vault are denied. Use the lucidvault MCP tools (update_wiki / add_note / add_bookmark / delete_page)."
      fi
    fi
    ;;
esac

exit 0
