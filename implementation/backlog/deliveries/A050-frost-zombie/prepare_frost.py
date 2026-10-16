"""Measured frost selections, retained as diagnostics after capped source-halo failure."""
from pathlib import Path
import sys,json
from PIL import Image
sys.dont_write_bytecode=True
D=Path(__file__).resolve().parent;ROOT=D.parents[3];sys.path.insert(0,str(ROOT/'tools'));from import_art import render_source;from palette import COLOURS
sys.path.insert(0,str(ROOT/'implementation/backlog/deliveries/A028-dog'));from export_tools import register_feet
def read(p):return json.loads(p.read_text())
def write(p,v):p.write_text(json.dumps(v,indent=2)+'\n')
mapping={'frost_zombie':('frost-master-r1',1,.1,False),'frost_zombie_walk':('frost-walk-r3',4,.125,True),'frost_zombie_attack':('frost-attack-r1',3,.1,False),'frost_zombie_death':('frost-death-r1',4,.1,False),'ice_shatter':('ice-shatter-r1',4,.08,False),'head_frost_zombie':('head-frost-r1',1,1,False)};rgb=set()
for anim,(stem,count,seconds,loop) in mapping.items():
 if not anim.startswith('frost_zombie'):continue
 register_feet(D,stem,5)
 for e in read(D/f'raw/{stem}.recipes.json'):rgb.update(px[:3] for px in render_source(e['recipe']).get_flattened_data() if px[3])
bodykeys=[k for k,v in COLOURS.items() if v in rgb];data=read(D/'raw/head-frost-r1.recipes.json');r=data[0]['recipe'];r['palette_keys']=bodykeys;r['content_anchor_xy']=[6,6];im=render_source(r);data[0]['native_bounds']=im.getbbox();write(D/'raw/head-frost-r1.recipes.json',data);im.resize((96,96),Image.Resampling.NEAREST).save(D/'preview/head-native-6x.png');print('Eye',im.getpixel((7,10)),'bone',COLOURS['bone'],COLOURS['bone_dark'])
data=read(D/'raw/ice-shatter-r1.recipes.json');fxkeys=['ink','ink_soft','water_dark','water','water_light','moon','bone','stone_light','night_light']
for e in data:e['recipe']['palette_keys']=fxkeys
write(D/'raw/ice-shatter-r1.recipes.json',data)
sel={'status':'review','issues':['Alpha audit correction: raw RGB preview displays hidden RGB in zero-alpha areas. Correct RGBA compositing is clean; the apparent diffusehalo is not visible art. Source outside-dilatedmask alpha is at most1 beyond18rawpixels (<1logicalpixel). Binary128 threshold removes edge/mask encoding noise as prescribed. The formerhalo rejection is withdrawn; no additional generation was used.','Selected r3 walking has warmnear leg ahead in contact0 and coolfar leg ahead in contact2. Final owner visualapproval pending.'],'files':{},'rejected':{'frost-master-r2':'17pxwidth below18pxminimum at29pxheight; r1 chosen19x29.','frost-walk-r1':'Same leg forward in contacts; superseded byr2/r3. Halo diagnosis withdrawn after correctRGBA alpha audit.','frost-walk-r2':'Superseded by r3. Earlier sourcehalo diagnosis withdrawn: hiddenzeroalphaRGB was misread as visiblehalo.'},'decisions':{}};files=[]
for anim,(stem,count,seconds,loop) in mapping.items():
 for i in range(count):
  head=anim.startswith('head');fx=anim=='ice_shatter';direction='none' if head or fx else 'west';fields={'inspection_eye_xy':[7,10],'palette_keys':bodykeys} if head else {'palette_keys':fxkeys} if fx else {};f={'anim':anim,'dir':direction,'frame':i,'pose':anim+'_'+str(i),'output':f'native/{anim}/{direction}/{i+1:02d}.png','runtime_name':'sprites/'+('ui/head_frost_zombie.png' if head else ('effects/' if fx else 'enemies/')+anim+('' if anim=='frost_zombie' else '_'+str(i))+'.png'),'canvas_wh':[16,16] if head else [24,24] if fx else [64,48],'pivot_xy':[8,8] if head else [12,12] if fx else [32,44],'draw_scale':1,'seconds':seconds,'loop':loop,'mirror':'none' if head or fx else 'runtime','points':{},'grounded':not(head or fx)};files.append(f);sel['files'][anim+'/'+direction+'/'+str(i)]={'stem':stem,'index':i,'fields':fields};sel['decisions'][stem]={'decision':'selected for final owner review, not approved'}
plan={'title':'The frost zombie','date':'2026-10-14','status':'review','palette_mode':'A','expected_files':17,'files':files,'mirror_pairs':{},'deviations':[],'supersedes':[],'comparison':[{'path':'sprites/enemies/walker.png','pivot_xy':[32,44],'draw_scale':1}]};write(D/'raw/delivery-spec.json',plan);write(D/'raw/selection.json',sel);write(D/'raw/body-palette-keys.json',bodykeys)
