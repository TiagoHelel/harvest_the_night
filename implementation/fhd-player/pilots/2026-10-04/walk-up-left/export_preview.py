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


# Both complete arm cycles are sampled from generated sources in one shared pipeline.
import sys
sys.path.insert(0,str(ROOT.parent))
from full_arm_cycle_export import export_direction
frames,tracking_frames,cycle = export_direction('up-left')
metrics = cycle['frames_metrics']
source = clean(Image.open(SOURCE / cycle['selected_source']))
cols,rows = cycle['source_col_cuts'],cycle['source_row_cuts']
scale = cycle['common_source_scale']

idle_src = clean(Image.open(SOURCE / 'rotation-r1.png'))
idle_crop = idle_src.crop(idle_src.getbbox())
idle_small = idle_crop.resize((round(idle_crop.width * HEIGHT / idle_crop.height), HEIGHT), Image.Resampling.NEAREST)
idle = Image.new('RGBA', (FRAME, FRAME))
idle.alpha_composite(idle_small, ((FRAME-idle_small.width)//2, TOP))
idle.save(ROOT / 'idle-native.png')

# Colored arm frames from the shared export retain source arm identities.

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
    caption(ImageDraw.Draw(diagnostic),(15,10),f'ARM LEFT CYAN / RIGHT PINK | MATERIALS | FRAME {i+1}',12)
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
save_gif(previews, ROOT / 'up-diagonals-full-arms-r13.gif', 100)
save_gif(slow, ROOT / 'gait-comparison-slow.gif', 200)
save_gif(diagnostics, ROOT / 'tracking-materials-full-arms-r13.gif', 200)
save_gif(idle_previews, ROOT / 'idle-walk-up-left.gif', 100)
previews[0].convert('RGB').save(ROOT / 'comparison-poster.png')
contact.convert('RGB').save(ROOT / 'contact-sheet.png')
report = {'status': 'awaiting user approval; not integrated', 'frames': 8, 'fps': 10,
          'canvas': [80,80], 'selected_source': cycle['selected_source'], 'source_size': list(source.size),
          'arm_override_frames':list(range(1,9)),
          'source_row_cuts': rows, 'source_col_cuts': cols, 'native_target_height': HEIGHT,
          'fhd_display_scale': 2, 'common_source_scale': scale, 'source_alpha_threshold': 128,
          'arm_source_hat_calibration':32,
          'tracking_source': 'full-arm-tracking-r12.png; cyan left arm/pink right arm',
          'color_motion_status':cycle['color_motion_status'],
          'resample': 'nearest', 'anchor': 'hat center and fixed head top', 'frames_metrics': metrics,
          'gif_frame_durations_ms': [100]*8,
          'limitations': ['Restored materials are not pixel-identical to the tracking source.',
                         'Approval preview only; not rendered inside the game.',
                         'Diagnostic colors support visual review; numeric frame checks do not prove gait quality.']}
(ROOT / 'validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'heights':[m['height'] for m in metrics],
                  'hat_widths':[m['hat_region_width'] for m in metrics]},indent=2))
