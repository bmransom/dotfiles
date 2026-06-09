#!/bin/sh
# oh-my-zsh
[ -d "$HOME/.oh-my-zsh" ] || RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
# tmux plugin manager
[ -d "$HOME/.tmux/plugins/tpm" ] || git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
# default LTS node via nvm (the TS/JS LSPs need node on PATH)
export NVM_DIR="$HOME/.nvm"
nvmsh="$(brew --prefix nvm 2>/dev/null)/nvm.sh"
[ -s "$nvmsh" ] && . "$nvmsh" && nvm install --lts >/dev/null 2>&1 || true
