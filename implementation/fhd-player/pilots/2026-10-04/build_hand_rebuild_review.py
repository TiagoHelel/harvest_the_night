"""Sample generated hand edits, compose reviews and verify isolated preview scope."""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw, ImageFont
from full_arm_cycle_export import sample

ROOT=Path(__file__).resolve().parent
DIRECTIONS=['up-right','up-left']

def caption(draw,xy,value,size=15):
    draw.text(xy,value,fill='#e9e3cf',font=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',size))

def save_gif(frames,path,ms):
    atlas=Image.new('RGB',(frames[0].width*8,frames[0].height))
    for i,frame in enumerate(frames): atlas.paste(frame,(i*frame.width,0))
    palette=atlas.quantize(colors=256)
    frames=[f.quantize(palette=palette,dither=Image.Dither.NONE) for f in frames]
    frames[0].save(path,save_all=True,append_images=frames[1:],duration=ms,
                   loop=0,disposal=2,optimize=False)
    with Image.open(path) as gif:
        assert gif.n_frames==8 and gif.info['loop']==0
        for i in range(8):
            gif.seek(i); assert gif.info['duration']==ms

def build(selection,promote=False,revision='r14'):
    data={}; normal=[]; slow=[]; idle_previews={d:[] for d in DIRECTIONS}
    contact=Image.new('RGBA',(1280,400),'#303a3e')
    for direction in DIRECTIONS:
        frames,report=sample(direction,selection[direction],'frames' if promote else 'hand-candidate')
        data[direction]=(frames,report)
    for i in range(8):
        canvas=Image.new('RGBA',(1040,420),'#20292c'); draw=ImageDraw.Draw(canvas)
        caption(draw,(22,16),'UP DIAGONALS / HAND REBUILD / 8 FRAMES / 10 FPS',19)
        check=Image.new('RGBA',(1280,380),'#303a3e'); cd=ImageDraw.Draw(check)
        for j,direction in enumerate(DIRECTIONS):
            frame=data[direction][0][i]; folder=ROOT/f'walk-{direction}'
            old=Image.open(folder/f'before-hand-rebuild/frames/walk-{direction}-{i+1:02}.png').convert('RGBA')
            for x,size,y in [(20+j*175,160,90),(365+j*335,320,75)]:
                caption(draw,(x+5,66),f'{direction.upper()} | '+('FHD 1x' if size==160 else 'DETAIL 2x'))
                canvas.alpha_composite(frame.resize((size,size),Image.Resampling.NEAREST),(x,y))
            for offset,im,label in [(0,old,'BEFORE'),(320,frame,'NEW HANDS')]:
                x=j*640+offset
                check.alpha_composite(im.resize((320,320),Image.Resampling.NEAREST),(x,35))
                caption(cd,(x+10,10),f'{direction.upper()} {label} / {i+1}',13)
            contact.alpha_composite(frame.resize((160,160),Image.Resampling.NEAREST),(i*160,j*195+25))
            caption(ImageDraw.Draw(contact),(i*160+10,j*195+5),f'{direction.upper()} {i+1}',12)
            idle=Image.open(folder/'idle-native.png').convert('RGBA')
            standing=Image.new('RGBA',(880,400),'#20292c'); sd=ImageDraw.Draw(standing)
            caption(sd,(22,15),f'WALK {direction.upper()} / HAND REBUILD / 10 FPS',19)
            for x,im,size,label in [(30,idle,160,'MASTER | FHD 1x'),(225,frame,160,'WALK | FHD 1x'),
                                     (475,frame,320,'WALK | DETAIL 2x')]:
                caption(sd,(x,66),label)
                standing.alpha_composite(im.resize((size,size),Image.Resampling.NEAREST),(x,90 if size==160 else 75))
            caption(sd,(30,312),'Preview only - awaiting visual approval',14)
            caption(sd,(30,350),f'Frame {i+1:02} / 08',14)
            idle_previews[direction].append(standing.convert('RGB'))
        caption(draw,(22,370),'Compact hands / connected wrists / awaiting visual review',14)
        caption(draw,(22,395),f'Frame {i+1:02} / 08 | Preview only',14)
        normal.append(canvas.convert('RGB')); slow.append(check.convert('RGB'))
    save_gif(normal,ROOT/f'up-diagonal-hands-{revision}.gif',100)
    save_gif(slow,ROOT/f'up-diagonal-hands-before-after-{revision}.gif',200)
    contact.convert('RGB').save(ROOT/'hand-rebuild-contact-sheet.png')
    normal[0].save(ROOT/'up-diagonal-hands-poster.png')
    if not promote:
        print('Candidate GIF exported without replacing current native frames.')
        return
    baseline=json.loads((ROOT/'hand-rebuild-baseline.json').read_text())
    changed=[]
    for name,old_hash in baseline.items():
        path=ROOT/name
        if hashlib.sha256(path.read_bytes()).hexdigest()!=old_hash:
            changed.append(name)
            assert name.startswith(('walk-up-right/frames/','walk-up-left/frames/')),name
    assert len(changed)==16,changed
    for direction in DIRECTIONS:
        frames,report=data[direction]; folder=ROOT/f'walk-{direction}'
        contact=Image.new('RGBA',(1280,390),'#303a3e')
        for i,frame in enumerate(frames):
            old=Image.open(folder/f'before-hand-rebuild/frames/walk-{direction}-{i+1:02}.png').convert('RGBA')
            for y,im,label in [(25,old,'BEFORE'),(210,frame,'HANDS R15')]:
                contact.alpha_composite(im.resize((160,160),Image.Resampling.NEAREST),(i*160,y))
                caption(ImageDraw.Draw(contact),(i*160+8,y-20),f'{i+1} | {label}',12)
        contact.convert('RGB').save(folder/'contact-sheet.png')
        save_gif(idle_previews[direction],folder/f'idle-walk-{direction}.gif',100)
        report.update(status='awaiting user review; preview only',frames=8,fps=10,fhd_display_scale=2,
                      gif_frame_durations_ms=[100]*8,
                      limitations=['Generated arm edits are not byte-exact outside hands inside edited poses.',
                                   'Frame and scope checks do not prove anatomy or smooth motion.'])
        (folder/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
    report={'date':'2026-10-05','status':'awaiting user visual review; not integrated',
            'scope_checks':'PASS','changed_frames':changed,'unchanged_frame_count':len(baseline)-len(changed),
            'selected_sources':selection,'fps':10,'canvas':[80,80],'display_scale':2,
            'gif_durations_ms':[100]*8,'slow_gif_durations_ms':[200]*8,
            'runtime_changes':False,'engine_suite_rerun':False,
            'visual_review':'Compact hand/wrist candidate selected after rejecting R14 raised paddles and R16 bulky bent fist.',
            'remaining_review':['UP-RIGHT far-left arm travel remains subtle in R15; do not mark the earlier full arm-smoothing gate resolved.',
                                'User must approve hand silhouettes and loop continuity at normal preview size.'],
            'limits':'Automated scope/format checks are not user approval.'}
    (ROOT/'hand-rebuild-validation.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({d:{'heights':[p['height'] for p in data[d][1]['frames_metrics']],
                       'hat_widths':[p['hat_region_width'] for p in data[d][1]['frames_metrics']]}
                      for d in DIRECTIONS},indent=2))

if __name__=='__main__':
    import sys
    selection=json.loads((ROOT/'hand-rebuild-selection.json').read_text())
    revision=sys.argv[sys.argv.index('--revision')+1] if '--revision' in sys.argv else 'r14'
    build(selection,promote='--promote-preview' in sys.argv,revision=revision)
