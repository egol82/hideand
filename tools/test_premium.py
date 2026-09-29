#!/usr/bin/env python3
"""Run real-engine proportional geometry, native UI, existing contact tests and optional evidence."""
from __future__ import annotations
import argparse, json, os, re, subprocess, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
MAPS=['toy_manor','toy_home','warehouse','garden','sugar_market','starlight_arcade','pocket_station']
def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--godot',default=os.environ.get('GODOT_BIN','godot'))
    parser.add_argument('--matches',action='store_true'); parser.add_argument('--capture',action='store_true')
    a=parser.parse_args(); out=ROOT/'ci-artifacts'; out.mkdir(exist_ok=True)
    def run(name,args,marker='',limit=150):
        p=subprocess.run([a.godot,'--path',str(ROOT),'--audio-driver','Dummy',*args],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=limit,env=dict(os.environ,GODOT_SILENCE_ROOT_WARNING='1'))
        text=p.stdout+p.stderr; (out/(name+'.log')).write_text(text,encoding='utf-8'); print(text,flush=True)
        if p.returncode or (marker and marker not in text) or re.search(r'SCRIPT ERROR:|Parse Error:|Shader compilation failed|(?:^|\s)ERROR:|FAIL:',text): raise RuntimeError(name+' failed')
        return text
    run('premium-import',['--headless','--editor','--import'])
    run('premium-unit',['--headless','--fixed-fps','60','--script','res://tests/premium/test_premium.gd','--','--quality-test'],'PREMIUM_UNIT_RESULT: 133 checks, 0 failures')
    run('premium-sync',['--headless','--fixed-fps','60','--script','res://tests/smash/test_sync.gd','--','--quality-test','--premium'],'SYNC_UNIT_RESULT: 94 checks, 0 failures')
    run('premium-entry',['--headless','--fixed-fps','60','--quit-after','360','--','--phase4-smoke'],'PHASE4_SMOKE_READY')
    if a.matches:
        results=[]
        for mode in ['field','classic']:
            for m in MAPS:
                text=run('premium-'+mode+'-'+m,['--headless','--fixed-fps','60','--quit-after','150000','res://scenes/phase12.tscn','--','--phase4-autoplay','--map='+m,'--mode='+mode],'PHASE4_AUTOPLAY_RESULT:')
                data=json.loads(re.search(r'PHASE4_AUTOPLAY_RESULT: (\{.*\})',text).group(1))
                if data['rounds']!=4 or data['map']!=m or data['mode']!=mode: raise RuntimeError('Incomplete match')
                results.append(data)
        (out/'premium-matches.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8')
    if a.capture:
        run('premium-render',['--rendering-method','gl_compatibility','--fixed-fps','60','--script','res://tests/premium/capture.gd','--','--quality-test'],'PREMIUM_CAPTURE_PASS',280)
        run('premium-baseline',['--rendering-method','gl_compatibility','--fixed-fps','60','--script','res://tests/premium/capture.gd','--','--quality-test','--baseline'],'PREMIUM_BASELINE_PASS',120)
        if len(list(out.glob('premium_*.png')))!=12: raise RuntimeError('Expected twelve rendered views')
    print('PREMIUM_SUITE_PASS: actual engine checks; not manual art/comfort/GPU review.')
if __name__=='__main__':
    try: main()
    except (RuntimeError,OSError,ValueError,subprocess.TimeoutExpired) as e: print('FAIL:',e,file=sys.stderr); sys.exit(1)
