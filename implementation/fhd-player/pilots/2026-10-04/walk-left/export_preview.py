"""Cut ImageGen source and build same-scale right/left approval previews."""
from pathlib import Path
import hashlib
import json
import statistics
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[4]
SOURCE = REPO / 'assets/art_source/player-fhd/pilots/2026-10-04/walk-left/materials-r2.png'
RIGHT = ROOT.parent / 'walk-right'
FRAME, HEIGHT, TOP = 80, 64, 8

def clean(im):
    im = im.convert('RGBA')
    im.putalpha(im.getchannel('A').point(lambda a: 255 if a >= 128 else 0))
    return im

def caption(draw, xy, text, size=15, fill='#e9e3cf'):
    draw.text(xy, text, font=ImageFont.truetype('C:/Windows/Fonts/consola.ttf', size), fill=fill)

def save_gif(frames, path, duration):
    atlas = Image.new('RGB', (frames[0].width * 8, frames[0].height))
    for i, frame in enumerate(frames):
        atlas.paste(frame.convert('RGB'), (i * frame.width, 0))
    palette = atlas.quantize(colors=256)
    converted = [f.convert('RGB').quantize(palette=palette, dither=Image.Dither.NONE) for f in frames]
    converted[0].save(path, save_all=True, append_images=converted[1:], duration=duration,
                      loop=0, disposal=2, optimize=False)
    with Image.open(path) as saved:
        assert saved.n_frames == 8
        for i in range(8):
            saved.seek(i)
            assert saved.info['duration'] == duration

source = clean(Image.open(SOURCE))
assert source.size == (1536, 1024), source.size
# Source gutter is inspected before choosing this cut; do not split a hat.
ROW_CUT = 498
rows = [0, ROW_CUT, 1024]
cells = [source.crop((c * 384, rows[r], (c + 1) * 384, rows[r + 1]))
         for r in range(2) for c in range(4)]
scale = HEIGHT / statistics.median(c.getbbox()[3] - c.getbbox()[1] for c in cells)
frames, metrics = [], []
(ROOT / 'frames').mkdir(exist_ok=True)
strip = Image.new('RGBA', (FRAME * 8, FRAME))
for i, cell in enumerate(cells):
    box = cell.getbbox()
    head = cell.crop((0, box[1], cell.width, box[1] + 100)).getbbox()
    center = (head[0] + head[2]) / 2
    small = cell.resize((round(cell.width * scale), round(cell.height * scale)), Image.Resampling.NEAREST)
    frame = Image.new('RGBA', (FRAME, FRAME))
    frame.alpha_composite(small, (round(FRAME / 2 - center * scale), TOP - small.getbbox()[1]))
    b = frame.getbbox()
    assert b[3] < FRAME - 2
    frame.save(ROOT / f'frames/walk-left-{i + 1:02}.png')
    strip.alpha_composite(frame, (i * FRAME, 0))
    hb = frame.crop((0, TOP, FRAME, TOP + 14)).getbbox()
    metrics.append({'frame': i + 1, 'bbox': b, 'height': b[3] - b[1],
                    'hat_region_width': hb[2] - hb[0],
                    'sha256': hashlib.sha256(frame.tobytes()).hexdigest()})
    frames.append(frame)
assert len({m['sha256'] for m in metrics}) == 8
strip.save(ROOT / 'walk-left-strip.png')

previews, slow = [], []
contact = Image.new('RGBA', (1280, 390), '#303a3e')
for i, left in enumerate(frames):
    right = Image.open(RIGHT / f'frames/walk-right-{i + 1:02}.png').convert('RGBA')
    canvas = Image.new('RGBA', (1040, 420), '#20292c')
    d = ImageDraw.Draw(canvas)
    caption(d, (22, 16), 'APPROVED RIGHT / WALK LEFT / 8 FRAMES / 10 FPS', 19)
    for label, x in [('RIGHT | FHD 1x',20),('LEFT | FHD 1x',195),
                     ('RIGHT | DETAIL 2x',390),('LEFT | DETAIL 2x',720)]:
        caption(d, (x, 66), label)
    for x, im, size in [(20,right,160),(195,left,160),(365,right,320),(700,left,320)]:
        canvas.alpha_composite(im.resize((size,size), Image.Resampling.NEAREST),
                               (x,90 if size == 160 else 75))
    caption(d, (22,292), 'Same display scale', fill='#aac2bd')
    caption(d, (22,320), 'Compare legs and counter-swing', fill='#aac2bd')
    caption(d, (22,370), f'Frame {i + 1:02} / 08 | awaiting approval', 14)
    previews.append(canvas)
    check = Image.new('RGBA', (640,370), '#303a3e')
    check.alpha_composite(right.resize((320,320),Image.Resampling.NEAREST),(0,35))
    check.alpha_composite(left.resize((320,320),Image.Resampling.NEAREST),(320,35))
    caption(ImageDraw.Draw(check),(15,10), f'APPROVED RIGHT / LEFT / FRAME {i + 1}')
    slow.append(check)
    contact.alpha_composite(right.resize((160,160),Image.Resampling.NEAREST),(i*160,25))
    contact.alpha_composite(left.resize((160,160),Image.Resampling.NEAREST),(i*160,210))
    caption(ImageDraw.Draw(contact),(i*160+10,190),f'{i+1:02}')
save_gif(previews, ROOT / 'right-left-comparison.gif', 100)
save_gif(slow, ROOT / 'gait-comparison-slow.gif', 200)
previews[0].convert('RGB').save(ROOT / 'comparison-poster.png')
contact.convert('RGB').save(ROOT / 'contact-sheet.png')
report = {'status':'awaiting user approval; not integrated', 'frames':8, 'fps':10,
          'canvas':[80,80], 'selected_source':'materials-r2.png', 'source_row_cuts':rows,
          'native_target_height':64, 'fhd_display_scale':2, 'common_source_scale':scale,
          'source_alpha_threshold':128, 'resample':'nearest',
          'anchor':'hat center and fixed head top', 'frames_metrics':metrics,
          'gif_frame_durations_ms':[100]*8,
          'limitations':['Generated reflection is not guaranteed pixel-identical.',
                         'Near arm begins forward swing one frame later than approved right.',
                         'Preview display scale only; no engine playback validation.']}
(ROOT / 'validation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
