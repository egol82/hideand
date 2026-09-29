#!/usr/bin/env python3
"""Offline source hygiene only; does not claim GDScript compilation or gameplay QA."""
from __future__ import annotations
import json
import re
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

def balanced(text: str) -> bool:
    stack: list[str] = []
    quote, escape, comment = '', False, False
    pairs = {')':'(', ']':'[', '}':'{'}
    for char in text:
        if comment:
            if char == '\n': comment = False
        elif quote:
            if escape: escape = False
            elif char == '\\': escape = True
            elif char == quote: quote = ''
        elif char == '#': comment = True
        elif char in '\"\'': quote = char
        elif char in '([{': stack.append(char)
        elif char in ')]}':
            if not stack or stack.pop() != pairs[char]: return False
    return not stack and not quote

def main() -> int:
    checks: list[dict] = []
    def check(value: bool, name: str) -> None:
        checks.append({'name': name, 'pass': bool(value)})
        print(f"{'PASS' if value else 'FAIL'}: {name}")
    config = (ROOT/'project.godot').read_text(encoding='utf-8')
    check('run/main_scene="res://scenes/phase12.tscn"' in config, 'Hideaway Manor main scene configured')
    for filename in ['scenes/main.tscn','scenes/phase2.tscn','scenes/phase3.tscn','scenes/phase4.tscn','tests/test_weapon.gd','tests/phase2/test_phase2.gd']:
        check((ROOT/filename).is_file(), f'preserved entry: {filename}')
    for file in sorted((ROOT/'scripts').rglob('*.gd')) + sorted((ROOT/'tests').rglob('*.gd')):
        text = file.read_text(encoding='utf-8')
        path = str(file.relative_to(ROOT))
        check(balanced(text), f'{path}: delimiters')
        functions = re.findall(r'^(?:static )?func (\w+)\(', text, re.M)
        check(len(functions) == len(set(functions)), f'{path}: distinct function names')
        resources = re.findall(r'(?:preload|load)\("res://([^"\n]+)"\)', text)
        resources += re.findall(r'^extends "res://([^"\n]+)"', text, re.M)
        for resource in sorted(set(resources)):
            if resource.startswith('assets/renderlab/generated/'):
                print(f'INFO: optional authoring output validated by test_studio --export: {resource}')
                continue
            check((ROOT/resource).is_file(), f'{path}: {resource}')
    for scene in (ROOT/'scenes').rglob('*.tscn'):
        for resource in re.findall(r'path="res://([^"]+)"', scene.read_text()):
            check((ROOT/resource).exists(), f'{scene.name}: {resource}')
    report = {'validator':'offline-source-hygiene','checks':len(checks),'failures':[c['name'] for c in checks if not c['pass']], 'not_verified_by_this_script':['GDScript compilation','engine runtime','visual quality','human playtest']}
    (ROOT/'docs/offline_check_report.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    print(f"{len(checks)} checks, {len(report['failures'])} failures. Not an engine test.")
    return int(bool(report['failures']))

if __name__ == '__main__':
    raise SystemExit(main())
