#!/usr/bin/env bash
# Tests for same-harness skill extraction spawning.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -x "$SCRIPT_DIR/spawn-extractor.sh" ]; then
  SCRIPT="$SCRIPT_DIR/spawn-extractor.sh"
else
  SCRIPT="$SCRIPT_DIR/executable_spawn-extractor.sh"
fi
SOCK="agent-spawn-extractor-test"
export AGENT_TMUX="tmux -L $SOCK"
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

tmux -L "$SOCK" kill-server 2>/dev/null || true
tmux -L "$SOCK" new-session -d -s host -n extract-perf

echo "harness detection:"
out=$(AGENT_HARNESS=claude "$SCRIPT" --print-harness 2>&1)
assert_eq "$out" "claude" "explicit AGENT_HARNESS wins"
out=$(env -u AGENT_HARNESS CODEX_CI=1 "$SCRIPT" --print-harness 2>&1)
assert_eq "$out" "codex" "detects codex env"

echo "spawn command:"
out=$(AGENT_HARNESS=codex TMUX=fake "$SCRIPT" --dry-run performance-comparison .agent/skill-extractions/performance-comparison/brief.md /tmp/proj 2>&1)
assert_contains "$out" "codex" "codex extraction launches codex"
assert_not_contains "$out" "claude" "codex extraction does not launch claude"
assert_contains "$out" "Read .agent/skill-extractions/performance-comparison/brief.md" "seed prompt points at brief"
assert_contains "$out" "Draft or revise the skill" "seed prompt is extraction-specific"
assert_contains "$out" "spawned window:" "inside tmux reports window"

out=$(AGENT_HARNESS=claude TMUX=fake "$SCRIPT" --dry-run performance-comparison .agent/skill-extractions/performance-comparison/brief.md /tmp/proj 2>&1)
assert_contains "$out" "claude" "claude extraction launches claude"
assert_contains "$out" "extract-performance-comparison" "window slug is extraction-specific"

out=$(env -u TMUX AGENT_TMUX="tmux-does-not-exist-xyz" AGENT_HARNESS=codex "$SCRIPT" --dry-run performance-comparison .agent/skill-extractions/performance-comparison/brief.md 2>&1)
assert_contains "$out" "tmux not found" "missing tmux prints fallback"
assert_contains "$out" "codex" "fallback preserves harness command"

tmux -L "$SOCK" kill-server 2>/dev/null || true
echo
[ "$fail" -eq 0 ] && echo "ALL PASS" || { echo "FAILURES"; exit 1; }
