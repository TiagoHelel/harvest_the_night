"""Check the complete authored tower replacement and exact reproducible cuts."""
import sys
from PIL import Image
import import_art
import gen_sprites

# Each family's levels and the task whose art it is. The four legacy towers
# are 0013's, three levels each; A038's hive (task 0237) has one step.
FAMILIES = {'gun_tower': (3, '0013'), 'flame_tower': (3, '0013'), 'mortar': (3, '0013'),
            'auto_crossbow': (3, '0013'), 'beehive': (2, 'A038')}
LEGACY = ('gun_tower', 'flame_tower', 'mortar', 'auto_crossbow')
STATES = ('', '_hurt', '_fire', '_wreck')


def main():
    data = import_art.load_manifest()
    files, images = import_art.build(data)
    entries = {e['id']: e for e in data['assets']}
    migrated = gen_sprites.migrated_towers()
    if set(migrated) != {'buildings/' + name for name in LEGACY}:
        raise ValueError('Legacy tower recipes still own a complete migrated family')
    levels = states = outlets = 0
    for family, (count, task) in FAMILIES.items():
        whole_levels = []
        for level in range(1, count + 1):
            name = family + ('_%d' % level if level > 1 else '')
            master = entries['buildings/' + name]
            seen, cells = [], []
            for suffix in STATES:
                ident = 'buildings/' + name + suffix
                e, image = entries[ident], images[ident]
                if e.get('generation_task') != task or e.get('tower_family') != family or e.get('tower_level') != level:
                    raise ValueError('Wrong authored family/level: ' + ident)
                if not e.get('source', '').startswith('assets/art_source/defences/' + family + '/'):
                    raise ValueError('Tower borrows another source: ' + ident)
                if e['canvas_wh'] != [32, 48] or e['pivot_xy'] != [16, 44] or e['cell_offset_xy'] != [-8, -28]:
                    raise ValueError('Tower canvas/ground contact drifts: ' + ident)
                if e['content_scale'] != master['content_scale'] or e['source'] != master['source']:
                    raise ValueError('States refit their body independently: ' + ident)
                if suffix and e.get('variant_of') != master['id']:
                    raise ValueError('State loses its direct identity: ' + ident)
                box = image.getbbox()
                if not box or box[0] < 1 or box[1] < 1 or box[2] >= 32 or box[3] != 44:
                    raise ValueError('Tower clips its canvas or floats: ' + ident)
                if any(p[3] not in (0, 255) for p in import_art.samples(image)):
                    raise ValueError('Tower has alpha halos: ' + ident)
                if image.tobytes() in seen:
                    raise ValueError('Missing independently authored state: ' + ident)
                seen.append(image.tobytes())
                if (import_art.ROOT / e['output']).read_bytes() != files[e['output']]:
                    raise ValueError('Runtime tower diverges from source: ' + ident)
                if suffix != '_wreck':
                    points = e.get('muzzles_xy', [])
                    expected = 2 if family == 'gun_tower' and level == 3 else 1
                    if len(points) != expected or e.get('muzzle_xy') != points[0]:
                        raise ValueError('Missing independently authored weapon outlets: ' + ident)
                    for point in points:
                        if image.getpixel(tuple(point))[3] != 255:
                            raise ValueError('Weapon outlet floats outside source: ' + ident)
                    outlets += len(points)
                elif 'muzzle_xy' in e or 'muzzles_xy' in e:
                    raise ValueError('A wreck emits a weapon flash: ' + ident)
                if not import_art.ROOT.joinpath(e['output']).exists() or e['output'] != 'sprites/' + ident + '.png':
                    raise ValueError('Tower output is not its runtime name: ' + ident)
                # A038's cuts carry no sheet cell: its crop is the cut.
                cells.append(e.get('sheet_cell_xywh', e['crop_xywh']))
                states += 1
            # A shared transparent gutter row/column is allowed; opaque pixels
            # can never be shared by cuts, even before alpha reduction.
            with Image.open(import_art.ROOT / master['source']) as raw:
                alpha = raw.convert('RGBA').getchannel('A').point(lambda a: 255 if a >= 128 else 0)
                for i, (x, y, w, h) in enumerate(cells):
                    for xx, yy, ww, hh in cells[i + 1:]:
                        left, top, right, bottom = max(x, xx), max(y, yy), min(x + w, xx + ww), min(y + h, yy + hh)
                        if right > left and bottom > top and alpha.crop((left, top, right, bottom)).getbbox():
                            raise ValueError('Tower state cuts share opaque pixels: ' + name)
            whole_levels.append(images[master['id']])
            levels += 1
        if len({im.tobytes() for im in whole_levels}) != count:
            raise ValueError('Levels repeat the same construction: ' + family)
        first, last = whole_levels[0], whole_levels[-1]
        changed = sum(a != b for a, b in zip(import_art.samples(first), import_art.samples(last)))
        if changed < 80:
            raise ValueError('First/last level reinforcement is too small at native scale: ' + family)
    print('OK: %d tower families / %d authored levels / %d distinct states, exact cuts, common canvas/contact, %d opaque weapon outlets and complete legacy migration' % (len(FAMILIES), levels, states, outlets))
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (ValueError, KeyError, OSError) as error:
        print('FAIL: ' + str(error))
        sys.exit(1)
