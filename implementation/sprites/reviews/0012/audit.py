"""Record exact returned sources and preserved baseline art/core bytes."""
from pathlib import Path
import hashlib
import io
import json
import subprocess
import tarfile
from PIL import Image

ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
BASE='b9f0298'

def digest(data):return hashlib.sha256(data).hexdigest()

def main():
    manifest=json.loads((ROOT/'assets/art_source/manifest.json').read_text())
    selected=[e for e in manifest['assets'] if e.get('generation_task')=='0012']
    outputs={e['output'] for e in selected}
    assert len(outputs)==30
    archive=subprocess.check_output(['git','archive',BASE,'sprites','src/core','src/ui/player_frames.gd','assets/art_source','tools/palette.py','tools/determinism_sim_hash.txt','tools/determinism_data_hash.txt'],cwd=ROOT)
    with tarfile.open(fileobj=io.BytesIO(archive)) as snapshot:
        old={m.name:snapshot.extractfile(m).read() for m in snapshot.getmembers() if m.isfile()}
    old_png={p:b for p,b in old.items() if p.startswith('sprites/') and p.endswith('.png')}
    changed=sorted(p for p,b in old_png.items() if (ROOT/p).read_bytes()!=b)
    added=sorted(p for p in outputs if p not in old_png)
    assert len(changed)==20 and set(changed)<=outputs and len(added)==10
    preserved_png=sorted(set(old_png)-outputs)
    assert len(preserved_png)==250
    assert all((ROOT/p).read_bytes()==old_png[p] for p in preserved_png)
    protected={p:b for p,b in old.items() if not p.startswith('sprites/') and p not in ('assets/art_source/manifest.json','assets/art_source/ownership.json','assets/art_source/README.md')}
    assert all((ROOT/p).read_bytes()==b for p,b in protected.items())
    previous=json.loads(old['assets/art_source/manifest.json'])
    current={e['id']:e for e in manifest['assets']}
    assert all(e==current[e['id']] for e in previous['assets'] if e['output'] not in outputs)
    sources=[]
    for path in sorted((ROOT/'implementation/sprites/generation').glob('0012-*-call.json')):
        call=json.loads(path.read_text())
        raw=(ROOT/call['source']).read_bytes()
        assert raw==Path(call['returned_file']).read_bytes()
        assert digest(raw)==call['source_sha256']
        assert digest((ROOT/call['prompt']).read_bytes())==call['prompt_sha256']
        assert all((ROOT/p).is_file() for p in call['references'])
        call['decision']='Accepted: source alpha, native palette/scale/contact, identity and actual Godot states reviewed. Master-only records establish identity; state strips own final production frames.'
        path.write_text(json.dumps(call,indent=2)+'\n',encoding='utf-8',newline='\n')
        sources.append(dict(source=call['source'],source_sha256=digest(raw),returned_file=call['returned_file'],prompt=call['prompt'],prompt_sha256=call['prompt_sha256'],references=call['references'],revision=call['revision'],source_wh=call['source_wh'],source_alpha_range=call['source_alpha_range']))
    assert len(sources)==10
    frames=[]
    for entry in selected:
        im=Image.open(ROOT/entry['output']).convert('RGBA')
        frames.append(dict(id=entry['id'],output_sha256=digest((ROOT/entry['output']).read_bytes()),canvas_wh=list(im.size),visible_bounds=list(im.getbbox()),pivot_xy=entry['pivot_xy'],content_scale=entry.get('content_scale'),source=entry.get('source'),input=entry.get('input'),light_xy=entry.get('light_xy'),smoke_xy=entry.get('smoke_xy')))
    owners=json.loads((ROOT/'assets/art_source/ownership.json').read_text())['outputs']
    counts={name:sum(e['owner']==name for e in owners) for name in ('raster','ascii','player-sheet')}
    assert counts['raster']==184 and counts['ascii']==96 and len(owners)==280
    data=dict(baseline=BASE,changed_existing_pngs=changed,added_pngs=added,preserved_png_count=len(preserved_png),preserved_png_sha256={p:digest(old_png[p]) for p in preserved_png},protected_file_count=len(protected),protected_sha256={p:digest(b) for p,b in protected.items()},unchanged_previous_manifest_entries=True,ownership_counts=counts,tool_calls=sources,frames=frames,simulation=(ROOT/'tools/determinism_sim_hash.txt').read_text().strip(),data=(ROOT/'tools/determinism_data_hash.txt').read_text().strip())
    (HERE/'scope-and-sources.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8',newline='\n')
    print('PASS: 10 exact ImageGen returns/prompts; 20 changed + 10 added runtime PNGs; 250 other PNGs and %d protected files unchanged; owners 184 raster / 96 ASCII'%len(protected))

if __name__=='__main__':main()
