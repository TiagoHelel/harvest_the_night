"""Common nearest sampling and authorized garment-only palette conversion."""
from pathlib import Path
import colorsys
import hashlib
import json
import sys
from PIL import Image, ImageDraw, ImageFont

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[4]
SOURCE=ROOT/'assets/art_source/player-fhd/idle-blue-grounded'
sys.path.insert(0,str(HERE))
from prepare import DIRS, digest

SCALE=0.18  # One measured scale for the entire eight-view source sheet.

def reference(path,role):
    return {'path':path.relative_to(ROOT).as_posix(),'sha256':digest(path),'role':role}

def build():
    raw_path=SOURCE/'idle-r1.raw.png'
    raw=Image.open(raw_path).convert('RGBA');w,h=raw.size
    palette_file=HERE.parent/'palette-variants/validation.json'
    palette=[tuple(e['rgb']) for e in json.loads(palette_file.read_text())['variants']['blue']]
    frames=[];report=[]
    (SOURCE/'frames').mkdir(exist_ok=True)
    for j,(direction,suffix) in enumerate(DIRS.items()):
        box=(int(j%4*w/4),int(j//4*h/2),int((j%4+1)*w/4),int((j//4+1)*h/2))
        cell=raw.crop(box)
        cell.putalpha(cell.getchannel('A').point(lambda a:255 if a>=128 else 0))
        bounds=cell.getbbox();crop=cell.crop(bounds)
        size=tuple(round(n*SCALE) for n in crop.size)
        crop=crop.resize(size,Image.Resampling.NEAREST)
        native=Image.new('RGBA',(80,80));native.alpha_composite(crop,(40-size[0]//2,72-size[1]))
        original=native.copy();mask=Image.new('L',(80,80));changes=0;colors=set()
        for y in range(80):
            for x in range(80):
                r,g,b,a=native.getpixel((x,y));hue,s,v=colorsys.rgb_to_hsv(r/255,g/255,b/255)
                if a and y>=28 and 185<=hue*360<=270 and s>=.3 and b>=6:
                    mask.putpixel((x,y),255)
                    rgb=min(palette,key=lambda c:sum((c[k]-(r,g,b)[k])**2 for k in range(3)))
                    native.putpixel((x,y),(*rgb,a));colors.add(rgb);changes+=rgb!=(r,g,b)
        assert native.getchannel('A').tobytes()==original.getchannel('A').tobytes()
        for y in range(80):
            for x in range(80):
                if not mask.getpixel((x,y)):assert native.getpixel((x,y))==original.getpixel((x,y))
        native_path=SOURCE/f'frames/{direction}.png';native.save(native_path)
        (HERE/'masks').mkdir(exist_ok=True);mask.save(HERE/f'masks/{direction}.png')
        (HERE/'before-palette').mkdir(exist_ok=True);original.save(HERE/f'before-palette/{direction}.png')
        frames.append(native)
        report.append({'direction':direction,'suffix':suffix,'raw_cell_xyxy':box,
                       'raw_content_xyxy':bounds,'common_scale':SCALE,'native_bbox_xyxy':native.getbbox(),
                       'source':reference(native_path,'Generated neutral standing pose, both boots grounded'),
                       'garment_rgb_pixels_changed':changes,'garment_colors':len(colors),
                       'alpha_and_non_garment_rgba_preserved':True})
    contract={'version':1,'date':'2026-10-05','reason':'Replace raised-foot walk poses used as idle in runtime',
              'canvas_wh':[80,80],'pivot_xy':[40,72],'draw_scale':.5,'idle_seconds':.55,'idle_slots':3,
              'raw':reference(raw_path,'Accepted generated eight-way neutral idle sheet'),
              'prompt':reference(HERE/'idle-r1.prompt.txt','Eight-way grounded idle generation prompt'),
              'references':[reference(HERE/'raised-foot-edit-target.png','Edit target: prior raised-foot idle stand-ins'),
                            reference(HERE/'approved-walk-reference.png','Approved walking identity and proportions'),
                            reference(palette_file,'User-approved RIGHT blue garment ramp'),
                            reference(HERE/'walk-baseline.json','Frozen 192 approved walk review/source/runtime hashes')],
              'palette_rgb':palette,'sampling':'Measured cells, alpha>=128, one 0.18 nearest scale, center x40 / ground y72; garment palette only',
              'frames':report}
    (HERE/'runtime-idle-contract.json').write_text(json.dumps(contract,indent=2)+'\n')
    poster=Image.new('RGBA',(1440,240),'#20292c');draw=ImageDraw.Draw(poster)
    font=ImageFont.truetype('C:/Windows/Fonts/consola.ttf',16)
    for j,(direction,frame) in enumerate(zip(DIRS,frames)):
        draw.text((j*180+12,15),direction.upper(),font=font,fill='#e9e3cf')
        poster.alpha_composite(frame.resize((160,160),Image.Resampling.NEAREST),(j*180,45))
        draw.line((j*180+20,189,j*180+140,189),fill='#516e68')
    poster.convert('RGB').save(HERE/'idle-all-eight.png')
    print('Eight neutral standing poses: common 0.18 sampling, original blue garment ramp, unchanged approved walks.')

if __name__=='__main__':build()
