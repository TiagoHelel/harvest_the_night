"""Build review-only native/nearest-threefold sheets; never edit source art."""
from pathlib import Path
import json
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
entries=[e for e in json.loads((ROOT/'assets/art_source/manifest.json').read_text(encoding='utf-8'))['assets'] if e.get('generation_task')=='0018']
ids=[p['id'] for p in json.loads((ROOT/'implementation/sprites/generation/0018-plan.json').read_text(encoding='utf-8'))]
for ground in ('light','dark','checker'):
    page=Image.new('RGBA',(360,240),(218,213,183,255) if ground=='light' else (41,38,52,255))
    d=ImageDraw.Draw(page)
    if ground=='checker':
        for y in range(0,240,8):
            for x in range(0,360,8):
                if (x+y)//8%2==0:d.rectangle((x,y,x+7,y+7),fill=(116,116,120,255))
    for i,resource in enumerate(ids):
        x,y=(i%3)*120,(i//3)*48
        d.text((x+2,y+2),resource,fill=(23,21,28,255) if ground=='light' else (239,232,205,255))
        for prefix,offset in [('icon',10),('hud',42)]:
            art=Image.open(ROOT/f'sprites/ui/{prefix}_{resource}.png').convert('RGBA')
            page.alpha_composite(art,(x+offset,y+22))
    page.save(HERE/f'icons-{ground}-native.png')
    page.resize((1080,720),Image.Resampling.NEAREST).save(HERE/f'icons-{ground}-3x.png')

# The raw-source alpha overview is evidence only; canonical source PNGs stay exact.
page=Image.new('RGBA',(1000,840),(41,38,52,255))
d=ImageDraw.Draw(page)
for i,resource in enumerate(ids):
    x,y=(i%5)*200,(i//5)*280
    source=Image.open(ROOT/f'assets/art_source/ui/{resource}.png').convert('RGBA')
    d.text((x+4,y+4),resource,fill=(239,232,205,255))
    crop=source.crop(source.getbbox());crop.thumbnail((180,220),Image.Resampling.NEAREST)
    page.alpha_composite(crop,(x+(200-crop.width)//2,y+30))
page.save(HERE/'raw-alpha-overview.png')

captures=[]
folder=ROOT/'implementation/shots/sprites/0018'
for i,path in enumerate(sorted(folder.rglob('*.png'))):
    art=Image.open(path).convert('RGBA')
    assert art.size==(480,270),path
    # Both views fit within 1440x1080, retaining exact native/3x pixels.
    review=Image.new('RGBA',(1440,1080),(24,22,30,255))
    review.alpha_composite(art,(0,0))
    ImageDraw.Draw(review).text((500,20),path.relative_to(folder).as_posix()+' / native above, nearest 3x below',fill=(239,232,205,255))
    review.alpha_composite(art.resize((1440,810),Image.Resampling.NEAREST),(0,270))
    out=f'captures-{i:02}.png';review.save(HERE/out)
    captures.append(dict(capture=path.relative_to(ROOT).as_posix(),review=f'implementation/sprites/reviews/0018/{out}'))
(HERE/'capture-index.json').write_text(json.dumps(captures,indent=2)+'\n',encoding='utf-8',newline='\n')
(HERE/'measured-contract.json').write_text(json.dumps(entries,indent=2)+'\n',encoding='utf-8',newline='\n')
before=HERE/'before-hud-reflow'
changed=[]
if before.is_dir():
    for path in sorted(before.glob('*.png')):
        old=Image.open(path).convert('RGBA');new=Image.open(folder/path.name).convert('RGBA')
        outside=0
        for y in range(270):
            for x in range(480):
                if not (90<=x<210 and y<27) and old.getpixel((x,y))!=new.getpixel((x,y)):outside+=1
        changed.append(dict(capture=path.name,outside_money_region_changed_pixels=outside))
    for start in range(0,len(changed),10):
        page=Image.new('RGBA',(1440,1080),(24,22,30,255));d=ImageDraw.Draw(page)
        for row,item in enumerate(changed[start:start+10]):
            art=Image.open(folder/item['capture']).convert('RGBA').crop((0,0,480,27))
            y=row*108
            page.alpha_composite(art,(0,y));d.text((500,y+5),item['capture'],fill=(239,232,205,255))
            page.alpha_composite(art.resize((1440,81),Image.Resampling.NEAREST),(0,y+27))
        page.save(HERE/f'final-hud-strips-{start//10}.png')
    (HERE/'hud-reflow-diff.json').write_text(json.dumps(changed,indent=2)+'\n',encoding='utf-8',newline='\n')
print(f'Reviewed family sheets and {len(captures)} native/3x capture pages prepared')
