"""Compose QA sheets only: source alpha, native states, anchors and Godot captures."""
from pathlib import Path
import hashlib
import json
import sys
from PIL import Image,ImageDraw

ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'tools'))
from check_station_art import FAMILY

def checker(size):
    im=Image.new('RGBA',size,'#e8e0cf');d=ImageDraw.Draw(im)
    for y in range(0,size[1],8):
        for x in range(0,size[0],8):
            if (x//8+y//8)%2:d.rectangle((x,y,x+7,y+7),fill='#b3ab9d')
    return im

def pair(im,name):
    im.save(HERE/(name+'.png'))
    im.resize(tuple(n*3 for n in im.size),Image.Resampling.NEAREST).save(HERE/(name+'-3x.png'))

def main():
    for name,color in [('light','#e8e0cf'),('dark','#241f2e'),('checker',None)]:
        sheet=Image.new('RGBA',(360,320),color) if color else checker((360,320))
        d=ImageDraw.Draw(sheet)
        for row,(ident,(folder,canvas,pivot)) in enumerate(FAMILY.items()):
            d.text((3,row*52+1),ident,fill='#241f2e' if color=='#e8e0cf' else '#e8e0cf')
            for col,suffix in enumerate(['','_active','_hurt'] if len(canvas) and canvas[0]==48 else ['']):
                im=Image.open(ROOT/('sprites/'+folder+'/'+ident+suffix+'.png')).convert('RGBA')
                sheet.alpha_composite(im,(96+col*88-pivot[0],row*52+50-pivot[1]))
        pair(sheet,'states-'+name)
    raws=list((ROOT/'assets/art_source/buildings').glob('*/master.png'))+list((ROOT/'assets/art_source/buildings').glob('*/states.png'))
    raws=[p for p in sorted(raws) if p.parent.name in FAMILY]
    for index in range(0,len(raws),2):
        sheet=Image.new('RGBA',(960,420),'#241f2e');d=ImageDraw.Draw(sheet)
        for row,path in enumerate(raws[index:index+2]):
            raw=Image.open(path).convert('RGBA')
            d.text((3,row*210+1),path.parent.name+'/'+path.name+' alpha '+str(raw.getchannel('A').getextrema()),fill='#e8e0cf')
            for col,color in enumerate(['#e8e0cf','#241f2e',None]):
                bg=Image.new('RGBA',(312,188),color) if color else checker((312,188))
                preview=raw.copy();preview.thumbnail((304,180),Image.Resampling.NEAREST)
                bg.alpha_composite(preview,((312-preview.width)//2,(188-preview.height)//2))
                sheet.paste(bg,(col*320,row*210+20))
        sheet.save(HERE/('source-alpha-%02d.png'%(index//2)))
    scale=Image.new('RGBA',(432,96),'#241f2e');d=ImageDraw.Draw(scale)
    contracts=json.loads((HERE/'measured-contract.json').read_text())
    for i,ident in enumerate(['house','workshop','kitchen','press','generator','shop','well','farmer']):
        if ident=='house':folder,pivot='buildings',(32,60)
        elif ident=='farmer':folder,pivot='actors',(24,44)
        else:folder,_,pivot=FAMILY[ident]
        path='sprites/'+folder+'/'+('idle_south_0' if ident=='farmer' else ident)+'.png'
        im=Image.open(ROOT/path).convert('RGBA');x=28+i*52
        scale.alpha_composite(im,(x-pivot[0],82-pivot[1]));d.text((x-22,1),ident,fill='#e8e0cf')
    d.line((0,82,431,82),fill='#e8e0cf');pair(scale,'relative-scale')
    sheet=Image.new('RGBA',(480,168),'#241f2e');d=ImageDraw.Draw(sheet)
    for i,ident in enumerate(['workshop','kitchen','generator']):
        entry=next(e for e in contracts if e['id'].endswith('/'+ident+'_active'))
        im=Image.open(ROOT/entry['output']).convert('RGBA').resize((144,144),Image.Resampling.NEAREST)
        sheet.alpha_composite(im,(i*160,22));d.text((i*160,2),ident+' glow/smoke',fill='#e8e0cf')
        for key,color in [('light_xy','#ffefb5'),('smoke_xy','#8abbea')]:
            x,y=entry[key];d.rectangle((i*160+x*3,22+y*3,i*160+x*3+2,22+y*3+2),outline=color)
    sheet.save(HERE/'emission-points.png')
    folder=ROOT/'implementation/shots/sprites/0012'
    captures=sorted((folder/'stations').glob('*.png'))+sorted(folder.glob('*.png'))
    pages=(len(captures)+3)//4
    for page in range(pages):
        sheet=Image.new('RGBA',(960,576),'#241f2e');d=ImageDraw.Draw(sheet)
        for i,path in enumerate(captures[page*4:page*4+4]):
            x,y=i%2*480,i//2*288
            d.text((x+3,y+2),path.stem,fill='#e8e0cf')
            im=Image.open(path).convert('RGBA');assert im.size==(480,270)
            sheet.paste(im,(x,y+18))
        pair(sheet,'captures-%02d'%page)
        big=sheet.resize((2880,1728),Image.Resampling.NEAREST)
        for side in range(2):big.crop((1440*side,0,1440*(side+1),1728)).save(HERE/('captures-%02d-3x-%d.png'%(page,side)))
    (HERE/'frame-review.json').write_text(json.dumps(dict(captures=[dict(path=p.relative_to(ROOT).as_posix(),sha256=hashlib.sha256(p.read_bytes()).hexdigest()) for p in captures],capture_pages=pages,native_size=[480,270],nearest_scale=3),indent=2)+'\n',encoding='utf-8',newline='\n')
    print('Saved 14 native states, 10 raw alpha reviews, scale/emission reviews and %d captures on %d pages'%(len(captures),pages))

if __name__=='__main__':main()
