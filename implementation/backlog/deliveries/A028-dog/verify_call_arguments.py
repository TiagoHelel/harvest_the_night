"""Recover exact tool arguments from immutable UTF-8 request receipts."""
from pathlib import Path
import json
D=Path(__file__).resolve().parent
packs=['A028-dog','A040-garlic-braid','A042-electric-fence','A043-strong-walls','A045-power-weapon-icons','A054-winter-lord']
fixed=[]
for slug in packs:
 for folder in ['raw','rejected']:
  for callpath in (D.parent/slug/folder).glob('*.call.json'):
   reqpath=callpath.with_name(callpath.name.replace('.call.json','.request.json'))
   if not reqpath.exists():continue
   c=json.loads(callpath.read_text(encoding='utf-8'));r=json.loads(reqpath.read_text(encoding='utf-8'))
   if 'arguments' not in r:continue
   promptpath=callpath.with_name(callpath.name.replace('.call.json','.prompt.txt'))
   assert r['arguments']['prompt']==promptpath.read_text(encoding='utf-8'),promptpath
   if c.get('arguments')!=r['arguments']:
    c['arguments']=r['arguments'];callpath.write_text(json.dumps(c,indent=2)+'\n',encoding='utf-8');fixed.append(str(callpath.relative_to(D.parent)))
print('Exact UTF-8 tool arguments verified; corrected',len(fixed),'metadata records')
for name in ['finalize_continuation.py','archive_continuation_sources.py']:
 p=D/name;s=p.read_text(encoding='utf-8');s=s.replace('.read_text()',".read_text(encoding='utf-8')");p.write_text(s,encoding='utf-8')
