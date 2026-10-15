"""Keep unselected ImageGen returns with rejection reasons and intact provenance."""
from pathlib import Path
import json,hashlib
D=Path(__file__).resolve().parent
rejections={
 'A028-dog':{'dog-wag-low-r1':'More body-colour drift than selected r2.','dog-wag-low-r3':'Third correction changed more non-tail pixels than selected r2.','dog-walk-r1':'Contact poses did not alternate the front-leg lead clearly.','dog-walk-r3':'The hind-leg correction weakened the front-contact sequence; r2 retained for review.','dog-sleep-r1':'Superseded by breathing correction r2.'},
 'A054-winter-lord':{'winter-walk-r4':'Touching silhouettes prevent four clean crops.','winter-cast-r4':'Raised staff exceeds the silhouette-height ceiling.'},
 'A042-electric-fence':{'electric-whole-column-r1':'End blocks and over-wide horizontal span do not fit shared geometry.','electric-whole-column-r2':'Horizontal span still too long and wires too close.','electric-hurt-column-r1':'Post alpha differs by only one native pixel; damage disappears under joins.'},
 'A043-strong-walls':{'hardwood-whole-column-r1':'Relative module sizes and wreck envelope fail shared geometry.','hardwood-whole-column-r2':'Vertical is too short and wreck too wide at the post scale.','sandbag-whole-column-r1':'Horizontal span and wreck are oversized relative to the stack.','sandbag-whole-column-r2':'Wreck remains too wide.','hardwood-hurt-column-r1':'Some north-facing joined masks hide the break (only two alpha differences).'}
}
moved={}
for slug,items in rejections.items():
 d=(D.parent/slug).resolve();selected={f['source'] for f in json.loads((d/'raw/export-plan.json').read_text(encoding='utf-8'))['files']}
 (d/'rejected').mkdir(exist_ok=True)
 for name,reason in items.items():
  assert 'raw/'+name+'.png' not in selected,(slug,name)
  for suffix in ['.png','.prompt.txt','.call.json','.request.json']:
   src=d/'raw'/(name+suffix);dst=d/'rejected'/(name+suffix)
   assert src.resolve().is_relative_to(d) and dst.resolve().is_relative_to(d)
   if src.exists():
    if dst.exists():assert src.read_bytes()==dst.read_bytes(),dst
    else:src.rename(dst)
   if suffix=='.png':moved[str(src.resolve())]=str(dst.resolve())
  (d/'rejected'/(name+'.reason.txt')).write_text(reason+'\n',encoding='utf-8')
  callpath=d/'rejected'/(name+'.call.json')
  if callpath.exists():
   call=json.loads(callpath.read_text(encoding='utf-8'));call.update(decision='rejected / '+reason,copied_path='rejected/'+name+'.png');callpath.write_text(json.dumps(call,indent=2)+'\n',encoding='utf-8')
# Keep exact original arguments/prompts; resolve moved references through metadata.
for slug in rejections:
 d=D.parent/slug
 for folder in ['raw','rejected']:
  for p in (d/folder).glob('*.call.json'):
   c=json.loads(p.read_text(encoding='utf-8'));changed=False
   for ref in c.get('input_images',[]):
    key=str(Path(ref.get('archived_path',ref['path'])).resolve())
    if key in moved:
     ref['archived_path']=moved[key];assert hashlib.sha256(Path(ref['archived_path']).read_bytes()).hexdigest()==ref['sha256'];changed=True
   if changed:p.write_text(json.dumps(c,indent=2)+'\n',encoding='utf-8')
print(len(moved),'unselected raw images archived with reasons; no approved image moved')
