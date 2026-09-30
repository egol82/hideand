#!/usr/bin/env python3
"""Canyon increment: actual movement/occupancy, bounded wind, wet expiry and unchanged regressions."""
from __future__ import annotations
import argparse,json,os,re,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def main():
    p=argparse.ArgumentParser();p.add_argument('--godot',default=os.environ.get('GODOT_BIN','godot'))
    for flag in ['skip-import','matches','regressions','capture-only']:p.add_argument('--'+flag,action='store_true')
    a=p.parse_args();out=ROOT/'ci-artifacts';out.mkdir(exist_ok=True)
    env=dict(os.environ,GODOT_BIN=a.godot,GODOT_SILENCE_ROOT_WARNING='1')
    def execute(name,cmd,marker,timeout=360):
        r=subprocess.run(cmd,cwd=ROOT,env=env,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=timeout)
        text=r.stdout+r.stderr;(out/(name+'.log')).write_text(text,encoding='utf-8')
        # Keep caller output compact; individual actual logs retain every assertion.
        print(name,r.returncode,'\n'.join(l for l in text.splitlines() if 'RESULT:' in l or '_PASS' in l or 'FAIL:' in l),flush=True)
        if r.returncode or marker not in text or re.search(r'SCRIPT ERROR:|Parse Error:|Shader compilation failed|(?:^|\s)ERROR:|FAIL:',text):raise RuntimeError(f'{name} failed; see {name}.log')
    def engine(name,args,marker,timeout=360):execute(name,[a.godot,'--path',str(ROOT),'--audio-driver','Dummy',*args],marker,timeout)
    if not a.skip_import:engine('canyon21-import',['--headless','--editor','--import'],'',600)
    if a.capture_only:
        engine('canyon21-render',['--rendering-method','gl_compatibility','--fixed-fps','30','--script','res://tests/canyon21/capture.gd','--','--quality-test'],'CANYON21_CAPTURE_PASS',420)
        for tag in ['lane_ready','lane_riding','lane_exit','gust_rest','gust_warning','gust_active','gust_settled']:
            if (out/('canyon21_'+tag+'.png')).stat().st_size<1000:raise RuntimeError('Missing actual render '+tag)
    else:
        engine('canyon21-expiry',['--headless','--script','res://tests/wetland21/test_expiry.gd','--','--quality-test'],'WETLAND21_EXPIRY_RESULT: 39 checks, 0 failures')
        engine('canyon21-unit',['--headless','--script','res://tests/canyon21/test_canyon.gd','--','--quality-test'],'CANYON21_UNIT_RESULT: 289 checks, 0 failures')
        # Preserves real Wet101 + Pine126 + sync94 and current default entry, no duplicate definitions.
        execute('canyon21-preserved',[sys.executable,'tools/test_wetland21.py','--godot',a.godot,'--skip-import',*(['--matches'] if a.matches else [])],'WETLAND21_SUITE_PASS',1200)
        if a.regressions:
            for file,args,marker in [('hideplay',[],'HIDEPLAY_SUITE_PASS'),('maps',['--skip-matches'],'MAP_PACK_SUITE_PASS'),('outdoor20',['--skip-import'],'OUTDOOR20_SUITE_PASS')]:
                execute('canyon21-prior-'+file,[sys.executable,'tools/test_'+file+'.py','--godot',a.godot,*args],marker,600)
    print('CANYON21_SUITE_PASS')
if __name__=='__main__':
    try:main()
    except (OSError,ValueError,RuntimeError,subprocess.TimeoutExpired) as e:print('FAIL:',e,file=sys.stderr);sys.exit(1)
