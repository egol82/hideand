#!/usr/bin/env python3
"""Focused actual-engine sync tests, preserved map autoplay, and actual-contact rendering."""
import argparse, json, os, re, subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
def main():
    p = argparse.ArgumentParser()
    p.add_argument('--godot', default=os.environ.get('GODOT_BIN', 'godot'))
    p.add_argument('--capture', action='store_true'); p.add_argument('--video', action='store_true'); p.add_argument('--matches', action='store_true')
    a = p.parse_args(); out = ROOT/'ci-artifacts'; out.mkdir(exist_ok=True)
    def run(label, args, marker, limit=240):
        r = subprocess.run([a.godot, '--path', str(ROOT), '--audio-driver', 'Dummy', *args], capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=limit, env=dict(os.environ, GODOT_SILENCE_ROOT_WARNING='1'))
        text = r.stdout+r.stderr; (out/(label+'.log')).write_text(text, encoding='utf-8'); print(text, flush=True)
        if r.returncode or (marker and marker not in text) or re.search(r'SCRIPT ERROR:|Parse Error:|Shader compilation failed|(?:^|\s)ERROR:|FAIL:', text): raise RuntimeError(label+' failed')
        return text
    run('sync-import', ['--headless', '--editor', '--import'], '')
    run('sync-tests', ['--headless', '--fixed-fps', '60', '--quit-after', '12000', '--script', 'res://tests/smash/test_sync.gd', '--', '--quality-test'], 'SYNC_UNIT_RESULT:')
    run('sync-smash-regression', ['--headless', '--fixed-fps', '60', '--quit-after', '12000', '--script', 'res://tests/smash/test_smash.gd', '--', '--quality-test', '--sync-followup'], 'SMASH_UNIT_RESULT:')
    run('sync-entry', ['--headless', '--fixed-fps', '60', '--quit-after', '400', 'res://scenes/phase9_followup.tscn', '--', '--phase4-smoke'], 'PHASE4_SMOKE_READY')
    if a.matches:
        results=[]
        for mode in ['field','classic']:
            for map_id in ['toy_home','warehouse','garden','sugar_market','starlight_arcade','pocket_station']:
                text=run('sync-'+mode+'-'+map_id, ['--headless','--fixed-fps','60','--quit-after','150000','res://scenes/phase9_followup.tscn','--','--phase4-autoplay','--mode='+mode,'--map='+map_id], 'PHASE4_AUTOPLAY_RESULT:')
                data=json.loads(re.search(r'PHASE4_AUTOPLAY_RESULT: (\{.*\})',text).group(1))
                if data.get('rounds')!=4 or data.get('map')!=map_id or data.get('mode')!=mode: raise RuntimeError('incomplete/wrong match')
                results.append(data)
        (out/'sync-match-results.json').write_text(json.dumps(results,indent=2)+'\n')
    if a.capture:
        args=['--rendering-method','gl_compatibility','--fixed-fps','60','--quit-after','12000','--script','res://tests/smash/capture_sync.gd','--','--quality-test']
        if a.video: args += ['--video']
        run('sync-render',args,'SYNC_CAPTURE_PASS',400)
        for map_id in ['sugar_market','starlight_arcade','pocket_station']:
            for frame in ['idle','impact','reaction']:
                f=out/('sync_'+map_id+'_'+frame+'.png')
                if not f.is_file() or f.stat().st_size<1000: raise RuntimeError('missing render '+str(f))
    print('SYNC_SUITE_PASS: actual engine evidence, not human testing or hardware/audio latency benchmark.')
if __name__=='__main__':
    try: main()
    except (OSError,RuntimeError,ValueError,subprocess.TimeoutExpired) as e: print('FAIL:',e,file=sys.stderr); sys.exit(1)
