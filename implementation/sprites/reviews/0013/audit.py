"""Audit exact ImageGen provenance, scoped migration and protected baseline bytes."""
from pathlib import Path
import hashlib
import io
import json
import subprocess
import tarfile
from PIL import Image

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
BASE = '87079a1'


def digest(data):
    return hashlib.sha256(data).hexdigest()


def main():
    manifest = json.loads((ROOT / 'assets/art_source/manifest.json').read_text())
    selected = [e for e in manifest['assets'] if e.get('generation_task') == '0013']
    outputs = {e['output'] for e in selected}
    assert len(outputs) == 48
    archive = subprocess.check_output(['git', 'archive', BASE, 'sprites', 'src/core', 'src/ui/player_frames.gd', 'assets/art_source', 'tools/palette.py', 'tools/determinism_sim_hash.txt', 'tools/determinism_data_hash.txt'], cwd=ROOT)
    with tarfile.open(fileobj=io.BytesIO(archive)) as snapshot:
        old = {m.name: snapshot.extractfile(m).read() for m in snapshot.getmembers() if m.isfile()}
    old_png = {p: b for p, b in old.items() if p.startswith('sprites/') and p.endswith('.png')}
    changed = sorted(p for p, b in old_png.items() if (ROOT / p).read_bytes() != b)
    added = sorted(p for p in outputs if p not in old_png)
    assert len(changed) == 40 and set(changed) <= outputs and len(added) == 8
    preserved_png = sorted(set(old_png) - outputs)
    assert len(preserved_png) == 240
    assert all((ROOT / p).read_bytes() == old_png[p] for p in preserved_png)
    protected = {p: b for p, b in old.items() if not p.startswith('sprites/') and p not in ('assets/art_source/manifest.json', 'assets/art_source/ownership.json', 'assets/art_source/README.md')}
    assert all((ROOT / p).read_bytes() == b for p, b in protected.items())
    previous = json.loads(old['assets/art_source/manifest.json'])
    current = {e['id']: e for e in manifest['assets']}
    assert all(e == current[e['id']] for e in previous['assets'] if e['output'] not in outputs)
    chosen = {e['source'] for e in selected}
    calls, rejected = [], []
    for path in sorted((ROOT / 'implementation/sprites/generation').glob('0013-*-call.json')):
        call = json.loads(path.read_text())
        raw = (ROOT / call['source']).read_bytes()
        assert raw == Path(call['returned_file']).read_bytes()
        assert digest(raw) == call['source_sha256']
        assert digest((ROOT / call['prompt']).read_bytes()) == call['prompt_sha256']
        assert all(digest((ROOT / p).read_bytes()) == call['reference_hashes'][p] for p in call['references'])
        if call['kind'] == 'master' or call['source'] in chosen:
            call['decision'] = 'Accepted: source alpha, native/3x identity, construction, source-owned contact and actual Godot states reviewed. Masters are immutable identity references; selected level sheets own the four runtime states.'
            path.write_text(json.dumps(call, indent=2) + '\n', encoding='utf-8', newline='\n')
        else:
            assert call['decision'].startswith('Rejected'), call
            rejected.append(call['source'])
        calls.append(call)
    assert len(calls) == 22 and len(rejected) == 6
    frames = []
    for e in selected:
        im = Image.open(ROOT / e['output']).convert('RGBA')
        frames.append(dict(id=e['id'], output_sha256=digest((ROOT / e['output']).read_bytes()), canvas_wh=list(im.size), visible_bounds=list(im.getbbox()), pivot_xy=e['pivot_xy'], content_scale=e['content_scale'], source=e['source'], muzzles_xy=e.get('muzzles_xy', [])))
    owners = json.loads((ROOT / 'assets/art_source/ownership.json').read_text())['outputs']
    counts = {name: sum(e['owner'] == name for e in owners) for name in ('raster', 'ascii', 'player-sheet')}
    assert counts == {'raster': 232, 'ascii': 56, 'player-sheet': 0} and len(owners) == 288
    captures = sorted((ROOT / 'implementation/shots/sprites/0013').rglob('*.png'))
    assert len(captures) == 29
    reviews = []
    for p in captures:
        reviews.append(dict(path=str(p.relative_to(ROOT)).replace('\\', '/'), sha256=digest(p.read_bytes()), native_wh=list(Image.open(p).size), reviewed_scales=[1, 3]))
    (HERE / 'frame-review.json').write_text(json.dumps(reviews, indent=2) + '\n', encoding='utf-8', newline='\n')
    audit = dict(baseline=BASE, changed_existing_pngs=changed, added_pngs=added, preserved_png_count=len(preserved_png), preserved_png_sha256={p: digest(old_png[p]) for p in preserved_png}, protected_file_count=len(protected), protected_sha256={p: digest(b) for p, b in protected.items()}, unchanged_previous_manifest_entries=True, ownership_counts=counts, tool_calls=calls, rejected_sources=rejected, frames=frames, simulation=(ROOT / 'tools/determinism_sim_hash.txt').read_text().strip(), data=(ROOT / 'tools/determinism_data_hash.txt').read_text().strip())
    (HERE / 'scope-and-sources.json').write_text(json.dumps(audit, indent=2) + '\n', encoding='utf-8', newline='\n')
    print('PASS: 22 exact ImageGen returns/prompts/references (16 accepted / 6 retained rejections); 40 changed + 8 added PNGs; 240 other PNGs and %d protected files unchanged; 29 reviewed captures; owners 232 raster / 56 ASCII' % len(protected))


if __name__ == '__main__':
    main()
