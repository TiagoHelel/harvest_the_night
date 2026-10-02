"""Install complete authored tower levels, states and measured native muzzles."""
from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / 'tools'))
import import_art

SELECTED = {'gun_tower': ['level-1-r2', 'level-2-r2', 'level-3'],
            'flame_tower': ['level-1-r1', 'level-2', 'level-3'],
            'mortar': ['level-1', 'level-2', 'level-3'],
            'auto_crossbow': ['level-1-r1', 'level-2', 'level-3']}
# Authored on the reviewed native weapon mouths/rail ends, not cell centers.
WHOLE = {'gun_tower': [[[26, 20]], [[26, 19]], [[27, 19], [27, 21]]],
         'flame_tower': [[[26, 21]], [[25, 22]], [[25, 25]]],
         'mortar': [[[21, 27]], [[23, 24]], [[22, 23]]],
         'auto_crossbow': [[[25, 18]], [[25, 20]], [[26, 22]]]}
FIRE = {'gun_tower': [[[26, 20]], [[26, 19]], [[26, 18], [26, 21]]],
        'flame_tower': [[[26, 21]], [[26, 21]], [[25, 25]]],
        'mortar': [[[22, 26]], [[23, 22]], [[23, 21]]],
        'auto_crossbow': [[[24, 19]], [[26, 21]], [[26, 22]]]}
HURT = dict(WHOLE)
HURT['gun_tower'] = [[[24, 20]], [[26, 19]], [[27, 19], [27, 21]]]


def measured_point(image, desired):
    x, y = desired
    candidates = [(nx, ny) for ny in range(max(0, y - 1), min(image.height, y + 2))
                  for nx in range(max(0, x - 1), min(image.width, x + 2))
                  if image.getpixel((nx, ny))[3] == 255]
    assert candidates, ('Review point leaves weapon', desired)
    return list(min(candidates, key=lambda p: ((p[0] - x) ** 2 + (p[1] - y) ** 2, p[1], p[0])))


def main():
    # Calls used these files through .trim(); preserve the exact submitted text.
    for path in sorted(HERE.glob('0013-*-call.json')):
        call = json.loads(path.read_text())
        prompt = ROOT / call['prompt']
        submitted = prompt.read_text(encoding='utf-8').strip()
        prompt.write_text(submitted, encoding='utf-8', newline='\n')
        call['prompt_sha256'] = import_art.sha(prompt.read_bytes())
        call['reference_hashes'] = {p: import_art.sha((ROOT / p).read_bytes()) for p in call['references']}
        call['tool_arguments'] = dict(transparent_background=True,
                                      referenced_image_paths=[str(ROOT / p) for p in call['references']])
        path.write_text(json.dumps(call, indent=2) + '\n', encoding='utf-8', newline='\n')
    manifest = json.loads(import_art.MANIFEST.read_text())
    owner_path = ROOT / 'assets/art_source/ownership.json'
    owners = json.loads(owner_path.read_text())
    by_output = {e['output']: e for e in owners['outputs']}
    entries = []
    for ident, kinds in SELECTED.items():
        for level, kind in enumerate(kinds, 1):
            call = json.loads((HERE / f'0013-{ident}-{kind}-call.json').read_text())
            assert (ROOT / call['source']).read_bytes() == Path(call['returned_file']).read_bytes()
            assert len(call['measured_recipes']) == 4
            meta = dict(owner='raster', palette='tools/palette.py:COLOURS', seconds=0.55,
                        loop=True, frame=0, prompt=call['prompt'], prompt_sha256=call['prompt_sha256'],
                        references=[dict(path=p, sha256=call['reference_hashes'][p],
                                         role='Identity master / camera-material reference as indexed in exact prompt')
                                    for p in call['references']], tool='built-in ImageGen',
                        generation_task='0013', revision=call['revision'], source_sha256=call['source_sha256'],
                        cell_offset_xy=[-8, -28], tower_family=ident, tower_level=level)
            for state_index, recipe in enumerate(call['measured_recipes']):
                entry = dict(recipe)
                entry.update(meta, output='sprites/' + entry['id'] + '.png', animation=entry['id'])
                if state_index:
                    entry['variant_of'] = call['measured_recipes'][0]['id']
                if state_index != 3:
                    image = import_art.render_source(entry)
                    desired = (WHOLE, HURT, FIRE)[state_index][ident][level - 1]
                    points = [measured_point(image, p) for p in desired]
                    assert len({tuple(p) for p in points}) == len(points), (entry['id'], points)
                    entry.update(muzzle_xy=points[0], muzzles_xy=points,
                                 muzzle_region_xywh=[max(0, points[0][0] - 2), max(0, points[0][1] - 2), 5, 5])
                entry['output_sha256'] = import_art.sha(import_art.png(import_art.render_source(entry)))
                entries.append(entry)
                by_output[entry['output']] = dict(output=entry['output'], owner='raster')
    replacements = {e['id']: e for e in entries}
    existing = {e['id'] for e in manifest['assets']}
    manifest['assets'] = [replacements.get(e['id'], e) for e in manifest['assets']] + [e for e in entries if e['id'] not in existing]
    owners['outputs'] = [by_output[p] for p in sorted(by_output)]
    import_art.MANIFEST.write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8', newline='\n')
    owner_path.write_text(json.dumps(owners, indent=2) + '\n', encoding='utf-8', newline='\n')
    review = ROOT / 'implementation/sprites/reviews/0013'
    (review / 'measured-contract.json').write_text(json.dumps(entries, indent=2) + '\n', encoding='utf-8', newline='\n')
    print('Installed 48 source-owned tower frames, 12 levels, stable canvas/contact and authored muzzle metadata')


if __name__ == '__main__':
    main()
