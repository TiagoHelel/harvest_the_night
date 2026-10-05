"""Compare native corrections, their old poses and authorized scope."""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parent

def text(draw,xy,label,size=15):
    draw.text(xy,label,fill='#e9e3cf',font=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',size))

def save(frames,name,ms):
    atlas=Image.new('RGB',(frames[0].width*8,frames[0].height))
    for i,frame in enumerate(frames): atlas.paste(frame,(i*frame.width,0))
    palette=atlas.quantize(colors=256)
    frames=[f.quantize(palette=palette,dither=Image.Dither.NONE) for f in frames]
    frames[0].save(ROOT/name,save_all=True,append_images=frames[1:],duration=ms,
                   loop=0,disposal=2,optimize=False)
    with Image.open(ROOT/name) as gif:
        assert gif.n_frames==8 and gif.info['loop']==0
        for i in range(8):
            gif.seek(i); assert gif.info['duration']==ms

normal=[]; slow=[]
for i in range(8):
    right=Image.open(ROOT/f'walk-up-right/frames/walk-up-right-{i+1:02}.png').convert('RGBA')
    left=Image.open(ROOT/f'walk-up-left/frames/walk-up-left-{i+1:02}.png').convert('RGBA')
    canvas=Image.new('RGBA',(1040,420),'#20292c'); d=ImageDraw.Draw(canvas)
    text(d,(22,16),'UP DIAGONALS / ARM SMOOTHING / 8 FRAMES / 10 FPS',19)
    for label,x in [('UP-RIGHT | FHD 1x',20),('UP-LEFT | FHD 1x',195),
                    ('UP-RIGHT | DETAIL 2x',390),('UP-LEFT | DETAIL 2x',720)]:
        text(d,(x,66),label)
    for x,im,size in [(20,right,160),(195,left,160),(365,right,320),(700,left,320)]:
        canvas.alpha_composite(im.resize((size,size),Image.Resampling.NEAREST),
                               (x,90 if size==160 else 75))
    text(d,(22,370),'UP-RIGHT: continuous far left arm / UP-LEFT: modest swing5/6',14)
    text(d,(22,395),f'Frame {i+1:02} / 08 | Preview only - awaiting review',14)
    normal.append(canvas.convert('RGB'))
    check=Image.new('RGBA',(1280,380),'#303a3e'); sd=ImageDraw.Draw(check)
    for j,(direction,now) in enumerate([('up-right',right),('up-left',left)]):
        old=Image.open(ROOT/f'walk-{direction}/before-arm-smoothing/frames/walk-{direction}-{i+1:02}.png').convert('RGBA')
        for offset,im,label in [(0,old,'BEFORE'),(320,now,'AFTER')]:
            x=j*640+offset
            check.alpha_composite(im.resize((320,320),Image.Resampling.NEAREST),(x,35))
            text(sd,(x+10,10),f'{direction.upper()} {label} / {i+1}',14)
    slow.append(check.convert('RGB'))
save(normal,'up-diagonal-arms.gif',100)
save(slow,'up-diagonal-arms-before-after.gif',200)
normal[4].save(ROOT/'up-diagonal-arms-poster.png')
before=json.loads((ROOT/'arm-smoothing-baseline.json').read_text())
changed=[]
for name,old_hash in before.items():
    path=ROOT/name; im=Image.open(path).convert('RGBA')
    assert im.size==(80,80) and set(im.getchannel('A').tobytes()) <= {0,255}
    if hashlib.sha256(path.read_bytes()).hexdigest()!=old_hash:
        changed.append(name)
        assert name.startswith('walk-up-right/frames/') or name in [
            'walk-up-left/frames/walk-up-left-05.png','walk-up-left/frames/walk-up-left-06.png'],name
assert len(changed)==10,changed
report={'date':'2026-10-05','status':'awaiting user review; preview only',
        'changed_frames':changed,'unchanged_frame_count':len(before)-len(changed),
        'unchanged_up_left':[1,2,3,4,7,8],'fps':10,'canvas':[80,80],'display_scale':2,
        'gif_durations_ms':[100]*8,'slow_gif_durations_ms':[200]*8,
        'runtime_changes':False,'engine_suite_rerun':False,
        'limitations':['Generated edits preserve design, not byte-exact pixels inside edited poses.',
                       'Frame counts and scope assertions do not prove anatomy or motion quality.']}
(ROOT/'arm-smoothing-validation.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
