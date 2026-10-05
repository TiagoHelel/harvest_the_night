"""Cut generated UP-LEFT artwork and compare the approved directional gait."""
from pathlib import Path
import hashlib
import json
import statistics
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[4]
SOURCE = REPO / 'assets/art_source/player-fhd/pilots/2026-10-04/walk-up-left'
RIGHT = ROOT.parent / 'walk-up-right'
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
        assert saved.n_frames == 8 and saved.info['loop'] == 0
        for i in range(8):
            saved.seek(i)
            assert saved.info['duration'] == duration


source = clean(Image.open(SOURCE / 'arms-r9.png'))
cols = [round(i * source.width / 4) for i in range(5)]
blank = [y for y in range(round(source.height*.4),round(source.height*.6))
         if source.getchannel('A').crop((0,y,source.width,y+1)).getbbox() is None]
assert blank, 'No empty source row gutter; inspect before cutting.'
rows = [0, round(statistics.median(blank)), source.height]
cells = [source.crop((cols[c], rows[r], cols[c+1], rows[r+1]))
         for r in range(2) for c in range(4)]
assert all(c.getbbox() is not None for c in cells)
# Arm silhouettes must not change the accepted head and leg display scale.
scale = json.loads((ROOT / 'before-arms-2026-10-05/validation.json').read_text())['common_source_scale']
reference = clean(Image.open(SOURCE / 'rebuild-materials-r7.png'))
reference_cells = [reference.crop((cols[c],rows[r],cols[c+1],rows[r+1]))
                   for r in range(2) for c in range(4)]
def hat_width(cell):
    b=cell.getbbox()
    h=cell.crop((0,b[1],cell.width,b[1]+round((b[3]-b[1])*.22))).getbbox()
    return h[2]-h[0]
arm_source_calibration = statistics.median(map(hat_width,reference_cells))/statistics.median(map(hat_width,cells))
scale *= arm_source_calibration
frames, metrics = [], []
(ROOT / 'frames').mkdir(exist_ok=True)
strip = Image.new('RGBA', (FRAME * 8, FRAME))
for i, cell in enumerate(cells):
    cell_scale = scale
    box = cell.getbbox()
    head_depth = round((box[3] - box[1]) * .22)
    head = cell.crop((0, box[1], cell.width, box[1] + head_depth)).getbbox()
    center = (head[0] + head[2]) / 2
    small = cell.resize((round(cell.width * cell_scale), round(cell.height * cell_scale)), Image.Resampling.NEAREST)
    frame = Image.new('RGBA', (FRAME, FRAME))
    frame.alpha_composite(small, (round(FRAME / 2 - center * cell_scale), TOP - small.getbbox()[1]))
    b = frame.getbbox()
    assert b[0] > 0 and b[2] < FRAME and b[3] < FRAME - 2, b
    assert set(frame.getchannel('A').tobytes()) <= {0, 255}
    frame.save(ROOT / f'frames/walk-up-left-{i + 1:02}.png')
    strip.alpha_composite(frame, (i * FRAME, 0))
    hb = frame.crop((0, TOP, FRAME, TOP + 14)).getbbox()
    metrics.append({'frame': i+1, 'bbox': b, 'height': b[3]-b[1],
                    'hat_region_width': hb[2]-hb[0],
                    'sha256': hashlib.sha256(frame.tobytes()).hexdigest()})
    frames.append(frame)
