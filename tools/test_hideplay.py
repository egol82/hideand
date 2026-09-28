#!/usr/bin/env python3
"""Actual Godot traversal, hiding/search, preserved combat sync and staged rendering checks."""
from __future__ import annotations
import argparse, json, os, re, subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
MAPS = ['toy_manor','toy_home','warehouse','garden','sugar_market','starlight_arcade','pocket_station']
def main() -> None:
    p=argparse.ArgumentParser()
    p.add_argument('--godot',default=os.environ.get('GODOT_BIN','godot'))
    p.add_argument('--matches',action='store_true'); p.add_argument('--capture',action='store_true'); p.add_argument('--video',action='store_true')
    a=p.parse_args(); out=ROOT/'ci-artifacts'; out.mkdir(exist_ok=True)
    def run(name: str,args: list[str],marker: str='',limit: int=180) -> str:
        result=subprocess.run([a.godot,'--path',str(ROOT),'--audio-driver','Dummy',*args],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=limit,env=dict(os.environ,GODOT_SILENCE_ROOT_WARNING='1'))
        text=result.stdout+result.stderr; (out/(name+'.log')).write_text(text,encoding='utf-8'); print(text,flush=True)
        if result.returncode or (marker and marker not in text) or re.search(r'SCRIPT ERROR:|Parse Error:|Shader compilation failed|(?:^|\s)ERROR:|FAIL:',text):
            raise RuntimeError(name+' failed; inspect the saved log')
        return text
    run('hideplay-import',['--headless','--editor','--import'])
    run('hideplay-unit',['--headless','--fixed-fps','60','--script','res://tests/hideplay/test_hideplay.gd','--','--quality-test'],'HIDEPLAY_UNIT_RESULT: 257 checks, 0 failures')
    run('hideplay-sync',['--headless','--fixed-fps','60','--script','res://tests/smash/test_sync.gd','--','--quality-test','--hideplay'],'SYNC_UNIT_RESULT: 94 checks, 0 failures')
    if a.matches:
        results=[]
        for mode in ['field','classic']:
            for name in MAPS:
                text=run('hideplay-'+mode+'-'+name,['--headless','--fixed-fps','60','--quit-after','150000','res://scenes/phase11.tscn','--','--phase4-autoplay','--map='+name,'--mode='+mode],'PHASE4_AUTOPLAY_RESULT:')
                data=json.loads(re.search(r'PHASE4_AUTOPLAY_RESULT: (\{.*\})',text).group(1))
                if data['rounds']!=4 or data['map']!=name or data['mode']!=mode: raise RuntimeError('Wrong/incomplete match '+name)
                results.append(data)
        (out/'hideplay-matches.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8')
    if a.capture:
        run('hideplay-render',['--rendering-method','gl_compatibility','--fixed-fps','60','--script','res://tests/hideplay/capture.gd','--','--quality-test']+(['--video'] if a.video else []),'HIDEPLAY_CAPTURE_PASS',500)
        images=list(out.glob('hideplay_0*.png'))
        if len(images)!=9 or any(f.stat().st_size<1000 for f in images): raise RuntimeError('Missing rendered views')
        if a.video:
            frames=list((out/'hideplay_frames').glob('*.png'))
            if len(frames)!=180: raise RuntimeError('Incomplete staircase frames')
    print('HIDEPLAY_SUITE_PASS: engine tests/staged footage, not human fun/comfort or GPU performance certification.')
if __name__=='__main__':
    try: main()
    except (OSError,ValueError,RuntimeError,subprocess.TimeoutExpired) as e:
        print('FAIL:',e,file=sys.stderr); sys.exit(1)
