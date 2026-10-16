"""Metadata and final source choices for Harvester owner review."""
from pathlib import Path
import sys,json
from PIL import Image
sys.dont_write_bytecode=True
D=Path(__file__).resolve().parent;ROOT=D.parents[3];sys.path.insert(0,str(ROOT/'tools'));from import_art import render_source;from palette import COLOURS
def read(p):return json.loads(p.read_text())
def write(p,v):p.write_text(json.dumps(v,indent=2)+'\n')
mapping={'harvester':('harvester-master-r2',1,.1,False),'harvester_walk':('harvester-walk-r2',4,.14,True),'harvester_windup':('harvester-windup-r1',3,.1,False),'harvester_charge':('harvester-charge-r3',4,.1,True),'harvester_crush':('harvester-crush-r1',3,.1,False),'harvester_death':('harvester-death-r3',5,.12,False),'wreck_debris':('wreck-debris-r1',4,.08,False),'head_harvester':('head-harvester-r1',1,1,False)};rgb=set();metadata={}
for anim,(stem,count,seconds,loop) in mapping.items():
 if not anim.startswith('harvester'):continue
 data=read(D/f'raw/{stem}.recipes.json')
 for i,e in enumerate(data):
  r=e['recipe'];im=render_source(r);fields={}
  if anim=='harvester_windup':
   # Hub centres measured in preview/windup-coordinate-review.png.
   hubs=[[[36,50],[60,50]],[[33,43],[58,51]],[[31,31],[51,50]]][i];dx=round(sum(q[0] for q in hubs)/2-40)
   if 'windup_hub_registration_dx' not in e:r['content_anchor_xy'][0]+=dx;e['windup_hub_registration_dx']=dx
   else:dx=e['windup_hub_registration_dx']
   im=render_source(r);fields['inspection_wheel_hubs_xy']=[[q[0]-dx,q[1]] for q in hubs]
  elif anim!='harvester_death':
   spans=e.get('registered_wheel_contact_clusters',[[23,33],[47,57]]);spans=sorted(spans,key=lambda q:q[1]-q[0],reverse=True)[:2];fields['inspection_wheel_contacts']=spans
  if anim!='harvester_death':
   b=im.getbbox();pts=[(x,y) for y in range(b[1],b[3]) for x in range(max(1,b[2]-12),b[2]) if im.getpixel((x,y))[3]];top=min(y for x,y in pts);xs=[x for x,y in pts if y==top];point=[xs[len(xs)//2],top];fields['points']={'smoke_xy':point}
  e['native_bounds']=im.getbbox();rgb.update(px[:3] for px in im.get_flattened_data() if px[3]);metadata[(anim,i)]=fields
 write(D/f'raw/{stem}.recipes.json',data)
bodykeys=[k for k,v in COLOURS.items() if v in rgb];data=read(D/'raw/head-harvester-r1.recipes.json');r=data[0]['recipe'];r['palette_keys']=bodykeys;r['content_anchor_xy']=[7,6];im=render_source(r);data[0]['native_bounds']=im.getbbox();write(D/'raw/head-harvester-r1.recipes.json',data);im.resize((96,96),Image.Resampling.NEAREST).save(D/'preview/head-native-6x.png');print('Head bones',[(x,y) for y in range(5,10) for x in range(4,12) if im.getpixel((x,y))[:3] in [COLOURS['bone'],COLOURS['bone_dark']]])
data=read(D/'raw/wreck-debris-r1.recipes.json');fxkeys=['ink','ink_soft','wood_dark','wood','wood_light','stone_dark','stone','stone_light','soil_dark','soil','soil_light']
for e in data:e['recipe']['palette_keys']=fxkeys
write(D/'raw/wreck-debris-r1.recipes.json',data)
sel={'status':'review','issues':['Wind-up anchors are registered to measured wheelhub centres; contact-only anchoring would incorrectlyplace liftedwheel poses. Smoke is metadata only.','Charge r3 is an edit of roll r2 at matching source dimensions and inherits its exactcontent_scale; do not fit each newheaderangle independently.','Death0 scale is measured from rearstack/ground, excluding airbornepanel. No per-frame resize. Final owner must judge machineproportions and rotation/charge/readability at1x in assembledscene.'],'files':{},'rejected':{'harvester-master-r1':'Overlongfrontprojection71x44; cannotcentrewheelswithclearborder.','harvester-walk-r1':'Shortenedmachinebody; superseded byr2.','harvester-charge-r1':'Narrowermachine; superseded by edit ofr2roll.','harvester-charge-r2':'Header tips belowwheelbaseline; r3raisesheader.','harvester-death-r1':'Panelburst occurslate andlastwreck26high withstandingstack.','harvester-death-r2':'Correctposes but overlappingcolumnspace; r3safelyseparates.'},'decisions':{}};files=[]
for anim,(stem,count,seconds,loop) in mapping.items():
 for i in range(count):
  head=anim=='head_harvester';fx=anim=='wreck_debris';direction='none' if head or fx else 'west';fields=metadata.get((anim,i),{}).copy()
  if head:fields.update(inspection_eye_xy=[[6,7],[9,8]],palette_keys=bodykeys)
  if fx:fields['palette_keys']=fxkeys
  f={'anim':anim,'dir':direction,'frame':i,'pose':anim+'_'+str(i),'output':f'native/{anim}/{direction}/{i+1:02d}.png','runtime_name':'sprites/'+('ui/head_harvester.png' if head else ('effects/' if fx else 'enemies/')+anim+('' if anim=='harvester' else '_'+str(i))+'.png'),'canvas_wh':[16,16] if head else [24,20] if fx else [80,64],'pivot_xy':[8,8] if head else [12,18] if fx else [40,60],'draw_scale':1,'seconds':seconds,'loop':loop,'mirror':'none' if head or fx else 'runtime','points':fields.pop('points',{}),'grounded':not head};files.append(f);sel['files'][anim+'/'+direction+'/'+str(i)]={'stem':stem,'index':i,'fields':fields};sel['decisions'][stem]={'decision':'selected for final owner review; not approved'}
plan={'title':'The Harvester','date':'2026-10-14','status':'review','palette_mode':'A','expected_files':25,'files':files,'mirror_pairs':{},'deviations':[],'supersedes':[],'comparison':[{'path':'sprites/enemies/giant.png','pivot_xy':[40,60],'draw_scale':1}]};write(D/'raw/delivery-spec.json',plan);write(D/'raw/selection.json',sel);write(D/'raw/body-palette-keys.json',bodykeys)
