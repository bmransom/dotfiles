# Setting up dotfiles

My dotfiles setup is based on the approach described here: https://www.atlassian.com/git/tutorials/dotfiles

To install my dotfiles on a new system, follow these steps:

1. Add alias to `.zshrc`: `alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'`
2. Ignore folder where dotfiles are stored to avoid weird recursion issues: `echo ".dotfiles" >> .gitignore`
3. Clone the repo: `git clone --bare git@github.com:branransom/dotfiles.git $HOME/.dotfiles`
4. Checkout the repo contents in `$HOME`: `dotfiles checkout`
5. Avoid showing untracked files: `dotfiles config --local status.showUntrackedFiles no`

## Installation

1. Install Homebrew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
2. Install plugins from Brewfile: `cd ~/.homebrew && brew bundle`
3. Install oh-my-zsh: `sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`
4. oh-my-zsh will overwrite the existing `.zshrc`, so make sure to replace the default config
