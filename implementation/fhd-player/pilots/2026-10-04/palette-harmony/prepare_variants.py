"""Read-only input selection and garment masks for a palette-only review."""
from pathlib import Path
import colorsys
import hashlib
import json
from PIL import Image, ImageDraw, ImageFont

HERE=Path(__file__).resolve().parent
PILOT=HERE.parent
OUT=PILOT/'palette-variants'

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def garment(pixel,y):
    r,g,b,a=pixel
    h,s,v=colorsys.rgb_to_hsv(r/255,g/255,b/255)
    return bool(a and y>=28 and 185<=h*360<=270 and s>=.3 and b>=6)

def prepare():
    OUT.mkdir(exist_ok=True)
    selected=json.loads((PILOT/'walk-down-left/aggregate-selection.json').read_text())
    approved=json.loads((PILOT/'walk-down-size-review/approval.json').read_text())
    selected['down']=[{'path':'walk-down-size-review/'+approved['candidate']+'/'+name,'sha256':sha}
                      for name,sha in approved['approved_frame_sha256'].items()]
    records={}; atlas=Image.new('RGB',(1280,8*185),'#303a3e')
    draw=ImageDraw.Draw(atlas);font=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',13)
    for row,(direction,items) in enumerate(selected.items()):
        records[direction]=[]
        folder=OUT/'masks'/direction;folder.mkdir(parents=True,exist_ok=True)
        for i,item in enumerate(items):
            path=PILOT/item['path']; assert digest(path)==item['sha256']
            im=Image.open(path).convert('RGBA');mask=Image.new('L',im.size)
            for y in range(80):
                for x in range(80):
                    if garment(im.getpixel((x,y)),y):mask.putpixel((x,y),255)
            mp=folder/f'{i+1:02}.png';mask.save(mp)
            records[direction].append({**item,'mask':str(mp.relative_to(OUT)).replace('\\','/'),
                'mask_sha256':digest(mp),'garment_pixel_count':sum(v>0 for v in mask.get_flattened_data())})
            x=i*160;y=row*185
            draw.text((x+4,y+2),f'{direction.upper()} / {i+1}',font=font,fill='#e9e3cf')
            # Mask-only diagnostic silhouette, no farmer artwork recoloring.
            diag=Image.new('RGB',(80,80),'#303a3e')
            for yy in range(80):
                for xx in range(80):
                    if im.getpixel((xx,yy))[3]:diag.putpixel((xx,yy),(78,90,94))
                    if mask.getpixel((xx,yy)):diag.putpixel((xx,yy),(235,87,180))
            atlas.paste(diag.resize((160,160),Image.Resampling.NEAREST),(x,y+22))
    (OUT/'selection.json').write_text(json.dumps(records,indent=2)+'\n')
    atlas.save(OUT/'mask-audit.png')
    print('Prepared64 source hashes/masks including newly approved DOWN; no sprite edits.')

if __name__=='__main__':prepare()
