"""Compose source/native QA pages; never create or repair source pixels."""
from pathlib import Path
import json
import sys
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / 'tools'))
import import_art


def background(size, mode):
    im = Image.new('RGBA', size, '#e8e0cf' if mode != 'dark' else '#241f2e')
    if mode == 'checker':
        d = ImageDraw.Draw(im)
        for y in range(0, size[1], 8):
            for x in range(0, size[0], 8):
                if (x//8 + y//8) % 2:
                    d.rectangle((x,y,x+7,y+7), fill='#b3ab9d')
    return im


def pair(im, name):
    im.save(HERE / (name + '.png'))
    im.resize(tuple(n*3 for n in im.size), Image.Resampling.NEAREST).save(HERE / (name+'-3x.png'))


def main():
    data = import_art.load_manifest()
    _, images = import_art.build(data)
    entries = [e for e in data['assets'] if e.get('generation_task') == '0014']
    for family in ('wall', 'fence'):
        for mode in ('light', 'dark', 'checker'):
            im = background((320, 236), mode)
            d = ImageDraw.Draw(im)
            ink = '#e8e0cf' if mode == 'dark' else '#241f2e'
            d.text((3,2), family+' 16 masks / whole then hurt / 16x32', fill=ink)
            for mask in range(16):
                x,y = (mask%8)*40, 22+(mask//8)*106
                d.text((x+2,y), str(mask), fill=ink)
                for row,suffix in enumerate(('', '_hurt')):
                    ident = 'buildings/'+family+(f'_join_{mask}' if mask else '')+suffix
                    im.alpha_composite(images[ident], (x+12,y+14+row*38))
            pair(im, family+'-'+mode)
    others = [e for e in entries if e.get('operation') != 'compose']
    assert len(others) == 20
    for mode in ('light','dark','checker','silhouette'):
        im = background((480,206), mode)
        d = ImageDraw.Draw(im)
        ink = '#e8e0cf' if mode == 'dark' else '#241f2e'
        d.text((3,2), 'Source modules, low wrecks and three trap states', fill=ink)
        for i,e in enumerate(others):
            x,y = (i%8)*60, 20+(i//8)*60
            label=e['id'].split('/')[-1].replace('horizontal','H').replace('vertical','V').replace('triggered','trigger')
            d.text((x+1,y), label[:10], fill=ink)
            sprite=images[e['id']]
            if mode == 'silhouette':
                black=Image.new('RGBA',sprite.size,'#241f2e')
                black.putalpha(sprite.getchannel('A'))
                sprite=black
            im.alpha_composite(sprite,(x+(60-sprite.width)//2,y+14))
        pair(im,'modules-'+mode)
    # Each selected raw cut separately on light/dark/checker; thumbnails are
    # nearest samples of exact source pixels, with no backdrop removal.
    for page in range(0,len(others),4):
        im=Image.new('RGBA',(960,576),'#241f2e')
        d=ImageDraw.Draw(im)
        for row,e in enumerate(others[page:page+4]):
            x,y,w,h=e['crop_xywh']
            raw=Image.open(ROOT/e['source']).convert('RGBA').crop((x,y,x+w,y+h))
            d.text((3,row*144+2),e['id']+' / '+Path(e['source']).name+' / alpha '+str(raw.getchannel('A').getextrema()),fill='#e8e0cf')
            for col,mode in enumerate(('light','dark','checker')):
                bg=background((312,122),mode)
                thumb=raw.copy();thumb.thumbnail((304,114),Image.Resampling.NEAREST)
                bg.alpha_composite(thumb,((312-thumb.width)//2,(122-thumb.height)//2))
                im.paste(bg,(col*320,row*144+20))
        im.save(HERE/('source-cuts-%02d.png'%(page//4)))
    masters=[ROOT/'assets/art_source/defences'/f/'master.png' for f in ('barricade','mine')]
    im=Image.new('RGBA',(960,420),'#241f2e');d=ImageDraw.Draw(im)
    for row,path in enumerate(masters):
        raw=Image.open(path).convert('RGBA')
        d.text((3,row*210+2),path.parent.name+' master / alpha '+str(raw.getchannel('A').getextrema()),fill='#e8e0cf')
        for col,mode in enumerate(('light','dark','checker')):
            bg=background((312,188),mode)
            thumb=raw.copy();thumb.thumbnail((304,180),Image.Resampling.NEAREST)
            bg.alpha_composite(thumb,((312-thumb.width)//2,(188-thumb.height)//2))
            im.paste(bg,(col*320,row*210+20))
    im.save(HERE/'source-masters.png')
    captures=sorted((ROOT/'implementation/shots/sprites/0014').rglob('*.png'))
    for page in range(0,len(captures),2):
        im=Image.new('RGBA',(480,572),'#241f2e');d=ImageDraw.Draw(im)
        for row,path in enumerate(captures[page:page+2]):
            capture=Image.open(path).convert('RGBA')
            assert capture.size==(480,270),(path,capture.size)
            d.text((4,row*286+2),path.parent.name+'/'+path.stem,fill='#e8e0cf')
            im.paste(capture,(0,row*286+16))
        pair(im,'captures-%02d'%(page//2))
    (HERE/'capture-index.json').write_text(json.dumps([str(p.relative_to(ROOT)).replace('\\','/') for p in captures],indent=2)+'\n',encoding='utf-8')
    print(f'Saved native/3x QA for 84 outputs, 20 selected source cuts, two masters and {len(captures)} actual captures')


if __name__ == '__main__':main()
