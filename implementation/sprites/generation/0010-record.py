"""Preserve actual returned files and measure deterministic source reductions."""
from pathlib import Path
import hashlib
import json
import shutil
import sys
from PIL import Image,ImageDraw

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'tools'))
import import_art

def sha(raw): return hashlib.sha256(raw).hexdigest()

def main():
    ident,returned=sys.argv[1:3]
    plan=next(p for p in json.loads((HERE/'0010-plan.json').read_text(encoding='utf-8')) if p['id']==ident)
    folder=ROOT/'assets/art_source/crops'
    review=ROOT/'implementation/sprites/reviews/0010'
    folder.mkdir(parents=True,exist_ok=True);review.mkdir(parents=True,exist_ok=True)
    dest=folder/(ident+'.png')
    shutil.copyfile(returned,dest)
    im=Image.open(dest).convert('RGBA')
    recipes=[]
    if ident in ('wheat','corn','carrot'):
        height={'wheat':12,'corn':20,'carrot':10}[ident]
        cells=[];bounds=[]
        # Observed transparent gaps, not quarter-width guesses: the returned
        # growing forms have unequal source spacing and a larger mature form.
        cuts={'wheat':[0,480,970,1440,im.width], 'corn':[0,450,870,1400,im.width], 'carrot':[0,500,1050,1540,im.width]}.get(ident)
        assert cuts is not None, 'Measure the actual carrot gutters first'
        for i in range(4):
            x0,x1=cuts[i:i+2]
            a=im.crop((x0,0,x1,im.height)).getchannel('A').point(lambda a:255 if a>=128 else 0)
            b=a.getbbox();assert b
            bounds.append([x0+b[0],b[1],b[2]-b[0],b[3]-b[1]])
            cells.append([x0,0,x1-x0,im.height])
        scale=min(height/max(b[3] for b in bounds),12/max(b[2] for b in bounds))
        for i,box in enumerate(bounds):
            recipes.append(dict(id='crops/'+ident+'_'+str(i),source=dest.relative_to(ROOT).as_posix(),crop_xywh=box,sheet_cell_xywh=cells[i],gutter_xy=[0,0],canvas_wh=[16,24 if ident=='corn' else 16],pivot_xy=[8,22 if ident=='corn' else 14],content_scale=scale,alpha_threshold=128))
    else:
        assert im.getchannel('A').getextrema()==(255,255)
        # Native material cut stays square and samples a seamless edge-to-edge
        # swatch. Wet uses the exact same source rectangle and reduction size.
        edge=min(im.size)
        recipes=[dict(id='crops/'+ident,source=dest.relative_to(ROOT).as_posix(),crop_xywh=[0,0,edge,edge],sheet_cell_xywh=[0,0,*im.size],gutter_xy=[0,0],canvas_wh=[16,16],pivot_xy=[8,16],content_scale=16/edge,alpha_threshold=128,palette_keys=['soil_dark','soil','soil_light','ink_soft','ink'])]
    call=dict(id=ident,tool='built-in ImageGen',revision=0,returned_file=returned,source=dest.relative_to(ROOT).as_posix(),source_sha256=sha(dest.read_bytes()),source_wh=im.size,source_alpha_range=im.getchannel('A').getextrema(),references=plan['references'],prompt_text=plan['prompt'],measured_recipes=recipes,decision='Pending native/runtime review')
    (HERE/('0010-'+ident+'-call.json')).write_text(json.dumps(call,indent=2)+'\n',encoding='utf-8',newline='\n')
    sheet=Image.new('RGBA',(80,40),'#e8e0cf')
    for i,recipe in enumerate(recipes):
        native=import_art.render_source(recipe)
        sheet.alpha_composite(native,(i*20+2,30-recipe['pivot_xy'][1]))
        print(recipe['id'],recipe['crop_xywh'],recipe['content_scale'],native.getbbox())
    sheet.save(review/(ident+'-candidate.png'))
    sheet.resize((400,200),Image.Resampling.NEAREST).save(review/(ident+'-candidate-5x.png'))
    print('Preserved exact returned source',im.size,call['source_sha256'])

if __name__=='__main__':main()
