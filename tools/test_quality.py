#!/usr/bin/env python3
"""Real engine tests for playability / recovery. Uses isolated user://quality_tests files."""
from __future__ import annotations
import argparse, os, pathlib, re, subprocess, sys
ROOT = pathlib.Path(__file__).resolve().parents[1]

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--godot',default=os.environ.get('GODOT_BIN','godot'))
    parser.add_argument('--capture',action='store_true')
    args = parser.parse_args()
    out = ROOT/'ci-artifacts'; out.mkdir(exist_ok=True)
    entry = subprocess.run([args.godot,'--headless','--audio-driver','Dummy','--path',str(ROOT),'--fixed-fps','60','--quit-after','1800','res://scenes/phase5.tscn','--','--phase4-smoke'],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=80)
    entry_log = entry.stdout+entry.stderr
    (out/'phase5-entry.log').write_text(entry_log,encoding='utf-8')
    if entry.returncode or 'PHASE4_SMOKE_READY' not in entry_log or re.search(r'SCRIPT ERROR:|Parse Error:|(?:^|\s)ERROR:|FAIL:',entry_log):
        raise RuntimeError('Phase 5 entry scene failed its real-engine smoke check.')
    command = [args.godot,'--path',str(ROOT),'--audio-driver','Dummy','--fixed-fps','60','--quit-after','10000']
    command += ['--rendering-method','gl_compatibility'] if args.capture else ['--headless']
    command += ['--script','res://tests/quality/test_quality.gd','--','--quality-test']
    if args.capture: command += ['--capture-quality']
    proc = subprocess.run(command,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=120,env=dict(os.environ,GODOT_SILENCE_ROOT_WARNING='1'))
    text = proc.stdout+proc.stderr
    (out/('quality-render.log' if args.capture else 'quality-tests.log')).write_text(text,encoding='utf-8')
    print(text)
    result = re.search(r'QUALITY_UNIT_RESULT: (\d+) checks, 0 failures',text)
    if proc.returncode or not result or re.search(r'SCRIPT ERROR:|Parse Error:|(?:^|\s)ERROR:|FAIL:',text):
        raise RuntimeError('Quality suite failed; inspect log, not just process exit.')
    if args.capture:
        for name in ['00_menu_ko','01_workshop_ko','02_practice_ko','03_controls_ko','04_next_round_ko','05_results_ko','06_menu_en','07_practice_en','08_settings_en']:
            if not (out/f'phase5_{name}.png').is_file(): raise RuntimeError(f'Missing rendered screen {name}')
    print('QUALITY_SUITE_PASS: bounded tests and scripted engine input, not a human playtest.')
    return 0

if __name__ == '__main__':
    try: raise SystemExit(main())
    except (RuntimeError,subprocess.TimeoutExpired,FileNotFoundError) as exc:
        print(f'FAIL: {exc}',file=sys.stderr); raise SystemExit(1)
