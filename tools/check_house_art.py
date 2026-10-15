"""Check A035's farmhouse tiers: whole and hurt, full density, measured lights, slices.

Task 0217: every tier - I, II and III - whole and hurt, is A035's composition
from its own components on 128x128 standing on (64,120), drawn at 1.0 (no
longer the 64x64 at 2.0), with the canvas offset its 6x4 footprint gives.
Its five panes are cool glass by day - A035 leaves the warmth to the night's
lamps - with each pane's point on the glass's light, the lantern and chimney
points are
the same within a tier, the entrance meets the ground on the same row span in
every state, the left glass never moves, and the hurt state shows its damage.
The nine compatibility slices of each state - columns 48/32/48, rows
56/32/40 - put the whole drawing back together exactly.
"""
import sys
from PIL import Image
import import_art
import palette

TIERS = ('house', 'house_2', 'house_3')
COLS = (48, 32, 48)
ROWS = (56, 32, 40)


def main():
    data = import_art.load_manifest()
    files, images = import_art.build(data)
    entries = {e['id']: e for e in data['assets']}
    glass = {palette.COLOURS[k] for k in ('moon', 'night_light')}
    left_glass = None
    slices = 0
    for tier in TIERS:
        states = (tier, tier + '_hurt')
        for name in states:
            e = entries['buildings/' + name]
            im = images['buildings/' + name]
            if e.get('generation_task') != 'A035' or e['canvas_wh'] != [128, 128] or e['pivot_xy'] != [64, 120] \
                    or e.get('draw_scale', 1) != 1 or e['cell_offset_xy'] != [-16, -56]:
                raise ValueError('House off its full-density box: ' + name)
            if e.get('operation') != 'compose' or 'source' in e \
                    or any(entries[p['input']].get('assembly_component_of') != 'A035' for p in e['parts']):
                raise ValueError('A layered house not promoted as its composition: ' + name)
            box = im.getbbox()
            if not box or box[3] != 120 or box[0] < 1 or box[2] > 127:
                raise ValueError('House is clipped or floats: ' + name)
            row = [x for x in range(128) if im.getpixel((x, 119))[3]]
            if not row or (row[0], row[-1]) != (49, 69):
                raise ValueError('The entrance meets the ground elsewhere: %s %s' % (name, row[:1] + row[-1:]))
            if len(e['windows_xy']) != 5 or len(e['window_rects_xywh']) != 5:
                raise ValueError('House lost a pane: ' + name)
            for (x, y, w, h), point in zip(e['window_rects_xywh'], e['windows_xy']):
                if sum(im.getpixel((i, j))[:3] in glass for j in range(y, y + h) for i in range(x, x + w)) < 2                         or im.getpixel(tuple(point))[:3] != palette.COLOURS['moon']:
                    raise ValueError('A pane disappears at native resolution: ' + name)
            pane = im.crop((34, 85, 42, 92)).tobytes()
            if left_glass is None:
                left_glass = pane
            elif pane != left_glass:
                raise ValueError('The left glass moved: ' + name)
            assembled = Image.new('RGBA', (128, 128))
            area = 0
            for child in data['assets']:
                if child.get('input') == e['id']:
                    if child['operation'] != 'slice':
                        raise ValueError('House state uses a painted substitute: ' + child['id'])
                    x, y, w, h = child['slice_xywh']
                    assembled.paste(images[child['id']], (x, y))
                    area += w * h
                    slices += 1
            if area != 128 * 128 or assembled.tobytes() != im.tobytes():
                raise ValueError('House slices lose or duplicate pixels: ' + name)
            for entry in [e] + [c for c in data['assets'] if c.get('input') == e['id']]:
                if (import_art.ROOT / entry['output']).read_bytes() != files[entry['output']]:
                    raise ValueError('House runtime differs from source: ' + entry['id'])
        whole, hurt = (entries['buildings/' + n] for n in states)
        for field in ('windows_xy', 'window_rects_xywh', 'light_xy', 'smoke_xy'):
            if whole[field] != hurt[field]:
                raise ValueError('A light point moves when %s is hurt: %s' % (tier, field))
        a, b = (images['buildings/' + n] for n in states)
        if a.tobytes() == b.tobytes():
            raise ValueError('The hurt house shows no damage: ' + tier)
    print('OK: 3 house tiers whole and hurt, full density 128x128 at (64,120); %d exact slices; five panes of glass each; '
          'one entrance contact, one left glass' % slices)
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (ValueError, KeyError, OSError) as error:
        print('FAIL: ' + str(error))
        sys.exit(1)
