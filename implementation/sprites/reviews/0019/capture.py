"""Sequential native captures; do not overlap renderer runs with full perf."""
from pathlib import Path
import subprocess, sys

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
commands = [
    ('atmosphere-check-final.log', ['tools/show_art.py', '--atmosphere', '--check']),
    ('atmosphere-capture-final.log', ['tools/show_art.py', '--atmosphere', '--out=implementation/shots/sprites/0019/atmosphere']),
]
for name, flags in [('en', []), ('pt', ['--pt_BR']), ('en-contrast', ['--contrast']), ('pt-contrast', ['--pt_BR', '--contrast'])]:
    commands.append(('standard-' + name + '.log', ['tools/shot.py', 'sprites/0019', 'noon', 'dusk', 'wave', 'result', 'tech', *flags]))
for log, args in commands:
    result = subprocess.run([sys.executable, '-u', *args], cwd=ROOT, capture_output=True, text=True, encoding='utf-8', errors='replace')
    (HERE / log).write_text(result.stdout + result.stderr, encoding='utf-8', newline='\n')
    print(log, result.returncode, flush=True)
    if result.returncode:
        print(result.stdout + result.stderr)
        sys.exit(result.returncode)
