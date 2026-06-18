#!/usr/bin/env bash
# Tests for shared agent skill management scripts.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SOURCE_ROOT="$(cd "$ROOT/.." && pwd)"
script_path() {
  local name="$1"
  if [ -x "$ROOT/scripts/$name" ]; then printf '%s\n' "$ROOT/scripts/$name"; return; fi
  if [ -x "$ROOT/scripts/executable_$name" ]; then printf '%s\n' "$ROOT/scripts/executable_$name"; return; fi
  printf '%s\n' "$ROOT/scripts/$name"
}
VALIDATE="$(script_path validate-skills.sh)"
INSTALL="$(script_path install-skills.sh)"
FOUNDRY_SKILLS_DIR="${FOUNDRY_SKILLS_DIR:-$HOME/dev/workspace/foundry/plugins/foundry/skills}"
fail=0

assert_contains() {
  if [[ "$1" == *"$2"* ]]; then echo "  ok: $3"
  else echo "  FAIL: $3"; echo "    want substring: $2"; echo "    got: $1"; fail=1; fi
}

assert_not_contains() {
  if [[ "$1" != *"$2"* ]]; then echo "  ok: $3"
  else echo "  FAIL: $3"; echo "    unexpected substring: $2"; echo "    got: $1"; fail=1; fi
}

assert_eq() {
  if [ "$1" = "$2" ]; then echo "  ok: $3"
  else echo "  FAIL: $3 (got '$1' want '$2')"; fail=1; fi
}

assert_file() {
  if [ -f "$1" ]; then echo "  ok: $2"
  else echo "  FAIL: $2"; echo "    missing file: $1"; fail=1; fi
}

echo "validate-skills:"
out="$("$VALIDATE" 2>&1)"; rc=$?
assert_eq "$rc" "0" "valid skill tree exits zero"
assert_contains "$out" "valid:" "prints validated skills"
assert_not_contains "$out" "dot_claude/skills" "does not validate legacy Claude source"

echo "install-skills dry-run:"
out="$("$INSTALL" --dry-run --harness claude 2>&1)"; rc=$?
assert_eq "$rc" "0" "claude dry-run exits zero"
assert_contains "$out" "link" "claude strategy links skills"
assert_contains "$out" ".claude/skills/handoff" "claude target includes handoff"
assert_contains "$out" ".claude/skills/performance" "claude target includes performance"
assert_contains "$out" ".claude/skills/naming-standards" "claude target includes naming-standards"
assert_contains "$out" ".claude/skills/design-patterns" "claude target includes design-patterns"
assert_contains "$out" ".claude/skills/modular-structure" "claude target includes modular-structure"
assert_contains "$out" ".claude/skills/code" "claude target includes foundry code lifecycle"
assert_not_contains "$out" "link: $HOME/.claude/skills/reference-gap-profiling" "reference-gap-profiling is not installed as a standalone skill"
assert_not_contains "$out" "link: $HOME/.claude/skills/performance-comparison" "performance-comparison is not installed as a standalone skill"

out="$("$INSTALL" --dry-run --harness codex 2>&1)"; rc=$?
assert_eq "$rc" "0" "codex dry-run exits zero"
assert_contains "$out" "link" "codex strategy links foundry skills into native root"
assert_contains "$out" ".agents/skills" "codex target is generic agent root"
assert_contains "$out" "$FOUNDRY_SKILLS_DIR" "codex source is foundry skills"

out="$("$INSTALL" --dry-run --harness all 2>&1)"; rc=$?
assert_eq "$rc" "0" "all dry-run exits zero"
assert_contains "$out" "harness: claude" "all includes claude"
assert_contains "$out" "harness: codex" "all includes codex"

echo "chezmoi onchange hook:"
HOOK="$SOURCE_ROOT/run_onchange_after_40-agent-skills.sh.tmpl"
if [ -d "$SOURCE_ROOT/dot_agents" ]; then
  assert_file "$HOOK" "agent skills install hook exists"
  out="$(chezmoi execute-template --file "$HOOK" 2>&1)"; rc=$?
  assert_eq "$rc" "0" "agent skills install hook renders"
  assert_contains "$out" '--harness all' "hook installs all harnesses"
  assert_contains "$out" 'dot_agents hash:' "hook is keyed on dot_agents content"
else
  echo "  ok: source-only hook check skipped outside chezmoi source"
fi

echo
[ "$fail" -eq 0 ] && echo "ALL PASS" || { echo "FAILURES"; exit 1; }
