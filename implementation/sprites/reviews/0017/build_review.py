"""Review source-owned FX at native size and nearest 3x; no sprite edits."""
from pathlib import Path
import json
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
entries=[e for e in json.loads((ROOT/'assets/art_source/manifest.json').read_text())['assets'] if e.get('generation_task')=='0017']
for ground in ('light','dark','checker'):
    page=Image.new('RGBA',(320,280),(218,213,183,255) if ground=='light' else (41,38,52,255))
    d=ImageDraw.Draw(page)
    if ground=='checker':
        for y in range(0,280,8):
            for x in range(0,320,8):
                if (x+y)//8%2==0:d.rectangle((x,y,x+7,y+7),fill=(116,116,120,255))
    for row,family in enumerate(('muzzle','impact','flame','smoke','dust','splash','flare')):
        d.text((2,row*40+12),family,fill=(23,21,28,255) if ground=='light' else (239,232,205,255))
        for e in [e for e in entries if e['fx_family']==family]:
            x,y=64+e['frame']*60,row*40+5
            art=Image.open(ROOT/e['output']).convert('RGBA')
            page.alpha_composite(art,(x,y))
            px,py=e['pivot_xy']
            d.line((x+px-3,y+art.height+2,x+px+3,y+art.height+2),fill=(174,151,120,255))
    page.save(HERE/f'effects-{ground}-native.png')
    page.resize((960,840),Image.Resampling.NEAREST).save(HERE/f'effects-{ground}-3x.png')
(HERE/'measured-contract.json').write_text(json.dumps(entries,indent=2)+'\n',newline='\n')
