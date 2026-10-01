"""Compose house source/window/ground QA without modifying runtime art."""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent


def checker(size):
    im=Image.new('RGBA',size)
    draw=ImageDraw.Draw(im)
    for y in range(0,size[1],8):
        for x in range(0,size[0],8):
            draw.rectangle((x,y,x+7,y+7),fill='#e8e0cf' if (x//8+y//8)%2 else '#877e8a')
    return im


def pair(im,name):
    im.save(HERE/(name+'.png'))
    im.resize((im.width*3,im.height*3),Image.Resampling.NEAREST).save(HERE/(name+'-3x.png'))


def main():
    states=[Image.open(ROOT/('sprites/buildings/'+n+'.png')).convert('RGBA') for n in ('house','house_hurt')]
    for name,color in (('light','#e8e0cf'),('dark','#241f2e'),('checker',None)):
        sheet=Image.new('RGBA',(240,88),color) if color else checker((240,88))
        draw=ImageDraw.Draw(sheet)
        for i,im in enumerate(states):
            sheet.alpha_composite(im,(i*120+28,18))
            draw.text((i*120+4,3),('whole','hurt')[i],fill='#241f2e' if name=='light' else '#e8e0cf')
        pair(sheet,'states-'+name)
    sheet=Image.new('RGBA',(960,460),'#241f2e')
    draw=ImageDraw.Draw(sheet)
    for i,name in enumerate(('whole','hurt')):
        raw=Image.open(ROOT/('assets/art_source/buildings/house/'+name+'.png')).convert('RGBA')
        alpha=raw.getchannel('A').getextrema()
        raw.thumbnail((290,420),Image.Resampling.NEAREST)
        draw.text((i*480+3,3),name+' raw alpha '+str(alpha),fill='#e8e0cf')
        for j,color in enumerate(('#e8e0cf','#241f2e',None)):
            layer=Image.new('RGBA',(150,420),color) if color else checker((150,420))
            preview=raw.copy();preview.thumbnail((150,400),Image.Resampling.NEAREST)
            layer.alpha_composite(preview,((150-preview.width)//2,(420-preview.height)//2))
            sheet.paste(layer,(i*480+j*154+3,30))
    sheet.save(HERE/'source-alpha.png')
    scale=Image.new('RGBA',(320,96),'#241f2e');draw=ImageDraw.Draw(scale)
    placements=[('house',states[0],(32,60),56),('hurt',states[1],(32,60),132),('farmer',Image.open(ROOT/'sprites/actors/idle_south_0.png').convert('RGBA'),(24,44),202),('tree',Image.open(ROOT/'sprites/props/tree.png').convert('RGBA'),(20,44),256)]
    for name,im,pivot,x in placements:
        scale.alpha_composite(im,(x-pivot[0],82-pivot[1]))
        draw.text((x-20,3),name,fill='#e8e0cf')
    draw.line((8,82,310,82),fill='#e8e0cf')
    pair(scale,'relative-scale')
    windows=states[0].resize((512,512),Image.Resampling.NEAREST)
    marked=Image.new('RGBA',(512,512),'#241f2e');marked.alpha_composite(windows)
    draw=ImageDraw.Draw(marked)
    for x,y in [[32,33],[19,45],[41,45],[30,45],[52,46]]:
        draw.rectangle((x*8,y*8,x*8+7,y*8+7),outline='#ffefb5',width=2)
    draw.rectangle((51*8,12*8,51*8+7,12*8+7),outline='#8abbea',width=2)
    marked.save(HERE/'emission-points.png')
    folder=ROOT/'implementation/shots/sprites/0011'
    captures=sorted((folder/'house').glob('*.png'))+sorted(folder.glob('*.png'))
    assert len(captures)==49,len(captures)
    pages=(len(captures)+3)//4
    for page in range(pages):
        sheet=Image.new('RGBA',(960,576),'#241f2e');draw=ImageDraw.Draw(sheet)
        for i,path in enumerate(captures[page*4:(page+1)*4]):
            x,y=i%2*480,i//2*288
            draw.text((x+3,y+2),path.stem,fill='#e8e0cf')
            im=Image.open(path).convert('RGBA');assert im.size==(480,270)
            sheet.paste(im,(x,y+18))
        pair(sheet,'captures-%02d'%page)
        enlarged=sheet.resize((2880,1728),Image.Resampling.NEAREST)
        for side in range(2):
            enlarged.crop((side*1440,0,(side+1)*1440,1728)).save(HERE/('captures-%02d-3x-%d.png'%(page,side)))
    (HERE/'frame-review.json').write_text(json.dumps(dict(captures=[dict(path=p.relative_to(ROOT).as_posix(),sha256=hashlib.sha256(p.read_bytes()).hexdigest()) for p in captures],capture_pages=pages,native_size=[480,270],nearest_scale=3),indent=2)+'\n',encoding='utf-8',newline='\n')
    print('Saved two-state background/alpha/scale/lamp reviews and 49 native/nearest3x captures')


if __name__=='__main__':main()
