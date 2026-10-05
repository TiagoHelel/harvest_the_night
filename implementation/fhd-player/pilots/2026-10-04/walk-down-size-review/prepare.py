"""Freeze selected native frames and pack references without modifying art."""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
PILOT = HERE.parent
REPO = PILOT.parents[3]
SOURCE = REPO / 'assets/art_source/player-fhd/pilots/2026-10-04/walk-down-size-review'
SOURCE.mkdir(parents=True, exist_ok=True)

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

selected = json.loads((PILOT / 'walk-down-left/aggregate-selection.json').read_text())
baseline = {item['path']: digest(PILOT / item['path']) for items in selected.values() for item in items}
assert len(baseline) == 64
baseline_path = HERE / 'baseline.json'
if baseline_path.exists():
    assert json.loads(baseline_path.read_text()) == baseline
else:
    baseline_path.write_text(json.dumps(baseline, indent=2) + '\n')
for direction, name in [('down', 'old-down-eight'), ('right', 'right-eight-reference'), ('down-left', 'down-left-eight-reference')]:
    atlas = Image.new('RGBA', (320, 160))
    for i, item in enumerate(selected[direction]):
        frame = Image.open(PILOT / item['path']).convert('RGBA')
        atlas.alpha_composite(frame, ((i%4)*80, (i//4)*80))
    atlas.resize((1920,960), Image.Resampling.NEAREST).save(SOURCE / f'{name}.png')
old = Image.open(PILOT / selected['down'][0]['path']).convert('RGBA')
old.resize((640,640), Image.Resampling.NEAREST).save(SOURCE / 'old-down-pose.png')
# Kinematic pose guide only, never a drawing of the production farmer.
guide = Image.new('RGB', (1280,640), '#edf0e8')
draw = ImageDraw.Draw(guide)
font = ImageFont.truetype('C:/Windows/Fonts/consola.ttf', 13)
leg = [((34,67),(47,70)),((33,62),(47,69)),((35,60),(45,68)),((37,66),(45,66)),
       ((34,70),(47,67)),((34,69),(48,62)),((36,68),(45,60)),((36,66),(43,66))]
for i, (right_foot, left_foot) in enumerate(leg):
    ox,oy=(i%4)*320,(i//4)*320
    def pt(p): return (ox+p[0]*4,oy+p[1]*4)
    draw.text((ox+6,oy+7), f'{i+1}: RIGHT MAGENTA / LEFT CYAN', fill='black', font=font)
    draw.ellipse((*pt((30,8)),*pt((50,26))), fill='#aaa')
    draw.rectangle((*pt((33,27)),*pt((47,43))), fill='#aaa')
    for hip, foot, color in [((35,43),right_foot,'#e42aad'),((45,43),left_foot,'#00bfc9')]:
        knee=((hip[0]+foot[0])/2, (43+foot[1])/2)
        draw.line([pt(hip),pt(knee),pt(foot)], fill=color, width=13)
        draw.line([pt((foot[0]-3,foot[1])),pt((foot[0]+3,foot[1]))], fill=color,width=10)
    draw.line([pt((29,73)),pt((52,73))],fill='#888',width=1)
guide.save(SOURCE / 'down-motion-guide.png')
request = {'date':'2026-10-05','status':'in_progress','feedback':'DOWN appears smaller than other directions; regenerate DOWN first, pants recoloring later.',
           'scope':'New eight-pose front-facing DOWN candidate; preserve all64 selected original frames.',
           'display':'Same 80x80 cells, integer2x normal display; target body64px and hat31-32px.',
           'palette_harmonization':'deferred by user','runtime_integrated':False}
(HERE / 'request.json').write_text(json.dumps(request,indent=2) + '\n')
print('Prepared immutable64-frame baseline and lossless nearest references.')
