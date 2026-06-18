#!/usr/bin/env bash
# validate-skills.sh - validate Foundry-owned Agent Skills.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SKILLS_DIR="${AGENT_SOURCE_SKILLS_DIR:-${FOUNDRY_SKILLS_DIR:-$HOME/dev/workspace/foundry/plugins/foundry/skills}}"
fail=0

err() {
  printf 'error: %s\n' "$*" >&2
  fail=1
}

valid_name() {
  [[ "$1" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]
}

frontmatter_value() {
  local key="$1" file="$2"
  awk -v key="$key" '
    NR == 1 && $0 != "---" { exit }
    NR > 1 && $0 == "---" { exit }
    NR > 1 && index($0, key ":") == 1 {
      sub("^[^:]+:[[:space:]]*", "")
      gsub(/^"|"$/, "")
      print
      exit
    }
  ' "$file"
}

if [ ! -d "$SKILLS_DIR" ]; then
  err "skills directory not found: $SKILLS_DIR"
else
  found=0
  while IFS= read -r -d '' skill_dir; do
    found=1
    skill="$(basename "$skill_dir")"
    skill_md="$skill_dir/SKILL.md"
    if ! valid_name "$skill"; then
      err "$skill_dir: directory name must be lowercase hyphenated"
      continue
    fi
    if [ ! -f "$skill_md" ]; then
      err "$skill_dir: missing SKILL.md"
      continue
    fi
    if [ "$(sed -n '1p' "$skill_md")" != "---" ]; then
      err "$skill_md: missing YAML frontmatter"
      continue
    fi
    name="$(frontmatter_value name "$skill_md")"
    description="$(frontmatter_value description "$skill_md")"
    if [ -z "$name" ]; then err "$skill_md: missing name"; fi
    if [ -z "$description" ]; then err "$skill_md: missing description"; fi
    if [ "$name" != "$skill" ]; then err "$skill_md: name '$name' must match directory '$skill'"; fi
    if ! valid_name "$name"; then err "$skill_md: name must be lowercase hyphenated"; fi
    if [ "${#description}" -gt 1024 ]; then err "$skill_md: description exceeds 1024 characters"; fi
    if [ -d "$skill_dir/scripts" ]; then
      while IFS= read -r -d '' script; do
        case "$script" in
          */tests/*) ;;
          *.sh)
            [ -x "$script" ] || err "$script: shell script must be executable"
            ;;
        esac
      done < <(find "$skill_dir/scripts" -type f -print0)
    fi
    printf 'valid: %s\n' "$skill"
  done < <(find "$SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
  [ "$found" -eq 1 ] || err "no skills found in $SKILLS_DIR"
fi

[ "$fail" -eq 0 ]
