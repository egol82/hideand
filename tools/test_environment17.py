#!/usr/bin/env python3
"""Pinned-engine art/authority checks and real same-light comparisons; no fake render evidence."""
from __future__ import annotations
import argparse, json, os, re, subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
MAPS = ['toy_manor','toy_home','warehouse','garden','sugar_market','starlight_arcade','pocket_station']
def main():
    p=argparse.ArgumentParser();p.add_argument('--godot',default=os.environ.get('GODOT_BIN','godot'))
    p.add_argument('--matches',action='store_true');p.add_argument('--capture',action='store_true')
    a=p.parse_args();out=ROOT/'ci-artifacts';out.mkdir(exist_ok=True)
    def run(name,args,marker='',limit=240):
        r=subprocess.run([a.godot,'--path',str(ROOT),'--audio-driver','Dummy',*args],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=limit,env=dict(os.environ,GODOT_SILENCE_ROOT_WARNING='1'))
        text=r.stdout+r.stderr;(out/(name+'.log')).write_text(text,encoding='utf-8');print(text,flush=True)
        if r.returncode or (marker and marker not in text) or re.search(r'SCRIPT ERROR:|Parse Error:|Shader compilation failed|(?:^|\s)ERROR:|FAIL:',text):
            raise RuntimeError(f'{name} failed (exit={r.returncode}, marker={marker in text})')
        return text
    run('environment17-import',['--headless','--editor','--import'],limit=600)
    t=run('environment17-unit',['--headless','--script','res://tests/environment17/test_environment.gd','--','--quality-test'],'ENVIRONMENT17_UNIT_RESULT:')
    if not re.search(r'ENVIRONMENT17_UNIT_RESULT: \d+ checks, 0 failures',t):raise RuntimeError('Unit assertions failed')
    run('environment17-sync',['--headless','--script','res://tests/smash/test_sync.gd','--','--quality-test','--environment17'],'SYNC_UNIT_RESULT: 94 checks, 0 failures')
    run('environment17-entry',['--headless','--quit-after','360','--','--phase4-smoke'],'PHASE4_SMOKE_READY')
    run('environment17-export',['--headless','--script','res://tools/export_environment17.gd'],'ENVIRONMENT17_EXPORT_PASS: 16')
    if a.matches:
        matches=[]
        for mode in ['field','classic']:
            for map_id in MAPS:
                text=run('environment17-'+mode+'-'+map_id,['--headless','--fixed-fps','60','--quit-after','150000','res://scenes/phase17.tscn','--','--phase4-autoplay','--map='+map_id,'--mode='+mode],'PHASE4_AUTOPLAY_RESULT:',300)
                data=json.loads(re.search(r'PHASE4_AUTOPLAY_RESULT: (\{.*\})',text).group(1))
                if data['rounds']!=4 or data['map']!=map_id or data['mode']!=mode:raise RuntimeError('Incomplete match')
                matches.append(data)
        (out/'environment17-matches.json').write_text(json.dumps(matches,indent=2)+'\n',encoding='utf-8')
    if a.capture:
        run('environment17-render',['--rendering-method','gl_compatibility','--fixed-fps','30','--script','res://tests/environment17/capture.gd','--','--quality-test'],'ENVIRONMENT17_CAPTURE_PASS: 15',1800)
        tags=[tag+'_'+suffix for tag in ['fps','living','sofa','window','cupboard','kitchen','bedroom'] for suffix in ['before','after']]+['options']
        for tag in tags:
            f=out/('environment17_'+tag+'.png')
            if not f.is_file() or f.stat().st_size<1000:raise RuntimeError('Missing actual capture '+tag)
    print('ENVIRONMENT17_SUITE_PASS')
if __name__=='__main__':
    try:main()
    except (OSError,ValueError,RuntimeError,subprocess.TimeoutExpired) as e:print('FAIL:',e,file=sys.stderr);sys.exit(1)
