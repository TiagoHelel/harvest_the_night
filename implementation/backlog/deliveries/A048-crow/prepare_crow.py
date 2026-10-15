"""Select measured crow sources; no art synthesis."""
from pathlib import Path
import sys,json,shutil
from PIL import Image
sys.dont_write_bytecode=True
D=Path(__file__).resolve().parent;ROOT=D.parents[3];sys.path.insert(0,str(ROOT/'tools'));from import_art import render_source;from palette import COLOURS
def read(p):return json.loads(p.read_text())
spec=read(D/'raw/delivery-spec.json');mapping={'crow':'crow-master-r1','crow_fly':'crow-fly-r2','crow_land':'crow-land-r1','crow_peck':'crow-peck-r3','crow_death':'crow-death-r1','head_crow':'head-crow-r2'};sel={'status':'review','issues':[],'files':{},'rejected':{'crow-fly-r1':'Fourth wing is raised rather than level upstroke; superseded by r2.','crow-peck-r1':'Beak does not reach ground.','crow-peck-r2':'Beak still stops above ground.','head-crow-r1':'Eye disappears in native13px portrait.'},'decisions':{}}
rgb=set()
for anim,stem in mapping.items():
 if anim=='head_crow':continue
 for e in read(D/f'raw/{stem}.recipes.json'):rgb.update(px[:3] for px in render_source(e['recipe']).get_flattened_data() if px[3])
bodykeys=[k for k,v in COLOURS.items() if v in rgb]
p=D/'raw/head-crow-r2.recipes.json';data=read(p);data[0]['recipe']['palette_keys']=bodykeys;p.write_text(json.dumps(data,indent=2)+'\n')
for f in spec['files']:
 anim=f['anim'];stem=mapping[anim];fields={}
 if anim=='head_crow':
  fields['inspection_eye_xy']=[6,5]
 sel['files'][anim+'/'+f['dir']+'/'+str(f['frame'])]={'stem':stem,'index':f['frame'],'fields':fields}
 sel['decisions'][stem]={'decision':'selected for final owner review, not approved'}
(D/'raw/selection.json').write_text(json.dumps(sel,indent=2)+'\n');(D/'raw/body-palette-keys.json').write_text(json.dumps(bodykeys,indent=2)+'\n')
print('Head eye',fields,'body keys',bodykeys)
