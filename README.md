# dotfiles

Personal dotfiles, managed with [chezmoi](https://chezmoi.io). Source of truth: `~/git/dotfiles`.

## Bootstrap a new machine

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/bamaas/dotfiles/main/setup)"
```

Clones the repo, installs chezmoi, applies the configs, and installs [mise](https://mise.jdx.dev), which installs every other tool from `dot_config/mise/config.toml`.

## What's managed

| Area | Path |
|------|------|
| zsh | `dot_zshrc`, `dot_zshenv`, `dot_zprofile`, `dot_zshrc_user`, `dot_profile` |
| git | `dot_gitconfig`, `dot_gitignore_global` |
| nvim | `dot_config/nvim/` (NvChad; `lazy-lock.json` pins plugins) |
| k9s | `dot_config/k9s/` (config + skins) |
| mise | `dot_config/mise/config.toml` (the tool manifest) |
| zellij | `dot_config/zellij/` |
| Claude Code skills | `.chezmoiexternal.toml` — [mattpocock/skills](https://github.com/mattpocock/skills) into `~/.claude/skills/`, weekly refresh |

## Everyday workflow

```sh
cd ~/git/dotfiles      # edit files directly (dot_ = a leading dot in $HOME)
chezmoi diff           # preview
chezmoi apply          # write changes into $HOME
git add -A && git commit && git push
```

On another machine: `chezmoi update` (git pull + apply).

## Dev container (devpod)

`.devcontainer/` defines a Debian container that bakes the dotfiles, a lean
tool set (via mise), and Claude Code into the image at build time. Fast
startup, no registry — devpod builds and caches it locally.

```sh
devpod up github.com/bamaas/dotfiles      # this repo as a workspace
```

### Use it on any project

```sh
# A) dotfiles injection: keep the project's own devcontainer (or devpod's
#    default image), layer these dotfiles + tools on top
devpod up ${PWD} --dotfiles https://github.com/bamaas/dotfiles

# B) full baked image: copy this devcontainer into the project
cp -r ~/git/dotfiles/.devcontainer ${PWD}/ && devpod up ${PWD}
```

For B, the Dockerfile `COPY`s the build context as the chezmoi source — that
only works inside this repo. In other projects, replace the `COPY` line with:

```dockerfile
RUN git clone --depth=1 https://github.com/bamaas/dotfiles /home/vscode/git/dotfiles
```

### Claude Code on any project, one command

```sh
devpod up ${PWD} --dotfiles https://github.com/bamaas/dotfiles \
  --workspace-env CLAUDE_CODE_OAUTH_TOKEN="$CLAUDE_CODE_OAUTH_TOKEN" \
  && devpod ssh $(basename "$PWD") --command claude
```

### Container notes

- **Lean vs full tools:** containers get the lean set (node, neovim, ripgrep,
  fzf, bat, eza, zoxide, yq, lazygit, direnv, gh, zellij). The heavy set (go,
  python, terraform, k8s tooling) is macOS-only — see the `darwin` branch in
  `dot_config/mise/config.toml.tmpl`.
- **Claude Code auth:** the container reads `CLAUDE_CODE_OAUTH_TOKEN` from the
  host env. Generate it once with `claude setup-token`.
- **Docker:** the host socket is mounted and `docker-ce-cli` is baked in —
  `docker` works inside the container (socket group is fixed on start).
- **Secrets:** none in the image. Pass what's needed via `devpod up --env KEY=...`.

## Secrets

Public repo — no plaintext secrets. Machine-local secrets live in git- and
chezmoi-ignored files, recreated by hand per machine:

- `~/.zshrc.local` — sourced by `.zshrc` (e.g. Azure creds)
- `~/.config/mise/conf.d/secrets.local.toml` — merged into mise env (API keys)

If a secret ever needs to travel with the repo: `sops` + `age`.

## Notes

- **k9s** uses `K9S_CONFIG_DIR=$HOME/.config/k9s` (set in `.zshrc`) so the same
  path works on macOS and Linux.
- **nvim** plugin state and the base46 cache (`~/.local/share/nvim`) are
  regenerated on first launch — not tracked.
