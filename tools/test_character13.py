#!/usr/bin/env python3
"""Engine checks and staged mesh/rig evidence; no art-quality or human-comfort claims."""
from __future__ import annotations
import argparse, json, os, re, subprocess, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
MAPS=['toy_manor','toy_home','warehouse','garden','sugar_market','starlight_arcade','pocket_station']
def main():
    p=argparse.ArgumentParser()
    p.add_argument('--godot',default=os.environ.get('GODOT_BIN','godot'))
    p.add_argument('--matches',action='store_true');p.add_argument('--capture',action='store_true')
    p.add_argument('--rebuild',action='store_true')
    a=p.parse_args();out=ROOT/'ci-artifacts';out.mkdir(exist_ok=True)
    def run(name,args,marker,limit=180):
        r=subprocess.run([a.godot,'--path',str(ROOT),'--audio-driver','Dummy',*args],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=limit,env=dict(os.environ,GODOT_SILENCE_ROOT_WARNING='1'))
        text=r.stdout+r.stderr;(out/(name+'.log')).write_text(text,encoding='utf-8');print(text,flush=True)
        if r.returncode or (marker and marker not in text) or re.search(r'SCRIPT ERROR:|Parse Error:|Shader compilation failed|(?:^|\s)ERROR:|FAIL:',text):raise RuntimeError(name+' failed')
        return text
    if a.rebuild or not (ROOT/'assets/character13/buddy_rig.scn').exists():
        run('character-build',['--headless','--script','res://tools/build_character13.gd'],'CHARACTER_BUILD_PASS')
    run('character-import',['--headless','--editor','--import'],'')
    run('character-unit',['--headless','--fixed-fps','60','--script','res://tests/character13/test_character.gd','--','--quality-test'],'CHARACTER_UNIT_RESULT: 125 checks, 0 failures')
    run('character-sync',['--headless','--fixed-fps','60','--script','res://tests/smash/test_sync.gd','--','--quality-test','--character13'],'SYNC_UNIT_RESULT: 94 checks, 0 failures')
    run('character-entry',['--headless','--fixed-fps','60','--quit-after','360','--','--phase4-smoke'],'PHASE4_SMOKE_READY')
    if a.matches:
        results=[]
        for mode in ['field','classic']:
            for map_id in MAPS:
                text=run('character-'+mode+'-'+map_id,['--headless','--fixed-fps','60','--quit-after','150000','res://scenes/phase13.tscn','--','--phase4-autoplay','--map='+map_id,'--mode='+mode],'PHASE4_AUTOPLAY_RESULT:')
                data=json.loads(re.search(r'PHASE4_AUTOPLAY_RESULT: (\{.*\})',text).group(1))
                if data['rounds']!=4 or data['map']!=map_id or data['mode']!=mode:raise RuntimeError('Incomplete match')
                results.append(data)
        (out/'character-matches.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8')
    if a.capture:
        run('character-render',['--rendering-method','gl_compatibility','--fixed-fps','30','--script','res://tests/character13/capture.gd','--','--quality-test'],'CHARACTER_CAPTURE_PASS',300)
        expected=['comparison','front','back','a_pose','ready','game','workshop','reaction']
        for tag in expected:
            f=out/('character13_'+tag+'.png')
            if not f.is_file() or f.stat().st_size<1000:raise RuntimeError('Missing real render '+tag)
    print('CHARACTER_SUITE_PASS: native mesh/rig and game regressions; not a human art or GPU benchmark.')
if __name__=='__main__':
    try:main()
    except (RuntimeError,OSError,ValueError,subprocess.TimeoutExpired) as e:print('FAIL:',e,file=sys.stderr);sys.exit(1)
