"""Compose existing walk frames side by side; never regenerate sprite artwork."""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
DIRECTIONS = ['down', 'right', 'up', 'left', 'down-right', 'up-right', 'up-left']
STATUS = json.loads((ROOT/'directions-status.json').read_text(encoding='utf-8'))
DURATION = 100
SCALE = 2
WIDTH, HEIGHT = 40 + 200 * len(DIRECTIONS), 330
BACKGROUND = '#20292c'

def font(size):
    return ImageFont.truetype('C:/Windows/Fonts/consola.ttf', size)

def centered(draw, x, y, label, size=17, color='#e9e3cf'):
    f = font(size)
    box = draw.textbbox((0, 0), label, font=f)
    draw.text((x-(box[2]-box[0])/2, y), label, font=f, fill=color)

inputs = {}
for direction in DIRECTIONS:
    inputs[direction] = []
    for i in range(8):
        path = ROOT/f'walk-{direction}/frames/walk-{direction}-{i+1:02}.png'
        im = Image.open(path).convert('RGBA')
        assert im.size == (80,80), (path, im.size)
        inputs[direction].append((im, path, hashlib.sha256(path.read_bytes()).hexdigest()))

frames = []
for i in range(8):
    canvas = Image.new('RGBA', (WIDTH,HEIGHT), BACKGROUND)
    draw = ImageDraw.Draw(canvas)
    draw.text((24,16), f'FARMER WALK / {len(DIRECTIONS)} DIRECTIONS / 8 FRAMES / 10 FPS', font=font(20), fill='#e9e3cf')
    draw.text((24,45), 'Same integer 2x scale / about 128 px character height', font=font(14), fill='#aac2bd')
    for j, direction in enumerate(DIRECTIONS):
        center = 120+j*200
        centered(draw,center,76,direction.upper())
        im = inputs[direction][i][0]
        canvas.alpha_composite(im.resize((160,160),Image.Resampling.NEAREST),(center-80,100))
        approved = STATUS[f'walk_{direction.replace("-","_")}']['status'] == 'approved'
        centered(draw,center,269,'APPROVED' if approved else 'IN REVIEW',14,
                 '#95be9c' if approved else '#ebbe78')
    draw.text((24,307), f'Frame {i+1:02} / 08 | Existing preview frames - no game integration',
              font=font(13),fill='#aac2bd')
    frames.append(canvas.convert('RGB'))

# One shared palette avoids temporal flicker between direction frames.
atlas = Image.new('RGB',(WIDTH*8,HEIGHT))
for i,frame in enumerate(frames):
    atlas.paste(frame,(i*WIDTH,0))
palette = atlas.quantize(colors=256)
quantized = [f.quantize(palette=palette,dither=Image.Dither.NONE) for f in frames]
output = ROOT/'all-walk-directions.gif'
quantized[0].save(output,save_all=True,append_images=quantized[1:],duration=DURATION,
                  loop=0,disposal=2,optimize=False)
with Image.open(output) as gif:
    assert gif.size == (WIDTH,HEIGHT)
    assert gif.n_frames == 8
    assert gif.info['loop'] == 0
    for i in range(8):
        gif.seek(i)
        assert gif.info['duration'] == DURATION
frames[0].save(ROOT/'all-walk-directions-poster.png')
report = {'directions':DIRECTIONS,'canvas':[WIDTH,HEIGHT],'frames':8,'fps':10,
          'durations_ms':[DURATION]*8,'display_scale':SCALE,'resample':'nearest',
          'output':'all-walk-directions.gif','changes_to_source_frames':False,
          'review_status':{d:STATUS[f'walk_{d.replace("-","_")}']['status'] for d in DIRECTIONS},
          'inputs':{d:[{'path':str(p.relative_to(ROOT)).replace('\\','/'),'sha256':h}
                      for _,p,h in poses] for d,poses in inputs.items()}}
(ROOT/'all-walk-directions-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(output)
