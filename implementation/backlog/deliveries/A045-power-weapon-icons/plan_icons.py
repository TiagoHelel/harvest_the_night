"""One measured crop per ImageGen source; two palette-mapped native cuts."""
from pathlib import Path
from PIL import Image
import json,sys
sys.dont_write_bytecode=True
D=Path(__file__).resolve().parent;sys.path.insert(0,str(D.parents[3]/'tools'))
from import_art import render_source
P=json.loads((D/'raw/export-plan.json').read_text());P.update(status='review',files=[],quality_issues=[])
names=['farm_bell','call_dog','emergency_repair','decoy','beehive','catapult','garlic_braid','searchlight','electric_fence','wall_2','sandbag_wall']
preview=Image.new('RGBA',(11*40,42),(26,24,48,255))
for i,name in enumerate(names):
 source='raw/icon-'+name.replace('_','-')+'-r1.png'
 if not (D/source).exists():continue
 im=Image.open(D/source).convert('RGBA');a=im.getchannel('A').point(lambda x:255 if x>=128 else 0);x,y,x1,y1=a.getbbox();crop=[x,y,x1-x,y1-y]
 for size,detail,prefix in [(16,14,'icon'),(10,8,'hud')]:
  s=detail/max(crop[2:]);w,h=[max(1,round(v*s)) for v in crop[2:]];anim=prefix+'_'+name
  f=dict(anim=anim,dir='none',frame=0,pose='static '+name,output=f'native/{anim}/none/01.png',runtime_name=f'sprites/ui/{anim}.png',source=source,prompt=source.replace('.png','.prompt.txt'),call=source.replace('.png','.call.json'),recipe={'crop_xywh':crop,'content_scale':s,'content_anchor_xy':[w//2,h//2]},canvas_wh=[size,size],pivot_xy=[size//2,size//2],draw_scale=1,seconds=1,loop=False,mirror='none',grounded=False,palette_keys=None,points={})
  P['files'].append(f)
  native=render_source({'id':anim,'source':str(D/source),'palette':'tools/palette.py:COLOURS','canvas_wh':f['canvas_wh'],'pivot_xy':f['pivot_xy'],'alpha_threshold':128,**f['recipe']})
  preview.alpha_composite(native,(i*40+(0 if size==16 else 20),10))
P['deviations']=[{'rule':'Subject reference prerequisite','owner_words':'Sim, usar candidatas como referência','change':'Use the available candidate world sprites of A028/A040/A042/A043 as identity/material references only. Existing approvals are preserved; using a candidate reference does not approve or integrate that art.'}]
(D/'raw/export-plan.json').write_text(json.dumps(P,indent=2)+'\n',encoding='utf-8');preview.resize((preview.width*4,preview.height*4),Image.Resampling.NEAREST).save(D/'preview/icon-row-4x.png')
print(len(P['files']),'native cuts planned')
