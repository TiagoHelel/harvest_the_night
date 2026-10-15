"""Prepare all11 hive diagnostics; never conceal the failed fire-body copies."""
from pathlib import Path
import json,shutil
D=Path(__file__).resolve().parent;ROOT=D.parents[3]
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,v):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(v,indent=2)+'\n',encoding='utf-8')
spec=D/'raw/delivery-spec.json'
if not spec.exists():shutil.copyfile(D/'contract.json',spec)
draft=read(spec);files=[]
for original in draft['files']:
 f=dict(original);n=f['anim'];i=f['frame']
 if n=='bee_swarm':
  stem='bee-swarm-r1';r=read(D/f'raw/{stem}.recipes.json')[i]['recipe'];keys=['ink','gold'];pose=['cloud_a','cloud_b','cloud_c'][i];f['grounded']=False
 else:
  level=2 if n.startswith('beehive_2') else 1;stem='beehive-l1-r2' if level==1 else 'beehive-l2-r1';state=next((s for s in ['hurt','fire','wreck'] if n.endswith('_'+s)),'whole');index=['whole','hurt','fire','wreck'].index(state);r=read(D/f'raw/{stem}.recipes.json')[index]['recipe'];r=dict(r)
  if level==2:r['content_scale']=.0523
  keys=None;pose=state;f['grounded']=True
  if state!='wreck':
   x,y=[19,36] if level==1 else [18,33];f['points']={'muzzle_xy':[x,y],'muzzles_xy':[[x,y]],'muzzle_region_xywh':[x-2,y-2,5,5]}
  if state=='fire':f['review_issue']='Original ImageGen fire copy changes hive body pixels outside the bee cue. L1 correction limit reached; composition authorization is pending.'
 source=f'raw/{stem}.png';recipe={k:r[k] for k in ['crop_xywh','sheet_cell_xywh','content_scale']}
 if 'content_anchor_xy' in r:recipe['content_anchor_xy']=r['content_anchor_xy']
 recipe.update(alpha_threshold=128,palette_keys=keys,mirrored_from=None)
 f.update(source=source,prompt=source.replace('.png','.prompt.txt'),call=source.replace('.png','.call.json'),recipe=recipe,pose=pose)
 if keys:f['palette_keys']=keys
 files.append(f)
reasons={'beehive-l1-r1':'Wreck19px exceeds whole17px; fire changes body/edge pixels outside bee cue.', 'beehive-l1-r3':'Third full-sheet attempt still changes65native body pixels outside bee cue.'}
(D/'rejected').mkdir(exist_ok=True)
for stem,reason in reasons.items():
 for p in sorted((D/'raw').glob(stem+'.*')):
  target=D/'rejected'/p.name
  if target.exists():assert target.read_bytes()==p.read_bytes()
  else:shutil.move(str(p),str(target))
 (D/'rejected'/f'{stem}.reason.txt').write_text(reason+'\n',encoding='utf-8')
for folder in ['raw','rejected']:
 for p in (D/folder).glob('*.call.json'):
  c=read(p);stem=p.name.removesuffix('.call.json');p.with_name(stem+'.prompt.txt').write_text(c['arguments']['prompt'],encoding='utf-8')
  for ref in c.get('input_images',[]):
   if not Path(ref['path']).exists():ref['archived_path']=str((D/'rejected'/Path(ref['path']).name).resolve())
  if stem in reasons:c['decision']='rejected: '+reasons[stem];c['archived_path']=str((D/'rejected'/f'{stem}.png').resolve())
  elif stem.startswith('beehive-l'):c['decision']='cells0,1,3 internally acceptable; cell2 FIRE rejected for body changes; shown as diagnostic only';c['accepted_cells']=[0,1,3];c['rejected_cells']=[2]
  else:c['decision']='internally acceptable source/identity for final owner review; pack incomplete and unapproved'
  write(p,c)
plan={'title':draft['title'],'date':'2026-10-13','status':'blocked','palette_mode':'A','colour_ramp':[],'expected_files':11,'files':files,'mirror_pairs':{},'deviations':[],'supersedes':[],'comparison':[{'path':'sprites/buildings/gun_tower.png','pivot_xy':[16,44],'draw_scale':1}]};write(D/'raw/export-plan.json',plan)
(D/'build.py').write_text((ROOT/'implementation/backlog/deliveries/A028-dog/build.py').read_text(encoding='utf-8'),encoding='utf-8')
shutil.copyfile(ROOT/'implementation/backlog/deliveries/A003-guardian/review_extras_template.py',D/'review_extras.py')
log=D/'review-log.txt';entry='\n2026-10-14 / Full11frame diagnostics; L1 fire-copy limit reached\nL1r2 retained as partial source: cells0,1,3 are geometrically valid, fire is not accepted. L2r1 uses one scale0.0523 across all states; wreck22wide fits whole22wide. Swarm uses palette_keys ink/gold through standard nearest-palette conversion, excluding unintended wood/night edge shades; four1-2px bee components at native size, no pixel painting. Both fire poses still change body pixels outside cue; after L1third failed attempt, pack blocked with zero production exports. Owner composition-method question remains pending. Continue other new packs; no integration approval inferred.\n'
old=log.read_text(encoding='utf-8')
if entry not in old:log.write_text(old+entry,encoding='utf-8')
print('Prepared eleven diagnostic frames; no approved production export.')
