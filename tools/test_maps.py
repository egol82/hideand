#!/usr/bin/env python3
"""Real engine assertions and fixed-seed bot matches for the original map pack."""
import argparse, json, os, re, subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
MAPS = ['sugar_market', 'starlight_arcade', 'pocket_station']
def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--godot',default=os.environ.get('GODOT_BIN','godot')); ap.add_argument('--capture',action='store_true'); ap.add_argument('--skip-matches',action='store_true'); args=ap.parse_args()
    out=ROOT/'ci-artifacts'; out.mkdir(exist_ok=True)
    def run(name, cmd, marker, limit=160):
        p=subprocess.run([args.godot,'--path',str(ROOT),'--audio-driver','Dummy',*cmd],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=limit,env=dict(os.environ,GODOT_SILENCE_ROOT_WARNING='1'))
        text=p.stdout+p.stderr; (out/(name+'.log')).write_text(text,encoding='utf-8'); print(text,flush=True)
        if p.returncode or (marker and marker not in text) or re.search(r'SCRIPT ERROR:|Parse Error:|Shader compilation failed|(?:^|\s)ERROR:|FAIL:',text): raise RuntimeError(name+' failed')
        return text
    run('map-pack-import',['--headless','--editor','--import'],'')
    run('map-pack-tests',['--headless','--fixed-fps','60','--quit-after','12000','--script','res://tests/maps/test_maps.gd','--','--quality-test'],'MAP_PACK_UNIT_RESULT:')
    run('map-pack-entry',['--headless','--fixed-fps','60','--quit-after','400','res://scenes/phase7.tscn','--','--phase4-smoke'],'PHASE4_SMOKE_READY')
    results=[]
    if not args.skip_matches:
        for mode in ['field','classic']:
            for arena in MAPS:
                text=run(f'map-pack-{mode}-{arena}',['--headless','--fixed-fps','60','--quit-after','150000','res://scenes/phase7.tscn','--','--phase4-autoplay',f'--map={arena}',f'--mode={mode}'],'PHASE4_AUTOPLAY_RESULT:',180)
                match=re.search(r'PHASE4_AUTOPLAY_RESULT: (\{.*\})',text)
                data=json.loads(match.group(1)) if match else {}
                if data.get('map')!=arena or data.get('mode')!=mode or data.get('rounds')!=4 or data.get('hits',0)<=0: raise RuntimeError('Wrong map/mode or incomplete match')
                results.append(data)
        (out/'map-pack-match-results.json').write_text(json.dumps(results,indent=2)+'\n')
    if args.capture:
        run('map-pack-render',['--rendering-method','gl_compatibility','--fixed-fps','60','--quit-after','3500','--script','res://tests/maps/capture.gd','--','--quality-test'],'MAP_PACK_CAPTURE_PASS',240)
        for arena in MAPS:
            for label in ['menu','fps','route','overview']:
                p=out/f'phase7_{arena}_{label}.png'
                if not p.is_file() or p.stat().st_size<1000: raise RuntimeError('Missing real screenshot: '+str(p))
    print('MAP_PACK_SUITE_PASS: engine verification, not human fun or hardware-performance evidence.')
if __name__=='__main__':
    try: main()
    except (OSError,RuntimeError,ValueError,subprocess.TimeoutExpired) as e: print('FAIL:',e,file=sys.stderr); sys.exit(1)
