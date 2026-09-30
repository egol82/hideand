#!/usr/bin/env python3
"""Targeted outdoor-map integration, unchanged contact predicates and twenty full matches.
No automatic re-run of every historical suite. Real rendering is a separate opt-in operation.
"""
from __future__ import annotations
import argparse,json,os,re,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OLD=['toy_manor','sugar_market','starlight_arcade','pocket_station','toy_home','warehouse','garden']
NEW=['pine_hollow','reedwater_bend','amber_canyon']
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--godot',default=os.environ.get('GODOT_BIN','godot'))
    for flag in ['matches','capture','skip-import']:ap.add_argument('--'+flag,action='store_true')
    a=ap.parse_args();out=ROOT/'ci-artifacts';out.mkdir(exist_ok=True)
    def run(name,args,marker='',limit=300):
        p=subprocess.run([a.godot,'--path',str(ROOT),'--audio-driver','Dummy',*args],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=limit,env=dict(os.environ,GODOT_SILENCE_ROOT_WARNING='1'))
        text=p.stdout+p.stderr;(out/(name+'.log')).write_text(text,encoding='utf-8');print(text,flush=True)
        if p.returncode or (marker and marker not in text) or re.search(r'SCRIPT ERROR:|Parse Error:|Shader compilation failed|(?:^|\s)ERROR:|FAIL:',text):raise RuntimeError(name+' failed')
        return text
    if not a.skip_import:run('outdoor20-import',['--headless','--editor','--import','--quit'])
    t=run('outdoor20-unit',['--headless','--script','res://tests/outdoor20/test_outdoors.gd','--','--quality-test'],'OUTDOOR20_UNIT_RESULT:')
    if not re.search(r'OUTDOOR20_UNIT_RESULT: \d+ checks, 0 failures',t):raise RuntimeError('Assertions failed')
    run('outdoor20-sync',['--headless','--script','res://tests/smash/test_sync.gd','--','--quality-test','--outdoor20'],'SYNC_UNIT_RESULT: 94 checks, 0 failures')
    run('outdoor20-entry',['--headless','--quit-after','360','--','--phase4-smoke'],'PHASE4_SMOKE_READY')
    if a.matches:
        results=[]
        for mode in ['field','classic']:
            for mid in OLD+NEW:
                t=run('outdoor20-'+mode+'-'+mid,['--headless','--fixed-fps','60','--quit-after','150000','res://scenes/phase20.tscn','--','--phase4-autoplay','--map='+mid,'--mode='+mode],'PHASE4_AUTOPLAY_RESULT:',300)
                d=json.loads(re.search(r'PHASE4_AUTOPLAY_RESULT: (\{.*\})',t).group(1))
                if (d['rounds'],d['map'],d['mode'])!=(4,mid,mode):raise RuntimeError('Incomplete map/mode run '+mid)
                results.append(d)
        (out/'outdoor20-matches.json').write_text(json.dumps(results,indent=2)+'\n')
    if a.capture:
        run('outdoor20-render',['--rendering-method','gl_compatibility','--fixed-fps','30','--script','res://tests/outdoor20/capture.gd','--','--quality-test'],'OUTDOOR20_CAPTURE_PASS',500)
        for mid in NEW:
            for tag in ['game','plan','contact','near']:
                if (out/('outdoor20_'+mid+'_'+tag+'.png')).stat().st_size<1000:raise RuntimeError('Missing render')
    print('OUTDOOR20_SUITE_PASS')
if __name__=='__main__':
    try:main()
    except (OSError,ValueError,RuntimeError,subprocess.TimeoutExpired) as e:print('FAIL:',e,file=sys.stderr);sys.exit(1)
