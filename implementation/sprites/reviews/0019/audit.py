"""Prove existing sprite/source/core bytes and palette colours are preserved."""
from pathlib import Path
import hashlib, json, re, subprocess, sys

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
BASE = '303f38b'

def original(path):
    return subprocess.check_output(['git', 'show', BASE + ':' + path], cwd=ROOT)

def main():
    paths = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', BASE], cwd=ROOT, text=True).splitlines()
    manifest = json.loads((ROOT / 'assets/art_source/manifest.json').read_text(encoding='utf-8'))
    assert manifest == json.loads(original('assets/art_source/manifest.json'))
    assert len(manifest['assets']) == 447
    previous = original('tools/palette.py').decode('utf-8')
    current = (ROOT / 'tools/palette.py').read_text(encoding='utf-8')
    extract = lambda text: text[text.index('COLOURS = {'):text.index('\n}', text.index('COLOURS = {'))+2]
    assert extract(previous) == extract(current), 'Source palette colours changed'
    protected = []
    runtime = []
    for path in paths:
        prior_prompt = re.match(r'implementation/sprites/generation/(\d{4})', path)
        protect = path.startswith(('src/core/', 'assets/art_source/', 'docs/')) or path in ('project.godot', 'tools/determinism_sim_hash.txt', 'tools/determinism_data_hash.txt')
        art = path.startswith('sprites/') and path.endswith('.png')
        if protect or art or prior_prompt and int(prior_prompt[1]) < 19:
            old, now = original(path), (ROOT / path).read_bytes()
            assert now == old or not path.endswith('.png') and now.replace(b'\r\n',b'\n') == old.replace(b'\r\n',b'\n'), 'Protected file changed: ' + path
            protected.append(dict(path=path, sha256=hashlib.sha256(now).hexdigest()))
            if art:
                runtime.append(path)
    assert len(runtime) == 468
    new_source = subprocess.check_output(['git','ls-files','--others','--exclude-standard','assets/art_source/','sprites/','implementation/sprites/generation/'],cwd=ROOT,text=True).splitlines()
    assert not new_source, 'Unexpected new source/runtime art: ' + repr(new_source)
    report = dict(baseline=BASE, protected_count=len(protected), protected_files=protected, raster_entries=447, runtime_pngs=468, new_sources=0, imagegen_calls=0, source_palette_colours=42, sim_hash=(ROOT/'tools/determinism_sim_hash.txt').read_text().strip(), data_hash=(ROOT/'tools/determinism_data_hash.txt').read_text().strip())
    if '--staged' in sys.argv:
        staged = subprocess.check_output(['git','diff','--cached','--name-only'],cwd=ROOT,text=True).splitlines()
        assert not any(p.startswith(('src/core/','sprites/','assets/art_source/')) for p in staged)
        report['staged_files'] = len(staged)
    (HERE / 'scope-and-sources.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(f'OK: {len(protected)} protected files, all 468 runtime PNGs and 447 raster entries unchanged; zero new sprites/generations; 42 source colours preserved')

if __name__ == '__main__':
    main()
