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

tmux -L "$SOCK" kill-server 2>/dev/null || true
echo
[ "$fail" -eq 0 ] && echo "ALL PASS" || { echo "FAILURES"; exit 1; }
