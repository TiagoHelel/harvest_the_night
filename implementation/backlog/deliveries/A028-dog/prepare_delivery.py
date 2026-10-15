"""Prepare reproducible diagnostics after the dog's idle correction limit."""
from pathlib import Path
import json,shutil
D=Path(__file__).resolve().parent;ROOT=D.parents[3]

def write(p,v):p.write_text(json.dumps(v,indent=2)+'\n',encoding='utf-8')

reasons={'dog_sit_0-r1':'Sitting native bounds 16x16 fail required 13-15 wide and 17-19 tall; tail projection too wide.',
 'dog_sit_1-r1':'Idle edit changes body/paw pixels outside the intended ear area. Lower alpha can align, but body RGB differs.',
 'dog_sit_1-r2':'Second idle attempt changes twelve native pixels including body/paws; body is not stationary pixel for pixel.',
 'dog_sit_1-r3':'Third idle attempt changes twenty-six native pixels, including torso/paw shading; correction limit reached.'}
(D/'rejected').mkdir(exist_ok=True)
moved={}
for stem,reason in reasons.items():
 for p in sorted((D/'raw').glob(stem+'.*')):
  target=D/'rejected'/p.name
  if target.exists():assert target.read_bytes()==p.read_bytes()
  else:shutil.move(str(p),str(target))
  moved[str(p.resolve())]=str(target.resolve())
 (D/'rejected'/f'{stem}.reason.txt').write_text(reason+'\n',encoding='utf-8')
for folder in ['raw','rejected']:
 for p in (D/folder).glob('*.call.json'):
  c=json.loads(p.read_text(encoding='utf-8'))
  p.with_name(p.name.removesuffix('.call.json')+'.prompt.txt').write_text(c['arguments']['prompt'],encoding='utf-8')
  for ref in c.get('input_images',[]):
   original=str(Path(ref['path']).resolve())
   if original in moved:ref['archived_path']=moved[original]
   elif not Path(ref['path']).exists() and (D/'rejected'/Path(ref['path']).name).exists():ref['archived_path']=str((D/'rejected'/Path(ref['path']).name).resolve())
  stem=p.name.removesuffix('.call.json')
  if stem in reasons:c['decision']='rejected: '+reasons[stem];c['archived_path']=str((D/'rejected'/f'{stem}.png').resolve())
  elif stem in ['dog-master-r1','dog_sit_0-r2']:c['decision']='accepted identity/pose master for native-size style inspection only; whole pack is incomplete'
  write(p,c)
keys=['ink','ink_soft','wood_dark','wood','wood_light','soil_dark','bone_dark','bone','roof_light']
files=[]
for frame,source,top in [(0,'raw/dog_sit_0-r2.png',159),(1,'rejected/dog_sit_1-r1.png',161)]:
 stem=source.removesuffix('.png');files.append({'anim':'dog_sit','dir':'west','frame':frame,'output':f'native/dog_sit/west/{frame+1:02d}.png','runtime_name':f'sprites/props/dog_sit_{frame}.png','source':source,'prompt':stem+'.prompt.txt','call':stem+'.call.json','recipe':{'crop_xywh':[336,top,768,877],'sheet_cell_xywh':None,'content_scale':17/875,'content_anchor_xy':[7,17],'alpha_threshold':128,'palette_keys':keys,'mirrored_from':None},'canvas_wh':[40,32],'pivot_xy':[20,30],'draw_scale':1,'seconds':.5,'loop':True,'mirror':'runtime','pose':'sitting master' if frame==0 else 'ear flick; unwanted body color changes','grounded':True,'palette_keys':keys,'points':{},'review_issue':'Incomplete pack: idle body/paw colors still change after three attempts.'})
auth=json.loads((D/'authorization.json').read_text(encoding='utf-8'))
plan={'title':'The dog','date':'2026-10-13','status':'blocked','palette_mode':'A','colour_ramp':[],'expected_files':20,'files':files,'mirror_pairs':{},'deviations':[auth['reference_substitution']],'supersedes':[],'comparison':[{'path':'sprites/props/cow.png','pivot_xy':[12,22],'draw_scale':1}]}
write(D/'raw/export-plan.json',plan)
core=(ROOT/'implementation/backlog/deliveries/A030-coop-barn/export_core.py').read_text(encoding='utf-8')
core=core.replace(".read_text()", ".read_text(encoding='utf-8')")
core=core.replace("'date':'2026-10-10'", "'title':P['title'],'date':P['date']")
core=core.replace("e={'id':f['anim']", "e={'id':f['anim']")
if 'if e.get(\'palette_keys\') is None' not in core:
 core=core.replace("if f.get('palette_mode','A')=='A':return render_source(e)", "if e.get('palette_keys') is None:e.pop('palette_keys',None)\n if f.get('palette_mode','A')=='A':return render_source(e)")
(D/'build.py').write_text(core,encoding='utf-8')
(D/'qa.py').write_text('''"""Idle geometry and complete-pack checks; no raster modifications."""
def check(images,plan):
 fs=sorted(plan['files'],key=lambda f:f['frame']);a,b=[images[f['output']] for f in fs]
 return {'idle_body_identical':a.crop((0,19,40,32)).tobytes()==b.crop((0,19,40,32)).tobytes(), 'idle_paw_alpha_stationary':a.getchannel('A').crop((0,27,40,32)).tobytes()==b.getchannel('A').crop((0,27,40,32)).tobytes(), 'sitting_visible_targets':all(13<=im.getbbox()[2]-im.getbbox()[0]<=15 and 17<=im.getbbox()[3]-im.getbbox()[1]<=19 for im in [a,b]), 'seven_animations_complete':len({f['anim'] for f in fs})==7}
''',encoding='utf-8')
log=D/'review-log.txt';entry='\n2026-10-13 / Idle correction limit reached\nThe third dog_sit_1 attempt still changes lower body/paw colors. Pack blocked with two diagnostic sitting frames and accepted identity/pose masters; 18 animation frames not generated. No production export and no approval. Continue the other 20 requested new packs; owner reviews this blocker in the final batch HTML.\n'
old=log.read_text(encoding='utf-8')
if entry not in old:log.write_text(old+entry,encoding='utf-8')
print('Prepared dog diagnostics; twenty required frames remain unapproved.')
