#!/usr/bin/env bash
# handoff-spawn.sh — launch a fresh Claude Code successor seeded from a handoff briefing.
#
# Usage: handoff-spawn.sh [--dry-run] <slug> [project-dir]
#   <slug>        short context name for the successor (window or session name)
#   project-dir   working directory for the successor (default: current dir)
#
# Environment detection:
#   inside a tmux session     -> new background window (prefix+w to visit)
#   tmux installed, detached  -> new detached session (prints attach hint)
#   tmux absent               -> prints paste fallback note, exits 0
#
# Testability seams:
#   --dry-run                     print the tmux command instead of running it
#   HANDOFF_TMUX="tmux -L sock"    override the tmux invocation (default: tmux);
#                                  also used by tests to simulate tmux being absent
set -euo pipefail

readonly SEED_PROMPT='Resume from a handoff. Read .claude/handoff/HANDOFF.md in full, then continue the Next unit of work, honoring the Guardrails. If anything is ambiguous, state your plan before making changes.'

# list existing window names across the (overridable) tmux server, one per line.
existing_names() {
  read -r -a tb <<< "${HANDOFF_TMUX:-tmux}"
  "${tb[@]}" list-windows -a -F '#{window_name}' 2>/dev/null || true
}

# dedupe <slug> — reads candidate names (one per line) on stdin; prints a name
# not present in that list, appending -2, -3, ... on collision.
dedupe() {
  local base="$1" name="$1" n=2 existing
  existing="$(cat)"
  while printf '%s\n' "$existing" | grep -qxF -- "$name"; do
    name="${base}-${n}"; n=$((n + 1))
  done
  printf '%s' "$name"
}

main() {
  local dry_run=0
  if [ "${1:-}" = "--dry-run" ]; then dry_run=1; shift; fi
  local slug="${1:?usage: handoff-spawn.sh [--dry-run] <slug> [project-dir]}"
  local dir="${2:-$PWD}"

  local -a tmux_bin
  read -r -a tmux_bin <<< "${HANDOFF_TMUX:-tmux}"
  local pane_cmd="claude '$SEED_PROMPT'"

  emit() { # print (dry-run) or execute a command
    if [ "$dry_run" -eq 1 ]; then printf '%s\n' "$*"; else "$@"; fi
  }

  if [ -n "${TMUX:-}" ]; then
    slug="$(existing_names | dedupe "$slug")"
    emit "${tmux_bin[@]}" new-window -d -n "$slug" -c "$dir" "$pane_cmd"
    [ "$dry_run" -eq 1 ] || "${tmux_bin[@]}" display-message "handoff: spawned '$slug' in background — prefix+w to visit"
    echo "spawned window: $slug"
  elif command -v "${tmux_bin[0]}" >/dev/null 2>&1; then
    slug="$(existing_names | dedupe "$slug")"
    emit "${tmux_bin[@]}" new-session -d -s "$slug" -c "$dir" "$pane_cmd"
    echo "spawned detached session: $slug"
    echo "attach with: ${tmux_bin[*]} attach -t $slug"
  else
    echo "tmux not found — paste the briefing above into a fresh 'claude' session."
  fi
}

# Only run main when executed directly, so tests can source dedupe in isolation.
if [ "${BASH_SOURCE[0]}" = "$0" ]; then main "$@"; fi
