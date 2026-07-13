# dotfiles

Personal dotfiles, managed with [chezmoi](https://chezmoi.io). Source of truth lives at `~/git/dotfiles`.

## Bootstrap a new machine

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/bamaas/dotfiles/main/setup)"
```

This clones the repo, installs chezmoi, then `chezmoi apply` places the configs and installs [mise](https://mise.jdx.dev), which installs every other tool from `dot_config/mise/config.toml`.

## What's managed

| Area | Path |
|------|------|
| zsh | `dot_zshrc`, `dot_zshenv`, `dot_zprofile`, `dot_zshrc_user`, `dot_profile` |
| git | `dot_gitconfig`, `dot_gitignore_global` |
| nvim | `dot_config/nvim/` (NvChad; `lazy-lock.json` pins plugins) |
| k9s | `dot_config/k9s/` (config + skins) |
| mise | `dot_config/mise/config.toml` (the tool manifest) |
| zellij | `dot_config/zellij/` |
| Claude Code skills | `.chezmoiexternal.toml` (pulled from [mattpocock/skills](https://github.com/mattpocock/skills) into `~/.claude/skills/`, weekly refresh) |

## Everyday workflow

```sh
cd ~/git/dotfiles      # edit files directly (dot_ = a leading dot in $HOME)
chezmoi diff           # preview
chezmoi apply          # write changes into $HOME
git add -A && git commit && git push
```

Pull changes on another machine: `chezmoi update` (git pull + apply).

## Notes

- **k9s** uses `K9S_CONFIG_DIR=$HOME/.config/k9s` (set in `.zshrc`) so the same path works on macOS and Linux.
- **nvim** plugin state and the base46 cache live under `~/.local/share/nvim` and are regenerated on first launch — not tracked.

## Dev container (devpod)

A Debian dev container is defined in `.devcontainer/`. The `Dockerfile` bakes the
dotfiles + a **lean** tool set (via mise) + Claude Code at build time, so startup is
fast and no registry is needed — devpod builds and caches it locally.

```sh
devpod up github.com/bamaas/dotfiles      # spin up this repo as a workspace
```

### Use it on any project

Two ways to bring this environment to another repo:

```sh
# A) dotfiles injection: keep the project's own devcontainer (or devpod's
#    default image) and layer these dotfiles + tools on top
devpod up github.com/you/your-project --dotfiles https://github.com/bamaas/dotfiles

# B) full environment: copy this devcontainer into the project, then up it
cp -r ~/git/dotfiles/.devcontainer ~/git/your-project/
devpod up ~/git/your-project
```

A is zero-setup and works with any repo. B gives the complete baked image
(docker socket, Claude Code auth, lean mise tool set) — but the Dockerfile
`COPY`s the build context as the chezmoi source, which only works in this repo.
For other projects replace that `COPY` line with:

```dockerfile
RUN git clone --depth=1 https://github.com/bamaas/dotfiles /home/vscode/git/dotfiles
```

- **Lean vs full tools:** the container installs only the lean set (node, neovim,
  ripgrep, fzf, bat, eza, zoxide, yq, lazygit, direnv, gh, zellij). The heavy set
  (go, python, terraform, k8s tooling) is macOS-only — see the `{{ if eq .chezmoi.os "darwin" }}`
  branch in `dot_config/mise/config.toml.tmpl`.
- **Claude Code auth:** the container reads `CLAUDE_CODE_OAUTH_TOKEN` from the host
  env at up-time (generate once with `claude setup-token`, export it in `~/.zshrc.local`).
- **Docker:** the host docker socket is mounted and `docker-ce-cli` is baked in, so
  `docker` works inside the container (socket group is fixed on start).
- **Secrets:** the container has **no** secrets (they live in git-ignored local files
  that never enter the image). Pass any needed secret via `devpod up --env KEY=...`.

## Secrets

This is a **public** repo — no plaintext secrets. Machine-local secrets live in files that are **git- and chezmoi-ignored**, never committed:

- `~/.zshrc.local` — sourced by `.zshrc` (e.g. Azure creds)
- `~/.config/mise/conf.d/secrets.local.toml` — merged into mise env (API keys)

Recreate these by hand on each machine. If a real secret ever needs to travel with the repo, encrypt it with `sops` + `age`.
