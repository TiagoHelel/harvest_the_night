"""Add only missing walk/cast sources. Keep every approved export byte-identical."""
from pathlib import Path
from PIL import Image
import json,sys
sys.dont_write_bytecode=True
D=Path(__file__).resolve().parent;sys.path.insert(0,str(D.parents[3]/'tools'))
from import_art import render_source
P=json.loads((D/'raw/export-plan.json').read_text())
P['status']='review';P['files']=[f for f in P['files'] if f['anim'] not in ['winter_lord_walk','winter_lord_cast']]
def boxes(source,n):
 im=Image.open(D/source).convert('RGBA');a=im.getchannel('A').point(lambda x:255 if x>=128 else 0);runs=[]
 for x in range(im.width):
  if a.crop((x,0,x+1,im.height)).getbbox():
   if not runs or x>runs[-1][1]+1:runs.append([x,x])
   else:runs[-1][1]=x
 assert len(runs)==n,(source,runs)
 result=[]
 for x0,x1 in runs:
  b=a.crop((x0,0,x1+1,im.height)).getbbox();result.append([x0,b[1],x1+1-x0,b[3]-b[1]])
 return result
records={}
for anim,name,poses,seconds,loop in [('winter_lord_walk','winter-walk-r5',['near contact','passing','opposite contact','opposite passing'],.14,True),('winter_lord_cast','winter-cast-r5',['staff lifting','crystal above crown','peak crystals','peak held'],.1,False)]:
 source='raw/'+name+'.png';bs=boxes(source,4)
 # First pose is upright, staff below crown, at the accepted 46 px body height.
 scale=46/bs[0][3]
 records[anim]={'measured_bounds_xywh':bs,'content_scale':scale,'first_pose_height_target':46}
 for i,(b,pose) in enumerate(zip(bs,poses)):
  f={'anim':anim,'dir':'west','frame':i,'pose':pose,'output':f'native/{anim}/west/{i+1:02}.png','runtime_name':f'sprites/enemies/{anim}_{i}.png','source':source,'prompt':'raw/'+name+'.prompt.txt','call':'raw/'+name+'.call.json','recipe':{'crop_xywh':b,'content_scale':scale},'canvas_wh':[80,64],'pivot_xy':[40,60],'draw_scale':1,'seconds':seconds,'loop':loop,'mirror':'runtime','grounded':True,'palette_keys':None}
  P['files'].append(f)
P['deviations']=[d for d in P['deviations'] if not isinstance(d,str) or not (d.startswith('The walk') or d.startswith('The cast'))]
P['deviations'].append({'rule':'Continuation after previous r3 limit','owner_words':'entao bora continuar essa poha','change':'Generate only the two missing four-frame animations. All 14 previously approved native outputs are preserved. Source columns are measured from alpha gaps, one scale per strip.'})
(D/'raw/export-plan.json').write_text(json.dumps(P,indent=2)+'\n',encoding='utf-8');(D/'raw/continuation-measurements.json').write_text(json.dumps(records,indent=2)+'\n',encoding='utf-8')
print(records)
