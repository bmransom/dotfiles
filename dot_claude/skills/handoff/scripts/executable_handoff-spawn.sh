#!/usr/bin/env bash
# handoff-spawn.sh — launch a fresh Claude Code successor seeded from a handoff briefing.
#
# Usage: handoff-spawn.sh [--dry-run] [--skip-permissions] [--effort LEVEL] [--model NAME] <slug> [project-dir]
#   <slug>        short context name for the successor (window or session name)
#   project-dir   working directory for the successor (default: current dir)
#
# Successor options:
#   --skip-permissions  (alias --yolo)   run with --dangerously-skip-permissions (no approval
#                                         prompts) — opt-in, trusted repos only.
#                                         Env: HANDOFF_SKIP_PERMISSIONS=1
#   --effort LEVEL                        reasoning effort (low|medium|high|xhigh|max).
#                                         Defaults to the parent's CLAUDE_EFFORT; override with
#                                         the flag or HANDOFF_EFFORT=LEVEL.
#   --model NAME                          model alias or id (sonnet|opus|haiku|fable|...).
#                                         Override only; default is the successor's own default.
#                                         Env: HANDOFF_MODEL=NAME
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
  local dry_run=0 skip_perms=0 effort="" model=""
  while true; do
    case "${1:-}" in
      --dry-run)                  dry_run=1; shift;;
      --skip-permissions|--yolo)  skip_perms=1; shift;;
      --effort)                   effort="${2:?--effort requires a level}"; shift 2;;
      --effort=*)                 effort="${1#--effort=}"; shift;;
      --model)                    model="${2:?--model requires a name}"; shift 2;;
      --model=*)                  model="${1#--model=}"; shift;;
      --)                         shift; break;;
      *)                          break;;
    esac
  done
  # env fallbacks, used only when the matching flag is absent
  case "${HANDOFF_SKIP_PERMISSIONS:-}" in 1|true|yes) skip_perms=1;; esac
  # effort precedence: --effort flag > HANDOFF_EFFORT > inherited CLAUDE_EFFORT (parent's current)
  [ -z "$effort" ] && effort="${HANDOFF_EFFORT:-}"
  [ -z "$effort" ] && effort="${CLAUDE_EFFORT:-}"
  # model precedence: --model flag > HANDOFF_MODEL (no parent inherit — model isn't exported)
  [ -z "$model" ] && model="${HANDOFF_MODEL:-}"
  if [ -n "$effort" ]; then
    case "$effort" in
      low|medium|high|xhigh|max) ;;
      *) echo "handoff-spawn: invalid --effort '$effort' (use low|medium|high|xhigh|max)" >&2; exit 2;;
    esac
  fi

  local slug="${1:?usage: handoff-spawn.sh [--dry-run] [--skip-permissions] [--effort LEVEL] [--model NAME] <slug> [project-dir]}"
  local dir="${2:-$PWD}"

  local -a tmux_bin
  read -r -a tmux_bin <<< "${HANDOFF_TMUX:-tmux}"

  # assemble the successor command with any opt-in flags before the seed prompt
  local claude_opts=""
  [ "$skip_perms" -eq 1 ] && claude_opts+=" --dangerously-skip-permissions"
  [ -n "$effort" ] && claude_opts+=" --effort $effort"
  # quote model: alias variants like opus[1m] contain shell glob metacharacters
  [ -n "$model" ] && claude_opts+=" --model '$model'"
  local pane_cmd="claude${claude_opts} '$SEED_PROMPT'"

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
