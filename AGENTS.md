# dotfiles

chezmoi source for this machine's config. Every file here is applied into `$HOME`,
so **nothing written straight into `$HOME` survives** — the next `chezmoi apply`
overwrites it.

## Layout

| Source | Target |
|---|---|
| `dot_claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `dot_claude/private_settings.json.tmpl` | `~/.claude/settings.json` (mode 600) |
| `dot_claude/hooks/executable_*` | `~/.claude/hooks/*` |
| `dot_config/...` | `~/.config/...` |
| `dot_config/mise/config.toml.tmpl` | `~/.config/mise/config.toml` (all tool installs) |
| `.chezmoiscripts/run_once_after_*` | not applied — run after files, in name order |
| `.chezmoiexternal.toml` | third-party skills/plugins cloned into `$HOME` |

A file at the source root (`README.md`, this file) maps to `$HOME/<name>`, so every
repo-meta file must be listed in `.chezmoiignore`.

## Workflow

1. Edit the source here, never the target in `$HOME`.
2. `chezmoi apply` — add `--force <target>` when the target drifted on purpose.
3. `chezmoi status` must come back empty (a `R` line just means a script will re-run).
4. Commit. Conventional commits, small steps.

Tools go in `dot_config/mise/config.toml.tmpl`. Claude Code wiring (MCP servers,
plugins, skills, hooks) goes in `.chezmoiscripts/run_once_after_40-claude-config.sh`.

## Secrets

Never commit one. Machine-local secrets live in
`~/.config/mise/conf.d/secrets.local.toml` (chezmoi- and git-ignored); scripts read
them from the env, e.g. `MEM0_API_KEY`.

Claude Code settings are split for this reason: portable keys in
`dot_claude/private_settings.json.tmpl`, machine-local ones (`mcpServers`, anything
with a key in it) in `~/.claude/settings.local.json`, which Claude Code merges on top
and chezmoi ignores. Never move an MCP server with a key in its URL into the tracked
half.

## Gotchas that have already bitten

- **Installers write into managed files.** `graphify install` appends to
  `~/.claude/CLAUDE.md`; `lean-ctx init` rewrites hooks in `~/.claude/settings.json`
  and relocates its block in `~/.zshrc`. After running one, copy the change back into
  the source or the next apply reverts it.
- **Scripts here re-run on every content change**, so each block guards on its own
  result (`statusLine` present, plugin already in `installed_plugins.json`, skill dir
  exists). Without the guards an apply took minutes and left the target dirty.
- **`claude mcp add` argument order:** `-e` is variadic, so the server name comes
  first and the command after `--`. Wrong order fails with
  `error: missing required argument 'name'`, which `|| true` then hides.
- **Plugin cache dirs are not versioned by mtime.** Read `installPath` from
  `~/.claude/plugins/installed_plugins.json`; the newest directory is often not the
  installed one.
- **lean-ctx rewrites its own three hook entries** in `~/.claude/settings.json` to its
  resolved binary path whenever the server starts. The tracked copy matches what it
  writes; after a lean-ctx version bump, hand-edit those three `command` strings in
  `dot_claude/private_settings.json.tmpl`. Do **not** `chezmoi add
  ~/.claude/settings.json` any more: the source is a template and `add` would
  overwrite it with the rendered target, silently flattening the OS conditionals
  (on Linux that also means permanently losing the 34 macOS-only deny rules).
- **`~/.claude/settings.json` is OS-conditional.** Its deny list drops 34 local-only
  rules (`sudo`, `systemctl`, `brew`, `dd`, the `Read(**/.ssh/*)` family …) on Linux,
  because a deny always beats an allow so the entry has to be absent, not overridden.
  What survives everywhere reaches past the machine or is policy: `kubectl`/`helm`
  mutations, force-push, `Grep`/`Glob` (lean-ctx forces `ctx_*`), and
  `Edit(~/lucidvault/lucidvault/**)`. JSON has no trailing commas, so the invariant
  is: every deny entry ends with a comma except the final `"Glob"`, and that last
  one sits outside any conditional. Adding an entry at the end of a guarded block is
  fine; making a guarded block the *last* thing in the array is not. Verify both
  branches before committing — `chezmoi execute-template < the .tmpl | jq empty`
  locally for macOS and `ssh devbox chezmoi execute-template < the .tmpl | jq empty`
  for Linux (`.chezmoi.os` comes from the running machine, so one host cannot render
  both).
- **Hook commands** use `$HOME` and the mise shims
  (`~/.local/share/mise/shims/<tool>`), never a versioned install path.
- **Never let the shims dir precede `~/.local/bin` on PATH**, and never install
  `mise` as a mise tool (`aqua:jdx/mise`). mise points every shim it writes at
  whatever `mise` resolves to on PATH. With a `mise` shim present and a
  shims-first PATH, one `mise reshim` aims all ~250 shims at `shims/mise`, which
  then points at itself — `too many levels of symbolic links` for every tool.
  Recover with `PATH=~/.local/bin:$PATH ~/.local/bin/mise reshim --force`.
