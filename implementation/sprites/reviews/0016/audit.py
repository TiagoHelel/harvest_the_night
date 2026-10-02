"""Prove exact tool sources and preservation of all completed art/core bytes."""
from pathlib import Path
import hashlib
import json
import subprocess
import sys
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
BASE='94ce993'
h=lambda data:hashlib.sha256(data).hexdigest()

def original(path):
    return subprocess.check_output(['git','show',BASE+':'+path],cwd=ROOT)

def main():
    manifest=json.loads((ROOT/'assets/art_source/manifest.json').read_text())
    previous=json.loads(original('assets/art_source/manifest.json'))
    new={e['id']:e for e in manifest['assets']}
    replaced={'enemies/giant'+s for s in ('','_walk_b','_attack','_death','_telegraph')}
    for entry in previous['assets']:
        if entry['id'] not in replaced:
            assert new[entry['id']]==entry, 'Prior completed manifest changed: '+entry['id']
    baseline=subprocess.check_output(['git','ls-tree','-r','--name-only',BASE],cwd=ROOT,text=True).splitlines()
    changed=set(subprocess.check_output(['git','diff','--name-only',BASE],cwd=ROOT,text=True).splitlines())
    protected=[]
    for path in baseline:
        if path in ('tools/palette.py','tools/determinism_sim_hash.txt','tools/determinism_data_hash.txt') or path.startswith(('src/core/','docs/','assets/art_source/masters/','assets/art_source/player/','implementation/sprites/generation/000','implementation/sprites/generation/0010-','implementation/sprites/generation/0011-','implementation/sprites/generation/0012-','implementation/sprites/generation/0013-','implementation/sprites/generation/0014-','implementation/sprites/generation/0015-')) or path.startswith('assets/art_source/') and path not in ('assets/art_source/manifest.json','assets/art_source/ownership.json') or path.startswith('sprites/') and path.endswith('.png') and path.removeprefix('sprites/').removesuffix('.png') not in replaced:
            assert path not in changed,'Protected completed/core file changed: '+path
            current,old=(ROOT/path).read_bytes(),original(path)
            # Older text worktree files may retain CRLF while Git stores LF.
            # Compare canonical newlines only for text; all raster bytes are exact.
            assert current==old or not path.endswith('.png') and current.replace(b'\r\n',b'\n')==old.replace(b'\r\n',b'\n'),'Protected file contents changed: '+path
            protected.append(path)
    calls=[]
    generation=ROOT/'implementation/sprites/generation'
    for path in sorted(generation.glob('0016-*-call.json')):
        c=json.loads(path.read_text())
        assert h((ROOT/c['source']).read_bytes())==c['source_sha256']==h(Path(c['returned_file']).read_bytes())
        assert h((ROOT/c['prompt']).read_bytes())==c['prompt_sha256']
        for ref in c['references']:assert h((ROOT/ref).read_bytes())==c['reference_hashes'][ref]
        assert c['tool']=='built-in ImageGen' and c['tool_arguments']['transparent_background'] is True
        assert c['actual_submitted_arguments']['prompt']==(ROOT/c['prompt']).read_text()
        uses=[e['id'] for e in manifest['assets'] if e.get('source')==c['source']]
        calls.append(dict(source=c['source'],prompt=c['prompt'],source_sha256=c['source_sha256'],used_by=uses,decision='Accepted after native/3x motion review' if uses else c['decision']))
    assert len(calls)==5 and sum(bool(c['used_by']) for c in calls)==5
    report=dict(baseline=BASE,protected_count=len(protected),protected_files=protected,calls=calls,
                raster_entries=len(manifest['assets']),new_enemy_entries=sum(e.get('generation_task')=='0016' for e in manifest['assets']),
                sim_hash=(ROOT/'tools/determinism_sim_hash.txt').read_text().strip(),data_hash=(ROOT/'tools/determinism_data_hash.txt').read_text().strip())
    if '--staged' in sys.argv:
        paths=set()
        for c in calls:
            paths.update((c['source'],c['prompt']))
        for e in manifest['assets']:
            if e.get('generation_task')=='0016':paths.add(e['output'])
        for path in paths:
            blob=subprocess.check_output(['git','show',':'+path],cwd=ROOT)
            assert blob==(ROOT/path).read_bytes(),'Git newline or staged-byte drift: '+path
        report['staged_exact_files']=len(paths)
    (HERE/'scope-and-sources.json').write_text(json.dumps(report,indent=2)+'\n',newline='\n')
    print(f'OK: {len(protected)} prior core/art files unchanged, 5 exact raw returns, 5 selected sources, 20 source-owned frames/aliases')

if __name__=='__main__':main()
