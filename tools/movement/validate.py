"""Godot engine receipts compatible with this host's Windows PowerShell 5.1.

The supplied skill validator aborts on git rev-parse in a non-Git project.
This runner preserves that failure log and executes the same import/smoke gates.
"""
import datetime, hashlib, json, subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GODOT = Path(r'C:/Users/Aloha/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe')
stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
OUT = ROOT / 'artifacts/validation' / (stamp + '-movement')
OUT.mkdir(parents=True)
(ROOT / 'artifacts/validation/.gdignore').touch()
checks = {}
commands = {
    'project_import': ['--headless', '--editor', '--path', str(ROOT), '--quit'],
    'headless_runtime': ['--headless', '--path', str(ROOT), '--quit-after', '120'],
    'movement_replay': ['--headless', '--fixed-fps', '60', '--path', str(ROOT), '--script', 'res://tests/test_movement_integration.gd']
}
for name, args in commands.items():
    p = subprocess.run([str(GODOT), *args], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=60)
    (OUT / (name + '.log')).write_text(p.stdout, encoding='utf-8')
    errors = [line for line in p.stdout.splitlines() if any(t in line for t in ['SCRIPT ERROR', 'ERROR:', 'Parse Error', 'FAIL:'])]
    checks[name] = {'exit_code': p.returncode, 'errors': errors, 'pass': p.returncode == 0 and not errors}
receipt = {'engine': subprocess.check_output([str(GODOT), '--version'], text=True).strip(),
           'scene': 'res://scenes/movement_test.tscn', 'git': 'not configured; pre-edit file checkpoint saved',
           'skill_validator': 'attempted; PowerShell helper aborts on non-Git checkout (see artifacts/movement_integration/validator.log)',
           'checks': checks, 'overall_pass': all(c['pass'] for c in checks.values()),
           'graphical_evidence': 'Separate graphical_results.json and inspected Godot framebuffers; no manual feel claim',
           'source_hashes': {p: hashlib.file_digest((ROOT/p).open('rb'), 'sha256').hexdigest() for p in [
               'project.godot', 'scripts/player.gd', 'scripts/iven_movement_visual.gd', 'scripts/iven_flame.gd',
               'shaders/iven_flame.gdshader', 'scripts/movement_test.gd', 'tests/test_movement_integration.gd']}}
(OUT / 'receipt.json').write_text(json.dumps(receipt, indent=2))
(ROOT / 'artifacts/movement_integration/FINAL_ENGINE_RECEIPT.json').write_text(json.dumps(receipt, indent=2))
print(json.dumps({'path': str(OUT), 'checks': checks, 'overall_pass': receipt['overall_pass']}))
raise SystemExit(0 if receipt['overall_pass'] else 1)
