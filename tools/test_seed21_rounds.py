#!/usr/bin/env python3
"""Regression for stale server transforms in real four-round matches, never injected rounds."""
from __future__ import annotations
import argparse, json, os, re, subprocess, sys, time
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
MAPS = ('pine_hollow', 'reedwater_bend', 'amber_canyon')
BAD = re.compile(r'SCRIPT ERROR:|Parse Error:|Shader compilation failed|(?:^|\s)ERROR:|FAIL:')

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--godot', default=os.environ.get('GODOT_BIN', 'godot'))
    parser.add_argument('--skip-import', action='store_true')
    parser.add_argument('--unit-only', action='store_true')
    args = parser.parse_args()
    out = ROOT / 'ci-artifacts'
    out.mkdir(exist_ok=True)
    records: list[dict] = []
    env = dict(os.environ, GODOT_SILENCE_ROOT_WARNING='1')

    def run(name: str, options: list[str], marker: str, timeout: int = 420) -> str:
        cmd = [args.godot, '--headless', '--path', str(ROOT), '--audio-driver', 'Dummy', *options]
        start = time.monotonic()
        with (out / (name + '.log')).open('w', encoding='utf-8') as log:
            try:
                result = subprocess.run(cmd, env=env, stdout=log, stderr=subprocess.STDOUT, timeout=timeout)
                code = result.returncode
            except subprocess.TimeoutExpired:
                code = 124
        text = (out / (name + '.log')).read_text(encoding='utf-8', errors='replace')
        ok = code == 0 and marker in text and not BAD.search(text)
        records.append(dict(name=name, command=cmd, exit_code=code, marker=marker,
                            seconds=round(time.monotonic()-start, 3), passed=ok))
        (out / 'seed21-reset-execution.json').write_text(json.dumps(records, indent=2)+'\n', encoding='utf-8')
        print(name, code, 'PASS' if ok else 'FAIL', flush=True)
        if not ok:
            raise RuntimeError(name + ' failed; see its retained log')
        return text

    if not args.skip_import:
        run('seed21-reset-import', ['--editor', '--import'], '', 600)
    text = run('seed21-reset-unit', ['--script', 'res://tests/seed21/test_round_reset.gd', '--', '--quality-test'], 'SEED21_RESET_RESULT:')
    if not re.search(r'SEED21_RESET_RESULT: \d+ checks, 0 failures', text):
        raise RuntimeError('Reset assertions did not all pass')
    if args.unit_only:
        print('SEED21_RESET_UNIT_PASS'); return

    manifests: dict[str, list[dict]] = {}
    summaries: dict[str, dict] = {}
    for seed in (17, 0):
        for map_id in MAPS:
            for mode in ('field', 'classic'):
                # Seed17 Pine is repeated in a new engine process, like the reported repro.
                for repeat in range(2 if seed == 17 and map_id == 'pine_hollow' else 1):
                    key = f'{map_id}-{mode}-{seed}-{repeat}'
                    text = run('seed21-autoplay-'+key, ['--fixed-fps', '60', '--quit-after', '150000',
                        'res://scenes/phase21.tscn', '--', '--phase4-autoplay', '--map='+map_id,
                        '--mode='+mode, '--match-seed='+str(seed)], 'PHASE4_AUTOPLAY_RESULT:')
                    rows = [json.loads(line.split('ROUND_LAYOUT21: ', 1)[1]) for line in text.splitlines()
                            if line.startswith('ROUND_LAYOUT21: ')]
                    result = [json.loads(line.split('PHASE4_AUTOPLAY_RESULT: ', 1)[1]) for line in text.splitlines()
                              if line.startswith('PHASE4_AUTOPLAY_RESULT: ')]
                    if len(result) != 1 or result[0]['rounds'] != 4 or result[0]['map'] != map_id or result[0]['mode'] != mode:
                        raise RuntimeError(key + ': actual four-round match did not finish')
                    if len(rows) != 4 or len({row['id'] for row in rows}) != 4 or 'ROUND_LAYOUT21_REJECT' in text:
                        raise RuntimeError(key + ': expected four valid distinct natural rounds; no rejection')
                    if any(row['map'] != map_id or row['seed'] != seed or row['round'] != i or row['round_seed'] != seed+i*991
                           for i, row in enumerate(rows)):
                        raise RuntimeError(key + ': wrong seed/round provenance')
                    if repeat and (rows != manifests[f'{map_id}-{mode}-{seed}-0'] or result[0] != summaries[f'{map_id}-{mode}-{seed}-0']):
                        raise RuntimeError(key + ': repeated identical input diverged')
                    manifests[key] = rows; summaries[key] = result[0]
                    (out / 'seed21-reset-matches.json').write_text(json.dumps(dict(layouts=manifests, matches=summaries), indent=2)+'\n', encoding='utf-8')
            if manifests[f'{map_id}-field-{seed}-0'] != manifests[f'{map_id}-classic-{seed}-0']:
                raise RuntimeError(map_id + ': modes disagreed on the same seeded layouts')
    print('SEED21_RESET_AUTOPLAY_PASS: 14 actual matches, four layouts each; repeated Pine17 and mode manifests identical')
    print('SEED21_RESET_SUITE_PASS')

if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, KeyError, RuntimeError, subprocess.TimeoutExpired) as error:
        print('FAIL:', error, file=sys.stderr); sys.exit(1)
