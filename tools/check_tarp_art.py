"""Check A044's day tarps (task 0243): one cover per footprint, torn and
unveiling, exact outputs on the footprints' canvases and pivots."""
import sys
import import_art

# The three footprints (task 0234's settling): a tower's, the tall one-cell
# defences' and the short ones'.
FOOTPRINTS = {'tarp_tower': ([32, 48], [16, 44]), 'tarp_tall': ([16, 32], [8, 28]), 'tarp_short': ([16, 24], [8, 20])}


def main():
    data = import_art.load_manifest()
    files, images = import_art.build(data)
    entries = {e['id']: e for e in data['assets'] if e.get('generation_task') == 'A044'}
    if len(entries) != 12:
        raise ValueError('Tarp contract incomplete: %d' % len(entries))
    for footprint, (canvas, pivot) in FOOTPRINTS.items():
        names = [footprint, footprint + '_hurt', footprint + '_unveil_0', footprint + '_unveil_1']
        for name in names:
            e = entries['buildings/' + name]
            if e['canvas_wh'] != canvas or e['pivot_xy'] != pivot:
                raise ValueError('Tarp off its footprint: ' + name)
            if (import_art.ROOT / e['output']).read_bytes() != files[e['output']]:
                raise ValueError('Runtime tarp diverges from source: ' + name)
            if any(p[3] not in (0, 255) for p in import_art.samples(images[e['id']])):
                raise ValueError('Tarp has alpha halos: ' + name)
        boxes = {name: images['buildings/' + name].getbbox() for name in names}
        # The covers, whole and torn, stand on the pivot's row; the torn one
        # is its own picture.
        for name in names[:2]:
            if boxes[name][3] != pivot[1]:
                raise ValueError('Cover floats or sinks: %s %s' % (name, boxes[name]))
        if images['buildings/' + names[0]].tobytes() == images['buildings/' + names[1]].tobytes():
            raise ValueError('Torn cover is the whole one: ' + footprint)
        # The unveil: yanked up off the ground, then away higher still - two
        # frames of 0.12 s, played once.
        yank, away = boxes[names[2]], boxes[names[3]]
        if not yank[3] < pivot[1] - 4 or not away[3] < yank[3]:
            raise ValueError('Unveil does not lift: %s %s %s' % (footprint, yank, away))
        for i, name in enumerate(names[2:]):
            e = entries['buildings/' + name]
            if e['frame'] != i or e['seconds'] != 0.12 or e['loop'] is not False:
                raise ValueError('Unveil timing: ' + name)
    print('OK: 3 tarp footprints / 12 exact outputs, grounded covers, torn covers apart, unveils lifting')
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (ValueError, KeyError, OSError) as error:
        print('FAIL: ' + str(error))
        sys.exit(1)
