from pathlib import Path
import json,sys
from PIL import Image
D=Path(__file__).resolve().parent;ROOT=D.parents[3];sys.path.insert(0,str(ROOT/'tools'))
from import_art import render_source
recipes={};limits={'potato':[(2,3),(4,5),(7,8),(10,12)],'garlic':[(2,3),(4,6),(7,9),(10,12)],'strawberry':[(2,3),(4,5),(6,7),(8,10),(6,10)]}
for name,targets in limits.items():
 im=Image.open(D/f'raw/{name}-r1.png').convert('RGBA');mask=im.getchannel('A').point(lambda v:255 if v>=128 else 0);occupied=[x for x in range(im.width) if mask.crop((x,0,x+1,im.height)).getbbox()];gaps=[(b-a-1,a,b) for a,b in zip(occupied,occupied[1:]) if b-a>1];major=sorted(sorted(gaps,reverse=True)[:len(targets)-1],key=lambda t:t[1]);cuts=[0]+[(a+b)//2 for _,a,b in major]+[im.width];frames=[]
 for x0,x1 in zip(cuts,cuts[1:]):
  a,b,c,d=mask.crop((x0,0,x1,im.height)).getbbox();frames.append({'crop_xywh':[a+x0,b,c-a,d-b],'sheet_cell_xywh':[x0,0,x1-x0,im.height]})
 low=max((lo-.49)/f['crop_xywh'][3] for f,(lo,hi) in zip(frames,targets));high=min((hi+.49)/f['crop_xywh'][3] for f,(lo,hi) in zip(frames,targets));high=min(high,14/max(f['crop_xywh'][2] for f in frames));scale=(low+high)/2 if low<=high else min(high,11/frames[3]['crop_xywh'][3]);print(name,'scale window',low,high,'selected',scale)
 strip=Image.new('RGBA',(len(frames)*24,16))
 for i,f in enumerate(frames):
  e={'id':name+str(i),'source':str(D/f'raw/{name}-r1.png'),'crop_xywh':f['crop_xywh'],'content_scale':scale,'canvas_wh':[16,16],'pivot_xy':[8,14],'palette':'tools/palette.py:COLOURS','alpha_threshold':128};n=render_source(e);strip.alpha_composite(n,(i*24,0));f['content_scale']=scale;f['content_anchor_xy']=[round(f['crop_xywh'][2]*scale)//2,round(f['crop_xywh'][3]*scale)];f['native_bounds']=list(n.getbbox());f['height']=n.getbbox()[3]-n.getbbox()[1]
 strip.resize((strip.width*4,64),Image.Resampling.NEAREST).save(D/f'preview/{name}-stages-4x.png');recipes[name]=frames;print('native heights',[f['height'] for f in frames],'crops',[f['crop_xywh'] for f in frames])
(D/'raw/measured-stage-recipes.json').write_text(json.dumps(recipes,indent=2))
im=Image.open(D/'raw/carrot_seed-r1.png').convert('RGBA');b=im.getchannel('A').point(lambda v:255 if v>=128 else 0).getbbox();crop=[b[0],b[1],b[2]-b[0],b[3]-b[1]];print('packet aspect',crop[2]/crop[3],crop)
for size,maxh,piv in [(16,14,8),(10,8,5)]:
 scale=maxh/crop[3];e={'id':'packet','source':str(D/'raw/carrot_seed-r1.png'),'crop_xywh':crop,'content_scale':scale,'canvas_wh':[size,size],'pivot_xy':[piv,piv],'palette':'tools/palette.py:COLOURS','alpha_threshold':128,'content_anchor_xy':[round(crop[2]*scale)//2,round(crop[3]*scale)//2]};n=render_source(e);n.resize((size*8,size*8),Image.Resampling.NEAREST).save(D/f'preview/carrot_seed-r1-{size}-8x.png');print('packet',size,n.getbbox())
