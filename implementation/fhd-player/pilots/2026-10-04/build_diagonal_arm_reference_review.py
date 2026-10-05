"""Export reference-driven arm edits and compare them with the existing diagonal."""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw
from full_arm_cycle_export import sample
from build_hand_rebuild_review import caption, save_gif

ROOT=Path(__file__).resolve().parent
DIRECTIONS=['up-right','up-left']

def build(selection,promote=False,revision='r17'):
    assert not promote,'No reference candidate passed the visual gate; promotion is disabled.'
    data={d:sample(d,selection[d],'frames' if promote else 'reference-arm-candidate') for d in DIRECTIONS}
    normal=[]; slow=[]; per_direction={d:[] for d in DIRECTIONS}
    contact=Image.new('RGBA',(1280,400),'#303a3e')
    for i in range(8):
        canvas=Image.new('RGBA',(960,360),'#20292c'); draw=ImageDraw.Draw(canvas)
        caption(draw,(20,16),'DIAGONAL WALK / REFERENCE ARM SWING / 8 FRAMES / 10 FPS',17)
        ref=Image.open(ROOT/f'walk-down-right/frames/walk-down-right-{i+1:02}.png').convert('RGBA')
        for j,d in enumerate(['down-right']+DIRECTIONS):
            im=ref if j==0 else data[d][0][i]
            x=70+j*290
            caption(draw,(x+5,70),d.upper(),15)
            caption(draw,(x+5,92),'REFERENCE' if j==0 else 'FHD 1x',13)
            canvas.alpha_composite(im.resize((160,160),Image.Resampling.NEAREST),(x,110))
        check=Image.new('RGBA',(1280,380),'#303a3e'); cd=ImageDraw.Draw(check)
        for j,d in enumerate(DIRECTIONS):
            folder=ROOT/f'walk-{d}'; frame=data[d][0][i]
            old=Image.open(folder/f'before-diagonal-arm-reference/frames/walk-{d}-{i+1:02}.png').convert('RGBA')
            for offset,im,label in [(0,old,'BEFORE'),(320,frame,'REFERENCE EDIT')]:
                xx=j*640+offset
                check.alpha_composite(im.resize((320,320),Image.Resampling.NEAREST),(xx,35))
                caption(cd,(xx+10,10),f'{d.upper()} {label} / {i+1}',13)
            contact.alpha_composite(frame.resize((160,160),Image.Resampling.NEAREST),(i*160,j*195+25))
            caption(ImageDraw.Draw(contact),(i*160+10,j*195+5),f'{d.upper()} {i+1}',12)
            idle=Image.open(folder/'idle-native.png').convert('RGBA')
            standing=Image.new('RGBA',(880,400),'#20292c'); sd=ImageDraw.Draw(standing)
            caption(sd,(20,15),f'WALK {d.upper()} / REFERENCE ARM SWING / 10 FPS',18)
            for xx,im,size,label in [(30,idle,160,'MASTER | FHD 1x'),(225,frame,160,'WALK | FHD 1x'),(475,frame,320,'WALK | DETAIL 2x')]:
                caption(sd,(xx,66),label)
                standing.alpha_composite(im.resize((size,size),Image.Resampling.NEAREST),(xx,90 if size==160 else 75))
            caption(sd,(30,312),'Preview only - awaiting visual approval',14)
            caption(sd,(30,350),f'Frame {i+1:02} / 08',14)
            per_direction[d].append(standing.convert('RGB'))
        caption(draw,(20,285),'Approved motion reference: original DOWN-RIGHT poses 1,2,3,5,6,7,8',12)
        caption(draw,(20,305),'Displayed DOWN-RIGHT pose 4: separate repair still in review',12)
        caption(draw,(20,335),f'Frame {i+1:02} / 08 | Candidate not accepted: arm continuity unresolved',14)
        normal.append(canvas.convert('RGB')); slow.append(check.convert('RGB'))
    save_gif(normal,ROOT/f'up-diagonal-reference-arms-{revision}.gif',100)
    save_gif(slow,ROOT/f'up-diagonal-reference-before-after-{revision}.gif',200)
    contact.convert('RGB').save(ROOT/'diagonal-arm-reference-contact-sheet.png')
    normal[0].save(ROOT/'diagonal-arm-reference-poster.png')
    if promote:
        baseline=json.loads((ROOT/'diagonal-arm-reference-baseline.json').read_text())
        changed=[]
        for name,sha in baseline.items():
            if hashlib.sha256((ROOT/name).read_bytes()).hexdigest()!=sha:
                assert name.startswith(('walk-up-right/frames/','walk-up-left/frames/')),name
                changed.append(name)
        assert len(changed)==16
        for d in DIRECTIONS:
            frames,report=data[d]; folder=ROOT/f'walk-{d}'
            sheet=Image.new('RGBA',(1280,390),'#303a3e')
            for i,frame in enumerate(frames):
                old=Image.open(folder/f'before-diagonal-arm-reference/frames/walk-{d}-{i+1:02}.png').convert('RGBA')
                for y,im,label in [(25,old,'BEFORE'),(210,frame,'REFERENCE EDIT')]:
                    sheet.alpha_composite(im.resize((160,160),Image.Resampling.NEAREST),(i*160,y))
                    caption(ImageDraw.Draw(sheet),(i*160+8,y-20),f'{i+1} | {label}',12)
            sheet.convert('RGB').save(folder/'contact-sheet.png')
            save_gif(per_direction[d],folder/f'idle-walk-{d}.gif',100)
            report.update(status='awaiting user visual approval; preview only',frames=8,fps=10,fhd_display_scale=2,
                          limitations=['Generated edits are not byte-exact outside arms within edited poses.',
                                       'Scope/format checks do not prove smooth movement or anatomy.'])
            (folder/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
        report={'date':'2026-10-05','status':'awaiting visual approval; not integrated',
                'selected_sources':selection,'scope_checks':'PASS','changed_frames':changed,
                'unchanged_frame_count':len(baseline)-len(changed),'native_canvas':[80,80],
                'fps':10,'display_scale':2,'gif_durations_ms':[100]*8,'slow_durations_ms':[200]*8,
                'runtime_changes':False,'engine_suite_rerun':False,
                'reference':'Seven original accepted DOWN-RIGHT R5 poses; reopened pose4 excluded from generation input.',
                'visual_review':'See generation calls for candidate findings; awaiting user approval.'}
        (ROOT/'diagonal-arm-reference-validation.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({d:{'heights':[m['height'] for m in data[d][1]['frames_metrics']],
                          'hat_widths':[m['hat_region_width'] for m in data[d][1]['frames_metrics']]} for d in DIRECTIONS}))

if __name__=='__main__':
    import sys
    selection=json.loads((ROOT/'diagonal-arm-reference-selection.json').read_text())
    revision=sys.argv[sys.argv.index('--revision')+1] if '--revision' in sys.argv else 'r17'
    build(selection,'--promote-preview' in sys.argv,revision)
