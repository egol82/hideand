#!/usr/bin/env python3
from __future__ import annotations
import json, math, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
failures = []
checks = []

def check(value, label):
    checks.append(label)
    if not value:
        failures.append(label)
    print(f"{'PASS' if value else 'FAIL'}: {label}")

def delimiters_balanced(text):
    stack=[]; quote=''; escaped=False; comment=False
    pairs={')':'(',']':'[','}':'{'}
    for ch in text:
        if comment:
            if ch == '\n': comment=False
            continue
        if quote:
            if escaped: escaped=False
            elif ch == '\\': escaped=True
            elif ch == quote: quote=''
            continue
        if ch == '#': comment=True
        elif ch in "\"'": quote=ch
        elif ch in '([{': stack.append(ch)
        elif ch in ')]}':
            if not stack or stack.pop()!=pairs[ch]: return False
    return not stack and not quote

def main():
    project=ROOT/'project.godot'
    check(project.exists(),'Godot project exists')
    check('res://scenes/main.tscn' in project.read_text(encoding='utf-8'),'main scene is configured')
    gd_files=sorted(ROOT.rglob('*.gd'))
    check(len(gd_files)>=7,'game modules and Godot test runner exist')
    for file in gd_files:
        text=file.read_text(encoding='utf-8')
        rel=file.relative_to(ROOT)
        check(delimiters_balanced(text),f'{rel}: text delimiter balance')
        names=re.findall(r'^(?:static )?func (\w+)\(',text,re.M)
        check(len(names)==len(set(names)),f'{rel}: unique function names')
        for path in set(re.findall(r'res://([a-zA-Z0-9_/.\-]+)',text)):
            check((ROOT/path).exists(),f'{rel}: resource {path} exists')
    for scene in ROOT.rglob('*.tscn'):
        for path in re.findall(r'path="res://([^"]+)"',scene.read_text()):
            check((ROOT/path).exists(),f'{scene.name}: script resource exists')
    check(not any(p.name.startswith('.env') for p in ROOT.rglob('*')),'no environment/secret file bundled')
    check(not (ROOT/'.godot').exists(),'no generated engine cache bundled')
    data=(ROOT/'scripts/weapon_data.gd').read_text()
    get_float=lambda name: float(re.search(rf'const {name} := ([0-9.]+)',data).group(1))
    max_ink,max_reach,radius=get_float('MAX_INK'),get_float('MAX_REACH'),get_float('TUBE_RADIUS')
    check(max_ink>0 and max_reach>radius>0,'positive bounded weapon constants')
    check('Geometry2D.get_closest_point_to_segment' in data,'grip snap uses drawing geometry')
    check('SurfaceTool.new()' in (ROOT/'scripts/weapon_mesh.gd').read_text(),'weapon uses runtime mesh generation')
    check('PhysicsRayQueryParameters3D.create' in (ROOT/'scripts/main.gd').read_text(),'strike obstruction query is present')
    report={'validator':'offline-package-checks','checks':len(checks),'failures':failures,'godot_parse_test':'NOT RUN','godot_runtime_test':'NOT RUN','visual_playtest':'NOT RUN'}
    (ROOT/'docs/offline_check_report.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    print(f'\n{len(checks)} checks; {len(failures)} failures. Godot runtime NOT verified.')
    return 1 if failures else 0

if __name__=='__main__':
    sys.exit(main())
