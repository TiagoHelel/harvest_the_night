"""Machine scale/contact measurements and metadata. Never draws runtime art."""
from pathlib import Path
import sys,json
from PIL import Image,ImageDraw
sys.dont_write_bytecode=True
D=Path(__file__).resolve().parent;ROOT=D.parents[3];sys.path.insert(0,str(ROOT/'tools'));from import_art import render_source
sys.path.insert(0,str(ROOT/'implementation/backlog/deliveries/A028-dog'));from export_tools import group
def read(p):return json.loads(p.read_text())
def write(p,v):p.write_text(json.dumps(v,indent=2)+'\n')
# Charge is an edit of roll at the same source dimensions; inherit its physical scale.
walkscale=read(D/'raw/harvester-walk-r2.recipes.json')[0]['recipe']['content_scale'];c=read(D/'raw/harvester-charge-r3.cells.json');group(D,'harvester-charge-r3','4',[80,64],[40,60],c[0]['crop_xywh'][3]*walkscale)
# Death0 has airborne metal above the actual machine. Scale from the stack, not that metal.
raw=Image.open(D/'raw/harvester-death-r3.png').convert('RGBA');a=raw.getchannel('A').point(lambda v:255 if v>=128 else 0);c=read(D/'raw/harvester-death-r3.cells.json')[0];x,y,w,h=c['crop_xywh'];rear=a.crop((x+round(w*.6),y,x+w,y+h)).getbbox();body_height=h-rear[1];group(D,'harvester-death-r3','5',[80,64],[40,60],h*42.7/body_height)
write(D/'raw/death-body-measurement.json',{'first_crop_xywh':[x,y,w,h],'rear_stack_y':y+rear[1],'ground_y':y+h,'body_height_raw':body_height,'body_height_target':42.7})
c=read(D/'raw/wreck-debris-r1.cells.json');scale=min(21.7/max(v['crop_xywh'][2] for v in c),16.7/max(v['crop_xywh'][3] for v in c));group(D,'wreck-debris-r1','4',[24,20],[12,18],c[0]['crop_xywh'][3]*scale)
def clusters(im):
 xs=[x for x in range(80) if im.getchannel('A').crop((x,58,x+1,60)).getbbox()];groups=[]
 for x in xs:
  if not groups or x-groups[-1][-1]>2:groups.append([x])
  else:groups[-1].append(x)
 return [[v[0],v[-1]+1] for v in groups]
stems=['harvester-master-r2','harvester-walk-r2','harvester-windup-r1','harvester-charge-r3','harvester-crush-r1','harvester-death-r3']
for stem in stems:
 p=D/f'raw/{stem}.recipes.json';data=read(p);out=Image.new('RGBA',((80+4)*len(data),64))
 for i,e in enumerate(data):
  r=e['recipe'];im=render_source(r);x,y,w,h=r['crop_xywh'];s=r['content_scale'];r.setdefault('content_anchor_xy',[round(w*s)//2,round(h*s)]);r['content_anchor_xy'][1]+=im.getbbox()[3]-60;im=render_source(r)
  if stem in ['harvester-walk-r2','harvester-charge-r3','harvester-crush-r1']:
   gs=sorted(clusters(im),key=lambda q:q[1]-q[0],reverse=True)[:2]
   if len(gs)==2:
    centres=[(q[0]+q[1])/2 for q in gs];r['content_anchor_xy'][0]+=round(sum(centres)/2-40);im=render_source(r);e['registered_wheel_contact_clusters']=clusters(im)
  e['native_bounds']=im.getbbox();out.alpha_composite(im,(i*84,0));print(stem,i,im.getbbox(),clusters(im))
 write(p,data);out.resize((out.width*6,384),Image.Resampling.NEAREST).save(D/f'preview/{stem}-registered-6x.png')
 # Metadata coordinate diagram, not art: source-owned preview pixels remain untouched.
 if stem=='harvester-windup-r1':
  view=Image.new('RGBA',(out.width*8,64*8),(45,49,52,255));view.alpha_composite(out.resize(view.size,Image.Resampling.NEAREST));dr=ImageDraw.Draw(view)
  for i in range(len(data)):
   for xx in range(0,81,8):dr.line(((i*84+xx)*8,0,(i*84+xx)*8,512),fill=(85,85,85,255));dr.text(((i*84+xx)*8+2,2),str(xx),fill=(255,255,255,255))
   for yy in range(0,65,8):dr.line((i*84*8,yy*8,(i*84+80)*8,yy*8),fill=(85,85,85,255));dr.text((i*84*8+2,yy*8+2),str(yy),fill=(255,255,255,255))
  view.save(D/'preview/windup-coordinate-review.png')
