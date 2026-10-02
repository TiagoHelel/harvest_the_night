"""Register measured cuts from the accepted interior sheet; never synthesize art."""
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tools'))
import import_art

SOURCE = 'assets/art_source/interior/farmhouse-v1.png'
PROMPT = 'implementation/farm-house/interior.prompt.txt'
# Measured alpha bounds, except the opaque inner repeat tile for the floor.
CUTS = [
    ('floor', [190, 70, 256, 256], (16, 16), 16 / 256),
    ('wall', [656, 40, 221, 300], (24, 32), 32 / 300),
    ('bed', [1113, 42, 215, 307], (48, 64), 60 / 307),
    ('kitchen', [129, 395, 344, 285], (88, 76), 84 / 344),
    ('table', [562, 441, 450, 246], (80, 48), 72 / 450),
    ('fireplace', [1112, 365, 262, 322], (48, 64), 56 / 322),
    ('storage', [147, 700, 324, 283], (68, 60), 64 / 324),
    ('rug', [626, 807, 316, 160], (64, 36), 64 / 316),
    ('plant', [1119, 725, 225, 258], (28, 36), 24 / 225),
]


def main():
    sha = lambda path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest()
    manifest_path = ROOT / 'assets/art_source/manifest.json'
    registry_path = ROOT / 'assets/art_source/ownership.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    registry = json.loads(registry_path.read_text(encoding='utf-8'))
    for name, cut, canvas, scale in CUTS:
        output = f'sprites/interior/{name}.png'
        entry = dict(id=f'interior/{name}', owner='raster', source=SOURCE,
                     source_sha256=sha(SOURCE), crop_xywh=cut,
                     canvas_wh=list(canvas), pivot_xy=[canvas[0] // 2, canvas[1]],
                     content_scale=scale, alpha_threshold=128,
                     palette='tools/palette.py:COLOURS', animation=f'interior/{name}',
                     frame=0, seconds=1.0, loop=True, output=output,
                     prompt=PROMPT, prompt_sha256=sha(PROMPT), references=[])
        entry['output_sha256'] = hashlib.sha256(import_art.png(import_art.render_source(entry))).hexdigest()
        manifest['assets'] = [e for e in manifest['assets'] if e['output'] != output] + [entry]
        registry['outputs'] = [e for e in registry['outputs'] if e['output'] != output] + [dict(output=output, owner='raster')]
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    registry_path.write_text(json.dumps(registry, indent=2) + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
