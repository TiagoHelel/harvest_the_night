"""Keep exact tool returns and measure tower cuts without painting pixels."""
from pathlib import Path
import hashlib
import json
import shutil
import sys
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / 'tools'))
import import_art


def main():
    ident, kind, returned = sys.argv[1:4]
    plan = next(p for p in json.loads((HERE / '0013-plan.json').read_text()) if p['id'] == ident)
    folder = ROOT / 'assets/art_source/defences' / ident
    folder.mkdir(parents=True, exist_ok=True)
    review = ROOT / 'implementation/sprites/reviews/0013'
    review.mkdir(parents=True, exist_ok=True)
    dest = folder / (kind + '.png')
    if dest.exists():
        assert '--remeasure' in sys.argv and dest.read_bytes() == Path(returned).read_bytes(), 'Preserve previous candidates; choose a revision name'
    else:
        shutil.copyfile(returned, dest)
    raw = Image.open(dest).convert('RGBA')
    refs = plan['references'] if kind == 'master' else [(folder.relative_to(ROOT) / 'master.png').as_posix(), plan['references'][1]]
    prompt = 'implementation/sprites/generation/0013-' + ident + '-' + kind + '.prompt.txt'
    call = dict(id=ident, kind=kind, tool='built-in ImageGen',
                revision=int(kind.split('-r')[-1]) if '-r' in kind else 0,
                returned_file=returned, source=dest.relative_to(ROOT).as_posix(),
                source_sha256=hashlib.sha256(dest.read_bytes()).hexdigest(),
                source_wh=list(raw.size), source_alpha_range=list(raw.getchannel('A').getextrema()),
                prompt=prompt, prompt_sha256=import_art.sha((ROOT / prompt).read_bytes()),
                references=refs, measured_recipes=[], decision='Pending source measurement and native/runtime review')
    call_path = HERE / ('0013-' + ident + '-' + kind + '-call.json')
    call_path.write_text(json.dumps(call, indent=2) + '\n', encoding='utf-8', newline='\n')
    mask = raw.getchannel('A').point(lambda a: 255 if a >= 128 else 0)
    count = 1 if kind == 'master' else 4
    def spans_along(image, axis):
        spans, start = [], None
        length = image.size[axis]
        for n in range(length + 1):
            box = (n, 0, n + 1, image.height) if axis == 0 else (0, n, image.width, n + 1)
            visible = n < length and image.crop(box).getbbox() is not None
            if visible and start is None:
                start = n
            if not visible and start is not None:
                spans.append([start, n])
                start = None
        return spans
    cells = [(0, 0, raw.width, raw.height)]
    if count == 4:
        rows = spans_along(mask, 1)
        assert len(rows) >= 2, (ident, kind, 'Expected two separate rows', rows)
        # Detached authored sparks can create additional alpha bands. The
        # largest measured empty gutter separates cells; smaller gaps remain
        # inside the object's cut and retain every source pixel.
        row_gap = max(range(len(rows) - 1), key=lambda i: rows[i + 1][0] - rows[i][1])
        ycuts = [0, (rows[row_gap][1] + rows[row_gap + 1][0]) // 2, raw.height]
        cells = []
        for row, (y0, y1) in enumerate(zip(ycuts, ycuts[1:])):
            if row == 0:
                assert mask.crop((0, y1, raw.width, y1 + 1)).getbbox() is None
                y1 += 1
            spans = spans_along(mask.crop((0, y0, raw.width, y1)), 0)
            assert len(spans) >= 2, (ident, kind, 'Expected two separated objects in each row', spans)
            column_gap = max(range(len(spans) - 1), key=lambda i: spans[i + 1][0] - spans[i][1])
            xcuts = [0, (spans[column_gap][1] + spans[column_gap + 1][0]) // 2, raw.width]
            for column, (x0, x1) in enumerate(zip(xcuts, xcuts[1:])):
                if column == 0:
                    # Share only the measured transparent cut column, retaining
                    # a source margin on both cells even for a one-pixel gutter.
                    assert mask.crop((x1, y0, x1 + 1, y1)).getbbox() is None
                    x1 += 1
                cells.append((x0, y0, x1, y1))
    boxes, contacts = [], []
    for i, (x0, y0, x1, y1) in enumerate(cells):
        box = mask.crop((x0, y0, x1, y1)).getbbox()
        assert box and box[0] > 0 and box[1] > 0 and box[2] < x1 - x0 and box[3] < y1 - y0, (ident, i, box)
        # Measure contact on the planted lower quarter rather than on the barrel.
        low = box[3] - max(1, (box[3] - box[1]) // 4)
        base = mask.crop((x0, y0 + low, x1, y0 + box[3])).getbbox()
        contacts.append(((base[0] + base[2]) / 2, box[3]))
        boxes.append((x0, y0, x1, y1, box))
    level = 1 if kind == 'master' else int(kind.split('-')[1])
    target = plan['body_wh'][level - 1]
    whole = boxes[0][4]
    scale = min(target[0] / (whole[2] - whole[0]), target[1] / (whole[3] - whole[1]))
    # A single scale for all four states, leaving clearance around fire and wreck.
    for (_, _, _, _, b), (cx, cy) in zip(boxes, contacts):
        scale = min(scale, 15 / max(1, cx - b[0]), 15 / max(1, b[2] - cx), 41 / (cy - b[1]))
    states = ['master'] if count == 1 else ['whole', 'hurt', 'fire', 'wreck']
    suffix = '' if level == 1 else '_' + str(level)
    entries = []
    for state, (x0, y0, x1, y1, b), (cx, cy) in zip(states, boxes, contacts):
        name = ident + suffix + ('' if state in ('master', 'whole') else '_' + state)
        crop = [x0 + b[0], y0 + b[1], b[2] - b[0], b[3] - b[1]]
        entry = dict(id='buildings/' + name, source=dest.relative_to(ROOT).as_posix(),
                     crop_xywh=crop, sheet_cell_xywh=[x0, y0, x1 - x0, y1 - y0],
                     gutter_xy=[0, 0], canvas_wh=plan['canvas_wh'], pivot_xy=plan['pivot_xy'],
                     content_scale=scale, alpha_threshold=128,
                     content_anchor_xy=[round((cx - b[0]) * scale), round((cy - b[1]) * scale)])
        image = import_art.render_source(entry)
        preview = ident + '-' + kind + '-' + state
        image.save(review / (preview + '.png'))
        image.resize(tuple(n * 3 for n in image.size), Image.Resampling.NEAREST).save(review / (preview + '-3x.png'))
        entries.append(entry)
    call.update(measured_recipes=entries, source_bounds=[list(b) for _, _, _, _, b in boxes],
                source_contacts=[list(p) for p in contacts], decision='Pending native/runtime review')
    call_path.write_text(json.dumps(call, indent=2) + '\n', encoding='utf-8', newline='\n')
    print(json.dumps(dict(source=call['source'], source_wh=call['source_wh'], scale=scale,
                          previews=[str(review / (ident + '-' + kind + '-' + s + '-3x.png')) for s in states])))


if __name__ == '__main__':
    main()
