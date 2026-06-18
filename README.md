# Dotfiles

Cross-platform config for macOS (Intel and Apple Silicon) and Linux, managed with
[chezmoi](https://chezmoi.io). Editor and shell config stay identical across machines; only the
package list differs, set by a `personal` or `work` profile.

## Set up a new machine

```sh
sh -c "$(curl -fsLS get.chezmoi.io)"   # install chezmoi
chezmoi init --apply bmransom          # clone, prompt for profile, bootstrap, apply
```

The first run asks for the machine **profile** (`personal` or `work`), then:

- installs Homebrew if missing (`run_once_before`),
- runs `brew bundle` across the shared, OS, and profile layers (`run_onchange_after`),
- installs oh-my-zsh, tpm, and a default LTS Node (`run_once_after`),
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

Edit the source through `chezmoi edit`, never the deployed file. AI engineering skills are authored
in Foundry (`~/dev/workspace/foundry/plugins/foundry/skills`). This repo keeps only the local
installation glue: `run_onchange_after_40-agent-skills.sh.tmpl` runs the skill installer whenever
the glue or local Foundry skill checkout changes, exposing skills to harness-specific locations
such as `~/.agents/skills` and `~/.claude/skills`. Run `chezmoi status` to catch drift. To commit
and push every edit automatically, uncomment the `[git]` block in `.chezmoi.toml.tmpl`.

## Layout

- `dot_*` → files in `$HOME` (`dot_zshrc` → `~/.zshrc`).
- `dot_homebrew/Brewfile{,.darwin,.personal,.work}` → layered packages; the bundle script installs
  the shared layer, then darwin on macOS, then the machine's profile layer.
- `dot_agents/` → local agent-skill install/validation scripts. Foundry owns the AI skill bodies;
  Claude, Codex, and Pi support lives in `dot_agents/harnesses.toml`; harness-specific symlinks are
  generated automatically on apply by `run_onchange_after_40-agent-skills.sh.tmpl` or manually by
  `dot_agents/scripts/install-skills.sh`.
- `dot_claude/` → Claude Code config in `~/.claude`. Personal skills are not authored here; expose
  the generic skills with the installer. Runtime state (`projects/`, `plugins/`, caches) stays out
  of the repo via `.chezmoiignore`.
- `run_*` → bootstrap scripts.
- Git identity is directory-based through `~/.gitconfig` `includeIf`: personal by default, work
  under `~/dev/lm/`.

The earlier bare-repo version lives on the **`bare-repo-archive`** branch.
