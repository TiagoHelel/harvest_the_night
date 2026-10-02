"""Register two generated furniture sprites with measured alpha crops."""
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
import import_art

CUTS = [
    ('storage', 'storage-west', [298, 169, 436, 1205], [40, 76], 72 / 1205, [20, 76]),
    ('nightstand', 'nightstand-lamp', [266, 362, 492, 917], [32, 48], 42 / 917, [16, 48]),
]


def main():
    sha = lambda path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest()
    manifest_path = ROOT / 'assets/art_source/manifest.json'
    registry_path = ROOT / 'assets/art_source/ownership.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    registry = json.loads(registry_path.read_text(encoding='utf-8'))
    reference = 'assets/art_source/interior/farmhouse-v1.png'
    for name, source_name, crop, canvas, scale, pivot in CUTS:
        source = f'assets/art_source/interior/{source_name}-v1.png'
        prompt = f'implementation/house-polish/{source_name}.prompt.txt'
        output = f'sprites/interior/{name}.png'
        entry = dict(id=f'interior/{name}', owner='raster', source=source,
                     source_sha256=sha(source), crop_xywh=crop,
                     canvas_wh=canvas, pivot_xy=pivot, content_scale=scale,
                     alpha_threshold=128, palette='tools/palette.py:COLOURS',
                     animation=f'interior/{name}', frame=0, seconds=1.0,
                     loop=True, output=output, prompt=prompt,
                     prompt_sha256=sha(prompt), references=[
                         {'path': reference, 'sha256': sha(reference), 'role': 'style'}])
        entry['output_sha256'] = hashlib.sha256(import_art.png(import_art.render_source(entry))).hexdigest()
        manifest['assets'] = [e for e in manifest['assets'] if e['output'] != output] + [entry]
        registry['outputs'] = [e for e in registry['outputs'] if e['output'] != output] + [dict(output=output, owner='raster')]
    manifest_path.write_bytes((json.dumps(manifest, indent=2) + '\n').encode('utf-8'))
    registry_path.write_bytes((json.dumps(registry, indent=2) + '\n').encode('utf-8'))


if __name__ == '__main__':
    main()
