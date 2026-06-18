#!/usr/bin/env bash
# install-skills.sh - expose generic ~/.agents skills to supported harnesses.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SKILLS_DIR="${AGENT_SKILLS_DIR:-$ROOT/skills}"
DRY_RUN=0
HARNESS="all"

usage() {
  cat <<'USAGE'
Usage: install-skills.sh [--dry-run] [--harness claude|codex|pi|all]

Installs generic Agent Skills from ~/.agents/skills-compatible source.
Claude receives symlinks in ~/.claude/skills. Codex and Pi use ~/.agents/skills natively.
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
  find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -print | sort
}

install_claude() {
  local target_root="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
  printf 'harness: claude\n'
  mkdir_cmd=(mkdir -p "$target_root")
  run "${mkdir_cmd[@]}"
  while IFS= read -r skill_dir; do
    [ -n "$skill_dir" ] || continue
    local name target
    name="$(basename "$skill_dir")"
    target="$target_root/$name"
    if [ -L "$target" ]; then
      printf 'link: %s -> %s\n' "$target" "$skill_dir"
      run ln -sfn "$skill_dir" "$target"
    elif [ -e "$target" ]; then
      printf 'skip: %s exists and is not a symlink\n' "$target"
    else
      printf 'link: %s -> %s\n' "$target" "$skill_dir"
      run ln -s "$skill_dir" "$target"
    fi
  done < <(list_skills)
}

install_native() {
  local harness="$1"
  printf 'harness: %s\n' "$harness"
  printf 'native: %s uses ~/.agents/skills (source: %s)\n' "$harness" "$SKILLS_DIR"
}

[ -d "$SKILLS_DIR" ] || { echo "install-skills: skills directory not found: $SKILLS_DIR" >&2; exit 1; }

if [ "$HARNESS" = "all" ] || [ "$HARNESS" = "claude" ]; then install_claude; fi
if [ "$HARNESS" = "all" ] || [ "$HARNESS" = "codex" ]; then install_native codex; fi
if [ "$HARNESS" = "all" ] || [ "$HARNESS" = "pi" ]; then install_native pi; fi
