"""Preserve old poses and draw abstract joint guides for ImageGen edits."""
from pathlib import Path
import json
import hashlib
import shutil
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parents[3]/'assets/art_source/player-fhd/pilots/2026-10-04'
assert not (ROOT/'full-arm-cycle-baseline.json').exists(), 'Preserve existing baseline.'
baseline={str(p.relative_to(ROOT)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest()
          for p in ROOT.glob('walk-*/frames/*.png')}
(ROOT/'full-arm-cycle-baseline.json').write_text(json.dumps(baseline,indent=2)+'\n')
guides={
 'up-right': {
  'left_shoulder':(34,31),'right_shoulder':(48,31),
  'left_elbows':[(31,37),(31,38),(32,38),(31,39),(30,40),(31,39),(32,38),(31,38)],
  'left_hands':[(34,38),(32,40),(29,43),(27,46),(26,48),(27,46),(29,43),(32,40)],
  'right_elbows':[(51,39),(51,38),(50,37),(51,35),(52,34),(51,35),(50,37),(51,38)],
  'right_hands':[(54,46),(53,44),(51,41),(52,38),(54,36),(53,38),(51,41),(53,44)]},
 'up-left': {
  'left_shoulder':(32,31),'right_shoulder':(48,31),
  'left_elbows':[(27,35),(28,37),(30,38),(30,40),(31,41),(30,40),(30,38),(28,37)],
  'left_hands':[(24,37),(25,40),(29,43),(32,46),(34,47),(32,46),(29,43),(25,40)],
  'right_elbows':[(52,39),(51,38),(50,37),(49,35),(49,34),(49,35),(50,37),(51,38)],
  'right_hands':[(56,47),(55,44),(52,41),(51,38),(50,36),(51,38),(52,41),(55,44)]}}
font=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',17)
for direction,guide in guides.items():
    folder=ROOT/f'walk-{direction}'
    archive=folder/'before-full-arm-cycle'
    archive.mkdir(exist_ok=True)
    shutil.copytree(folder/'frames',archive/'frames')
    for name in ['export_preview.py','validation.json','generation.json','contact-sheet.png','index.html']:
        shutil.copy2(folder/name,archive/name)
    native=Image.new('RGBA',(320,160))
    diagram=Image.new('RGB',(1920,960),'#20292c'); d=ImageDraw.Draw(diagram)
    for i in range(8):
        frame=Image.open(folder/f'frames/walk-{direction}-{i+1:02}.png').convert('RGBA')
        native.alpha_composite(frame,((i%4)*80,(i//4)*80))
        x,y=(i%4)*480,(i//4)*480
        def point(p): return (x+p[0]*6,y+p[1]*6)
        d.ellipse((x+25*6,y+8*6,x+56*6,y+29*6),fill='#61676c')
        d.rectangle((x+33*6,y+30*6,x+49*6,y+49*6),fill='#61676c')
        for arm,color in [('left','#2cddd5'),('right','#ef58bc')]:
            chain=[guide[f'{arm}_shoulder'],guide[f'{arm}_elbows'][i],guide[f'{arm}_hands'][i]]
            d.line([point(p) for p in chain],fill=color,width=18)
            for p in chain:
                px,py=point(p); d.ellipse((px-8,py-8,px+8,py+8),fill='#fff5dc')
        d.text((x+18,y+405),f'{i+1} | LEFT CYAN / RIGHT PINK',font=font,fill='#e9e3cf')
        d.text((x+18,y+432),f'Hands L{guide["left_hands"][i]} R{guide["right_hands"][i]}',font=font,fill='#e9e3cf')
    native.resize((1920,960),Image.Resampling.NEAREST).save(SOURCE/f'walk-{direction}/full-arm-cycle-reference.png')
    diagram.save(SOURCE/f'walk-{direction}/full-arm-cycle-guide.png')
(ROOT/'full-arm-cycle-guide.json').write_text(json.dumps(guides,indent=2)+'\n')
print('Archived56frame baseline and prepared two eight-phase joint guides.')
