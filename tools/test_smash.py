#!/usr/bin/env python3
"""Execute actual engine assertions, startup, optional captures and final-scene autoplay."""
import argparse, json, os, re, subprocess, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def main():
    p=argparse.ArgumentParser(); p.add_argument('--godot', default=os.environ.get('GODOT_BIN','godot'))
    p.add_argument('--capture',action='store_true'); p.add_argument('--video',action='store_true'); p.add_argument('--matches',action='store_true')
    a=p.parse_args(); out=ROOT/'ci-artifacts'; out.mkdir(exist_ok=True)
    def run(name,args,marker,limit=220):
        result=subprocess.run([a.godot,'--path',str(ROOT),'--audio-driver','Dummy',*args],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=limit,env=dict(os.environ,GODOT_SILENCE_ROOT_WARNING='1'))
        text=result.stdout+result.stderr; (out/(name+'.log')).write_text(text,encoding='utf-8'); print(text,flush=True)
        if result.returncode or (marker and marker not in text) or re.search(r'SCRIPT ERROR:|Parse Error:|Shader compilation failed|(?:^|\s)ERROR:|FAIL:',text): raise RuntimeError(name+' failed')
        return text
    run('smash-import',['--headless','--editor','--import'],'')
    run('smash-tests',['--headless','--fixed-fps','60','--quit-after','12000','--script','res://tests/smash/test_smash.gd','--','--quality-test'],'SMASH_UNIT_RESULT:')
    run('smash-entry',['--headless','--fixed-fps','60','--quit-after','400','res://scenes/phase9.tscn','--','--phase4-smoke'],'PHASE4_SMOKE_READY')
    if a.matches:
        results=[]
        for mode in ['field','classic']:
            for map_id in ['toy_home','warehouse','garden','sugar_market','starlight_arcade','pocket_station']:
                text=run('smash-'+mode+'-'+map_id,['--headless','--fixed-fps','60','--quit-after','150000','res://scenes/phase9.tscn','--','--phase4-autoplay','--mode='+mode,'--map='+map_id],'PHASE4_AUTOPLAY_RESULT:')
                data=json.loads(re.search(r'PHASE4_AUTOPLAY_RESULT: (\{.*\})',text).group(1))
                if data.get('rounds')!=4 or data.get('map')!=map_id or data.get('mode')!=mode: raise RuntimeError('wrong complete match')
                results.append(data)
        (out/'smash-match-results.json').write_text(json.dumps(results,indent=2)+'\n')
    if a.capture:
        cmd=['--rendering-method','gl_compatibility','--fixed-fps','60','--quit-after','12000','--script','res://tests/smash/capture.gd','--','--quality-test']
        if a.video: cmd+=['--video']
        run('smash-render',cmd,'SMASH_CAPTURE_PASS',350)
        for tag in ['before','balanced_impact','balanced_wobble','heavy_impact','heavy_wobble','finish','blocked','reduced']:
            file=out/('phase9_'+tag+'.png')
            if not file.is_file() or file.stat().st_size<1000: raise RuntimeError('missing image '+tag)
    print('SMASH_SUITE_PASS: engine evidence, not human feel or GPU benchmark.')
if __name__=='__main__':
    try: main()
    except (OSError,ValueError,RuntimeError,subprocess.TimeoutExpired) as e: print('FAIL:',e,file=sys.stderr); sys.exit(1)
