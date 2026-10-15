"""Measure modules and compose cardinal joins using ART-CONTRACT 2.3 only."""
from pathlib import Path
from PIL import Image
import json,copy,sys
sys.dont_write_bytecode=True
D=Path(__file__).resolve().parent
P=json.loads((D/'raw/export-plan.json').read_text())
config=json.loads((D/'raw/barrier-selection.json').read_text())
def boxes(source,n,cells=None):
 im=Image.open(D/source).convert('RGBA');a=im.getchannel('A').point(lambda x:255 if x>=128 else 0);runs=[]
 if cells:
  result=[]
  for y0,y1 in zip(cells,cells[1:]):
   b=a.crop((0,y0,im.width,y1)).getbbox();assert b,(source,y0,y1)
   result.append([b[0],y0+b[1],b[2]-b[0],b[3]-b[1]])
  assert len(result)==n
  return result
 for y in range(im.height):
  if a.crop((0,y,im.width,y+1)).getbbox():
   if not runs or y>runs[-1][1]+41:runs.append([y,y])
   else:runs[-1][1]=y
 assert len(runs)==n,(source,runs)
 bs=[]
 for y0,y1 in runs:
  b=a.crop((0,y0,im.width,y1+1)).getbbox();bs.append([b[0],y0,b[2]-b[0],y1-y0+1])
 return bs
P['status']='review';P['files']=[f for f in P['files'] if f['anim']=='zap'];P['joins']={};records={}
for family,c in config.items():
 whole='raw/'+c['whole']+'.png';hurt='raw/'+c['hurt']+'.png';bs=boxes(whole,4,c.get('whole_cells_y'));hs=boxes(hurt,3,c.get('hurt_cells_y'))
 scale=(27/bs[2][3]) if c.get('scale_anchor')=='vertical27' else 16/bs[1][2]
 records[family]={'whole_boxes':bs,'hurt_boxes':hs,'content_scale':scale}
 for damaged,source,rects in [(False,whole,bs),(True,hurt,hs)]:
  for i,(part,b) in enumerate(zip(['post','horizontal','vertical','wreck'],rects)):
   name=family+'_'+part+('_hurt' if damaged else '');b=list(b)
   if part=='horizontal' and round(b[2]*scale)>16:
    # A continuous wire/beam is an authored repeatable module. Cut its centre
    # length at the shared scale; never squeeze the whole bar to fit the canvas.
    target=round(16/scale);b[0]+=(b[2]-target)//2;b[2]=target
   w,h=[max(1,round(v*scale)) for v in b[2:]]
   anchor=[w//2,h+8 if part in ['post','horizontal'] else h]
   if part=='horizontal' and c.get('wire_top_row') is not None:anchor[1]=28-c['wire_top_row']
   # A source crop never crosses another cell, and no module is individually resized.
   f=dict(anim=name,dir='none',frame=0,pose=('damaged ' if damaged else 'whole ')+part,output=f'native/{name}/none/01.png',runtime_name=f'sprites/buildings/'+('' if part=='wreck' else 'modules/')+name+'.png',source=source,prompt=source.replace('.png','.prompt.txt'),call=source.replace('.png','.call.json'),recipe={'crop_xywh':b,'content_scale':scale,'content_anchor_xy':anchor},canvas_wh=[16,32],pivot_xy=[8,28],draw_scale=1,seconds=.55,loop=False,mirror='none',grounded=part in ['vertical','wreck'],palette_keys=None,points={})
   P['files'].append(f)
 for damaged in [False,True]:
  suffix='_hurt' if damaged else '';post=next(f for f in P['files'] if f['anim']==family+'_post'+suffix)
  names={part:f'native/{family}_{part}{suffix}/none/01.png' for part in ['post','horizontal','vertical']}
  for mask in range(16):
   name=family+('' if mask==0 else f'_join_{mask}')+suffix;parts=[]
   for bit,part,rect,paste in [(1,'vertical',[0,8,16,20],[0,0]),(8,'horizontal',[0,0,8,32],[0,0]),(2,'horizontal',[8,0,8,32],[8,0]),(4,'vertical',[0,8,16,20],[0,8])]:
    if mask&bit:parts.append({'input':names[part],'slice_xywh':rect,'paste_xy':paste})
   parts.append({'input':names['post'],'slice_xywh':[0,0,16,32],'paste_xy':[0,0]})
   f=copy.deepcopy(post);f.update(anim=name,output=f'native/{name}/none/01.png',runtime_name='sprites/buildings/'+name+'.png',pose=f'connected mask {mask}',operation='compose',grounded=False,parts=parts,recipe={'content_scale':scale})
   P['files'].append(f);P['joins'][name]={'family':family,'state':'hurt' if damaged else 'whole','mask':mask,'parts':parts}
P['quality_issues']=[]
P['deviations']=[d for d in P.get('deviations',[]) if not isinstance(d,dict) or d.get('rule')!='Continuation layout']+[{'rule':'Continuation layout','change':'Vertical source columns preserve shared module scale. The previously authorized 27px vertical envelope resolves the shared A042/A043 source-ratio conflict. Posts/spans stay at row20; joins still use the exact original 2.3 slices.','owner_words':'Permitir até 27 px no canvas final'}]
(D/'raw/export-plan.json').write_text(json.dumps(P,indent=2)+'\n',encoding='utf-8');(D/'raw/barrier-measurements.json').write_text(json.dumps(records,indent=2)+'\n',encoding='utf-8');print(records)
