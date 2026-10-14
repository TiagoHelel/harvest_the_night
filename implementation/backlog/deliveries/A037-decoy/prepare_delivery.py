"""Prepare measured decoy recipes and honest incomplete-pack diagnostics."""
from pathlib import Path
import json,shutil
from PIL import Image
D=Path(__file__).resolve().parent;ROOT=D.parents[3]
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,v):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(v,indent=2)+'\n',encoding='utf-8')
spec=D/'raw/delivery-spec.json'
if not spec.exists():shutil.copyfile(D/'contract.json',spec)
draft=read(spec);files=[];cells=read(D/'raw/decoy-states-r3.cells.json')
for f in draft['files']:
 f=dict(f);name=f['anim'];i=f['frame']
 if name in ['decoy','decoy_hurt','decoy_wreck']:
  index=['decoy','decoy_hurt','decoy_wreck'].index(name);c=dict(cells[index]);c['crop_xywh']=list(c['crop_xywh'])
  if name=='decoy_wreck':c['crop_xywh']=read(D/'raw/decoy-wreck-grid-registration.json')[0]['recipe']['crop_xywh']
  source='raw/decoy-states-r3.png';recipe={**c,'content_scale':.0453};pose=name
 elif name in ['decoy_sway','decoy_hurt_sway']:
  stem='decoy-sway-r3' if name=='decoy_sway' else 'decoy-hurt-sway-r1';r=read(D/f'raw/{stem}.recipes.json')[i]['recipe'];source=f'raw/{stem}.png';recipe={k:r[k] for k in ['crop_xywh','sheet_cell_xywh','content_scale','content_anchor_xy']};pose=['lean_west_2','rebound_east_1','settle_west_1'][i]
  if name=='decoy_hurt_sway':f['review_issue']='All three attempts failed the required sway; r1 is diagnostic only, r3 clips the target canvas.'
 elif name=='zombie_bait':
  source='raw/zombie-bait-r1.png';im=Image.open(D/source).convert('RGBA');x,y,r,b=im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox();recipe={'crop_xywh':[x,y,r-x,b-y],'content_scale':12/(r-x)};pose='one rotten fish, ground bait'
 else:
  source='raw/icon-zombie-bait-r1.png';im=Image.open(D/source).convert('RGBA');x,y,r,b=im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox();s=(8 if name.startswith('hud_') else 14)/max(r-x,b-y);recipe={'crop_xywh':[x,y,r-x,b-y],'content_scale':s,'content_anchor_xy':[round((r-x)*s)//2,round((b-y)*s)//2]};pose='rotten fish tied to short stick, inventory kit';f['resource_id']='zombie_bait';f['display_role']='compact_hud' if name.startswith('hud_') else 'inventory'
 recipe.update(alpha_threshold=128,palette_keys=None,mirrored_from=None);recipe.setdefault('sheet_cell_xywh',None)
 f.update(source=source,prompt=source.replace('.png','.prompt.txt'),call=source.replace('.png','.call.json'),recipe=recipe,pose=pose,grounded=not name.startswith(('icon_','hud_')));files.append(f)
reasons={'decoy-master-r1':'Native standing width18 exceeds11-12 required.', 'decoy-states-r1':'Whole too wide15x26; wreck19x10 clips16px canvas at common scale.', 'decoy-states-r2':'Whole14x26 too wide; wreck17x9 clips target canvas.', 'decoy-sway-r1':'Sway exaggerated: head offsets about-4,+2.6,-1.9, rather than-2,+1,-1.', 'decoy-sway-r2':'Sway still exceeds target top displacement.', 'decoy-hurt-sway-r1':'Three damaged frames nearly stationary; required left/right/left sway absent.', 'decoy-hurt-sway-r2':'Moves base instead of correct upper-body sway; motion direction/magnitude incorrect.', 'decoy-hurt-sway-r3':'Excessive first-frame lean clips native16x32 when the stake base is grounded; third attempt limit reached.'}
(D/'rejected').mkdir(exist_ok=True)
for stem,reason in reasons.items():
 for p in sorted((D/'raw').glob(stem+'.*')):
  target=D/'rejected'/p.name
  if target.exists():assert target.read_bytes()==p.read_bytes()
  else:shutil.move(str(p),str(target))
 (D/'rejected'/f'{stem}.reason.txt').write_text(reason+'\n',encoding='utf-8')
for f in files:
 if not (D/f['source']).exists():
  for key in ['source','prompt','call']:f[key]='rejected/'+Path(f[key]).name
for folder in ['raw','rejected']:
 for p in (D/folder).glob('*.call.json'):
  c=read(p);stem=p.name.removesuffix('.call.json');p.with_name(stem+'.prompt.txt').write_text(c['arguments']['prompt'],encoding='utf-8')
  for ref in c.get('input_images',[]):
   if not Path(ref['path']).exists():ref['archived_path']=str((D/'rejected'/Path(ref['path']).name).resolve())
  c['decision']='rejected: '+reasons[stem] if stem in reasons else 'accepted identity/cells for native review; pack incomplete, not approved'
  if stem in reasons:c['archived_path']=str((D/'rejected'/f'{stem}.png').resolve())
  write(p,c)
plan={'title':draft['title'],'date':'2026-10-13','status':'blocked','palette_mode':'A','colour_ramp':[],'expected_files':12,'files':files,'mirror_pairs':{},'deviations':[],'supersedes':[],'comparison':[{'path':'sprites/buildings/barricade.png','pivot_xy':[8,20],'draw_scale':1}]};write(D/'raw/export-plan.json',plan)
core=(ROOT/'implementation/backlog/deliveries/A028-dog/build.py').read_text(encoding='utf-8');(D/'build.py').write_text(core,encoding='utf-8')
extras=ROOT/'implementation/backlog/deliveries/A003-guardian/review_extras_template.py'
if extras.exists():shutil.copyfile(extras,D/'review_extras.py')
log=D/'review-log.txt';entry='\n2026-10-13 / All12 diagnostic frames prepared; damaged sway failed after3tries\nWhole/hurt/wreck use one source and content_scale0.0453. The wreck crop includes12 measured transparent columns on the right for native grid registration; no source pixels altered. Whole11x27, hurt12x23, wreck14x8. Whole sway is internally acceptable with half-pixel quantization of the top shift. The damaged sway remains wrong; r1 is shown only as a diagnostic and r3 clips when anchored. All independent bait/icon assets were also generated. Pack blocked, zero production exports, no owner approval.\n'
old=log.read_text(encoding='utf-8')
if entry not in old:log.write_text(old+entry,encoding='utf-8')
print('Prepared twelve incomplete-pack diagnostic recipes, no production approval.')
