#!/usr/bin/env bash
# spawn-successor.sh - launch a same-harness successor seeded from a handoff briefing.
set -euo pipefail

readonly HANDOFF_PROMPT='Resume from a handoff. Read .agent/handoff/HANDOFF.md in full, then continue the Next unit of work, honoring the Guardrails. If .agent/handoff/HANDOFF.md is missing but .claude/handoff/HANDOFF.md exists, read the legacy Claude handoff and migrate any new handoff state to .agent/handoff/HANDOFF.md.'

existing_names() {
  read -r -a tb <<< "${AGENT_TMUX:-tmux}"
  "${tb[@]}" list-windows -a -F '#{window_name}' 2>/dev/null || true
}

dedupe() {
  local base="$1" name="$1" n=2 existing
  existing="$(cat)"
  while printf '%s\n' "$existing" | grep -qxF -- "$name"; do
    name="${base}-${n}"
    n=$((n + 1))
  done
  printf '%s' "$name"
}

parent_cmd() {
  if [ -n "${AGENT_PARENT_CMD:-}" ]; then printf '%s' "$AGENT_PARENT_CMD"; return; fi
  if [ -n "${EXTRACT_PARENT_CMD:-}" ]; then printf '%s' "$EXTRACT_PARENT_CMD"; return; fi
  ps -o comm= -o args= -p "${PPID:-0}" 2>/dev/null || true
}

detect_harness() {
  case "${AGENT_HARNESS:-}" in
    claude|codex|pi) printf '%s\n' "$AGENT_HARNESS"; return ;;
    "") ;;
    *) printf 'unknown\n'; return ;;
  esac
  if [ -n "${CODEX_THREAD_ID:-}" ] || [ -n "${CODEX_CI:-}" ]; then printf 'codex\n'; return; fi
  if env | grep -q '^CLAUDE'; then printf 'claude\n'; return; fi
  if env | grep -q '^PI_'; then printf 'pi\n'; return; fi
  local p
  p="$(parent_cmd)"
  case "$p" in
    *codex*) printf 'codex\n' ;;
    *claude*) printf 'claude\n' ;;
    *pi-coding-agent*|*" pi "*) printf 'pi\n' ;;
    *) printf 'unknown\n' ;;
  esac
}

quote_prompt() {
  local s="$1"
  printf "'%s'" "${s//\'/\'\\\'\'}"
}

agent_command() {
  local harness="$1" skip="$2" effort="$3" model="$4" prompt="$5"
  local cmd=""
  case "$harness" in
    claude)
      cmd="claude"
      [ "$skip" -eq 1 ] && cmd+=" --dangerously-skip-permissions"
      [ -n "$effort" ] && cmd+=" --effort $effort"
      [ -n "$model" ] && cmd+=" --model $(quote_prompt "$model")"
      ;;
    codex)
      cmd="codex"
      [ "$skip" -eq 1 ] && cmd+=" --dangerously-bypass-approvals-and-sandbox"
      ;;
    pi)
      cmd="${PI_AGENT_CMD:-pi}"
      ;;
    *)
      cmd="${AGENT_FALLBACK_CMD:-}"
      ;;
  esac
  [ -n "$cmd" ] || return 1
  printf '%s %s' "$cmd" "$(quote_prompt "$prompt")"
}

main() {
  local dry_run=0 print_harness=0 skip=0 effort="" model=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run) dry_run=1; shift ;;
      --print-harness) print_harness=1; shift ;;
      --skip-permissions|--yolo) skip=1; shift ;;
      --effort) effort="${2:?--effort requires a value}"; shift 2 ;;
      --effort=*) effort="${1#--effort=}"; shift ;;
      --model) model="${2:?--model requires a value}"; shift 2 ;;
      --model=*) model="${1#--model=}"; shift ;;
      --) shift; break ;;
      -*) echo "spawn-successor: unknown argument '$1'" >&2; exit 2 ;;
      *) break ;;
    esac
  done
  case "${AGENT_SKIP_PERMISSIONS:-}" in 1|true|yes) skip=1 ;; esac
  [ -z "$effort" ] && effort="${AGENT_EFFORT:-${CLAUDE_EFFORT:-}}"
  [ -z "$model" ] && model="${AGENT_MODEL:-}"
  if [ -n "$effort" ]; then
    case "$effort" in low|medium|high|xhigh|max) ;; *) echo "spawn-successor: invalid --effort '$effort'" >&2; exit 2 ;; esac
  fi

  local harness
  harness="$(detect_harness)"
  if [ "$print_harness" -eq 1 ]; then printf '%s\n' "$harness"; exit 0; fi

  local slug="${1:?usage: spawn-successor.sh [--dry-run] [--skip-permissions] [--effort LEVEL] [--model NAME] <slug> [project-dir]}"
  local dir="${2:-$PWD}"
  local pane_cmd
  if ! pane_cmd="$(agent_command "$harness" "$skip" "$effort" "$model" "$HANDOFF_PROMPT")"; then
    echo "unknown harness - paste this prompt into a fresh agent session:" >&2
    echo "$HANDOFF_PROMPT"
    exit 0
  fi

  read -r -a tmux_bin <<< "${AGENT_TMUX:-tmux}"
  emit() { if [ "$dry_run" -eq 1 ]; then printf '%s\n' "$*"; else "$@"; fi; }

  if [ -n "${TMUX:-}" ]; then
    slug="$(existing_names | dedupe "$slug")"
    emit "${tmux_bin[@]}" new-window -d -n "$slug" -c "$dir" "$pane_cmd"
    [ "$dry_run" -eq 1 ] || "${tmux_bin[@]}" display-message "handoff: spawned '$slug' in background"
    echo "spawned window: $slug"
  elif command -v "${tmux_bin[0]}" >/dev/null 2>&1; then
    slug="$(existing_names | dedupe "$slug")"
    emit "${tmux_bin[@]}" new-session -d -s "$slug" -c "$dir" "$pane_cmd"
    echo "spawned detached session: $slug"
    echo "attach with: ${tmux_bin[*]} attach -t $slug"
  else
    echo "tmux not found - run this manually:"
    echo "$pane_cmd"
  fi
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then main "$@"; fi
