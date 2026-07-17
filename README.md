# Dotfiles

Cross-platform config for macOS (Intel and Apple Silicon) and Linux, managed with
[chezmoi](https://chezmoi.io). Editor and shell config stay identical across machines; only the
package list differs, set by a `personal` or `work` profile.

## Set up a new machine

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply bmransom
```

The first run asks for the machine **profile** (`personal` or `work`), then:

- installs Homebrew if missing (`run_once_before`),
- runs `brew bundle` across the shared, OS, and profile layers (`run_onchange_after`),
- installs tpm (`run_once_after`),
- clones third-party zsh plugins declared in `.chezmoiexternal.toml`,
- applies every dotfile.

Set the terminal font to a Nerd Font (for example **Hack Nerd Font Mono**) so editor icons render.

## Edit and sync

Edits apply to your home directory on save, because `edit.apply = true`:

```sh
chezmoi edit ~/.zshrc          # opens the source; applies on quit
chezmoi edit --watch ~/.zshrc  # applies on every save, useful while iterating
chezmoi cd                     # enter the source repo; commit and push as usual
chezmoi update                 # pull and apply on another machine
```

Edit the source through `chezmoi edit`, never the deployed file. Run `chezmoi status` to catch
drift. To commit and push every edit automatically, uncomment the `[git]` block in
`.chezmoi.toml.tmpl`.

## Layout

- `dot_*` → files in `$HOME` (`dot_zshrc` → `~/.zshrc`).
- `dot_homebrew/Brewfile{,.darwin,.personal,.work}` → layered packages; the bundle script installs
  the shared layer, then darwin on macOS, then the machine's profile layer.
- `run_*` → bootstrap scripts.
- Git identity is profile-based: the `personal` profile defaults every repo under `~/` to the
  personal identity; the `work` profile ships none. Both profiles include untracked
  `~/.gitconfig-local` (if present) for machine-local identity and overrides.

## Work machines

This repo is public; work machines consume it **read-only**:

- Bootstrap clones anonymously over HTTPS. Never `gh auth login`, store GitHub credentials, or
  push from a work machine — edit on a personal machine, then `chezmoi update` at work.
- Set work identity locally, outside the repo:

  ```ini
  # ~/.gitconfig-local
  [user]
    name = Brandon Ransom
    email = <work email>
  ```

- Work-specific shell config goes in untracked `~/.zshrc.local` (sourced by `~/.zshrc` when
  present), and work-specific aliases in untracked `~/.aliases_local`. If work lines were added
  directly to `~/.zshrc`, move them out first — or run `chezmoi merge ~/.zshrc` to reconcile;
  `chezmoi apply` prompts before overwriting a file modified outside chezmoi.
- The `work` profile skips GitHub tooling (`gh`, the credential helpers, `.gitconfig-personal`),
  the `tldr` (cht.sh) alias, and Maccy.

The earlier bare-repo version lives on the **`bare-repo-archive`** branch.
