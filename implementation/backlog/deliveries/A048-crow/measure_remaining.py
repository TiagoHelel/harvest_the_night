"""Measured crow registration, source pixels only."""
from pathlib import Path
import sys,json
from PIL import Image
sys.dont_write_bytecode=True
D=Path(__file__).resolve().parent;ROOT=D.parents[3];sys.path.insert(0,str(ROOT/'tools'));from import_art import render_source
sys.path.insert(0,str(ROOT/'implementation/backlog/deliveries/A028-dog'));from export_tools import group
keys=['ink','ink_soft','night','night_light','moon','stone_dark','stone','stone_light','cloth_dark','bone','bone_dark','gold_dark']
group(D,'crow-death-r1','4',[32,24],[16,22],14.3*380/448)
group(D,'head-crow-r2','single',[16,16],[8,8],13,centre=True)
for stem in ['crow-peck-r3','crow-death-r1','head-crow-r2']:
 p=D/f'raw/{stem}.recipes.json';data=json.loads(p.read_text())
 for i,e in enumerate(data):
  r=e['recipe'];x,y,w,h=r['crop_xywh'];s=r['content_scale'];r['palette_keys']=keys
  if stem=='crow-peck-r3':
   # Feet-only box, excluding the dipping beak in frame1.
   feet=[[320,535,222,101],[990,540,224,105],[1620,536,231,100]][i];bx,by,bw,bh=feet
   r['content_anchor_xy']=[round((bx+bw/2-x)*s),round(h*s)];e['measured_feet_region_raw_xywh']=feet
  elif stem=='head-crow-r2':r['content_anchor_xy']=[round(w*s)//2,round(h*s)-7]
  im=render_source(r)
  if stem=='crow-peck-r3':r['content_anchor_xy'][1]+=im.getbbox()[3]-22;im=render_source(r)
  e['native_bounds']=im.getbbox()
 p.write_text(json.dumps(data,indent=2)+'\n')
 out=Image.new('RGBA',((im.width+4)*len(data),im.height))
 for i,e in enumerate(data):out.alpha_composite(render_source(e['recipe']),(i*(im.width+4),0))
 out.resize((out.width*6,out.height*6),Image.Resampling.NEAREST).save(D/f'preview/{stem}-registered-6x.png')
