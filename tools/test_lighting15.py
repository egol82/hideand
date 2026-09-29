#!/usr/bin/env python3
"""Actual material/state checks and same-light renders; no hardware quality/FPS claims."""
from __future__ import annotations
import argparse, json, os, re, subprocess, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
MAPS=['toy_manor','toy_home','warehouse','garden','sugar_market','starlight_arcade','pocket_station']
def main():
    p=argparse.ArgumentParser()
    p.add_argument('--godot',default=os.environ.get('GODOT_BIN','godot'))
    p.add_argument('--matches',action='store_true');p.add_argument('--capture',action='store_true')
    a=p.parse_args();out=ROOT/'ci-artifacts';out.mkdir(exist_ok=True)
    def run(name,args,marker,limit=240):
        r=subprocess.run([a.godot,'--path',str(ROOT),'--audio-driver','Dummy',*args],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=limit,env=dict(os.environ,GODOT_SILENCE_ROOT_WARNING='1'))
        text=r.stdout+r.stderr;(out/(name+'.log')).write_text(text,encoding='utf-8');print(text,flush=True)
        if r.returncode or (marker and marker not in text) or re.search(r'SCRIPT ERROR:|Parse Error:|Shader compilation failed|(?:^|\s)ERROR:|FAIL:',text):raise RuntimeError(name+' failed')
        return text
    run('lighting15-import',['--headless','--editor','--import'],'')
    unit=run('lighting15-unit',['--headless','--fixed-fps','60','--script','res://tests/lighting15/test_lighting.gd','--','--quality-test'],'LIGHTING15_UNIT_RESULT:')
    if not re.search(r'LIGHTING15_UNIT_RESULT: \d+ checks, 0 failures',unit):raise RuntimeError('Assertions did not pass')
    run('lighting15-sync',['--headless','--fixed-fps','60','--script','res://tests/smash/test_sync.gd','--','--quality-test','--lighting15'],'SYNC_UNIT_RESULT: 94 checks, 0 failures')
    run('lighting15-entry',['--headless','--fixed-fps','60','--quit-after','360','--','--phase4-smoke'],'PHASE4_SMOKE_READY')
    if a.matches:
        results=[]
        for mode in ['field','classic']:
            for map_id in MAPS:
                text=run('lighting15-'+mode+'-'+map_id,['--headless','--fixed-fps','60','--quit-after','150000','res://scenes/phase15.tscn','--','--phase4-autoplay','--map='+map_id,'--mode='+mode],'PHASE4_AUTOPLAY_RESULT:')
                data=json.loads(re.search(r'PHASE4_AUTOPLAY_RESULT: (\{.*\})',text).group(1))
                if data['rounds']!=4 or data['map']!=map_id or data['mode']!=mode:raise RuntimeError('Incomplete match')
                results.append(data)
        (out/'lighting15-matches.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8')
    if a.capture:
        run('lighting15-render',['--rendering-method','gl_compatibility','--fixed-fps','30','--script','res://tests/lighting15/capture.gd','--','--quality-test'],'LIGHTING15_CAPTURE_PASS',420)
        expected=['old_room','direct_room','gi_room','gi_empty','gi_feet','gi_upper','gi_menu','probe_body_on','probe_body_off','probe_weapon_on','probe_weapon_off','probe_hand_on','probe_hand_off']
        for tag in expected:
            f=out/('lighting15_'+tag+'.png')
            if not f.is_file() or f.stat().st_size<1000:raise RuntimeError('Missing real render '+tag)
    print('LIGHTING15_SUITE_PASS: material/state invariants and actual engine; not human/GPU validation.')
if __name__=='__main__':
    try:main()
    except (RuntimeError,OSError,ValueError,subprocess.TimeoutExpired) as e:print('FAIL:',e,file=sys.stderr);sys.exit(1)
