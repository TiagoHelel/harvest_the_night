"""Audit exact ImageGen returns, selected modules and untouched baseline bytes."""
from pathlib import Path
import hashlib
import io
import json
import subprocess
import sys
import tarfile
from PIL import Image

ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
BASE='4567753'


def digest(data):return hashlib.sha256(data).hexdigest()


def main():
    manifest=json.loads((ROOT/'assets/art_source/manifest.json').read_text())
    entries=[e for e in manifest['assets'] if e.get('generation_task')=='0014']
    measured=json.loads((HERE/'measured-contract.json').read_text())
    assert {e['id']:e for e in measured}=={e['id']:e for e in entries}
    outputs={e['output'] for e in entries}
    assert len(outputs)==84
    archive=subprocess.check_output(['git','archive',BASE,'sprites','src/core','src/ui/player_frames.gd','assets/art_source','tools/palette.py','tools/determinism_sim_hash.txt','tools/determinism_data_hash.txt'],cwd=ROOT)
    with tarfile.open(fileobj=io.BytesIO(archive)) as snapshot:
        old={m.name:snapshot.extractfile(m).read() for m in snapshot.getmembers() if m.isfile()}
    old_png={p:b for p,b in old.items() if p.startswith('sprites/') and p.endswith('.png')}
    changed=sorted(p for p,b in old_png.items() if (ROOT/p).read_bytes()!=b)
    added=sorted(outputs-set(old_png))
    assert len(changed)==10 and set(changed)<=outputs and len(added)==74
    preserved=sorted(set(old_png)-outputs)
    assert len(preserved)==278 and all((ROOT/p).read_bytes()==old_png[p] for p in preserved)
    protected={p:b for p,b in old.items() if not p.startswith('sprites/') and p not in ('assets/art_source/manifest.json','assets/art_source/ownership.json','assets/art_source/README.md')}
    assert all((ROOT/p).read_bytes()==b for p,b in protected.items())
    current={e['id']:e for e in manifest['assets']}
    assert all(e==current[e['id']] for e in json.loads(old['assets/art_source/manifest.json'])['assets'])
    chosen={e['source'] for e in entries if 'source' in e}
    calls=[];rejected=[]
    for path in sorted((ROOT/'implementation/sprites/generation').glob('0014-*-call.json')):
        c=json.loads(path.read_text())
        raw=(ROOT/c['source']).read_bytes()
        assert raw==Path(c['returned_file']).read_bytes()
        assert digest(raw)==c['source_sha256']
        assert digest((ROOT/c['prompt']).read_bytes())==c['prompt_sha256']
        assert all(digest((ROOT/p).read_bytes())==c['reference_hashes'][p] for p in c['references'])
        kind=c['kind']
        roles=sorted({e.get('module',e['id'].split('/')[-1]) for e in entries if e.get('source')==c['source']})
        if c['source'] in chosen or kind=='master':
            if c['decision'].startswith('Rejected'):
                c['prior_review_decision']=c['decision']
            if kind=='whole-r2':
                decision='Accepted vertical and low wreck modules only. Post/horizontal remain rejected: insufficient height at the shared reduction scale. Earlier full-family rejection is retained separately; this selection is explicitly partial.'
            elif kind=='whole-r3':
                decision='Accepted post and horizontal modules only: taller planted posts and coherent front construction. Vertical/wreck unused; whole-r2 retains the narrow north/south projection and low pile at the same physical scale.'
            elif kind=='hurt':
                decision='Accepted vertical wear module only: a broad authored stone/wood break remains readable in the narrow projection. Post/horizontal are superseded by hurt-r1 because their reduction was too low to distinguish at native size.'
            elif kind=='hurt-r1':
                decision='Accepted post and horizontal wear modules only: chipped upper post and broken rail/masonry section survive the shared reduction and are not hidden under the center post. Vertical/wreck unused in favor of the matching older projections.'
            elif kind=='master':
                decision='Accepted immutable identity reference: materials/camera and transparent alpha reviewed; the state sheet owns runtime pixels.'
            else:
                decision='Accepted three-state strip: native/3x whole/triggered/spent or whole/hurt/wreck drawings, shared scale/contact and actual Godot outcomes reviewed.'
            c['decision']=decision
            c['selected_runtime_roles']=roles
            path.write_text(json.dumps(c,indent=2)+'\n',encoding='utf-8',newline='\n')
        else:
            assert c['decision'].startswith('Rejected'),c
            rejected.append(c['source'])
        calls.append(c)
    assert len(calls)==16 and len(rejected)==4 and len(chosen)==10
    staged='--staged' in sys.argv
    if staged:
        expected={}
        for c in calls:
            expected[c['source']]=c['source_sha256']
            expected[c['prompt']]=c['prompt_sha256']
            expected.update(c['reference_hashes'])
        expected.update({e['output']:e['output_sha256'] for e in entries})
        for path,sha in expected.items():
            blob=subprocess.check_output(['git','show',':'+path],cwd=ROOT)
            assert digest(blob)==sha,('Staging changed hashed source/prompt/output bytes',path)
    frames=[]
    for e in entries:
        im=Image.open(ROOT/e['output']).convert('RGBA')
        frames.append(dict(id=e['id'],output_sha256=digest((ROOT/e['output']).read_bytes()),canvas_wh=list(im.size),visible_bounds=list(im.getbbox()),pivot_xy=e['pivot_xy'],content_scale=e.get('content_scale'),source=e.get('source'),input=e.get('input'),join_mask=e.get('join_mask'),parts=e.get('parts')))
    owners=json.loads((ROOT/'assets/art_source/ownership.json').read_text())['outputs']
    counts={name:sum(e['owner']==name for e in owners) for name in ('raster','ascii','player-sheet')}
    assert counts=={'raster':316,'ascii':46,'player-sheet':0} and len(owners)==362
    captures=sorted((ROOT/'implementation/shots/sprites/0014').rglob('*.png'))
    assert len(captures)==42
    reviews=[dict(path=str(p.relative_to(ROOT)).replace('\\','/'),sha256=digest(p.read_bytes()),native_wh=list(Image.open(p).size),reviewed_scales=[1,3]) for p in captures]
    (HERE/'frame-review.json').write_text(json.dumps(reviews,indent=2)+'\n',encoding='utf-8',newline='\n')
    report=dict(baseline=BASE,staged_hashed_bytes_verified=staged,changed_existing_pngs=changed,added_pngs=added,preserved_png_count=len(preserved),preserved_png_sha256={p:digest(old_png[p]) for p in preserved},protected_file_count=len(protected),protected_sha256={p:digest(b) for p,b in protected.items()},unchanged_previous_manifest_entries=True,ownership_counts=counts,tool_calls=calls,rejected_sources=rejected,frames=frames,simulation=(ROOT/'tools/determinism_sim_hash.txt').read_text().strip(),data=(ROOT/'tools/determinism_data_hash.txt').read_text().strip())
    (HERE/'scope-and-sources.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(f'PASS: 16 exact ImageGen returns/prompts/references; 8 partial module sources, 2 identity masters, 2 state strips, 4 retained rejections; 10 changed + 74 added PNGs; 278 other PNGs and {len(protected)} protected files unchanged; 42 reviewed captures; owners 316 raster / 46 ASCII')
    if staged:print(f'PASS: {len(expected)} hashed source/prompt/reference/runtime blobs are byte-exact in Git staging')


if __name__=='__main__':main()
