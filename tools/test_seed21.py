#!/usr/bin/env python3
"""Versioned round layouts plus the preserved Phase21/game regressions. No historical totals reused."""
from __future__ import annotations
import argparse,json,os,re,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def main():
    p=argparse.ArgumentParser();p.add_argument('--godot',default=os.environ.get('GODOT_BIN','godot'))
    for flag in ['skip-import','matches','regressions','capture-only']:p.add_argument('--'+flag,action='store_true')
    a=p.parse_args();out=ROOT/'ci-artifacts';out.mkdir(exist_ok=True)
    env=dict(os.environ,GODOT_BIN=a.godot,GODOT_SILENCE_ROOT_WARNING='1');records=[]
    def run(name,cmd,marker,timeout=600):
        r=subprocess.run(cmd,cwd=ROOT,env=env,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=timeout)
        text=r.stdout+r.stderr;(out/(name+'.log')).write_text(text,encoding='utf-8')
        ok=r.returncode==0 and marker in text and not re.search(r'SCRIPT ERROR:|Parse Error:|Shader compilation failed|(?:^|\s)ERROR:|FAIL:',text)
        records.append({'name':name,'command':cmd,'exit_code':r.returncode,'required_marker':marker,'passed':ok})
        (out/'seed21-execution.json').write_text(json.dumps(records,indent=2)+'\n',encoding='utf-8')
        print(name,r.returncode,'\n'.join(l for l in text.splitlines() if 'RESULT:' in l or '_PASS' in l or 'FAIL:' in l),flush=True)
        if not ok:raise RuntimeError(name+' failed; see its exact log')
    def engine(name,args,marker,timeout=600):run(name,[a.godot,'--path',str(ROOT),'--audio-driver','Dummy',*args],marker,timeout)
    if not a.skip_import:engine('seed21-import',['--headless','--editor','--import'],'')
    if a.capture_only:
        engine('seed21-render',['--rendering-method','gl_compatibility','--fixed-fps','30','--script','res://tests/seed21/capture.gd','--','--quality-test'],'SEED21_CAPTURE_PASS',600)
        for mid in ['pine_hollow','reedwater_bend','amber_canyon']:
            for view in ['round0','round1','gameplay']:
                if (out/('seed21_'+mid+'_'+view+'.png')).stat().st_size<1000:raise RuntimeError('Missing actual render')
    else:
        engine('seed21-unit',['--headless','--script','res://tests/seed21/test_layout.gd','--','--quality-test'],'SEED21_UNIT_RESULT: 340 checks, 0 failures')
        run('seed21-preserved',[sys.executable,'tools/test_canyon21.py','--godot',a.godot,'--skip-import',*(['--matches'] if a.matches else []),*(['--regressions'] if a.regressions else [])],'CANYON21_SUITE_PASS',1800)
        if a.matches:
            manifests={}
            for mid in ['pine_hollow','reedwater_bend','amber_canyon']:
                for mode in ['field','classic']:
                    text=(out/f'wetland21-{mode}-{mid}.log').read_text(encoding='utf-8')
                    rows=[json.loads(s.split('ROUND_LAYOUT21: ',1)[1]) for s in text.splitlines() if s.startswith('ROUND_LAYOUT21: ')]
                    if len(rows)!=4 or len({r['id'] for r in rows})!=4 or 'ROUND_LAYOUT21_REJECT' in text:raise RuntimeError('Expected four valid distinct natural rounds')
                    if any(r['map']!=mid or r['round']!=i or r['seed']!=8027 for i,r in enumerate(rows)):raise RuntimeError('Bad round provenance')
                    manifests[mid+'/'+mode]=rows
                if manifests[mid+'/field']!=manifests[mid+'/classic']:raise RuntimeError('Modes changed seeded scenery')
            (out/'seed21-match-layouts.json').write_text(json.dumps(manifests,indent=2)+'\n',encoding='utf-8')
            print('SEED21_MATCH_PROVENANCE_PASS: six natural matches; four distinct layouts each; modes share layout manifests')
    print('SEED21_SUITE_PASS')
if __name__=='__main__':
    try:main()
    except (OSError,ValueError,RuntimeError,subprocess.TimeoutExpired) as e:print('FAIL:',e,file=sys.stderr);sys.exit(1)
