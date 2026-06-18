#!/usr/bin/env bash
# Tests for same-harness successor spawning.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [ -x "$SCRIPT_DIR/spawn-successor.sh" ]; then
  SCRIPT="$SCRIPT_DIR/spawn-successor.sh"
else
  SCRIPT="$SCRIPT_DIR/executable_spawn-successor.sh"
fi
SOCK="agent-spawn-successor-test"
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
tmux -L "$SOCK" new-session -d -s host -n handoff-work

echo "dedupe:"
out=$(printf 'handoff-work\nother\n' | ( source "$SCRIPT"; dedupe handoff-work ))
assert_eq "$out" "handoff-work-2" "dedupes colliding tmux names"

echo "harness detection:"
out=$(AGENT_HARNESS=codex "$SCRIPT" --print-harness 2>&1)
assert_eq "$out" "codex" "explicit AGENT_HARNESS wins"
out=$(env -u AGENT_HARNESS CODEX_THREAD_ID=abc "$SCRIPT" --print-harness 2>&1)
assert_eq "$out" "codex" "detects codex env"
out=$(env -u AGENT_HARNESS -u CODEX_THREAD_ID -u CODEX_CI EXTRACT_PARENT_CMD="claude --dangerously-skip-permissions" "$SCRIPT" --print-harness 2>&1)
assert_eq "$out" "claude" "detects claude parent command"

echo "same-harness command:"
out=$(AGENT_HARNESS=codex TMUX=fake "$SCRIPT" --dry-run --skip-permissions next-task /tmp/proj 2>&1)
assert_contains "$out" "codex --dangerously-bypass-approvals-and-sandbox" "codex uses codex command"
assert_not_contains "$out" "new-window -d -n next-task -c /tmp/proj claude" "codex path does not launch claude"
assert_contains "$out" "Read .agent/handoff/HANDOFF.md" "uses generic handoff state"
assert_contains "$out" "spawned window:" "inside tmux reports window"

out=$(AGENT_HARNESS=claude TMUX=fake "$SCRIPT" --dry-run --effort high --model sonnet next-task /tmp/proj 2>&1)
assert_contains "$out" "claude --effort high --model 'sonnet'" "claude passes explicit effort/model"
assert_contains "$out" "Read .agent/handoff/HANDOFF.md" "claude uses generic handoff state"

echo "detached and fallback:"
out=$(env -u TMUX AGENT_HARNESS=claude "$SCRIPT" --dry-run next-task /tmp/proj 2>&1)
assert_contains "$out" "new-session" "detached run creates session"
assert_contains "$out" "attach with:" "detached run prints attach hint"

out=$(env -u TMUX AGENT_TMUX="tmux-does-not-exist-xyz" AGENT_HARNESS=codex "$SCRIPT" --dry-run next-task 2>&1)
assert_contains "$out" "tmux not found" "missing tmux prints fallback"
assert_contains "$out" "codex" "fallback preserves harness command"

tmux -L "$SOCK" kill-server 2>/dev/null || true
echo
[ "$fail" -eq 0 ] && echo "ALL PASS" || { echo "FAILURES"; exit 1; }
