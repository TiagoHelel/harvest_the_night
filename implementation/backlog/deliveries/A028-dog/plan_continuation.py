"""Measure ImageGen strips; crop and reduce only, never draw or repair pixels."""
import json,sys,hashlib
from pathlib import Path
from PIL import Image
sys.dont_write_bytecode=True
D=Path(__file__).resolve().parent
sys.path.insert(0,str(D.parents[3]/'tools'))
from import_art import render_source
P=json.loads((D/'raw/export-plan.json').read_text())
P['files']=[f for f in P['files'] if f['anim']=='dog_sit']
P['status']='review';P['date']='2026-10-14'
keys=P['files'][0]['palette_keys']
master=json.loads((D/'raw/dog-master-r1.recipe.json').read_text())
def render(source,recipe):
 source_path=D/source
 if not source_path.exists():source_path=D/'rejected'/Path(source).name
 return render_source({'id':'measure','source':str(source_path),'canvas_wh':[40,32],'pivot_xy':[20,30],'palette':'tools/palette.py:COLOURS','alpha_threshold':128,'palette_keys':keys,**recipe})
def add(name,source,recipes,poses,seconds,loop):
 for i,(recipe,pose) in enumerate(zip(recipes,poses)):
  f=dict(anim=name,dir='west',frame=i,output=f'native/{name}/west/{i+1:02}.png',runtime_name=f'sprites/props/{name}_{i}.png',source=source,prompt=source.replace('.png','.prompt.txt'),call=source.replace('.png','.call.json'),recipe=recipe,canvas_wh=[40,32],pivot_xy=[20,30],draw_scale=1,seconds=seconds,loop=loop,mirror='runtime',pose=pose,grounded=True,palette_keys=keys,points={})
  P['files'].append(f)
def bounds(source,n):
 im=Image.open(D/source).convert('RGBA');mask=im.getchannel('A').point(lambda a:255 if a>=128 else 0)
 active=[x for x in range(im.width) if mask.crop((x,0,x+1,im.height)).getbbox()]
 runs=[]
 for x in active:
  if not runs or x>runs[-1][1]+1:runs.append([x,x])
  else:runs[-1][1]=x
 assert len(runs)==n,(source,runs)
 return [[a,*mask.crop((a,0,b+1,im.height)).getbbox()[1::2],b+1] for a,b in runs]
def strip(name,source,n,maxw,maxh,poses,seconds,loop):
 # Shared cell dimensions and scale; only origin changes with cell/paw baseline.
 boxes=bounds(source,n) # x0,y0,y1,x1
 bw=max(x1-x0 for x0,y0,y1,x1 in boxes);bh=max(y1-y0 for x0,y0,y1,x1 in boxes)
 s=min(maxw/bw,maxh/bh);pad=round(1/s);cw=bw+2*pad;ch=bh+2*pad
 recipes=[]
 for x0,y0,y1,x1 in boxes:
  source_wh=Image.open(D/source).size
  # Source spacing is irregular: crop within the measured dog, never a neighbour.
  # The common scale and common baseline preserve size without per-frame fitting.
  x=x0;y=y1-ch+pad;frame_w=x1-x0
  recipe={'crop_xywh':[x,y,frame_w,ch],'content_scale':s}
  # The empty padding is still sampled and retained. Register the common ground row.
  tmp=render(source,recipe);bb=tmp.getbbox()
  recipe['content_anchor_xy']=[round(frame_w*s)//2,round(ch*s)-(30-bb[3])]
  recipes.append(recipe)
 add(name,source,recipes,poses,seconds,loop)
 return {'source':source,'measured_bounds':boxes,'shared_cell_wh':[cw,ch],'content_scale':s}
R={}
# Wag always uses the standing master's original crop and scale.
recipe={k:master[k] for k in ['crop_xywh','content_scale']}
ims=[render('raw/dog-master-r1.png',recipe)]+[render(f'raw/dog-wag-low-r{i}.png',recipe) for i in [1,2,3]]
changes=[]
for im in ims[1:]:
 changes.append({'outside_tail_changed_pixels':sum(im.getpixel((x,y))!=ims[0].getpixel((x,y)) for y in range(32) for x in range(26)),'all_changed_pixels':sum(a!=b for a,b in zip(im.get_flattened_data(),ims[0].get_flattened_data()))})
choice=1+min(range(3),key=lambda i:changes[i]['outside_tail_changed_pixels'])
add('dog_wag','raw/dog-master-r1.png',[recipe],['standing, tail high'],.12,True)
add('dog_wag',f'raw/dog-wag-low-r{choice}.png',[recipe],['standing, tail low'],.12,True)
P['files'][-1]['frame']=1;P['files'][-1]['output']='native/dog_wag/west/02.png';P['files'][-1]['runtime_name']='sprites/props/dog_wag_1.png'
R['wag']={'selected_revision':choice,'comparison':changes}
R['walk']=strip('dog_walk','raw/dog-walk-r2.png',4,22,16,['near front contact','passing','opposite front contact','opposite passing'],.15,True)
R['bark']=strip('dog_bark','raw/dog-bark-r1.png',3,22,17,['mouth closed, head back','mouth open','mouth closing'],.1,False)
R['sleep']=strip('dog_sleep','raw/dog-sleep-r2.png',2,20,10,['curled asleep','breathing'],.6,True)
R['run']=strip('dog_run','raw/dog-run-r1.png',4,28,15.4,['front landing','gathered','hind push','stretched'],.08,True)
R['bite']=strip('dog_bite','raw/dog-bite-r1.png',3,27,17,['crouch','open-jaw lunge','recover'],.1,False)
# Bite jaw contact is inspected against the native preview, not invented here.
P['files'][-2]['points']={'bite_xy':[9,21]}
P['deviations']=[d for d in P['deviations'] if d.get('rule')!='Strip spacing']+[{'rule':'Strip spacing','change':'ImageGen returned unequal frame gaps. Each frame is cropped inside its measured opaque x bounds, using one shared content_scale and cell height per animation; this prevents neighbour leakage. No pose is individually resized or painted.'}]
(D/'raw/export-plan.json').write_text(json.dumps(P,indent=2)+'\n',encoding='utf-8')
(D/'raw/continuation-measurements.json').write_text(json.dumps(R,indent=2)+'\n',encoding='utf-8')
preview=Image.new('RGBA',(4*44,7*40),(28,39,43,255))
for row,name in enumerate(['dog_sit','dog_wag','dog_walk','dog_bark','dog_sleep','dog_run','dog_bite']):
 for f in [f for f in P['files'] if f['anim']==name]:
  im=render(f['source'],f['recipe']);preview.alpha_composite(im,(f['frame']*44,row*40))
  print(name,f['frame'],im.getbbox())
preview.resize((preview.width*5,preview.height*5),Image.Resampling.NEAREST).save(D/'preview/continuation/native-review-5x.png')
print(json.dumps(R))
