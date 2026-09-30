#!/usr/bin/env python3
"""Scoped Pine21 tests. Captures/matches are actual engine fixtures, not human QA."""
from __future__ import annotations
import argparse, json, os, re, subprocess, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
MAPS=['toy_manor','toy_home','warehouse','garden','sugar_market','starlight_arcade','pocket_station','pine_hollow','reedwater_bend','amber_canyon']
def main():
    p=argparse.ArgumentParser();p.add_argument('--godot',default=os.environ.get('GODOT_BIN','godot'))
    for flag in ['capture','matches','skip-import']:p.add_argument('--'+flag,action='store_true')
    a=p.parse_args();out=ROOT/'ci-artifacts';out.mkdir(exist_ok=True)
    def run(name,args,marker,limit=240):
        cmd=[a.godot,'--path',str(ROOT),'--audio-driver','Dummy',*args]
        r=subprocess.run(cmd,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=limit,env=dict(os.environ,GODOT_SILENCE_ROOT_WARNING='1'))
        text=r.stdout+r.stderr;(out/(name+'.log')).write_text(text,encoding='utf-8');print(text,flush=True)
        if r.returncode or marker not in text or re.search(r'SCRIPT ERROR:|Parse Error:|(?:^|\s)ERROR:|FAIL:',text):raise RuntimeError(name+' failed')
        return text
    if not a.skip_import:run('pine21-import',['--headless','--editor','--import'],'')
    run('pine21-unit',['--headless','--script','res://tests/pine21/test_pine.gd','--','--quality-test'],'PINE21_UNIT_RESULT: 126 checks, 0 failures')
    run('pine21-sync',['--headless','--script','res://tests/smash/test_sync.gd','--','--quality-test','--pine21'],'SYNC_UNIT_RESULT: 94 checks, 0 failures')
    run('pine21-entry',['--headless','--quit-after','360','--','--phase4-smoke'],'PHASE4_SMOKE_READY')
    if a.matches:
        rows=[]
        for mode in ['field','classic']:
            for mid in MAPS:
                text=run('pine21-'+mode+'-'+mid,['--headless','--fixed-fps','60','--quit-after','150000','res://scenes/phase21.tscn','--','--phase4-autoplay','--map='+mid,'--mode='+mode],'PHASE4_AUTOPLAY_RESULT:',300)
                d=json.loads(re.search(r'PHASE4_AUTOPLAY_RESULT: (\{.*\})',text).group(1))
                if (d['map'],d['mode'],d['rounds'])!=(mid,mode,4):raise RuntimeError('Incomplete match')
                rows.append(d)
        (out/'pine21-matches.json').write_text(json.dumps(rows,indent=2)+'\n')
    if a.capture:
        run('pine21-render',['--rendering-method','gl_compatibility','--fixed-fps','30','--script','res://tests/pine21/capture.gd','--','--quality-test'],'PINE21_CAPTURE_PASS',300)
        for name in ['leaves','bush','hidden','expired']:
            if (out/('pine21_'+name+'.png')).stat().st_size<1000:raise RuntimeError('Missing render '+name)
    print('PINE21_SUITE_PASS')
if __name__=='__main__':
    try:main()
    except (OSError,ValueError,RuntimeError,subprocess.TimeoutExpired) as e:print('FAIL:',e,file=sys.stderr);sys.exit(1)
