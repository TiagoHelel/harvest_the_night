"""Rebuild accepted sources twice in an already clean, isolated Git checkout."""
from pathlib import Path
import argparse, hashlib, json, subprocess, sys

HERE = Path(__file__).resolve().parent

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--checkout', type=Path, required=True)
    args = parser.parse_args()
    checkout = args.checkout.resolve()
    def git(*flags):
        return subprocess.check_output(['git', *flags], cwd=checkout, text=True).strip()
    assert not git('status', '--porcelain'), 'Checkout must start completely clean'
    commit = git('rev-parse', 'HEAD')
    paths = [p for p in git('ls-files').splitlines() if p.startswith(('sprites/', 'assets/art_source/')) or p in ['src/ui/palette_data.gd', 'src/ui/raster_art.gd', 'src/ui/player_frames.gd']]
    def snapshot():
        return {p: hashlib.sha256((checkout/p).read_bytes()).hexdigest() for p in paths}
    original = snapshot()
    steps = []
    for cycle in (1, 2):
        for command in ['tools/import_art.py', 'tools/gen_sprites.py', 'tools/cut_sheet.py']:
            result = subprocess.run([sys.executable, command], cwd=checkout, capture_output=True, text=True, encoding='utf-8', errors='replace')
            step = dict(cycle=cycle, command=command, exit_code=result.returncode, output=result.stdout+result.stderr)
            steps.append(step)
            print(cycle, command, result.returncode, step['output'].strip(), flush=True)
            assert result.returncode == 0, step
        assert snapshot() == original, 'Rebuild changed accepted source/runtime/metadata bytes'
        assert not git('status', '--porcelain'), 'Rebuild produced a Git diff or untracked file'
    report = dict(commit=commit, initially_clean=True, finally_clean=True, identical_cycles=2, tracked_files=len(paths), runtime_pngs=sum(p.startswith('sprites/') and p.endswith('.png') for p in paths), files=original, steps=steps)
    (HERE/'clean-rebuild.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('PASS: two clean offline rebuilds preserve every accepted byte', flush=True)

if __name__ == '__main__':
    main()
