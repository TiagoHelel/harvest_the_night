"""Prepare a new batch delivery using measured source-owned recipes only."""
from pathlib import Path
import json,sys,shutil
D=Path(sys.argv[1]).resolve();ROOT=D.parents[3]
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,v):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(v,indent=2)+'\n',encoding='utf-8')
plan=read(D/'raw/delivery-spec.json');selection=read(D/'raw/selection.json');files=[]
for original in plan['files']:
 f=dict(original);key=f["anim"]+'/'+f["dir"]+'/'+str(f["frame"]);s=selection['files'].get(key)
 if not s:continue
 stem=s['stem'];r=read(D/f'raw/{stem}.recipes.json')[s['index']]['recipe'];r={**r,**s.get('recipe',{})}
 f.update(source=f'raw/{stem}.png',prompt=f'raw/{stem}.prompt.txt',call=f'raw/{stem}.call.json',recipe={k:r[k] for k in ['crop_xywh','sheet_cell_xywh','content_scale','content_anchor_xy','alpha_threshold','palette_keys'] if k in r});f['recipe'].setdefault('palette_keys',None);f['recipe']['mirrored_from']=None
 f.update(s.get('fields',{}));files.append(f)
plan.update(files=files,status=selection['status']);plan['quality_issues']=selection.get('issues',[]);write(D/'raw/export-plan.json',plan)
(D/'rejected').mkdir(exist_ok=True)
for stem,reason in selection.get('rejected',{}).items():
 for p in sorted((D/'raw').glob(stem+'.*')):
  target=D/'rejected'/p.name
  if target.exists():assert p.read_bytes()==target.read_bytes()
  else:shutil.move(str(p),str(target))
 (D/'rejected'/f'{stem}.reason.txt').write_text(reason+'\n',encoding='utf-8')
for folder in ['raw','rejected']:
 for p in (D/folder).glob('*.call.json'):
  c=read(p);stem=p.name.removesuffix('.call.json');p.with_name(stem+'.prompt.txt').write_text(c['arguments']['prompt'],encoding='utf-8')
  for ref in c['input_images']:
   if not Path(ref['path']).exists():ref['archived_path']=str((D/'rejected'/Path(ref['path']).name).resolve())
  if stem in selection.get('rejected',{}):c['decision']='rejected: '+selection['rejected'][stem];c['archived_path']=str((D/'rejected'/f'{stem}.png').resolve())
  elif stem in selection.get('decisions',{}):c.update(selection['decisions'][stem])
  write(p,c)
core=(ROOT/'implementation/backlog/deliveries/A028-dog/build.py').read_text(encoding='utf-8')
core=core.replace('from import_art import render_source','from import_art import render_source, png as importer_png').replace("out[f['output']]=png(im)","out[f['output']]=importer_png(im)")
core=core.replace("'poses':[e['pose'] for e in entries]","'points':f.get('points',{}),'poses':[e['pose'] for e in entries]")
core=core.replace("'alpha_threshold':128,'references':","'alpha_threshold':128,'palette_keys':None,'references':")
(D/'build.py').write_text(core,encoding='utf-8')
if not (D/'review_extras.py').exists():shutil.copyfile(ROOT/'implementation/backlog/deliveries/A003-guardian/review_extras_template.py',D/'review_extras.py')
log=D/'review-log.txt';entry='\n2026-10-14 / Measured native export\n'+'\n'.join(selection.get('issues',[]))+'\nNo art approval inferred. '+str(len(files))+' of '+str(plan['expected_files'])+' candidate frames measured. All art pixels derive from recorded ImageGen PNGs through read-only render_source.\n'
old=log.read_text(encoding='utf-8') if log.exists() else ''
if entry not in old:log.write_text(old+entry,encoding='utf-8')
print(D.name,len(files),'measured candidates',selection['status'])
