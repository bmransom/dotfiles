# tmux-startup.sh — interactive tmux session picker for new terminals.
#
# Sourced by ~/.zshrc's `~/.tools/**/*.sh` loop: DEFINES functions only, runs nothing
# at source time. ~/.zshrc invokes tmux_session_picker behind an interactive/TTY/
# not-in-tmux guard. Written to run under both zsh (runtime) and bash (tests):
# no shell arrays, no zsh-only syntax. $TSP_TMUX is a trusted internal value and is
# intentionally left unquoted so "tmux -L sock" word-splits.
#
# Testability seams (tests/test-tmux-startup.sh):
#   TSP_TMUX="tmux -L sock"   override the tmux invocation (default: tmux)
#   TSP_DRY_RUN=1             echo the attach/new action instead of running it
#   TSP_CHOICE=<line>         inject the picker selection (skip fzf)
#   TSP_NEW_NAME=<name>       inject the new-session name (skip the prompt)

# run, or in dry-run echo, a command
_tsp_run() {
  if [ "${TSP_DRY_RUN:-0}" = "1" ]; then printf 'RUN: %s\n' "$*"; else "$@"; fi
}

# true when tmux-resurrect has a saved snapshot to restore
_tsp_have_saved_state() {
  [ -e "${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect/last" ] || [ -e "$HOME/.tmux/resurrect/last" ]
}

# print the picker menu: running sessions ("name (N windows)"), then the action rows
_tsp_menu() {
  local tcmd="${TSP_TMUX:-tmux}"
  $tcmd list-sessions -F '#{session_name} (#{session_windows} windows)' 2>/dev/null
  if ! $tcmd has-session 2>/dev/null && _tsp_have_saved_state; then
    printf '%s\n' "[↻] restore previous sessions"
  fi
  printf '%s\n' "[+] new session…"
  printf '%s\n' "[plain shell]"
}

# pure: map a selected menu line to an action verb (plain | restore | new | attach <name>)
_tsp_action() {
  case "$1" in
    ""|"[plain shell]")               printf 'plain' ;;
    "[↻] restore previous sessions")  printf 'restore' ;;
    "[+] new session…")               printf 'new' ;;
    *)                                printf 'attach %s' "${1%% \(*}" ;;
  esac
}

# orchestrate: build menu -> choose (fzf, or plain fallback) -> act
tmux_session_picker() {
  local tcmd="${TSP_TMUX:-tmux}"
  local default_name="${PWD##*/}"
  local menu choice action name reply
  menu="$(_tsp_menu)"

  if [ -n "${TSP_CHOICE+x}" ]; then
    choice="$TSP_CHOICE"
  elif command -v fzf >/dev/null 2>&1; then
    choice="$(printf '%s\n' "$menu" | fzf --prompt='tmux ❯ ' --reverse --height=45% \
      --preview="$tcmd list-windows -t {1} 2>/dev/null" --preview-window=right:50%:wrap)"
  else
    printf '%s\n' "$menu" | nl -w2 -s') '
    printf 'select> '; read -r reply
    choice="$(printf '%s\n' "$menu" | sed -n "${reply}p" 2>/dev/null)"
  fi

  action="$(_tsp_action "$choice")"
  case "$action" in
    plain)   return 0 ;;
    restore) _tsp_run $tcmd start-server; sleep 1; tmux_session_picker ;;
    new)
      name="${TSP_NEW_NAME-}"
      if [ -z "${TSP_NEW_NAME+x}" ]; then
        printf 'new session name [%s]: ' "$default_name"; read -r name
      fi
      name="${name:-$default_name}"
      _tsp_run $tcmd new-session -s "$name" ;;
    attach*) _tsp_run $tcmd attach -t "${action#attach }" ;;
  esac
}
