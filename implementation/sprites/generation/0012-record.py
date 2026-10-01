"""Preserve actual tool returns; measure common-scale source cuts, never paint art."""
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
    ident,kind,returned=sys.argv[1:4]
    plan=next(p for p in json.loads((HERE/'0012-plan.json').read_text()) if p['id']==ident)
    folder=ROOT/'assets/art_source/buildings'/ident
    folder.mkdir(parents=True,exist_ok=True)
    review=ROOT/'implementation/sprites/reviews/0012';review.mkdir(parents=True,exist_ok=True)
    dest=folder/(kind+'.png');shutil.copyfile(returned,dest)
    raw=Image.open(dest).convert('RGBA')
    mask=raw.getchannel('A').point(lambda a:255 if a>=128 else 0)
    cells=1 if kind=='master' else 3
    cuts=[0,raw.width]
    if cells==3:
        # AI spacing is measured from actual empty alpha columns. Equal
        # thirds would clip this otherwise complete strip at a cell edge.
        spans=[];start=None
        for x in range(raw.width+1):
            visible=x<raw.width and mask.crop((x,0,x+1,raw.height)).getbbox() is not None
            if visible and start is None:start=x
            if not visible and start is not None:spans.append([start,x]);start=None
        assert len(spans)==3,(ident,'Expected three fully separated objects',spans)
        cuts=[0]+[(spans[i][1]+spans[i+1][0])//2 for i in range(2)]+[raw.width]
    boxes=[]
    for i in range(cells):
        x0,x1=cuts[i:i+2]
        box=mask.crop((x0,0,x1,raw.height)).getbbox()
        assert box and box[0]>0 and box[1]>0 and box[2]<x1-x0 and box[3]<raw.height,(ident,i,box)
        boxes.append((x0,x1,box))
    # One family scale is measured from the union of all authored state extents.
    width=max(b[2]-b[0] for _,_,b in boxes)
    height=max(b[3]-b[1] for _,_,b in boxes)
    scale=min(plan['body_wh'][0]/width,plan['body_wh'][1]/height)
    entries=[]
    for i,(x0,x1,b) in enumerate(boxes):
        state=('master',) if cells==1 else ('idle','active','hurt')
        name=ident if state[i] in ('master','idle') else ident+'_'+state[i]
        # Actual authored bounds/contact, never per-state resizing. Every
        # state uses the exact same measured family scale and native pivot.
        cx=(b[0]+b[2])//2;cy=b[3]
        local_x=b[0]
        crop=[x0+local_x,b[1],b[2]-b[0],b[3]-b[1]]
        assert crop[0]>=x0 and crop[0]+crop[2]<=x1 and crop[1]>=0
        entry=dict(id=plan['folder']+'/'+name,source=dest.relative_to(ROOT).as_posix(),crop_xywh=crop,sheet_cell_xywh=[x0,0,x1-x0,raw.height],gutter_xy=[0,0],canvas_wh=plan['canvas_wh'],pivot_xy=plan['pivot_xy'],content_scale=scale,alpha_threshold=128)
        if ident not in ('shop','well'):
            # The moving press lever changes the complete silhouette center;
            # contact is measured on the planted lower base, not on that lever.
            low=cy-max(1,(b[3]-b[1])//4)
            ground=mask.crop((x0,low,x1,cy)).getbbox()
            ground_x=(ground[0]+ground[2])//2
            entry['content_anchor_xy']=[round((ground_x-local_x)*scale),round(crop[3]*scale)]
        image=import_art.render_source(entry)
        preview=ident+'-'+kind+'-'+state[i]
        image.save(review/(preview+'.png'))
        image.resize(tuple(n*3 for n in image.size),Image.Resampling.NEAREST).save(review/(preview+'-3x.png'))
        entries.append(entry)
    refs=plan['references'] if kind=='master' else [(folder.relative_to(ROOT)/'master.png').as_posix(),plan['references'][0]]
    prompt='implementation/sprites/generation/0012-'+ident+'-'+kind+'.prompt.txt'
    call=dict(id=ident,kind=kind,tool='built-in ImageGen',revision=0,returned_file=returned,source=dest.relative_to(ROOT).as_posix(),source_sha256=hashlib.sha256(dest.read_bytes()).hexdigest(),source_wh=list(raw.size),source_alpha_range=list(raw.getchannel('A').getextrema()),prompt=prompt,prompt_sha256=import_art.sha((ROOT/prompt).read_bytes()),references=refs,measured_recipes=entries,source_bounds=[list(b) for _,_,b in boxes],decision='Pending native/runtime review')
    (HERE/('0012-'+ident+'-'+kind+'-call.json')).write_text(json.dumps(call,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(json.dumps(dict(source=call['source'],source_wh=call['source_wh'],scale=scale,crops=[e['crop_xywh'] for e in entries])))

if __name__=='__main__':main()
