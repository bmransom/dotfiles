#!/usr/bin/env bash
# Tests for tmux-startup.sh. Run: bash ~/.local/share/chezmoi/tests/test-tmux-startup.sh
# Sources the function file from the chezmoi source (self-contained, no apply needed).
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/../dot_tools/tmux-startup.sh"
fail=0

assert_eq()       { if [ "$1" = "$2" ]; then echo "  ok: $3"; else echo "  FAIL: $3 (got '$1' want '$2')"; fail=1; fi; }
assert_contains() { if [[ "$1" == *"$2"* ]]; then echo "  ok: $3"; else echo "  FAIL: $3"; echo "    want: $2"; echo "    got:  $1"; fail=1; fi; }
assert_empty()    { if [ -z "$1" ]; then echo "  ok: $2"; else echo "  FAIL: $2 (got '$1')"; fail=1; fi; }

echo "_tsp_action (pure choice -> action):"
assert_eq "$(_tsp_action '')"                                "plain"          "empty (esc) -> plain"
assert_eq "$(_tsp_action '[plain shell]')"                   "plain"          "[plain shell] -> plain"
assert_eq "$(_tsp_action '[↻] restore previous sessions')"   "restore"        "restore entry -> restore"
assert_eq "$(_tsp_action '[+] new session…')"                "new"            "new entry -> new"
assert_eq "$(_tsp_action 'octant (3 windows)')"              "attach octant"  "session line -> attach <name>"

echo "tmux_session_picker dispatch (dry-run, injected choice, isolated socket):"
out="$(TSP_TMUX='tmux -L tsp-test' TSP_DRY_RUN=1 TSP_CHOICE='octant (3 windows)' tmux_session_picker)"
assert_contains "$out" "RUN: tmux -L tsp-test attach -t octant" "attach -> tmux attach -t <name>"
out="$(TSP_TMUX='tmux -L tsp-test' TSP_DRY_RUN=1 TSP_CHOICE='[plain shell]' tmux_session_picker)"
assert_empty "$out" "plain shell -> runs nothing"
out="$(TSP_TMUX='tmux -L tsp-test' TSP_DRY_RUN=1 TSP_CHOICE='[+] new session…' TSP_NEW_NAME=proj tmux_session_picker)"
assert_contains "$out" "RUN: tmux -L tsp-test new-session -s proj" "new -> tmux new-session with injected name"

echo
[ "$fail" -eq 0 ] && echo "ALL PASS" || { echo "FAILURES"; exit 1; }