assert len({m['sha256'] for m in metrics}) == 8
# Replace ONLY reported poses5/6; the other6R9 frames retain their pixels.
pair=clean(Image.open(SOURCE/'arm-05-06-r10.png'))
mid=round(pair.width/2)
pair_cells=[pair.crop((0,0,mid,pair.height)),pair.crop((mid,0,pair.width,pair.height))]
pair_scale=32/statistics.median(map(hat_width,pair_cells))
for i,cell in zip([4,5],pair_cells):
    b=cell.getbbox()
    head=cell.crop((0,b[1],cell.width,b[1]+round((b[3]-b[1])*.22))).getbbox()
    center=(head[0]+head[2])/2
    small=cell.resize((round(cell.width*pair_scale),round(cell.height*pair_scale)),Image.Resampling.NEAREST)
    frame=Image.new('RGBA',(FRAME,FRAME))
    frame.alpha_composite(small,(round(FRAME/2-center*pair_scale),TOP-small.getbbox()[1]))
    b=frame.getbbox()
    assert b[0]>0 and b[2]<FRAME and b[3]<FRAME-2,b
    frames[i]=frame
    frame.save(ROOT/f'frames/walk-up-left-{i+1:02}.png')
    hb=frame.crop((0,TOP,FRAME,TOP+14)).getbbox()
    metrics[i]={'frame':i+1,'bbox':b,'height':b[3]-b[1],'hat_region_width':hb[2]-hb[0],
                'sha256':hashlib.sha256(frame.tobytes()).hexdigest()}
strip=Image.new('RGBA',(FRAME*8,FRAME))
for i,frame in enumerate(frames):
    strip.alpha_composite(frame,(i*FRAME,0))
assert len({m['sha256'] for m in metrics}) == 8
strip.save(ROOT / 'walk-up-left-strip.png')

