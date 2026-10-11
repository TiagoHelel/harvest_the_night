"""Validate complete boss ownership, body/contact scale and all authored poses.

**Table-driven** (task 0246): `BOSSES` holds each boss family's motion counts,
canvas, pivot, cell offset and the generation task its sources came from - the
Giant's today; 0266-0268 add theirs. The five ordinary-and-Giant families keep
complete ownership, as a subset: a new enemy family cannot fail this check.
"""
from PIL import ImageChops
import import_art
import gen_sprites

COUNTS = {'master': 1, 'walk': 4, 'windup': 3, 'slam': 3, 'death': 5}

## Each boss family: its motion counts, canvas, pivot and cell offset, the
## generation task its sources came from, how tall its raised wind-up must
## stand and how low its collapse must finish.
BOSSES = {
    'giant': {'counts': COUNTS, 'canvas': [80, 64], 'pivot': [40, 60], 'offset': [-32, -44],
              'task': '0016', 'windup_top': 50, 'death_low': 20,
              'aliases': (('walk_b', 'walk_2'), ('attack', 'slam_0'), ('death', 'death_4'),
                          ('telegraph', 'windup_2'))},
}
ORDINARY = ('walker', 'runner', 'tank', 'breaker')
WORDS = {1: 'one', 2: 'two', 3: 'three', 4: 'four', 5: 'five', 6: 'six'}
OWNED = {'enemies/' + f for f in ORDINARY + ('giant',)}


def check_family(family, spec, data, files, images, entries, old):
    """One boss family's poses; returns its visible master's width and height."""
    title = family.capitalize()
    width, height = spec['canvas']
    for motion, count in spec['counts'].items():
        frames = sorted((e for e in data['assets'] if e.get('enemy_family') == family and e.get('enemy_motion') == motion and 'source' in e), key=lambda e: e['frame'])
        if len(frames) != count or [e['frame'] for e in frames] != list(range(count)):
            raise ValueError('Missing %s motion: %s' % (title, motion))
        if len({e['content_scale'] for e in frames}) != 1 or len({e['source'] for e in frames}) != 1:
            raise ValueError('%s per-frame source/scale drift: %s' % (title, motion))
        shapes = []
        heights = []
        for e in frames:
            if e.get('generation_task') != spec['task'] or not e['source'].startswith('assets/art_source/enemies/%s/' % family):
                raise ValueError('Unowned %s pose: %s' % (title, e['id']))
            if e['canvas_wh'] != spec['canvas'] or e['pivot_xy'] != spec['pivot'] or e['cell_offset_xy'] != spec['offset']:
                raise ValueError('%s contact drift: %s' % (title, e['id']))
            image = images[e['id']]
            box = image.getbbox()
            if not box or box[0] < 1 or box[1] < 1 or box[2] >= width or box[3] != spec['pivot'][1]:
                raise ValueError('Clipped or floating %s: %s' % (title, e['id']))
            if image.tobytes() in shapes:
                raise ValueError('Repeated %s pose: %s' % (title, e['id']))
            shapes.append(image.tobytes())
            heights.append(box[3] - box[1])
            if any(pixel[3] not in (0, 255) for pixel in import_art.samples(image)):
                raise ValueError('%s alpha fringe: %s' % (title, e['id']))
            if (import_art.ROOT / e['output']).read_bytes() != files[e['output']] or e['output'].removeprefix('sprites/') in old:
                raise ValueError('%s source/runtime/legacy mismatch: %s' % (title, e['id']))
        if motion == 'windup' and not (heights[0] < heights[1] < heights[2] and heights[2] >= spec['windup_top']):
            raise ValueError('Wind-up does not visibly raise the striking arm')
        if motion == 'death' and (heights[-1] > spec['death_low'] or any(a < b for a, b in zip(heights, heights[1:]))):
            raise ValueError('%s collapse does not finish low' % title)
        if motion == 'walk':
            for i, a in enumerate(frames):
                for b in frames[i + 1:]:
                    for dy in range(-2, 3):
                        if ImageChops.difference(ImageChops.offset(images[a['id']], 0, dy), images[b['id']]).getbbox() is None:
                            raise ValueError('%s walk is only a shifted body' % title)
    master = images['enemies/' + family].getbbox()
    gw, gh = master[2] - master[0], master[3] - master[1]
    for ordinary in ORDINARY:
        box = images['enemies/' + ordinary].getbbox()
        if not (gw > box[2] - box[0] and gh >= 1.3 * (box[3] - box[1])):
            raise ValueError('%s does not dominate the visible ordinary body: %s' % (title, ordinary))
    for alias, target in spec['aliases']:
        e = entries['enemies/%s_%s' % (family, alias)]
        if e.get('alias_of') != 'enemies/%s_%s' % (family, target) or e.get('operation') != 'copy' or files[e['output']] != files[entries[e['input']]['output']]:
            raise ValueError('Stale %s compatibility pose: %s' % (title, alias))
    return gw, gh


def main():
    data = import_art.load_manifest()
    files, images = import_art.build(data)
    entries = {e['id']: e for e in data['assets']}
    # **A subset, not the whole** (task 0246): the five families keep their
    # complete ownership, and a family a later task adds cannot fail it.
    if not OWNED <= gen_sprites.migrated_enemies():
        raise ValueError('All five enemy families must have complete ownership')
    old = gen_sprites.everything(dispatch=False)
    for family, spec in BOSSES.items():
        gw, gh = check_family(family, spec, data, files, images, entries, old)
        poses = sum(spec['counts'].values())
        width, height = spec['canvas']
        pivot_x, pivot_y = spec['pivot']
        print(f'OK: {poses} authored {family.capitalize()} poses, {WORDS.get(len(spec["aliases"]), len(spec["aliases"]))} exact aliases, {width}x{height}/({pivot_x},{pivot_y}), visible master {gw}x{gh}, real wind-up/collapse')


if __name__ == '__main__':
    main()
