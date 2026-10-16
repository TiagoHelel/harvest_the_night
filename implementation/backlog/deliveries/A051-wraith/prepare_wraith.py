"""Wraith measured exports. No generated runtime translucency."""
from pathlib import Path
import sys,json
from PIL import Image
sys.dont_write_bytecode=True
D=Path(__file__).resolve().parent;ROOT=D.parents[3];sys.path.insert(0,str(ROOT/'tools'));from import_art import render_source;from palette import COLOURS
def read(p):return json.loads(p.read_text())
def write(p,v):p.write_text(json.dumps(v,indent=2)+'\n')
keys=['ink','ink_soft','night','night_light','moon','stone_dark','stone','stone_light','cloth_dark','cloth','water_dark','bone','bone_dark'];mapping={'wraith':('wraith-master-r1',1,.1,False),'wraith_walk':('wraith-walk-r1',4,.125,True),'wraith_attack':('wraith-attack-r1',3,.1,False),'wraith_death':('wraith-death-r2',4,.1,False),'head_wraith':('head-wraith-r1',1,1,False)};rgb=set()
for anim,(stem,count,seconds,loop) in mapping.items():
 if anim=='head_wraith':continue
 data=read(D/f'raw/{stem}.recipes.json')
 for e in data:
  r=e['recipe'];r['palette_keys']=keys;im=render_source(r);x,y,w,h=r['crop_xywh'];s=r['content_scale'];r['content_anchor_xy']=[round(w*s)//2,round(h*s)+im.getbbox()[3]-44];im=render_source(r);e['native_bounds']=im.getbbox();rgb.update(px[:3] for px in im.get_flattened_data() if px[3])
 write(D/f'raw/{stem}.recipes.json',data)
bodykeys=[k for k,v in COLOURS.items() if v in rgb];data=read(D/'raw/head-wraith-r1.recipes.json');r=data[0]['recipe'];r['palette_keys']=bodykeys;r['content_anchor_xy']=[6,6];im=render_source(r);data[0]['native_bounds']=im.getbbox();write(D/'raw/head-wraith-r1.recipes.json',data);im.resize((96,96),Image.Resampling.NEAREST).save(D/'preview/head-native-6x.png');print('Head bone points',[(x,y) for y in range(5,10) for x in range(3,10) if im.getpixel((x,y))[:3] in [COLOURS['bone'],COLOURS['bone_dark']]])
sel={'status':'review','issues':['Raw display may expose invisibleRGB in zero-alpha area; correctRGBA composite and actualalpha audit show clean hard cutouts. Binary threshold128 is applied as prescribed. No runtime fade baked in.','Final owner approval pending; wraith-walk-r2 request was not executed after alpha audit corrected the misleadingrawpreview.'],'files':{},'rejected':{'wraith-master-r2':'Unselected alternate; master1 has clearer three-pronged clothhem at1x.','wraith-death-r1':'Finalknot7pxhigh; corrected r2 is5pxhigh.'},'decisions':{}};files=[]
for anim,(stem,count,seconds,loop) in mapping.items():
 for i in range(count):
  head=anim=='head_wraith';direction='none' if head else 'west';fields={'inspection_eye_xy':[[5,5],[6,6]],'palette_keys':bodykeys} if head else {'palette_keys':keys};f={'anim':anim,'dir':direction,'frame':i,'pose':anim+'_'+str(i),'output':f'native/{anim}/{direction}/{i+1:02d}.png','runtime_name':'sprites/'+('ui/head_wraith.png' if head else 'enemies/'+anim+('' if anim=='wraith' else '_'+str(i))+'.png'),'canvas_wh':[16,16] if head else [64,48],'pivot_xy':[8,8] if head else [32,44],'draw_scale':1,'seconds':seconds,'loop':loop,'mirror':'none' if head else 'runtime','points':{},'grounded':not head};files.append(f);sel['files'][anim+'/'+direction+'/'+str(i)]={'stem':stem,'index':i,'fields':fields};sel['decisions'][stem]={'decision':'selected for final review; no approval inferred'}
plan={'title':'The wraith','date':'2026-10-14','status':'review','palette_mode':'A','expected_files':13,'files':files,'mirror_pairs':{},'deviations':[],'supersedes':[],'comparison':[{'path':'sprites/enemies/walker.png','pivot_xy':[32,44],'draw_scale':1}]};write(D/'raw/delivery-spec.json',plan);write(D/'raw/selection.json',sel);write(D/'raw/body-palette-keys.json',bodykeys)
