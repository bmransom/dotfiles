#!/usr/bin/env bash
# Tests for handoff-spawn.sh — run: bash <skill>/scripts/tests/test-handoff-spawn.sh
# Resolves the script relative to its own location, so it is path-portable.
# Isolated on a throwaway tmux socket; never touches the real tmux server.
set -uo pipefail

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/handoff-spawn.sh"
SOCK="handoff-spawn-test"
export HANDOFF_TMUX="tmux -L $SOCK"
fail=0

assert_contains() { # <haystack> <needle> <msg>
  if [[ "$1" == *"$2"* ]]; then echo "  ok: $3"
  else echo "  FAIL: $3"; echo "    want substring: $2"; echo "    got: $1"; fail=1; fi
}
assert_eq() { # <got> <want> <msg>
  if [ "$1" = "$2" ]; then echo "  ok: $3"
  else echo "  FAIL: $3 (got '$1' want '$2')"; fail=1; fi
}
assert_not_contains() { # <haystack> <needle> <msg>
  if [[ "$1" != *"$2"* ]]; then echo "  ok: $3"
  else echo "  FAIL: $3"; echo "    unexpected substring: $2"; echo "    in: $1"; fail=1; fi
}

# fresh isolated server
tmux -L "$SOCK" kill-server 2>/dev/null || true
tmux -L "$SOCK" new-session -d -s host -n existing-name

echo "dedupe (pure function):"
out=$(printf 'existing-name\nother\n' | ( source "$SCRIPT"; dedupe existing-name ))
assert_eq "$out" "existing-name-2" "appends -2 on collision"
out=$(printf 'a\nb\n' | ( source "$SCRIPT"; dedupe lp-bounds ))
assert_eq "$out" "lp-bounds" "keeps name when no collision"

echo "inside-tmux branch (dry-run):"
out=$(TMUX=fake "$SCRIPT" --dry-run lp-bounds /tmp/proj 2>&1)
assert_contains "$out" "new-window" "uses new-window when inside tmux"
assert_contains "$out" "-n lp-bounds" "names the window with the slug"
assert_contains "$out" "-c /tmp/proj" "sets the project dir"
assert_contains "$out" "spawned window: lp-bounds" "reports the window outcome"

echo "detached branch (dry-run, tmux present, not attached):"
out=$(env -u TMUX "$SCRIPT" --dry-run lp-bounds /tmp/proj 2>&1)
assert_contains "$out" "new-session" "uses new-session when detached"
assert_contains "$out" "attach with:" "prints the attach hint"

echo "no-tmux branch (simulated via override to a missing binary):"
out=$(env -u TMUX HANDOFF_TMUX="tmux-does-not-exist-xyz" "$SCRIPT" --dry-run lp-bounds 2>&1)
assert_contains "$out" "tmux not found" "falls back to paste note"

echo "skip-permissions — default off, opt-in (dry-run):"
out=$(env -u CLAUDE_EFFORT TMUX=fake "$SCRIPT" --dry-run lp-bounds /tmp/proj 2>&1)
assert_not_contains "$out" "--dangerously-skip-permissions" "default does not skip permissions"
out=$(env -u CLAUDE_EFFORT TMUX=fake "$SCRIPT" --dry-run --skip-permissions lp-bounds /tmp/proj 2>&1)
assert_contains "$out" "claude --dangerously-skip-permissions" "--skip-permissions adds the flag"
out=$(env -u CLAUDE_EFFORT TMUX=fake "$SCRIPT" --dry-run --yolo lp-bounds /tmp/proj 2>&1)
assert_contains "$out" "--dangerously-skip-permissions" "--yolo aliases --skip-permissions"
out=$(env -u CLAUDE_EFFORT TMUX=fake HANDOFF_SKIP_PERMISSIONS=1 "$SCRIPT" --dry-run lp-bounds /tmp/proj 2>&1)
assert_contains "$out" "--dangerously-skip-permissions" "HANDOFF_SKIP_PERMISSIONS=1 enables skip"

echo "effort — inherits parent CLAUDE_EFFORT by default (dry-run):"
out=$(env -u CLAUDE_EFFORT TMUX=fake "$SCRIPT" --dry-run lp-bounds /tmp/proj 2>&1)
assert_not_contains "$out" "--effort" "no effort flag when the parent's effort is unset"
out=$(CLAUDE_EFFORT=high TMUX=fake "$SCRIPT" --dry-run lp-bounds /tmp/proj 2>&1)
assert_contains "$out" "--effort high" "inherits the parent's CLAUDE_EFFORT by default"
out=$(CLAUDE_EFFORT=high TMUX=fake "$SCRIPT" --dry-run --effort low lp-bounds /tmp/proj 2>&1)
assert_contains "$out" "--effort low" "--effort flag overrides inherited effort"
assert_not_contains "$out" "--effort high" "inherited effort is replaced, not appended"
out=$(CLAUDE_EFFORT=high HANDOFF_EFFORT=max TMUX=fake "$SCRIPT" --dry-run lp-bounds /tmp/proj 2>&1)
assert_contains "$out" "--effort max" "HANDOFF_EFFORT overrides inherited effort"
out=$(env -u CLAUDE_EFFORT TMUX=fake "$SCRIPT" --dry-run --effort bogus lp-bounds /tmp/proj 2>&1); rc=$?
assert_contains "$out" "invalid --effort" "rejects an unknown effort level"
assert_eq "$rc" "2" "invalid effort exits non-zero"

tmux -L "$SOCK" kill-server 2>/dev/null || true
echo
[ "$fail" -eq 0 ] && echo "ALL PASS" || { echo "FAILURES"; exit 1; }
