"""Evaluate an authored replacement at native scale before installing it."""
from pathlib import Path
import json
import sys
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / 'tools'))
import import_art

HERE = Path(__file__).resolve().parent
SOURCE = 'assets/art_source/enemies/walker/walk-v2.png'
PROMPT = 'implementation/sprites/generation/walker-walk-fix.prompt.txt'


def main():
    data = json.loads(import_art.MANIFEST.read_text())
    source = Image.open(ROOT / SOURCE).convert('RGBA')
    alpha = source.getchannel('A').point(lambda a: 255 if a >= 128 else 0)
    runs, start = [], None
    for x in range(source.width + 1):
        on = x < source.width and alpha.crop((x, 0, x+1, source.height)).getbbox() is not None
        if on and start is None:
            start = x
        if not on and start is not None:
            runs.append((start, x))
            start = None
    assert len(runs) == 4, 'Each full body must have a genuinely empty gutter'
    cuts = [0] + [(runs[i-1][1]+runs[i][0])//2 for i in range(1,4)] + [source.width]
    boxes = []
    for i in range(4):
        x0, x1 = cuts[i], cuts[i+1]
        box = alpha.crop((x0, 0, x1, source.height)).getbbox()
        assert box
        boxes.append((x0 + box[0], box[1], x0 + box[2], box[3]))
    scale = 29 / max(b[3] - b[1] for b in boxes)
    entries, old, new = [], [], []
    previous = json.loads((HERE / 'before-entries.json').read_text())
    for i, b in enumerate(boxes):
        entry = next(e for e in data['assets'] if e['id'] == 'enemies/walker_walk_' + str(i))
        old.append(import_art.render_source(previous[i]))
        entry.update(source=SOURCE, source_sha256=import_art.sha((ROOT / SOURCE).read_bytes()),
                     crop_xywh=[b[0], b[1], b[2]-b[0], b[3]-b[1]],
                     sheet_cell_xywh=[cuts[i], 0, cuts[i+1]-cuts[i], source.height],
                     content_scale=scale, content_anchor_xy=[round((b[2]-b[0])*scale/2), round((b[3]-b[1])*scale)],
                     prompt=PROMPT, prompt_sha256=import_art.sha((ROOT / PROMPT).read_bytes()),
                     references=[{'path':'assets/art_source/enemies/walker/master.png',
                                  'sha256':import_art.sha((ROOT / 'assets/art_source/enemies/walker/master.png').read_bytes()),
                                  'role':'Identity reference'}], revision=1,
                     scale_reference={'role':'tallest standing pose','raw_height':max(b[3]-b[1] for b in boxes),'native_height':29},
                     ground_measurement='shared strip baseline; fixed centered body anchor')
        image = import_art.render_source(entry)
        entry['output_sha256'] = import_art.sha(import_art.png(image))
        entries.append(entry)
        new.append(image)
    page = Image.new('RGBA', (300, 128), (218, 213, 183, 255))
    draw = ImageDraw.Draw(page)
    for row, frames in enumerate((old, new)):
        draw.text((2, row*64+1), 'Previous' if row == 0 else 'Candidate', fill=(26,24,32,255))
        for i, frame in enumerate(frames):
            page.alpha_composite(frame, (i*72+6, row*64+15))
    page.save(HERE / 'comparison-native.png')
    page.resize((900,384), Image.Resampling.NEAREST).save(HERE / 'comparison-3x.png')
    (HERE / 'candidate-entries.json').write_text(json.dumps(entries, indent=2)+'\n')
    print('Candidate scale', scale, 'boxes', boxes)


if __name__ == '__main__':
    main()
