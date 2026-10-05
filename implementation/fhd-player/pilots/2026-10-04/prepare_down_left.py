"""One-time approval/bootstrap: do not rerun after DOWN-LEFT production starts."""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw

PILOT = Path(__file__).resolve().parent
REPO = PILOT.parents[3]
HERE = PILOT / 'walk-down-left'
SOURCE = REPO / 'assets/art_source/player-fhd/pilots/2026-10-04/walk-down-left'
HERE.mkdir(exist_ok=True); SOURCE.mkdir(parents=True, exist_ok=True)
ur = PILOT / 'selected-UR03-UL03/UR03/revisions/boot4-r4/frames'
hashes = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(ur.glob('*.png'))}
assert len(hashes) == 8
approval = {'date': '2026-10-05', 'status': 'approved', 'user_feedback': 'ta bom vai, ok',
            'candidate': 'UR03/revisions/boot4-r4/frames', 'frame_sha256': hashes, 'runtime_integrated': False}
(PILOT / 'selected-UR03-UL03/UR03-approval.json').write_text(json.dumps(approval, indent=2) + '\n')
status_path = PILOT / 'directions-status.json'
status = json.loads(status_path.read_text())
status['walk_up_right'].update(status='approved', approval_date='2026-10-05', user_feedback='ta bom vai, ok',
    review_limit='User approved exact UR03 boot4-r4 cycle. No runtime promotion.')
status['walk_up_right']['selected_archive_review'].update(status='approved', user_feedback='ta bom vai, ok', approved_frame_sha256=hashes)
status['walk_down_left'] = {'status': 'in_progress', 'date': '2026-10-05',
    'workflow': 'Rotate first, opposite contacts, fixed anatomical cyan/magenta ownership, two four-pose transitions, material restoration.',
    'runtime_integrated': False}
status_path.write_text(json.dumps(status, indent=2) + '\n')
path = PILOT / 'selected-UR03-UL03/index.html'
html = path.read_text().replace('UR03 cycle awaits review.', 'UR03 and UL03 cycles approved.')
path.write_text(html)
call_path = PILOT / 'selected-UR03-UL03/UR03-boot4-r4.call.json'
call = json.loads(call_path.read_text()); call.update(status='approved by user2026-10-05', user_approval='ta bom vai, ok')
call_path.write_text(json.dumps(call, indent=2) + '\n')
baseline = {str(p.relative_to(PILOT)).replace('\\', '/'): hashlib.sha256(p.read_bytes()).hexdigest()
    for folder in PILOT.glob('walk-*/frames') for p in folder.glob('*.png')}
baseline.update({str(p.relative_to(PILOT)).replace('\\', '/'): hashlib.sha256(p.read_bytes()).hexdigest() for p in ur.glob('*.png')})
ul = PILOT / 'selected-UR03-UL03/UL03/frames'
baseline.update({str(p.relative_to(PILOT)).replace('\\', '/'): hashlib.sha256(p.read_bytes()).hexdigest() for p in ul.glob('*.png')})
(HERE / 'baseline.json').write_text(json.dumps(baseline, indent=2) + '\n')
for name, path in [('approved-down', PILOT / 'walk-down/frames/walk-down-01.png'),
                   ('approved-left', PILOT / 'walk-left/frames/walk-left-01.png'),
                   ('diagonal-proportions', PILOT / 'walk-down-right/frames/walk-down-right-01.png')]:
    Image.open(path).convert('RGBA').resize((640, 640), Image.Resampling.NEAREST).save(SOURCE / f'{name}-reference.png')
timeline = Image.new('RGBA', (320, 160))
for i in range(8):
    path = PILOT / f'walk-down-right/frames/walk-down-right-{i+1:02}.png'
    timeline.alpha_composite(Image.open(path).convert('RGBA'), ((i%4)*80, (i//4)*80))
timeline.resize((1280, 640), Image.Resampling.NEAREST).save(SOURCE / 'down-right-eight-reference.png')
timeline.crop((0, 0, 320, 80)).resize((1280, 320), Image.Resampling.NEAREST).save(SOURCE / 'down-right-four-reference.png')
# Plain kinematic diagram only: never paints production farmer art.
feet = [((33,70),(48,65)), ((36,70),(47,61)), ((41,70),(42,61)), ((46,67),(34,65)),
        ((48,64),(32,70)), ((46,60),(36,70)), ((40,61),(40,70)), ((34,65),(45,68))]
knees = [((38,56),(44,55)), ((40,57),(44,54)), ((43,57),(40,53)), ((45,55),(36,56)),
         ((45,54),(36,57)), ((44,53),(39,57)), ((41,53),(42,57)), ((36,56),(44,55))]
canvas = Image.new('RGB', (1280,640), '#edf0e8'); draw = ImageDraw.Draw(canvas)
for i, (ends, bends) in enumerate(zip(feet,knees)):
    ox,oy=(i%4)*320,(i//4)*320
    draw.text((ox+10,oy+8), f'{i+1}: LEFT CYAN / RIGHT MAGENTA', fill='black')
    def pt(p): return (ox+p[0]*4,oy+p[1]*4)
    draw.ellipse((*pt((30,8)),*pt((50,27))), fill='#aaa')
    draw.polygon([pt((29,18)),pt((23,22)),pt((29,25))], fill='#555')
    draw.rectangle((*pt((34,28)),*pt((47,44))), fill='#aaa')
    # Far right chain first, then near left chain; roots never exchange.
    for j,hip,color in [(1,(37,44),'#e42aad'),(0,(44,44),'#00bfc9')]:
        draw.line([pt(hip),pt(bends[j]),pt(ends[j])], fill=color, width=9)
        draw.ellipse((pt((hip[0]-2,hip[1]-2))+pt((hip[0]+2,hip[1]+2))), fill=color, outline='black')
        fx,fy=ends[j]; draw.line([pt((fx-4,fy)),pt((fx+2,fy))],fill=color,width=8)
    draw.line([pt((25,73)),pt((58,73))],fill='#999',width=1)
canvas.save(SOURCE / 'ownership-eight-guide.png')
for name,row in [('transition-a-guide',0),('transition-b-guide',1)]:
    out=Image.new('RGB',(640,640),'white')
    for j in range(4): out.paste(canvas.crop((j*320,row*320,(j+1)*320,(row+1)*320)),((j%2)*320,(j//2)*320))
    out.save(SOURCE / f'{name}.png')
print('UR03 approved;72existing/approved native frames frozen; down-left guides/references ready.')
