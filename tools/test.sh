#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT_BIN:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1 && [[ ! -x "$GODOT" ]]; then
  echo 'Set GODOT_BIN to a Godot standard executable.' >&2; exit 1
fi
check_run() {
  local log
  log="$(mktemp)"
  "$GODOT" "$@" 2>&1 | tee "$log"
  if grep -Eq 'SCRIPT ERROR:|Parse Error:|^ERROR:' "$log"; then
    rm -f "$log"; return 1
  fi
  if [[ " $* " == *" --smoke-test "* ]] && ! grep -q 'PHASE1_SMOKE_READY' "$log"; then
    echo 'Missing scene initialization completion marker.' >&2
    rm -f "$log"; return 1
  fi
  rm -f "$log"
}
"$GODOT" --version
check_run --headless --path "$ROOT" --editor --import
check_run --headless --path "$ROOT" --script res://tests/test_weapon.gd
check_run --headless --fixed-fps 60 --quit-after 240 --path "$ROOT" -- --smoke-test
printf '\nGodot checks passed. A GUI playtest is still required.\n'
