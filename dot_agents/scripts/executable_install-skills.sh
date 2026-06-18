#!/usr/bin/env bash
# install-skills.sh - expose Foundry-owned Agent Skills to supported harnesses.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SOURCE_SKILLS_DIR="${AGENT_SOURCE_SKILLS_DIR:-${FOUNDRY_SKILLS_DIR:-$HOME/dev/workspace/foundry/plugins/foundry/skills}}"
TARGET_SKILLS_DIR="${AGENT_TARGET_SKILLS_DIR:-${AGENT_SKILLS_DIR:-$HOME/.agents/skills}}"
BACKUP_EXISTING="${AGENT_BACKUP_EXISTING:-1}"
STALE_SKILLS="${AGENT_STALE_SKILLS:-reference-gap-profiling performance-comparison}"
DRY_RUN=0
HARNESS="all"

usage() {
  cat <<'USAGE'
Usage: install-skills.sh [--dry-run] [--harness claude|codex|pi|all]

Installs Foundry-owned Agent Skills into harness-visible locations.
Codex and Pi receive symlinks in ~/.agents/skills. Claude receives symlinks in ~/.claude/skills.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --harness) HARNESS="${2:?--harness requires a value}"; shift 2 ;;
    --harness=*) HARNESS="${1#--harness=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "install-skills: unknown argument '$1'" >&2; usage >&2; exit 2 ;;
  esac
done

case "$HARNESS" in
  claude|codex|pi|all) ;;
  *) echo "install-skills: unsupported harness '$HARNESS'" >&2; exit 2 ;;
esac

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf 'DRY-RUN: %s\n' "$*"
  else
    "$@"
  fi
}

list_skills() {
  find "$SOURCE_SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -print | sort
}

backup_path() {
  local target="$1"
  local stamp
  stamp="$(date +%Y%m%d%H%M%S)"
  printf '%s.backup-%s' "$target" "$stamp"
}

replace_with_link() {
  local source="$1" target="$2" backup
  if [ -L "$target" ]; then
    printf 'link: %s -> %s\n' "$target" "$source"
    run ln -sfn "$source" "$target"
  elif [ -e "$target" ]; then
    if [ "$BACKUP_EXISTING" -eq 1 ]; then
      backup="$(backup_path "$target")"
      printf 'backup: %s -> %s\n' "$target" "$backup"
      run mv "$target" "$backup"
      printf 'link: %s -> %s\n' "$target" "$source"
      run ln -s "$source" "$target"
    else
      printf 'skip: %s exists and is not a symlink\n' "$target"
    fi
  else
    printf 'link: %s -> %s\n' "$target" "$source"
    run ln -s "$source" "$target"
  fi
}

prune_stale() {
  local target_root="$1" name target backup
  for name in $STALE_SKILLS; do
    target="$target_root/$name"
    [ -e "$target" ] || [ -L "$target" ] || continue
    backup="$(backup_path "$target")"
    printf 'stale: %s -> %s\n' "$target" "$backup"
    run mv "$target" "$backup"
  done
}

install_links() {
  local harness="$1" target_root="$2" skill_dir name target
  printf 'harness: %s\n' "$harness"
  printf 'source: %s\n' "$SOURCE_SKILLS_DIR"
  printf 'target: %s\n' "$target_root"
  local mkdir_cmd=(mkdir -p "$target_root")
  run "${mkdir_cmd[@]}"
  while IFS= read -r skill_dir; do
    [ -n "$skill_dir" ] || continue
    name="$(basename "$skill_dir")"
    target="$target_root/$name"
    replace_with_link "$skill_dir" "$target"
  done < <(list_skills)
  prune_stale "$target_root"
}

install_claude() {
  install_links claude "${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
}

install_native() {
  install_links "$1" "$TARGET_SKILLS_DIR"
}

[ -d "$SOURCE_SKILLS_DIR" ] || { echo "install-skills: skills directory not found: $SOURCE_SKILLS_DIR" >&2; exit 1; }

if [ "$HARNESS" = "all" ] || [ "$HARNESS" = "claude" ]; then install_claude; fi
if [ "$HARNESS" = "all" ] || [ "$HARNESS" = "codex" ]; then install_native codex; fi
if [ "$HARNESS" = "all" ] || [ "$HARNESS" = "pi" ]; then install_native pi; fi
