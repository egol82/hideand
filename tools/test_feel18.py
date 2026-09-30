#!/usr/bin/env python3
"""Actual Godot state/contact/match and optional renderer verification; never image substitutes."""
from __future__ import annotations
import argparse,json,os,re,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
MAPS=['toy_manor','toy_home','warehouse','garden','sugar_market','starlight_arcade','pocket_station']
def main():
    p=argparse.ArgumentParser();p.add_argument('--godot',default=os.environ.get('GODOT_BIN','godot'))
    p.add_argument('--matches',action='store_true');p.add_argument('--capture',action='store_true');p.add_argument('--video',action='store_true');p.add_argument('--skip-import',action='store_true')
    a=p.parse_args();out=ROOT/'ci-artifacts';out.mkdir(exist_ok=True)
    def run(name,args,marker='',limit=300):
        r=subprocess.run([a.godot,'--path',str(ROOT),'--audio-driver','Dummy',*args],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=limit,env=dict(os.environ,GODOT_SILENCE_ROOT_WARNING='1'))
        text=r.stdout+r.stderr;(out/(name+'.log')).write_text(text,encoding='utf-8');print(text,flush=True)
        if r.returncode or (marker and marker not in text) or re.search(r'SCRIPT ERROR:|Parse Error:|Shader compilation failed|(?:^|\s)ERROR:|FAIL:',text):raise RuntimeError(f'{name} failed (exit {r.returncode})')
        return text
    if not a.skip_import:run('feel18-import',['--headless','--editor','--import'],limit=600)
    t=run('feel18-unit',['--headless','--script','res://tests/feel18/test_feel.gd','--','--quality-test'],'FEEL18_UNIT_RESULT:')
    if not re.search(r'FEEL18_UNIT_RESULT: \d+ checks, 0 failures',t):raise RuntimeError('Failed assertions')
    run('feel18-sync',['--headless','--script','res://tests/smash/test_sync.gd','--','--quality-test','--feel18'],'SYNC_UNIT_RESULT: 94 checks, 0 failures')
    run('feel18-entry',['--headless','--quit-after','360','--','--phase4-smoke'],'PHASE4_SMOKE_READY')
    if a.matches:
        results=[]
        for mode in ['field','classic']:
            for map_id in MAPS:
                text=run('feel18-'+mode+'-'+map_id,['--headless','--fixed-fps','60','--quit-after','150000','res://scenes/phase18.tscn','--','--phase4-autoplay','--map='+map_id,'--mode='+mode],'PHASE4_AUTOPLAY_RESULT:',360)
                data=json.loads(re.search(r'PHASE4_AUTOPLAY_RESULT: (\{.*\})',text).group(1))
                if data['rounds']!=4 or data['map']!=map_id or data['mode']!=mode:raise RuntimeError('Incomplete match')
                results.append(data)
        (out/'feel18-matches.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8')
    if a.capture:
        run('feel18-render',['--rendering-method','gl_compatibility','--fixed-fps','30','--script','res://tests/feel18/capture.gd','--','--quality-test',*(['--video'] if a.video else [])],'FEEL18_CAPTURE_PASS',900)
        for tag in ['before_contact','after_contact','quick','balanced','heavy','finish','blocked','miss','manor','options']:
            f=out/('feel18_'+tag+'.png')
            if not f.is_file() or f.stat().st_size<1000:raise RuntimeError('Missing actual image '+tag)
    print('FEEL18_SUITE_PASS')
if __name__=='__main__':
    try:main()
    except (OSError,ValueError,RuntimeError,subprocess.TimeoutExpired) as e:print('FAIL:',e,file=sys.stderr);sys.exit(1)
