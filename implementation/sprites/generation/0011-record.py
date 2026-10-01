"""Preserve raw tool returns and measure a shared house state scale."""
from pathlib import Path
import hashlib
import json
import shutil
import sys
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'tools'))
import import_art

def main():
    ident,returned=sys.argv[1:3]
    plan=next(p for p in json.loads((HERE/'0011-plan.json').read_text(encoding='utf-8')) if p['id']==ident)
    folder=ROOT/'assets/art_source/buildings/house';folder.mkdir(parents=True,exist_ok=True)
    review=ROOT/'implementation/sprites/reviews/0011';review.mkdir(parents=True,exist_ok=True)
    dest=folder/(plan['state']+'.png');shutil.copyfile(returned,dest)
    im=Image.open(dest).convert('RGBA')
    box=im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
    assert box and box[0]>0 and box[1]>0 and box[2]<im.width and box[3]<im.height
    x,y,x1,y1=box
    if ident=='house':scale=min(56/(x1-x),55/(y1-y))
    else:scale=json.loads((HERE/'0011-house-call.json').read_text(encoding='utf-8'))['measured_recipe']['content_scale']
    e=dict(id='buildings/'+ident,source=dest.relative_to(ROOT).as_posix(),crop_xywh=[x,y,x1-x,y1-y],sheet_cell_xywh=[0,0,*im.size],gutter_xy=[0,0],canvas_wh=[64,64],pivot_xy=[32,60],content_scale=scale,alpha_threshold=128)
    native=import_art.render_source(e)
    call=dict(id=ident,tool='built-in ImageGen',revision=0,returned_file=returned,source=e['source'],source_sha256=hashlib.sha256(dest.read_bytes()).hexdigest(),source_wh=im.size,source_alpha_range=im.getchannel('A').getextrema(),prompt_text=plan['prompt'],references=plan['references'],measured_recipe=e,native_bbox=native.getbbox(),decision='Pending native/runtime review')
    (HERE/('0011-'+ident+'-call.json')).write_text(json.dumps(call,indent=2)+'\n',encoding='utf-8',newline='\n')
    native.save(review/(ident+'-candidate.png'))
    native.resize((192,192),Image.Resampling.NEAREST).save(review/(ident+'-candidate-3x.png'))
    print(json.dumps(call,indent=2))

if __name__=='__main__':main()
