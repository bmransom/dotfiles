#!/usr/bin/env bash
# Dotfiles should not own or install AI agent skills.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0

check_absent_path() {
  local path="$1"
  if [ ! -e "$ROOT/$path" ]; then
    echo "  ok: $path absent"
  else
    echo "  FAIL: $path should not be managed here"
    fail=1
  fi
}

check_no_match() {
  local pattern="$1" label="$2" out rc
  out="$(rg -n --glob '!tests/test-no-agent-skill-glue.sh' "$pattern" "$ROOT" 2>&1)"
  rc=$?
  if [ "$rc" -eq 1 ]; then
    echo "  ok: $label"
  else
    echo "  FAIL: $label"
    echo "$out"
    fail=1
  fi
}

echo "agent skill ownership:"
check_absent_path "dot_agents"
check_absent_path "dot_claude"
check_absent_path "run_onchange_after_40-agent-skills.sh.tmpl"
check_no_match "dev/workspace/foundry|FOUNDRY_SKILLS_DIR|run_onchange_after_40-agent-skills|dot_agents" \
  "no Foundry-coupled agent skill installer remains"

echo
[ "$fail" -eq 0 ] && echo "ALL PASS" || { echo "FAILURES"; exit 1; }
