# Dotfiles (managed with [chezmoi](https://chezmoi.io))

Cross-platform dotfiles for macOS (Intel + Apple Silicon) and Linux. Editor/shell config is
identical everywhere; only the package list differs per machine via a `personal`/`work` profile.

## New machine

```sh
# 1. install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)"

# 2. one command: clone + prompt profile + apply + bootstrap
chezmoi init --apply bmransom
```

On first run it prompts for the machine **profile** (`personal` or `work`), then:
- installs Homebrew if missing (`run_once_before`)
- runs `brew bundle` for the shared + OS + profile layers (`run_onchange_after`)
- installs oh-my-zsh, tpm, and a default LTS node (`run_once_after`)
- applies all dotfiles

> Set your terminal font to a Nerd Font (e.g. **Hack Nerd Font Mono**) for editor icons.

## Daily use

```sh
chezmoi edit ~/.zshrc      # edit the source, then:
chezmoi apply              # regenerate the real file
# — or — edit ~/.zshrc directly, then:
chezmoi re-add             # pull the change back into the source

chezmoi cd                 # drop into the source repo (normal git)
git add -A && git commit && git push
chezmoi update             # pull + apply on another machine
```

## Layout

- `dot_*` → files in `$HOME` (e.g. `dot_zshrc` → `~/.zshrc`)
- `dot_homebrew/Brewfile{,.darwin,.personal,.work}` → layered packages; the bundle script installs
  shared + (darwin on macOS) + the machine's profile layer
- `run_*` → bootstrap scripts
- Git identity is directory-based via `~/.gitconfig` `includeIf` (personal default; work under `~/dev/lm/`)

The previous bare-repo version of this repo is archived on the **`bare-repo-archive`** branch.
