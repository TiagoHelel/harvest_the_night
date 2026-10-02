"""Display the exact Giant outputs at native size and nearest 3x on three grounds."""
from pathlib import Path
import json
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
entries=[e for e in json.loads((ROOT/'assets/art_source/manifest.json').read_text())['assets'] if e.get('generation_task')=='0016' and 'source' in e]
for ground in ('light','dark','checker'):
    page=Image.new('RGBA',(480,400),(218,213,183,255) if ground=='light' else (41,38,52,255))
    d=ImageDraw.Draw(page)
    if ground=='checker':
        for y in range(0,400,8):
            for x in range(0,480,8):
                if (x+y)//8%2==0:d.rectangle((x,y,x+7,y+7),fill=(116,116,120,255))
    for row,motion in enumerate(('master','walk','windup','slam','death')):
        d.text((2,row*80),motion,fill=(23,21,28,255) if ground=='light' else (239,232,205,255))
        for e in [e for e in entries if e['enemy_motion']==motion]:
            x,y=e['frame']*96+8,row*80+12
            page.alpha_composite(Image.open(ROOT/e['output']).convert('RGBA'),(x,y))
            d.line((x+32,y+60,x+48,y+60),fill=(174,151,120,255))
    page.save(HERE/f'motions-{ground}-native.png')
    page.resize((1440,1200),Image.Resampling.NEAREST).save(HERE/f'motions-{ground}-3x.png')
(HERE/'measured-contract.json').write_text(json.dumps(entries,indent=2)+'\n',newline='\n')
