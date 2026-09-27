#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT_BIN:-godot}"
check_run() {
  local expected="$1" status=0 log
  shift
  log="$(mktemp)"
  "$GODOT" "$@" >"$log" 2>&1 || status=$?
  cat "$log"
  if [[ $status -ne 0 ]] || grep -Eq 'SCRIPT ERROR:|Parse Error:|(^|[[:space:]])ERROR:|FAIL:' "$log" || ! grep -Fq "$expected" "$log"; then
    echo "Phase 3 check failed or missing marker: $expected" >&2
    rm -f "$log"; return 1
  fi
  rm -f "$log"
}
check_run 'PHASE3_UNIT_RESULT:' --headless --fixed-fps 60 --quit-after 3000 --path "$ROOT" --script res://tests/phase3/test_phase3.gd -- --phase3-test
check_run 'PHASE3_SMOKE_READY' --headless --fixed-fps 60 --quit-after 1800 --path "$ROOT" res://scenes/phase3.tscn -- --phase3-smoke
for map in toy_home warehouse garden; do
  check_run 'PHASE3_AUTOPLAY_RESULT:' --headless --fixed-fps 60 --quit-after 180000 --path "$ROOT" res://scenes/phase3.tscn -- --phase3-autoplay "--map=$map"
done
