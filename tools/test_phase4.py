#!/usr/bin/env python3
"""Bounded real-engine verification. Zero exit WITHOUT required markers is failure."""
from __future__ import annotations
import argparse, os, pathlib, re, subprocess, sys
ROOT = pathlib.Path(__file__).resolve().parents[1]

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--godot', default=os.environ.get('GODOT_BIN','godot'))
    parser.add_argument('--capture', action='store_true')
    parser.add_argument('--skip-matches', action='store_true')
    args = parser.parse_args()
    records = ROOT/'ci-artifacts'
    records.mkdir(exist_ok=True)
    env = dict(os.environ, GODOT_SILENCE_ROOT_WARNING='1')
    def run(name: str, command: list[str], marker: str, timeout: int = 80) -> None:
        proc = subprocess.run([args.godot,'--path',str(ROOT),*command],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=timeout,env=env)
        text = proc.stdout+proc.stderr
        (records/(name+'.log')).write_text(text,encoding='utf-8')
        print(text,flush=True)
        if proc.returncode or re.search(r'SCRIPT ERROR:|Parse Error:|(?:^|\s)ERROR:|FAIL:',text) or (marker and marker not in text):
            raise RuntimeError(f'{name} failed, exit={proc.returncode}, marker={marker}')
    run('phase4-import',['--headless','--editor','--import'],'')
    run('phase4-unit',['--headless','--fixed-fps','60','--quit-after','4000','--script','res://tests/phase4/test_phase4.gd','--','--phase4-test'],'PHASE4_UNIT_RESULT:')
    run('phase4-smoke',['--headless','--fixed-fps','60','--quit-after','1800','res://scenes/phase4.tscn','--','--phase4-smoke'],'PHASE4_SMOKE_READY')
    if not args.skip_matches:
        for mode in ['field','classic']:
            for arena in ['toy_home','warehouse','garden']:
                run(f'phase4-{mode}-{arena}',['--headless','--fixed-fps','60','--quit-after','150000','res://scenes/phase4.tscn','--','--phase4-autoplay',f'--map={arena}',f'--mode={mode}'],'PHASE4_AUTOPLAY_RESULT:',120)
    if args.capture:
        run('phase4-render',['--audio-driver','Dummy','--rendering-method','gl_compatibility','res://scenes/phase4.tscn','--','--capture-phase4'],'PHASE4_SMOKE_READY')
        for name in ['00_menu','01_draw','02_lounge','03_reveal','04_swing','05_settings']:
            if not (records/f'phase4_{name}.png').is_file(): raise RuntimeError(f'Missing capture {name}')
    print('PHASE4_SUITE_PASS: engine tests, not a human playtest or hardware benchmark.')
    return 0

if __name__ == '__main__':
    try: raise SystemExit(main())
    except (RuntimeError,subprocess.TimeoutExpired,FileNotFoundError) as exc:
        print(f'FAIL: {exc}',file=sys.stderr)
        raise SystemExit(1)
