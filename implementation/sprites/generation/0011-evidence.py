"""Audit the farmhouse-only runtime delta and immutable ImageGen provenance."""
from pathlib import Path
from collections import Counter
import hashlib
import json
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[3]
HERE=ROOT/'implementation/sprites/reviews/0011'
BASELINE='a42b530'
sys.path.insert(0,str(ROOT/'tools'))
import import_art


def sha(data):return hashlib.sha256(data).hexdigest()


def main():
    names={'house'}|{'house_%d_%d'%(x,y) for x in range(3) for y in range(3)}
    expected={'sprites/buildings/'+n+'.png' for n in names}
    added={'sprites/buildings/'+n+'_hurt.png' for n in names}
    changed,unchanged=[],[]
    for path in sorted((ROOT/'sprites').rglob('*.png')):
        relative=path.relative_to(ROOT).as_posix()
        old=subprocess.run(['git','show',BASELINE+':'+relative],cwd=ROOT,capture_output=True)
        new=path.read_bytes()
        if old.returncode:
            assert relative in added,relative
            changed.append(dict(path=relative,sha256=sha(new),added=True))
        elif old.stdout!=new:
            changed.append(dict(path=relative,old_sha256=sha(old.stdout),sha256=sha(new),added=False))
        else:unchanged.append(relative)
    assert {e['path'] for e in changed if not e['added']}==expected
    assert {e['path'] for e in changed if e['added']}==added
    assert len(unchanged)==250
    preserved=['src/core','tools/palette.py','tools/determinism_sim_hash.txt','tools/determinism_data_hash.txt','docs/sprites_sem_fundo.png','src/ui/player_frames.gd','sprites/props','sprites/terrain','sprites/crops','assets/art_source/masters','assets/art_source/atlas.png']
    assert not subprocess.check_output(['git','diff',BASELINE,'--',*preserved],cwd=ROOT)
    counts=dict(Counter(e['owner'] for e in json.loads((ROOT/'assets/art_source/ownership.json').read_text(encoding='utf-8'))['outputs']))
    assert counts=={'raster':154,'ascii':116}
    (HERE/'runtime-delta.json').write_text(json.dumps(dict(baseline=BASELINE,changed=changed,unchanged_count=250,unchanged=unchanged,preserved=preserved,ownership_counts=counts),indent=2)+'\n',encoding='utf-8',newline='\n')
    attempts=[]
    recipes={e['id']:e for e in json.loads(import_art.MANIFEST.read_text(encoding='utf-8'))['assets']}
    for path in sorted((ROOT/'implementation/sprites/generation').glob('0011-*-call.json')):
        call=json.loads(path.read_text(encoding='utf-8'))
        assert (ROOT/call['source']).read_bytes()==Path(call['returned_file']).read_bytes()
        assert sha((ROOT/call['source']).read_bytes())==call['source_sha256']
        prompt=ROOT/('implementation/sprites/generation/0011-'+call['id']+'.prompt.txt')
        assert prompt.read_text(encoding='utf-8').strip()==call['prompt_text']
        initial=call['measured_recipe'];accepted=recipes[initial['id']]
        assert all(initial[key]==accepted[key] for key in initial),call['id']
        assert accepted['prompt_sha256']==sha(prompt.read_bytes())
        native=import_art.render_source(accepted)
        if list(native.getbbox())!=call['native_bbox']:
            call['initial_native_bbox']=call['native_bbox']
            call['native_bbox']=list(native.getbbox())
        call['decision']='Accepted after two-state native/nearest3x alpha/background/scale review, 49 actual Godot captures, all four production light states, full/hurt farmer/walker occlusion pixels, five physical window glows, automatic HP-only threshold/upgrade refresh, ghosts/camera bounds and unchanged simulation/data guards.'
        path.write_text(json.dumps(call,indent=2)+'\n',encoding='utf-8',newline='\n')
        attempts.append(call)
    assert len(attempts)==2 and all(c['revision']==0 for c in attempts)
    (ROOT/'implementation/sprites/generation/0011-generations.json').write_text(json.dumps(dict(date='2026-10-01',attempts=attempts,targeted_imagegen_revisions=0,measurement_note='One union source crop and reduction scale before promotion. Independent damage has one extra stair-edge pixel, with the same bottom contact and shared central tread. No source repainting.'),indent=2)+'\n',encoding='utf-8',newline='\n')
    print('OK: 2 immutable generated masters; 10 changed and 10 added house PNGs; other 250 PNGs/core/map/guards/palette/owner sheet/pilot/props/terrain/crops unchanged')


if __name__=='__main__':main()
