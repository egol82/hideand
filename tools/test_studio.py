#!/usr/bin/env python3
"""Real-engine A/B/C checks, unchanged contact assertions, editable export and captures."""
import argparse, json, os, re, subprocess, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def main():
    p=argparse.ArgumentParser()
    p.add_argument('--godot',default=os.environ.get('GODOT_BIN','godot'))
    p.add_argument('--capture',action='store_true'); p.add_argument('--contacts',action='store_true')
    p.add_argument('--matches',action='store_true'); p.add_argument('--export',action='store_true')
    a=p.parse_args(); out=ROOT/'ci-artifacts'; out.mkdir(exist_ok=True)
    def run(label,args,marker='',limit=240):
        result=subprocess.run([a.godot,'--path',str(ROOT),'--audio-driver','Dummy',*args],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=limit,env=dict(os.environ,GODOT_SILENCE_ROOT_WARNING='1'))
        text=result.stdout+result.stderr
        (out/(label+'.log')).write_text(text,encoding='utf-8'); print(text,flush=True)
        if result.returncode or (marker and marker not in text) or re.search(r'SCRIPT ERROR:|Parse Error:|Shader compilation failed|(?:^|\s)ERROR:|FAIL:',text): raise RuntimeError(label+' failed')
        return text
    run('studio-import',['--headless','--editor','--import'])
    run('studio-tests',['--headless','--script','res://tests/renderlab/test_studio.gd','--','--quality-test'],'STUDIO_UNIT_RESULT: 108 checks, 0 failures')
    run('studio-sync',['--headless','--fixed-fps','60','--quit-after','12000','--script','res://tests/smash/test_sync.gd','--','--quality-test','--studio'],'SYNC_UNIT_RESULT: 94 checks, 0 failures')
    run('studio-entry',['--headless','--fixed-fps','60','--quit-after','400','res://scenes/phase10.tscn','--','--phase4-smoke'],'PHASE4_SMOKE_READY')
    if a.export:
        run('studio-export',['--headless','--script','res://tools/export_studio_room.gd','--','--quality-test'],'STUDIO_UV2_EXPORT_PASS')
        data=json.loads((out/'studio-export.json').read_text())
        if data['errors'] or data['meshes']!=421 or data['unique_unwraps']!=74: raise RuntimeError('incomplete or unexpectedly changed static export')
        run('studio-export-verify',['--headless','--script','res://tests/renderlab/test_export.gd','--','--quality-test'],'STUDIO_EXPORT_VERIFY_PASS')
    if a.matches:
        results=[]
        for mode in ['field','classic']:
            for map_id in ['toy_home','warehouse','garden','sugar_market','starlight_arcade','pocket_station']:
                text=run('studio-'+mode+'-'+map_id,['--headless','--fixed-fps','60','--quit-after','150000','res://scenes/phase10.tscn','--','--phase4-autoplay','--mode='+mode,'--map='+map_id],'PHASE4_AUTOPLAY_RESULT:')
                data=json.loads(re.search(r'PHASE4_AUTOPLAY_RESULT: (\{.*\})',text).group(1))
                if data.get('rounds')!=4 or data.get('map')!=map_id or data.get('mode')!=mode: raise RuntimeError('wrong or incomplete match')
                results.append(data)
        (out/'studio-match-results.json').write_text(json.dumps(results,indent=2)+'\n')
    if a.capture:
        run('studio-render',['--rendering-method','gl_compatibility','--fixed-fps','60','--script','res://tests/renderlab/capture.gd','--','--quality-test'],'STUDIO_CAPTURE_PASS',420)
        names=['studio_'+m+'_'+str(p) for m in ['sugar_market','starlight_arcade','pocket_station'] for p in range(3)]+['studio_detail_0','studio_detail_2']
        for name in names:
            f=out/(name+'.png')
            if not f.is_file() or f.stat().st_size<1000: raise RuntimeError('missing screen '+name)
    if a.contacts:
        run('studio-contacts',['--rendering-method','gl_compatibility','--fixed-fps','60','--script','res://tests/smash/capture_sync.gd','--','--quality-test','--studio','--video'],'SYNC_CAPTURE_PASS',420)
    print('STUDIO_SUITE_PASS: rendered evidence and invariants, not hardware/fun or GI certification.')
if __name__=='__main__':
    try: main()
    except (OSError,ValueError,RuntimeError,subprocess.TimeoutExpired) as e: print('FAIL:',e,file=sys.stderr);sys.exit(1)
