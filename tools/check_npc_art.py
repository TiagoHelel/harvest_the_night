"""Validate A034's peddler (task 0216): the first character who is not the farmer.

**Why a new checker**: he is neither a prop nor a station, and his pack is
mode B - exact-source colours on the farmer's density, never reduced to the
palette - so the prop and station checks, which hold their families to
palette art at their own scales, have nothing to say about him.

Fourteen frames on 40x40 standing on (20,36), drawn at 1.0 like the farmer:
idle (four, 0.4 s) and talk (four, 0.15 s) facing south, and the side walk
(six, 0.1 s) facing west, east being the runtime mirror. Every frame is
exact-source art - A034's composition from its own components, or its exact
cut - with its feet on the pivot row and the approved export's pixels. Every
one is its own drawing but the idle's, which A034 draws neutral, neutral,
neutral, blink: its first three are one picture and the blink differs only
in the face.
"""
import hashlib
from pathlib import Path
import import_art

POSES = {'idle': (4, 0.4), 'talk': (4, 0.15), 'walk': (6, 0.1)}


def main():
    data = import_art.load_manifest()
    files, images = import_art.build(data)
    by_id = {e['id']: e for e in data['assets']}
    seen = set()
    count = 0
    for pose, (frames, seconds) in POSES.items():
        for frame in range(frames):
            e = by_id['actors/peddler_%s_%d' % (pose, frame)]
            if e.get('generation_task') != 'A034' or e['canvas_wh'] != [40, 40] or e['pivot_xy'] != [20, 36] \
                    or e['seconds'] != seconds or e['loop'] is not True or e['frame'] != frame \
                    or e.get('draw_scale', 1) != 1:
                raise ValueError('Peddler frame drift: ' + e['id'])
            if e['palette'] != import_art.EXACT_SOURCE:
                raise ValueError('The peddler was reduced to the palette: ' + e['id'])
            if e.get('operation') == 'compose' and any(
                    by_id[p['input']].get('assembly_component_of') != 'A034' for p in e['parts']):
                raise ValueError('A peddler part from outside his pack: ' + e['id'])
            image = images[e['id']]
            box = image.getbbox()
            if not box or box[0] < 1 or box[1] < 1 or box[2] >= 40 or box[3] != 36:
                raise ValueError('The peddler is off his feet: %s %s' % (e['id'], box))
            if any(p[3] not in (0, 255) for p in import_art.samples(image)):
                raise ValueError('Peddler alpha halo: ' + e['id'])
            if pose == 'idle':
                if frame in (1, 2) and image.tobytes() != images['actors/peddler_idle_0'].tobytes():
                    raise ValueError('The idle is not neutral three times: ' + e['id'])
                if frame == 3:
                    still = images['actors/peddler_idle_0']
                    changed = [(x, y) for y in range(40) for x in range(40) if image.getpixel((x, y)) != still.getpixel((x, y))]
                    if not changed or max(y for x, y in changed) > 20:
                        raise ValueError('The blink is not in the face: ' + e['id'])
            elif image.tobytes() in seen:
                raise ValueError('A peddler frame repeats: ' + e['id'])
            seen.add(image.tobytes())
            native = next(r for r in e['references'] if r['role'].startswith('Approved native export'))
            path = import_art.ROOT / native['path']
            if hashlib.sha256(Path(path).read_bytes()).hexdigest() != native['sha256']:
                raise ValueError('Approved export changed: ' + native['path'])
            if (import_art.ROOT / e['output']).read_bytes() != files[e['output']]:
                raise ValueError('Runtime peddler diverges: ' + e['id'])
            count += 1
    print('OK: the peddler: %d exact-source frames - idle and talk facing south, the walk west - on his feet, '
          'the idle a blink after three still frames' % count)


if __name__ == '__main__':
    main()
