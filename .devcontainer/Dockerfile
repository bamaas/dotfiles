# Debian dev container that bakes the dotfiles + tools at build time.
# Startup is fast (everything is in the image); no registry required —
# devpod builds and caches this locally.
FROM mcr.microsoft.com/devcontainers/base:debian

# OS deps (base image already has git/curl/sudo and the `vscode` user)
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
 && apt-get install -y --no-install-recommends zsh unzip ca-certificates \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# Marks this as a container build -> chezmoi renders the lean mise tool set.
ENV DEVCONTAINER=1

# make zsh the login shell for the non-root user
RUN chsh -s /usr/bin/zsh vscode

USER vscode
ENV HOME=/home/vscode
WORKDIR /home/vscode
ENV PATH=/home/vscode/.local/bin:/home/vscode/.local/share/mise/shims:$PATH

# Repo becomes chezmoi's source of truth inside the container.
COPY --chown=vscode:vscode . /home/vscode/git/dotfiles

# 1) chezmoi  2) mise  (chezmoi must exist before mise on real machines; mirror that here)
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" \
 && curl -fsSL https://mise.run | sh

# Apply dotfiles: renders lean mise config (Linux), then the run_once script
# installs the tool set via mise.
RUN chezmoi init --source="$HOME/git/dotfiles" --apply

# Claude Code (needs node, now installed by mise)
RUN mise exec node -- npm install -g @anthropic-ai/claude-code

ENV SHELL=/usr/bin/zsh
