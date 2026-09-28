#!/usr/bin/env python3
"""Actual hand-fit invariants, shared entry smoke, optional staged engine captures."""
import argparse, os, re, subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--godot', default=os.environ.get('GODOT_BIN', 'godot'))
    ap.add_argument('--capture', action='store_true')
    a = ap.parse_args()
    out = ROOT/'ci-artifacts'; out.mkdir(exist_ok=True)
    def run(label, args, marker, limit=180):
        p = subprocess.run([a.godot, '--path', str(ROOT), '--audio-driver', 'Dummy', *args], capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=limit, env=dict(os.environ, GODOT_SILENCE_ROOT_WARNING='1'))
        text = p.stdout+p.stderr
        (out/(label+'.log')).write_text(text, encoding='utf-8'); print(text, flush=True)
        if p.returncode or (marker and marker not in text) or re.search(r'SCRIPT ERROR:|Parse Error:|Shader compilation failed|(?:^|\s)ERROR:|FAIL:',text):
            raise RuntimeError(label+' failed')
    run('grip-import', ['--headless','--editor','--import'], '')
    run('grip-tests', ['--headless','--fixed-fps','60','--quit-after','6000','--script','res://tests/viewmodel/test_grip.gd','--','--quality-test'], 'GRIP_UNIT_RESULT:')
    run('grip-safety', ['--headless','--fixed-fps','60','--quit-after','1000','--script','res://tests/viewmodel/test_grip_safety.gd'], 'GRIP_SAFETY_RESULT:')
    run('grip-entry', ['--headless','--fixed-fps','60','--quit-after','400','res://scenes/phase8.tscn','--','--phase4-smoke'], 'PHASE4_SMOKE_READY')
    if a.capture:
        run('grip-render', ['--rendering-method','gl_compatibility','--fixed-fps','60','--quit-after','6000','--script','res://tests/viewmodel/capture.gd','--','--quality-test'], 'GRIP_CAPTURE_PASS',240)
        expected = ['sugar_market','starlight_arcade','pocket_station','long_staff','sideways'] + [s+'_'+t for s in ['quick','balanced','heavy'] for t in ['windup','active','recovery']]
        for tag in expected:
            p = out/('phase8_'+tag+'.png')
            if not p.exists() or p.stat().st_size<1000: raise RuntimeError('Missing real image '+tag)
    print('GRIP_SUITE_PASS: actual engine checks; not human grip/comfort or GPU validation.')
if __name__ == '__main__':
    try: main()
    except (OSError, RuntimeError, subprocess.TimeoutExpired) as e: print('FAIL:',e,file=sys.stderr); sys.exit(1)