idle_src = clean(Image.open(SOURCE / 'rotation-r1.png'))
idle_crop = idle_src.crop(idle_src.getbbox())
idle_small = idle_crop.resize((round(idle_crop.width * HEIGHT / idle_crop.height), HEIGHT), Image.Resampling.NEAREST)
idle = Image.new('RGBA', (FRAME, FRAME))
idle.alpha_composite(idle_small, ((FRAME-idle_small.width)//2, TOP))
idle.save(ROOT / 'idle-native.png')

# The tracking source was already uniformly sampled and packed into80px cells.
# Read those pixels exactly for the geometry/material comparison.
tracking_source = clean(Image.open(SOURCE / 'rebuild-tracking-r6-packed.png'))
assert tracking_source.size == (320,160)
tracking_cells = [tracking_source.crop((c*80,r*80,(c+1)*80,(r+1)*80))
                  for r in range(2) for c in range(4)]
tracking_frames = []
(ROOT/'tracking-frames').mkdir(exist_ok=True)
for i,cell in enumerate(tracking_cells):
    frame=cell
    frame.save(ROOT/f'tracking-frames/phase-{i+1:02}.png')
    tracking_frames.append(frame)

previews, slow, idle_previews, diagnostics = [], [], [], []
contact = Image.new('RGBA', (1280, 390), '#303a3e')
for i, left in enumerate(frames):
    right = Image.open(RIGHT / f'frames/walk-up-right-{i+1:02}.png').convert('RGBA')
    canvas = Image.new('RGBA', (1040, 420), '#20292c')
    d = ImageDraw.Draw(canvas)
    caption(d, (22,16), 'WALK UP-RIGHT / WALK UP-LEFT / 8 FRAMES / 10 FPS', 19)
    for label, x in [('UP-RIGHT | FHD 1x',20), ('UP-LEFT | FHD 1x',195),
                     ('UP-RIGHT | DETAIL 2x',390), ('UP-LEFT | DETAIL 2x',720)]:
        caption(d, (x,66), label)
    for x, im, size in [(20,right,160), (195,left,160), (365,right,320), (700,left,320)]:
        canvas.alpha_composite(im.resize((size,size), Image.Resampling.NEAREST),
                               (x,90 if size == 160 else 75))
    caption(d, (22,292), 'Same display scale', fill='#aac2bd')
    caption(d, (22,320), 'Compare opposite contacts', fill='#aac2bd')
    caption(d, (22,370), f'Frame {i+1:02} / 08 | awaiting approval', 14)
    previews.append(canvas)
    check = Image.new('RGBA', (640,370), '#303a3e')
    check.alpha_composite(right.resize((320,320),Image.Resampling.NEAREST), (0,35))
    check.alpha_composite(left.resize((320,320),Image.Resampling.NEAREST), (320,35))
    caption(ImageDraw.Draw(check), (15,10), f'UP-RIGHT / UP-LEFT / FRAME {i+1}', 13)
    slow.append(check)
    diagnostic=Image.new('RGBA',(640,370),'#303a3e')
    diagnostic.alpha_composite(tracking_frames[i].resize((320,320),Image.Resampling.NEAREST),(0,35))
    diagnostic.alpha_composite(left.resize((320,320),Image.Resampling.NEAREST),(320,35))
    caption(ImageDraw.Draw(diagnostic),(15,10),f'LEFT CYAN / RIGHT PINK | MATERIALS | FRAME {i+1}',12)
    diagnostics.append(diagnostic)
    contact.alpha_composite(right.resize((160,160),Image.Resampling.NEAREST), (i*160,25))
    contact.alpha_composite(left.resize((160,160),Image.Resampling.NEAREST), (i*160,210))
    caption(ImageDraw.Draw(contact), (i*160+10,190), f'{i+1:02}')
    standing = Image.new('RGBA', (880,400), '#20292c')
    sd = ImageDraw.Draw(standing)
    caption(sd, (22,15), 'WALK UP-LEFT / 8 FRAMES / 10 FPS', 20)
    for label, x in [('MASTER | FHD 1x',30), ('WALK | FHD 1x',225), ('WALK | DETAIL 2x',470)]:
        caption(sd, (x,66), label)
    for x, im, size in [(30,idle,160), (225,left,160), (475,left,320)]:
        standing.alpha_composite(im.resize((size,size),Image.Resampling.NEAREST), (x,90 if size==160 else 70))
    caption(sd, (30,287), '64 px artwork / integer 2x = 128 px screen height', 14)
    caption(sd, (30,312), 'Preview only - awaiting approval', 14, '#aac2bd')
    caption(sd, (30,348), f'Frame {i+1:02} / 08', 14)
    idle_previews.append(standing)
save_gif(previews, ROOT / 'up-diagonals-arms-r10.gif', 100)
save_gif(slow, ROOT / 'gait-comparison-slow.gif', 200)
save_gif(diagnostics, ROOT / 'tracking-materials-arms-r10.gif', 200)
save_gif(idle_previews, ROOT / 'idle-walk-up-left.gif', 100)
previews[0].convert('RGB').save(ROOT / 'comparison-poster.png')
contact.convert('RGB').save(ROOT / 'contact-sheet.png')
report = {'status': 'awaiting user approval; not integrated', 'frames': 8, 'fps': 10,
          'canvas': [80,80], 'selected_source': 'arms-r9.png + arm-05-06-r10.png override5/6', 'source_size': list(source.size),
          'arm_override_frames':[5,6],'arm_pair_source_scale':pair_scale,
          'source_row_cuts': rows, 'source_col_cuts': cols, 'native_target_height': HEIGHT,
          'fhd_display_scale': 2, 'common_source_scale': scale, 'source_alpha_threshold': 128,
          'arm_source_hat_calibration': arm_source_calibration,
          'tracking_source': 'rebuild-tracking-r6-packed.png; already-native geometry reference',
          'resample': 'nearest', 'anchor': 'hat center and fixed head top', 'frames_metrics': metrics,
          'gif_frame_durations_ms': [100]*8,
          'limitations': ['Restored materials are not pixel-identical to the tracking source.',
                         'Approval preview only; not rendered inside the game.',
                         'Diagnostic colors support visual review; numeric frame checks do not prove gait quality.']}
(ROOT / 'validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'heights':[m['height'] for m in metrics],
                  'hat_widths':[m['hat_region_width'] for m in metrics]},indent=2))
