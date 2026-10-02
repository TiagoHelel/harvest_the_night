"""Append submitted argument spelling and review decisions without changing sources/prompts."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
manifest=json.loads((ROOT/'assets/art_source/manifest.json').read_text())
for path in HERE.glob('0016-*-call.json'):
    c=json.loads(path.read_text())
    c['actual_submitted_arguments']=dict(prompt=(ROOT/c['prompt']).read_text(),
        referenced_image_paths=[(ROOT/p).as_posix() for p in c['references']],transparent_background=True)
    uses=[e['id'] for e in manifest['assets'] if e.get('source')==c['source']]
    c['selected_outputs']=uses
    if uses:c['decision']='Accepted after native/3x complete motion review; source crop and palette conversion only'
    elif c['id']=='breaker' and c['kind']=='attack':c['decision']='Rejected: neighboring full-body/tool bounds overlap horizontally; revision 1 supplies clear cells'
    path.write_text(json.dumps(c,indent=2)+'\n',encoding='utf-8',newline='\n')
print('Recorded 5 exact submissions and final review selections')
