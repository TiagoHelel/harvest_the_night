"""Prove final sources/core invariants and account for every visual closeout gate."""
from pathlib import Path
import argparse, hashlib, json, re, subprocess
from collections import Counter
from PIL import Image

ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent

def git(*args):
    return subprocess.check_output(['git',*args],cwd=ROOT,text=True).strip()

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--complete',action='store_true')
    args=parser.parse_args()
    planning='40262bd'
    frozen='c03c169'
    protected=['src/core','project.godot','tools/determinism_sim_hash.txt','tools/determinism_data_hash.txt','docs/reference-sheet.png','docs/sprites_sem_fundo.png']
    assert not git('diff','--name-only',planning,'--',*protected),'Core/planning invariant changed'
    assert not git('diff','--name-only',frozen,'--','assets/art_source','sprites','src/ui/raster_art.gd','src/ui/player_frames.gd','src/ui/palette_data.gd','tools/import_art.py','tools/gen_sprites.py','tools/cut_sheet.py','tools/art_ownership.py','tools/palette.py','tools/sprite_maps.py','tools/ui_surfaces.py'),'Accepted art/rebuild recipes changed'
    assert not git('ls-files','--others','--exclude-standard','assets/art_source','sprites','implementation/sprites/generation'),'Unexpected source/runtime/generation output'
    clean=json.loads((HERE/'clean-rebuild.json').read_text(encoding='utf-8'))
    assert clean['identical_cycles']==2 and clean['initially_clean'] and clean['finally_clean']
    for name,digest in clean['files'].items():
        assert sha(ROOT/name)==digest,'Clean rebuild input/output changed: '+name
    assert git('diff','--name-only',frozen,'--','src','tools','scenes','project.godot')=='src/tools/art_showcase.gd','Runtime changed after final verified fixture corrections'
    catalogue=json.loads((HERE/'catalogue.json').read_text(encoding='utf-8'))
    for row in catalogue['outputs']:
        assert sha(ROOT/row['output'])==row['sha256']==clean['files'][row['output']]
        for leaf in row['sources']:
            assert sha(ROOT/leaf['source'])==leaf['source_sha256']
            if 'prompt' in leaf:
                assert sha(ROOT/leaf['prompt'])==leaf['prompt_sha256']
    assert catalogue['owners']=={'raster':447,'ascii':21}
    assert len(catalogue['aliases'])==16
    for row in catalogue['aliases']:
        assert (ROOT/row['alias']).read_bytes()==(ROOT/row['canonical']).read_bytes()
    # Keep the unused legacy recipe, but prove normal runtime code/scenes have
    # no reference to its output. Current family fixtures assert real textures.
    reference=subprocess.run(['rg','-n','placeholder.png','src','scenes'],cwd=ROOT,capture_output=True,text=True)
    assert reference.returncode==1,reference.stdout+reference.stderr
    runs=json.loads((HERE/'capture-runs.json').read_text(encoding='utf-8'))
    assert len(runs)==25 and all(r['exit_code']==0 for r in runs)
    for run in runs:
        log=(HERE/(run['name']+'.log')).read_text(encoding='utf-8')
        assert not re.search(r'SCRIPT ERROR:|^ERROR:',log,re.M),run['name']
        if 'SHOWCASE:' in log or 'PLAYER WORK:' in log or 'PLAYER REACTIONS:' in log:
            assert re.search(r'\d+ checks, 0 failed',log),run['name']
    index=json.loads((HERE/'capture-index.json').read_text(encoding='utf-8'))
    expected={'standard':64,'atmosphere':27,'barriers':37,'crops':36,'effects':37,'enemies':29,'giant':44,'house':44,'locomotion':36,'placement':33,'props':48,'reactions':64,'stations':48,'terrain':30,'towers':24,'ui':36,'water':45,'work':208}
    assert dict(Counter(r['family'] for r in index['captures']))==expected
    assert {r['capture'] for r in index['captures']}=={p.relative_to(ROOT).as_posix() for p in (ROOT/'implementation/shots/sprites/0020').rglob('*.png')}
    for row in index['captures']:
        assert sha(ROOT/row['capture'])==row['sha256']
    reuse=json.loads((HERE/'reused-review.json').read_text(encoding='utf-8'))
    assert reuse['count']==242==len(reuse['evidence'])
    assert {r['capture'] for r in reuse['evidence']}=={r['capture'] for r in index['captures'] if r['prior_pixels_identical']}
    for row in reuse['evidence']:
        for path,key in [('capture','current_sha256'),('prior_capture','prior_sha256'),('prior_review','prior_review_sha256'),('prior_index','prior_index_sha256')]:
            assert sha(ROOT/row[path])==row[key]
        assert Image.open(ROOT/row['capture']).convert('RGBA').tobytes()==Image.open(ROOT/row['prior_capture']).convert('RGBA').tobytes()
    embedded=[]
    for page in index['pages']:
        rendered=Image.open(HERE/page['review']).convert('RGBA')
        assert rendered.size==(2880,2160)
        for i,name in enumerate(page['captures']):
            original=Image.open(ROOT/name).convert('RGBA')
            x,y=(i%2)*1440,(i//2)*1080
            assert rendered.crop((x,y,x+480,y+270)).tobytes()==original.tobytes()
            assert rendered.crop((x,y+270,x+1440,y+1080)).tobytes()==original.resize((1440,810),Image.Resampling.NEAREST).tobytes()
            embedded.append(name)
    assert len(embedded)==len(set(embedded))==648
    assert set(embedded)=={r['capture'] for r in index['captures'] if not r['prior_pixels_identical']}
    assert {n for p in catalogue['contact_pages'] for n in p['outputs']}=={r['output'] for r in catalogue['outputs']}
    ledger=json.loads((HERE/'visual-review.json').read_text(encoding='utf-8'))
    reviewed={r['page']:r for r in ledger['reviewed']}
    for name,row in reviewed.items():
        assert row['decision']=='accepted' and sha(HERE/name)==row['sha256'],'Review page changed after inspection: '+name
    required={p['review'] for p in index['pages']}|{p[k] for p in catalogue['contact_pages'] for k in ['native','nearest_3x']}
    pending=sorted(required-set(reviewed))
    verify=(HERE/'verify.log').read_text(encoding='utf-8')
    assert '52 passed, 0 skipped, 0 failed' in verify and verify.rstrip().endswith('PASS')
    assert '1961000123 unchanged' in verify and '407837701 unchanged' in verify
    assert re.search(r'exports\s+PASS',verify)
    coverage=json.loads((HERE/'requirements-coverage.json').read_text(encoding='utf-8'))
    assert len(coverage['tasks'])==20
    assert coverage['final_review_sha256']==sha(HERE/'REVIEW.md')
    for row in coverage['tasks']:
        prompt=(ROOT/row['prompt']).read_text(encoding='utf-8')
        assert row['original_goal_and_requirements']==prompt.split('## Goal and requirements\n\n',1)[1].split('\n## ',1)[0].strip()
        assert row['original_done_gates']==prompt.split('## Done when\n\n',1)[1].split('\nFollow ',1)[0].strip()
        assert row['assessment']=='proved' and row['evidence_assessment']
        assert row['family_review_sha256']==sha(ROOT/row['family_review'])
        assert row['final_verify_sha256']==sha(HERE/'verify.log')
    report=dict(planning_baseline=planning,preserved_art_baseline=frozen,owners=catalogue['owners'],runtime_pngs=468,exact_aliases=16,clean_rebuild_cycles=2,full_verify_passed=52,sim_hash=1961000123,data_hash=407837701,capture_runs=len(runs),native_captures=index['total_captures'],family_capture_counts=expected,reused_prior_pixels=index['exact_prior_pixels'],prior_reviews_verified=242,new_views_embedded_native_and_nearest=648,reviewed_pages=len(reviewed),required_review_pages=len(required),pending_review_pages=pending,core_and_owner_references_preserved=True,zero_new_imagegen_calls=True,verification_log_sha256=sha(HERE/'verify.log'),visual_criteria_review_sha256=sha(HERE/'REVIEW.md'))
    (HERE/'completion-audit.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8',newline='\n')
    if args.complete:
        assert not pending,'Visual review still incomplete'
        assert (ROOT/'implementation/sprites/DELIVERY.md').is_file()
        assert 'in progress' not in (ROOT/'implementation/sprites/DELIVERY.md').read_text(encoding='utf-8')
    print(f"PASS: core/source preservation, clean reproduction, 468 owners, 16 aliases, 52 verification gates; {len(reviewed)}/{len(required)} review pages opened")

if __name__=='__main__':main()
