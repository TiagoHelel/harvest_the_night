"""Joint-only schematic references, never code-painted character artwork."""
from pathlib import Path
import json
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parents[3]/'assets/art_source/player-fhd/pilots/2026-10-04'
guides={
 'up-right':{'left_shoulder':(34,32),'right_shoulder':(48,32),
  'left_elbows':[(32,38),(31,39),(31,40),(30,41),(29,42),(30,41),(31,40),(31,39)],
  'left_wrists':[(34,43),(31,44),(28,46),(25,48),(24,49),(25,48),(28,46),(31,44)],
  'right_elbows':[(50,41),(51,40),(51,39),(50,38),(49,37),(50,38),(51,39),(51,40)],
  'right_wrists':[(54,49),(53,47),(52,45),(51,43),(50,42),(51,43),(52,45),(53,47)]},
 'up-left':{'left_shoulder':(32,32),'right_shoulder':(48,32),
  'left_elbows':[(28,38),(29,39),(30,40),(31,41),(32,42),(31,41),(30,40),(29,39)],
  'left_wrists':[(24,43),(26,44),(29,46),(32,48),(34,49),(32,48),(29,46),(26,44)],
  'right_elbows':[(52,41),(51,40),(50,39),(49,38),(48,37),(49,38),(50,39),(51,40)],
  'right_wrists':[(55,49),(54,47),(52,45),(51,43),(50,42),(51,43),(52,45),(54,47)]}}
for direction,guide in guides.items():
    im=Image.new('RGB',(1920,960),'#20292c'); draw=ImageDraw.Draw(im)
    for i in range(8):
        x,y=(i%4)*480,(i//4)*480
        draw.rectangle((x+33*6,y+32*6,x+49*6,y+49*6),fill='#565e64')
        for arm,color in [('left','#2cddd5'),('right','#ef58bc')]:
            joints=[guide[f'{arm}_shoulder'],guide[f'{arm}_elbows'][i],guide[f'{arm}_wrists'][i]]
            points=[(x+px*6,y+py*6) for px,py in joints]
            draw.line(points,fill=color,width=12)
            for px,py in points: draw.ellipse((px-6,py-6,px+6,py+6),fill='#fff5dc')
        draw.text((x+20,y+395),f'{i+1} | RELAXED WRIST BELOW ELBOW',font=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',17),fill='#fff5dc')
    im.save(SOURCE/f'walk-{direction}/neutral-wrist-guide.png')
    Image.open(ROOT/f'walk-{direction}/hand-candidate-native.png').resize((1920,960),Image.Resampling.NEAREST).save(SOURCE/f'walk-{direction}/hand-refinement-reference.png')
(ROOT/'neutral-wrist-guides.json').write_text(json.dumps(guides,indent=2)+'\n')
