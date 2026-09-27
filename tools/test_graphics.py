#!/usr/bin/env python3
"""Run graphics invariants and optional real renderer evidence; no quality/FPS guarantees."""
import argparse, os, re, subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--capture',action='store_true'); ap.add_argument('--godot',default=os.environ.get('GODOT_BIN','godot')); a=ap.parse_args()
    out=ROOT/'ci-artifacts'; out.mkdir(exist_ok=True)
    def run(args,name,marker,limit=150):
        p=subprocess.run([a.godot,'--path',str(ROOT),'--audio-driver','Dummy',*args],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=limit,env=dict(os.environ,GODOT_SILENCE_ROOT_WARNING='1'))
        text=p.stdout+p.stderr; (out/name).write_text(text,encoding='utf-8'); print(text)
        if p.returncode or marker not in text or re.search(r'SCRIPT ERROR:|Parse Error:|Shader compilation failed|(?:^|\s)ERROR:|FAIL:',text): raise RuntimeError('Failed: '+name)
    run(['--headless','--fixed-fps','60','--quit-after','4000','--script','res://tests/graphics/test_graphics.gd','--','--quality-test'],'graphics-tests.log','GRAPHICS_UNIT_RESULT:')
    run(['--headless','--fixed-fps','60','--quit-after','400','res://scenes/phase6.tscn','--','--phase4-smoke'],'graphics-entry.log','PHASE4_SMOKE_READY')
    if a.capture:
        run(['--rendering-method','gl_compatibility','--fixed-fps','60','--quit-after','2500','--script','res://tests/graphics/capture.gd','--','--quality-test'],'graphics-render.log','GRAPHICS_CAPTURE_PASS',210)
        for tag in ['menu','workshop','hero','lounge','menu_ko','workshop_ko','garden']:
            p=out/f'phase6_{tag}.png'
            if not p.is_file() or p.stat().st_size<1000: raise RuntimeError('Missing actual render: '+tag)
    print('GRAPHICS_SUITE_PASS: real engine invariants; not a human playtest or hardware benchmark.')
if __name__=='__main__':
    try: main()
    except (RuntimeError,subprocess.TimeoutExpired,FileNotFoundError) as e:
        print('FAIL:',e,file=sys.stderr);sys.exit(1)
