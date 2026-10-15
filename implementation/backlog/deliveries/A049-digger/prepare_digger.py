"""Source selections and native recipes for final diagnostic review."""
from pathlib import Path
import sys,json
from PIL import Image
sys.dont_write_bytecode=True
D=Path(__file__).resolve().parent;ROOT=D.parents[3];sys.path.insert(0,str(ROOT/'tools'));from import_art import render_source;from palette import COLOURS
sys.path.insert(0,str(ROOT/'implementation/backlog/deliveries/A028-dog'));from export_tools import group
def read(p):return json.loads(p.read_text())
def write(p,v):p.write_text(json.dumps(v,indent=2)+'\n')
group(D,'digger-burrow-r1','4',[64,48],[32,44],17.5*425/413)
group(D,'digger-mound-r1','3',[64,48],[32,44],18.3*167/525)
soil=['ink','ink_soft','soil_dark','soil','soil_light','wood_dark','stone_dark']
mapping={'digger':('digger-master-r2',1,.1,False),'digger_walk':('digger-walk-r3',4,.125,True),'digger_burrow':('digger-burrow-r1',4,.1,False),'digger_mound':('digger-mound-r1',3,.125,True),'digger_emerge':('digger-emerge-r1',4,.1,False),'digger_attack':('digger-attack-r2',3,.1,False),'digger_death':('digger-death-r2',4,.1,False),'head_digger':('head-digger-r1',1,1,False)}
rgb=set();files=[];sel={'status':'blocked','issues':['Walk exhausted3attempts: r1 has overlapping columns, r2 has diffusehalo, r3 still puts the same near leg forward in both contacts. No fourthattempt and no production export.','Emerge final stands26px but has neutral master stance rather than walk0 stride. Mixed-body soil clod mapping remains unverified.'],'files':{},'rejected':{'digger-master-r1':'32pxwide at26pxhigh; r2 meets20x26 and farther frombreaker.','digger-walk-r1':'Overlapping column space prevents safe rectangular extraction.','digger-walk-r2':'Diffusehalo outside body; forbidden even if removed bythreshold.','digger-death-r1':'Overlapping corpse/precedingcell.','digger-attack-r1':'Unrequestedsoil debris in attack, corrected byr2.'},'decisions':{}}
for anim,(stem,count,seconds,loop) in mapping.items():
 if anim=='head_digger':continue
 data=read(D/f'raw/{stem}.recipes.json')
 for i,e in enumerate(data):
  if anim=='digger_mound' or anim=='digger_burrow' and i==3:e['recipe']['palette_keys']=soil
  im=render_source(e['recipe']);e['native_bounds']=im.getbbox();rgb.update(px[:3] for px in im.get_flattened_data() if px[3])
 write(D/f'raw/{stem}.recipes.json',data)
bodykeys=[k for k,v in COLOURS.items() if v in rgb];data=read(D/'raw/head-digger-r1.recipes.json');r=data[0]['recipe'];r['palette_keys']=bodykeys;r['content_anchor_xy']=[5,6];im=render_source(r);data[0]['native_bounds']=im.getbbox();write(D/'raw/head-digger-r1.recipes.json',data);im.resize((96,96),Image.Resampling.NEAREST).save(D/'preview/head-native-6x.png')
print('Eye candidates',[(x,y) for y in range(6,10) for x in range(5,10) if im.getpixel((x,y))[:3] in [COLOURS['bone'],COLOURS['bone_dark']]])
for anim,(stem,count,seconds,loop) in mapping.items():
 for i in range(count):
  head=anim=='head_digger';direction='none' if head else 'west';fields={'inspection_eye_xy':[7,8],'palette_keys':bodykeys} if head else {};f={'anim':anim,'dir':direction,'frame':i,'pose':anim+'_'+str(i),'output':f'native/{anim}/{direction}/{i+1:02d}.png','runtime_name':'sprites/'+('ui/head_digger.png' if head else 'enemies/'+anim+('' if anim=='digger' else '_'+str(i))+'.png'),'canvas_wh':[16,16] if head else [64,48],'pivot_xy':[8,8] if head else [32,44],'draw_scale':1,'seconds':seconds,'loop':loop,'mirror':'none' if head else 'runtime','points':{},'grounded':not head};files.append(f);sel['files'][anim+'/'+direction+'/'+str(i)]={'stem':stem,'index':i,'fields':fields};sel['decisions'][stem]={'decision':'diagnostic candidate only; pack gait rejected, no approval'}
plan={'title':'The digger','date':'2026-10-14','status':'blocked','palette_mode':'A','expected_files':24,'files':files,'mirror_pairs':{},'deviations':[],'supersedes':[],'comparison':[{'path':'sprites/enemies/walker.png','pivot_xy':[32,44],'draw_scale':1}]}
write(D/'raw/delivery-spec.json',plan);write(D/'raw/selection.json',sel);write(D/'raw/body-palette-keys.json',bodykeys)
