#!/usr/bin/env python3
"""Real engine tests, inherited hit predicates, all-map matches and optional GPU evidence."""
from __future__ import annotations
import argparse,json,os,re,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
MAPS=['toy_manor','sugar_market','starlight_arcade','pocket_station','toy_home','warehouse','garden']
def main():
    p=argparse.ArgumentParser();p.add_argument('--godot',default=os.environ.get('GODOT_BIN','godot'));p.add_argument('--matches',action='store_true');p.add_argument('--capture',action='store_true');a=p.parse_args()
    out=ROOT/'ci-artifacts';out.mkdir(exist_ok=True)
    def run(name,args,marker='',limit=240):
        r=subprocess.run([a.godot,'--path',str(ROOT),'--audio-driver','Dummy',*args],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=limit,env=dict(os.environ,GODOT_SILENCE_ROOT_WARNING='1'))
        text=r.stdout+r.stderr;(out/(name+'.log')).write_text(text,encoding='utf-8');print(text,flush=True)
        if r.returncode or (marker and marker not in text) or re.search(r'SCRIPT ERROR:|Parse Error:|Shader compilation failed|(?:^|\s)ERROR:|FAIL:',text):raise RuntimeError(name+' failed')
        return text
    run('world19-import',['--headless','--editor','--import','--quit'])
    run('world19-unit',['--headless','--script','res://tests/world19/test_world.gd','--','--quality-test'],'WORLD19_UNIT_RESULT:')
    run('world19-sync',['--headless','--script','res://tests/smash/test_sync.gd','--','--quality-test','--world19'],'SYNC_UNIT_RESULT: 94 checks, 0 failures')
    run('world19-entry',['--headless','--quit-after','360','res://scenes/phase19.tscn','--','--phase4-smoke'],'PHASE4_SMOKE_READY')
    if a.matches:
        results=[]
        for mode in ['field','classic']:
            for mid in MAPS:
                t=run('world19-'+mode+'-'+mid,['--headless','--fixed-fps','60','--quit-after','150000','res://scenes/phase19.tscn','--','--phase4-autoplay','--map='+mid,'--mode='+mode],'PHASE4_AUTOPLAY_RESULT:',300)
                d=json.loads(re.search(r'PHASE4_AUTOPLAY_RESULT: (\{.*\})',t).group(1));assert d['rounds']==4 and d['map']==mid and d['mode']==mode;results.append(d)
        (out/'world19-matches.json').write_text(json.dumps(results,indent=2)+'\n')
    if a.capture:
        run('world19-render',['--rendering-method','gl_compatibility','--fixed-fps','30','--script','res://tests/world19/capture.gd','--','--quality-test'],'WORLD19_CAPTURE_PASS: 26 images',600)
        for name in [m+'_'+s for m in MAPS[1:] for s in ['before','after','full','near']]+['manor_preserved','options']:
            assert (out/('world19_'+name+'.png')).stat().st_size>1000,name
    print('WORLD19_SUITE_PASS')
if __name__=='__main__':
    try:main()
    except (OSError,RuntimeError,AssertionError,ValueError,subprocess.TimeoutExpired) as e:print('FAIL:',e,file=sys.stderr);sys.exit(1)
