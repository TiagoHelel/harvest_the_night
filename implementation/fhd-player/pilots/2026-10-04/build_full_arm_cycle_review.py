"""Compose generated arm repairs, compare old poses and verify native scope."""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parent

def label(draw,xy,value,size=15):
    draw.text(xy,value,fill='#e9e3cf',font=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',size))

def save(frames,name,ms):
    atlas=Image.new('RGB',(frames[0].width*8,frames[0].height))
    for i,f in enumerate(frames): atlas.paste(f,(i*f.width,0))
    palette=atlas.quantize(colors=256)
    converted=[f.quantize(palette=palette,dither=Image.Dither.NONE) for f in frames]
    converted[0].save(ROOT/name,save_all=True,append_images=converted[1:],duration=ms,
                      loop=0,disposal=2,optimize=False)
    with Image.open(ROOT/name) as gif:
        assert gif.n_frames==8 and gif.info['loop']==0
        for i in range(8):
            gif.seek(i); assert gif.info['duration']==ms

normal=[]; slow=[]; tracking=[]
for i in range(8):
    canvas=Image.new('RGBA',(1040,420),'#20292c'); draw=ImageDraw.Draw(canvas)
    label(draw,(22,16),'UP DIAGONALS / FULL ARM CYCLE / 8 FRAMES / 10 FPS',19)
    before_after=Image.new('RGBA',(1280,380),'#303a3e'); bd=ImageDraw.Draw(before_after)
    colors=Image.new('RGBA',(1280,380),'#303a3e'); cd=ImageDraw.Draw(colors)
    for j,direction in enumerate(['up-right','up-left']):
        folder=ROOT/f'walk-{direction}'
        frame=Image.open(folder/f'frames/walk-{direction}-{i+1:02}.png').convert('RGBA')
        color=Image.open(folder/f'arm-tracking-frames/walk-{direction}-{i+1:02}.png').convert('RGBA')
        old=Image.open(folder/f'before-full-arm-cycle/frames/walk-{direction}-{i+1:02}.png').convert('RGBA')
        x=20+j*175
        label(draw,(x,66),f'{direction.upper()} | FHD 1x')
        canvas.alpha_composite(frame.resize((160,160),Image.Resampling.NEAREST),(x,90))
        x=365+j*335
        label(draw,(x+15,66),f'{direction.upper()} | DETAIL 2x')
        canvas.alpha_composite(frame.resize((320,320),Image.Resampling.NEAREST),(x,75))
        for offset,im,caption in [(0,old,'BEFORE'),(320,frame,'AFTER')]:
            x=j*640+offset
            before_after.alpha_composite(im.resize((320,320),Image.Resampling.NEAREST),(x,35))
            label(bd,(x+10,10),f'{direction.upper()} {caption} / {i+1}',14)
        for offset,im,caption in [(0,color,'ARM COLORS'),(320,frame,'MATERIALS')]:
            x=j*640+offset
            colors.alpha_composite(im.resize((320,320),Image.Resampling.NEAREST),(x,35))
            label(cd,(x+10,10),f'{direction.upper()} {caption} / {i+1}',14)
    label(draw,(22,370),'Both arms / full eight-pose revision / awaiting visual review',14)
    label(draw,(22,395),f'Frame {i+1:02} / 08 | Preview only',14)
    normal.append(canvas.convert('RGB')); slow.append(before_after.convert('RGB')); tracking.append(colors.convert('RGB'))
save(normal,'up-diagonal-full-arms-r13.gif',100)
save(slow,'up-diagonal-full-arms-before-after-r13.gif',200)
save(tracking,'up-diagonal-full-arms-tracking-r13.gif',200)
normal[4].save(ROOT/'up-diagonal-full-arms-poster.png')
baseline=json.loads((ROOT/'full-arm-cycle-baseline.json').read_text())
changed=[]
for name,old_hash in baseline.items():
    path=ROOT/name; im=Image.open(path).convert('RGBA')
    assert im.size==(80,80) and set(im.getchannel('A').tobytes()) <= {0,255}
    if hashlib.sha256(path.read_bytes()).hexdigest()!=old_hash:
        changed.append(name)
        assert name.startswith(('walk-up-right/frames/','walk-up-left/frames/')),name
assert len(changed)==16,changed
report={'date':'2026-10-05','status':'awaiting user review; preview only',
        'scope_checks':'PASS','changed_frames':changed,'unchanged_frame_count':len(baseline)-len(changed),
        'fps':10,'canvas':[80,80],'display_scale':2,'gif_durations_ms':[100]*8,
        'slow_gif_durations_ms':[200]*8,'runtime_changes':False,'engine_suite_rerun':False,
        'color_diagnostic':{d:json.loads((ROOT/f'walk-{d}/arm-color-motion.json').read_text())['gates']
                            for d in ['up-right','up-left']},
        'visual_gate':'NOT MET: UP-LEFT near-arm7-to8 is still too abrupt for the requested smooth cycle.',
        'limits_reached':'Three targeted ImageGen revisions per direction, as required by sprite runner42-44.',
        'limitations':['Generated edits retain design rather than byte-exact pixels inside edited poses.',
                       'UP-RIGHT R12 diagnostic far-arm vertical range5px fails the planned6px gate; R13 requests a larger arc.',
                       'Colored motion measurements do not establish final restored-arm anatomy, gait coherence or user approval.']}
(ROOT/'full-arm-cycle-validation.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
