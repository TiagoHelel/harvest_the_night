"""Deterministic alpha cleanup, common-scale cutting and approval GIF export."""
from pathlib import Path
import hashlib
import json
import statistics
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[4]
SOURCE = REPO / 'assets/art_source/player-fhd/pilots/2026-10-04'
FRAME = 80
HEIGHT = 64
TOP = 8

def clean(im):
    im = im.convert('RGBA')
    im.putalpha(im.getchannel('A').point(lambda a: 255 if a >= 128 else 0))
    return im

def cuts(path):
    im = clean(Image.open(path))
    assert im.size == (1536, 1024), im.size
    return [im.crop((c*384, r*512, (c+1)*384, (r+1)*512))
            for r in range(2) for c in range(4)]

def pack(cells, scale):
    frames = []
    for cell in cells:
        box = cell.getbbox()
        assert box is not None
        # Hat center anchors horizontal position; arm swings cannot shift the body.
        head = cell.crop((0, box[1], cell.width, box[1] + 100)).getbbox()
        center = (head[0] + head[2]) / 2
        small = cell.resize((round(cell.width*scale), round(cell.height*scale)), Image.Resampling.NEAREST)
        b = small.getbbox()
        frame = Image.new('RGBA', (FRAME, FRAME))
        frame.alpha_composite(small, (round(FRAME/2-center*scale), TOP-b[1]))
        assert frame.getbbox()[3] < FRAME - 2
        frames.append(frame)
    return frames

def caption(d, xy, text, size=15, fill='#e9e3cf'):
    try:
        font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', size)
    except OSError:
        font = ImageFont.load_default()
    d.text(xy, text, font=font, fill=fill)

def gif(frames, path, duration):
    # One palette for the whole sequence prevents palette flicker.
    atlas = Image.new('RGB', (frames[0].width*len(frames), frames[0].height))
    for i, frame in enumerate(frames):
        atlas.paste(frame.convert('RGB'), (i*frame.width, 0))
    palette = atlas.quantize(colors=256)
    paletted = [f.convert('RGB').quantize(palette=palette, dither=Image.Dither.NONE) for f in frames]
    paletted[0].save(path, save_all=True, append_images=paletted[1:], duration=duration, loop=0, disposal=2, optimize=False)

tracking_cells = cuts(SOURCE / 'walk-down/tracking-r1.png')
normal_cells = cuts(SOURCE / 'walk-down/materials-r1.png')
scale = HEIGHT / statistics.median(c.getbbox()[3]-c.getbbox()[1] for c in normal_cells)
normal = pack(normal_cells, scale)
tracking = pack(tracking_cells, scale)
idle_source = clean(Image.open(SOURCE / 'character-r1.png'))
ib = idle_source.getbbox()
idle_crop = idle_source.crop(ib)
idle_small = idle_crop.resize((round(idle_crop.width*HEIGHT/idle_crop.height), HEIGHT), Image.Resampling.NEAREST)
idle = Image.new('RGBA', (FRAME, FRAME))
idle.alpha_composite(idle_small, ((FRAME-idle_small.width)//2, TOP))
idle.save(ROOT/'idle-native.png')
frames_dir = ROOT/'frames'
frames_dir.mkdir(exist_ok=True)
strip = Image.new('RGBA', (FRAME*8, FRAME))
metrics=[]
for i, frame in enumerate(normal):
    frame.save(frames_dir/f'walk-down-{i+1:02}.png')
    strip.alpha_composite(frame, (i*FRAME, 0))
    b=frame.getbbox()
    metrics.append({'frame':i+1,'bbox':b,'height':b[3]-b[1], 'sha256':hashlib.sha256(frame.tobytes()).hexdigest()})
assert len({m['sha256'] for m in metrics}) == 8
strip.save(ROOT/'walk-down-strip.png')
preview=[]
diagnostic=[]
for i, frame in enumerate(normal):
    canvas=Image.new('RGBA',(880,400),'#20292c')
    d=ImageDraw.Draw(canvas)
    caption(d,(22,15),'WALK DOWN / 8 FRAMES / 10 FPS',20)
    caption(d,(30,66),'IDLE | FHD 1x')
    caption(d,(225,66),'WALK | FHD 1x')
    caption(d,(470,66),'WALK | DETAIL 2x')
    for x in (30,225):
        d.line((x,234,x+160,234),fill='#4b6661')
    canvas.alpha_composite(idle.resize((160,160),Image.Resampling.NEAREST), (30,90))
    canvas.alpha_composite(frame.resize((160,160),Image.Resampling.NEAREST), (225,90))
    canvas.alpha_composite(frame.resize((320,320),Image.Resampling.NEAREST), (475,70))
    caption(d,(30,287),'64 px artwork / integer 2x = 128 px screen height',14)
    caption(d,(30,312),'Preview only - awaiting approval',14, '#aac2bd')
    caption(d,(30,348),f'Frame {i+1:02} / 08',14)
    preview.append(canvas)
    check=Image.new('RGBA',(640,370),'#303a3e')
    check.alpha_composite(tracking[i].resize((320,320),Image.Resampling.NEAREST),(0,35))
    check.alpha_composite(frame.resize((320,320),Image.Resampling.NEAREST),(320,35))
    caption(ImageDraw.Draw(check),(15,10),f'LEG TRACKING / MATERIALS / FRAME {i+1}')
    diagnostic.append(check)
gif(preview,ROOT/'idle-walk-down.gif',100)
gif(diagnostic,ROOT/'leg-tracking-slow.gif',200)
preview[0].convert('RGB').save(ROOT/'preview-poster.png')
contact=Image.new('RGBA',(1280,390),'#303a3e')
for i,frame in enumerate(normal):
    contact.alpha_composite(tracking[i].resize((160,160),Image.Resampling.NEAREST),(i*160,25))
    contact.alpha_composite(frame.resize((160,160),Image.Resampling.NEAREST),(i*160,210))
    caption(ImageDraw.Draw(contact),(i*160+10,190),f'{i+1:02}')
contact.convert('RGB').save(ROOT/'contact-sheet.png')
report={'status':'awaiting user review; not integrated','frames':8,'fps':10,'canvas':[80,80],
        'native_target_height':64,'fhd_display_scale':2,'common_source_scale':scale,
        'idle_bbox':idle.getbbox(),'frames_metrics':metrics,
        'source_alpha_threshold':128,'resample':'nearest','anchor':'hat center and fixed head top',
        'limitations':['Prototype display size, not yet rendered inside the game.',
                        'ImageGen material restoration may alter pixels; inspect against tracking source.']}
ta = clean(Image.open(SOURCE/'walk-down/tracking-r1.png')).getchannel('A')
ma = clean(Image.open(SOURCE/'walk-down/materials-r1.png')).getchannel('A')
from PIL import ImageChops
intersection = ImageChops.darker(ta, ma).histogram()[255]
union = ImageChops.lighter(ta, ma).histogram()[255]
report['material_restoration_silhouette_iou'] = intersection / union
with Image.open(ROOT/'idle-walk-down.gif') as saved:
    assert saved.n_frames == 8
    durations = []
    for i in range(saved.n_frames):
        saved.seek(i)
        durations.append(saved.info['duration'])
    assert durations == [100] * 8
    report['gif_frame_durations_ms'] = durations
(ROOT/'validation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
