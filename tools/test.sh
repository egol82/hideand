#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT_BIN:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1 && [[ ! -x "$GODOT" ]]; then
  echo 'Set GODOT_BIN to a Godot Standard executable.' >&2; exit 1
fi
check_run() {
  local expected="$1" log status=0
  shift
  if [[ " $* " == *" --script "* ]]; then
    set -- --fixed-fps 60 --quit-after 1800 "$@"
  fi
  log="$(mktemp)"
  "$GODOT" "$@" >"$log" 2>&1 || status=$?
  cat "$log"
  if [[ $status -ne 0 ]] || grep -Eq 'SCRIPT ERROR:|Parse Error:|(^|[[:space:]])ERROR:|FAIL:' "$log"; then
    rm -f "$log"; return 1
  fi
  if [[ -n "$expected" ]] && ! grep -Fq "$expected" "$log"; then
    echo "Required completion marker missing: $expected" >&2
    rm -f "$log"; return 1
  fi
  rm -f "$log"
}
"$GODOT" --version
check_run '' --headless --path "$ROOT" --editor --import
check_run 'PHASE1_UNIT_RESULT:' --headless --path "$ROOT" --script res://tests/test_weapon.gd
check_run 'PHASE2_UNIT_RESULT:' --headless --path "$ROOT" --script res://tests/phase2/test_phase2.gd
check_run 'PHASE2_INTERACTION_RESULT:' --headless --path "$ROOT" --script res://tests/phase2/test_interactions.gd
check_run 'PHASE1_SMOKE_READY' --headless --fixed-fps 60 --quit-after 360 --path "$ROOT" res://scenes/main.tscn -- --smoke-test
check_run 'PHASE2_SMOKE_READY' --headless --fixed-fps 60 --quit-after 600 --path "$ROOT" -- --phase2-smoke --seed=8027
check_run 'PHASE2_AUTOPLAY_RESULT:' --headless --fixed-fps 60 --quit-after 45000 --path "$ROOT" -- --autoplay-test
printf '\nEngine checks passed. Human playtesting and Windows export validation remain separate.\n'
