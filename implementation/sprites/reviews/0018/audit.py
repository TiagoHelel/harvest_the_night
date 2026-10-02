"""Prove raw tool returns, exact cuts and preservation of completed art/core."""
from pathlib import Path
import hashlib,json,re,subprocess,sys
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
BASE='566a503'
h=lambda data:hashlib.sha256(data).hexdigest()

def original(path):
    return subprocess.check_output(['git','show',BASE+':'+path],cwd=ROOT)

def main():
    manifest=json.loads((ROOT/'assets/art_source/manifest.json').read_text(encoding='utf-8'))
    previous=json.loads(original('assets/art_source/manifest.json'))
    current={e['id']:e for e in manifest['assets']}
    for e in previous['assets']:
        assert current[e['id']]==e,'Completed raster entry changed: '+e['id']
    assert len(previous['assets'])==417 and len(current)==447
    ids=[p['id'] for p in json.loads((ROOT/'implementation/sprites/generation/0018-plan.json').read_text(encoding='utf-8'))]
    replaced={'ui/icon_'+i for i in ids}|{'ui/'+s for s in ('panel','tooltip','button_normal','button_hover','button_pressed','button_disabled','tab','checkbox_on','checkbox_off','slider_grab')}
    assert len(replaced)==25
    baseline=subprocess.check_output(['git','ls-tree','-r','--name-only',BASE],cwd=ROOT,text=True).splitlines()
    changed=set(subprocess.check_output(['git','diff','--name-only',BASE],cwd=ROOT,text=True).splitlines())
    protected=[]
    for path in baseline:
        source=path.startswith('assets/art_source/') and path not in ('assets/art_source/manifest.json','assets/art_source/ownership.json')
        prior_generation=re.match(r'implementation/sprites/generation/(\d{4})',path)
        guard=path in ('tools/palette.py','tools/determinism_sim_hash.txt','tools/determinism_data_hash.txt') or path.startswith(('src/core/','docs/'))
        art=path.startswith('sprites/') and path.endswith('.png') and path.removeprefix('sprites/').removesuffix('.png') not in replaced
        if guard or source or art or prior_generation and int(prior_generation[1])<18:
            assert path not in changed,'Protected completed/core file changed: '+path
            data,old=(ROOT/path).read_bytes(),original(path)
            assert data==old or not path.endswith('.png') and data.replace(b'\r\n',b'\n')==old.replace(b'\r\n',b'\n'),'Protected file byte drift: '+path
            protected.append(path)
    calls=[];exact=set()
    for resource in ids:
        cp=ROOT/f'implementation/sprites/generation/0018-{resource}-call.json'
        c=json.loads(cp.read_text(encoding='utf-8'))
        assert c['tool']=='built-in ImageGen' and c['revision']==0
        assert h((ROOT/c['source']).read_bytes())==c['source_sha256']==h(Path(c['returned_file']).read_bytes())
        prompt=(ROOT/c['prompt']).read_bytes()
        assert h(prompt)==c['prompt_sha256'] and c['actual_submitted_arguments']['prompt']==prompt.decode('utf-8')
        args=f'implementation/sprites/generation/0018-{resource}-arguments.json'
        assert json.loads((ROOT/args).read_text(encoding='utf-8'))==c['actual_submitted_arguments']
        for ref in c['references']:assert h((ROOT/ref).read_bytes())==c['reference_hashes'][ref]
        uses=[e for e in manifest['assets'] if e.get('source')==c['source']]
        assert len(uses)==2 and all(e.get('generation_task')=='0018' for e in uses)
        assert all(h((ROOT/e['output']).read_bytes())==e['output_sha256'] for e in uses)
        calls.append(dict(source=c['source'],prompt=c['prompt'],source_sha256=c['source_sha256'],used_by=[e['id'] for e in uses],decision=c['decision']))
        exact.update([c['source'],c['prompt'],args,*[e['output'] for e in uses]])
    assert len(calls)==15 and len(exact)==75
    report=dict(baseline=BASE,protected_count=len(protected),protected_files=protected,calls=calls,replaced_legacy_outputs=sorted(replaced),raster_entries=447,new_ui_entries=30,sim_hash=(ROOT/'tools/determinism_sim_hash.txt').read_text().strip(),data_hash=(ROOT/'tools/determinism_data_hash.txt').read_text().strip())
    if '--staged' in sys.argv:
        for path in sorted(exact):
            assert subprocess.check_output(['git','show',':'+path],cwd=ROOT)==(ROOT/path).read_bytes(),'Staged-byte drift: '+path
        report['staged_exact_files']=len(exact)
    (HERE/'scope-and-sources.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(f'OK: {len(protected)} prior core/art files and 417 raster entries unchanged; 15 exact raw returns; 30 source-owned UI cuts')

if __name__=='__main__':main()
