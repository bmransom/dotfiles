#!/usr/bin/env bash
# Tests for shared agent skill management scripts.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
script_path() {
  local name="$1"
  if [ -x "$ROOT/scripts/$name" ]; then printf '%s\n' "$ROOT/scripts/$name"; return; fi
  if [ -x "$ROOT/scripts/executable_$name" ]; then printf '%s\n' "$ROOT/scripts/executable_$name"; return; fi
  printf '%s\n' "$ROOT/scripts/$name"
}
VALIDATE="$(script_path validate-skills.sh)"
INSTALL="$(script_path install-skills.sh)"
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

out="$("$INSTALL" --dry-run --harness codex 2>&1)"; rc=$?
assert_eq "$rc" "0" "codex dry-run exits zero"
assert_contains "$out" "native" "codex strategy uses native root"
assert_contains "$out" ".agents/skills" "codex target is generic agent root"

out="$("$INSTALL" --dry-run --harness all 2>&1)"; rc=$?
assert_eq "$rc" "0" "all dry-run exits zero"
assert_contains "$out" "harness: claude" "all includes claude"
assert_contains "$out" "harness: codex" "all includes codex"

echo
[ "$fail" -eq 0 ] && echo "ALL PASS" || { echo "FAILURES"; exit 1; }
