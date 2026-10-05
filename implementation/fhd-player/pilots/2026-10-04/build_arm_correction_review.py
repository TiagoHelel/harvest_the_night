"""Compose corrected sprites and verify the authorized preview-only scope."""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent


def label(draw, xy, text, size=15):
    draw.text(xy, text, fill='#e9e3cf',
              font=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',size))


def save_gif(frames, name, duration):
    atlas=Image.new('RGB',(frames[0].width*8,frames[0].height))
    for i,frame in enumerate(frames):
        atlas.paste(frame,(i*frame.width,0))
    palette=atlas.quantize(colors=256)
    quantized=[frame.quantize(palette=palette,dither=Image.Dither.NONE) for frame in frames]
    quantized[0].save(ROOT/name,save_all=True,append_images=quantized[1:],duration=duration,
                      loop=0,disposal=2,optimize=False)
    with Image.open(ROOT/name) as saved:
        assert saved.n_frames==8 and saved.info['loop']==0
        for i in range(8):
            saved.seek(i)
            assert saved.info['duration']==duration


frames=[]
before_after=[]
for i in range(8):
    up=Image.open(ROOT/f'walk-up-left/frames/walk-up-left-{i+1:02}.png').convert('RGBA')
    down=Image.open(ROOT/f'walk-down-right/frames/walk-down-right-{i+1:02}.png').convert('RGBA')
    old=Image.open(ROOT/f'walk-up-left/before-arms-2026-10-05/frames/walk-up-left-{i+1:02}.png').convert('RGBA')
    canvas=Image.new('RGBA',(1040,420),'#20292c')
    draw=ImageDraw.Draw(canvas)
    label(draw,(22,16),'ARM CORRECTIONS / 8 FRAMES / 10 FPS',20)
    for text,x in [('UP-LEFT | FHD 1x',20),('DOWN-RIGHT | FHD 1x',195),
                   ('UP-LEFT | DETAIL 2x',390),('DOWN-RIGHT | DETAIL 2x',720)]:
        label(draw,(x,66),text)
    for x,im,size in [(20,up,160),(195,down,160),(365,up,320),(700,down,320)]:
        canvas.alpha_composite(im.resize((size,size),Image.Resampling.NEAREST),
                               (x,90 if size==160 else 75))
    label(draw,(22,370),'UP-LEFT: opposing arm swing / DOWN-RIGHT: frame4 sleeve cleanup',14)
    label(draw,(22,395),f'Frame {i+1:02} / 08 | Preview only - awaiting review',14)
    frames.append(canvas.convert('RGB'))
    check=Image.new('RGBA',(640,370),'#303a3e')
    check.alpha_composite(old.resize((320,320),Image.Resampling.NEAREST),(0,35))
    check.alpha_composite(up.resize((320,320),Image.Resampling.NEAREST),(320,35))
    label(ImageDraw.Draw(check),(15,10),f'UP-LEFT BEFORE / AFTER | FRAME {i+1}',14)
    before_after.append(check.convert('RGB'))
save_gif(frames,'arm-corrections.gif',100)
save_gif(before_after,'up-left-arms-before-after.gif',200)
frames[3].save(ROOT/'arm-corrections-poster.png')

baseline=json.loads((ROOT/'arm-correction-baseline.json').read_text())
changed=[]
for path,old_hash in baseline.items():
    path=path.replace('\\','/')
    file=ROOT/path
    if hashlib.sha256(file.read_bytes()).hexdigest()!=old_hash:
        changed.append(path)
        assert path.startswith('walk-up-left/frames/') or path=='walk-down-right/frames/walk-down-right-04.png',path
    im=Image.open(file).convert('RGBA')
    assert im.size==(80,80) and set(im.getchannel('A').tobytes()) <= {0,255}
assert 'walk-down-right/frames/walk-down-right-04.png' in changed
report={'date':'2026-10-05','status':'awaiting user approval; preview only',
        'changed_frames':changed,'unchanged_frame_count':len(baseline)-len(changed),
        'down_right_unchanged_frames':[1,2,3,5,6,7,8],
        'native_canvas':[80,80],'display_scale':2,'fps':10,'loop':0,
        'art_method':'built-in ImageGen edits; deterministic alpha/cuts/nearest/GIF composition',
        'visual_checks':'Manual source and native inspection; frame counts do not prove anatomy or gait.',
        'runtime_changes':False,'full_engine_suite_rerun':False}
(ROOT/'arm-correction-validation.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
