#!/usr/bin/env python3
"""Pinned-engine motion/IK/contact checks. Captures are staged; match completion is not art QA."""
from __future__ import annotations
import argparse,json,os,re,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
MAPS=['toy_manor','toy_home','warehouse','garden','sugar_market','starlight_arcade','pocket_station']
def main():
    p=argparse.ArgumentParser();p.add_argument('--godot',default=os.environ.get('GODOT_BIN','godot'))
    p.add_argument('--matches',action='store_true');p.add_argument('--capture',action='store_true');p.add_argument('--video',action='store_true')
    a=p.parse_args();out=ROOT/'ci-artifacts';out.mkdir(exist_ok=True)
    def run(name,args,marker='',limit=240):
        r=subprocess.run([a.godot,'--path',str(ROOT),'--audio-driver','Dummy',*args],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=limit,env=dict(os.environ,GODOT_SILENCE_ROOT_WARNING='1'))
        text=r.stdout+r.stderr;(out/(name+'.log')).write_text(text,encoding='utf-8');print(text,flush=True)
        if r.returncode or (marker and marker not in text) or re.search(r'SCRIPT ERROR:|Parse Error:|Shader compilation failed|(?:^|\s)ERROR:|FAIL:',text):raise RuntimeError(f'{name} failed (exit={r.returncode}, marker={marker in text})')
        return text
    run('animation16-import',['--headless','--editor','--import'],limit=300)
    run('animation16-unit',['--headless','--script','res://tests/animation16/test_animation.gd','--','--quality-test'],'ANIMATION16_UNIT_RESULT:')
    run('animation16-ground',['--headless','--script','res://tests/animation16/test_ground.gd','--','--quality-test'],'ANIMATION16_GROUND_RESULT:')
    run('animation16-sync',['--headless','--script','res://tests/smash/test_sync.gd','--','--quality-test','--animation16'],'SYNC_UNIT_RESULT: 94 checks, 0 failures')
    run('animation16-entry',['--headless','--quit-after','360','--','--phase4-smoke'],'PHASE4_SMOKE_READY')
    run('animation16-export',['--headless','--script','res://tools/export_animation16.gd'],'ANIMATION16_EXPORT_PASS')
    if a.matches:
        results=[]
        for mode in ['field','classic']:
            for map_id in MAPS:
                text=run('animation16-'+mode+'-'+map_id,['--headless','--fixed-fps','60','--quit-after','150000','res://scenes/phase16.tscn','--','--phase4-autoplay','--map='+map_id,'--mode='+mode],'PHASE4_AUTOPLAY_RESULT:',240)
                data=json.loads(re.search(r'PHASE4_AUTOPLAY_RESULT: (\{.*\})',text).group(1))
                if data['rounds']!=4 or data['map']!=map_id or data['mode']!=mode:raise RuntimeError('Incomplete match')
                results.append(data)
        (out/'animation16-matches.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8')
    if a.capture:
        run('animation16-render',['--rendering-method','gl_compatibility','--fixed-fps','30','--script','res://tests/animation16/capture.gd','--','--quality-test',*(['--video'] if a.video else [])],'ANIMATION16_CAPTURE_PASS',600)
        tags=['pose_'+s for s in ['idle','walk','run','hide','peek','windup','attack','hit','recover','ko']]+['live_manor','live_walk','live_run','contact_0','contact_1','contact_2']
        for tag in tags:
            f=out/('animation16_'+tag+'.png')
            if not f.is_file() or f.stat().st_size<1000:raise RuntimeError('Missing actual capture '+tag)
    print('ANIMATION16_SUITE_PASS')
if __name__=='__main__':
    try:main()
    except (OSError,ValueError,RuntimeError,subprocess.TimeoutExpired) as e:print('FAIL:',e,file=sys.stderr);sys.exit(1)
