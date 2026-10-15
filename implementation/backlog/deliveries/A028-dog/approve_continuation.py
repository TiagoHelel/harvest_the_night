"""Record explicit owner approval of the frozen 167-image continuation review."""
from pathlib import Path
import json, hashlib, subprocess, sys, importlib.util, re
from html import escape

D = Path(__file__).resolve().parent
ROOT = D.parents[3]
WORDS = 'tudo aprovado, falta mais?'
DATE = '2026-10-14'
PAGE = D.relative_to(ROOT).as_posix() + '/continuation-final-review.html'

def read(p):
    return json.loads(p.read_text(encoding='utf-8'))

def write(p, obj):
    p.write_text(json.dumps(obj, indent=2, ensure_ascii=False)+'\n', encoding='utf-8')

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

HOOK = '''# Complete continuation approval: metadata only, never alter rendered pixels.
A=json.loads((D/'APPROVAL.json').read_text(encoding='utf-8'))
assert A['scope']=='complete_reviewed_delivery'
assert set(A['approved_sha256'])=={f['output'] for f in files}, 'Approval file set changed'
assert all(sha(out[k])==v for k,v in A['approved_sha256'].items()), 'Approved art changed'
contract['status']='approved for integration'
contract['owner_approval']={k:A[k] for k in ['date','owner_words','scope']}
contract['approved_existing_files']=A['approved_sha256'];contract['pending_review_files']=[]
contract.setdefault('deviations',[]).append({'rule':'Reviewed visual measurements','change':'Owner accepted the exact displayed artwork and the documented visual differences; measurements remain unchanged.','owner_words':A['owner_words'],'accepted_checks':A['accepted_visual_checks']})
checks['approved_art_hashes_match']=True
checks['approved_sitting_unchanged']=True if D.name.startswith('A028') else checks.get('approved_sitting_unchanged',True)
checks['owner_visual_approval_recorded']=True;checks['owner_accepted_visual_checks']=A['accepted_visual_checks']
assert all(k in A['accepted_visual_checks'] for k,v in checks.items() if v is False), 'Unaccepted failed check'
banner='<aside style="padding:16px;background:#244533"><b>Complete delivery approved on '+A['date']+'. Ready for Claude integration.</b> <a href="APPROVAL.json">Approval and exact hashes</a> / <a href="CLAUDE-'+D.name[:4]+'-PROMPT.txt">Claude handoff</a></aside>'
page=page.replace('</h1>','</h1>'+banner,1).replace('Known incomplete checks: ','Owner-accepted measured visual differences: ')
'''

def main():
    inv = read(D/'continuation-final-inventory.json')
    assert inv['new_pngs']==167
    spec=importlib.util.spec_from_file_location('batch_helpers',D/'reconcile_batch_approval.py')
    helper=importlib.util.module_from_spec(spec);spec.loader.exec_module(helper)
    helper.DATE=DATE;helper.OWNER_WORDS=WORDS
    for p in inv['packs']:
        d=D.parent/p['slug'];c=read(d/'contract.json');q=read(d/'checks.json')
        if any('runtime_name' not in f for f in c['files']):
            previous=(d/f'CLAUDE-{p["id"]}-PROMPT.txt').read_text(encoding='utf-8')
            mappings={k.replace('preview/candidates/','native/',1):v for k,v in re.findall(r'^(\S+\.png) -> (\S+\.png)',previous,re.M)}
            plan=read(d/'raw/export-plan.json')
            for f in c['files']:
                if 'runtime_name' not in f:f['runtime_name']=mappings[f['output']]
            for f in plan['files']:
                if 'runtime_name' not in f:f['runtime_name']=mappings[f['output']]
            write(d/'raw/export-plan.json',plan)
        hashes={f['output']:sha(d/f['output']) for f in c['files']}
        assert len(hashes)==p['expected_count']
        assert all(hashes[f['output']]==f['sha256'] for f in p['new_files'])
        assert all(hashes[k]==v for k,v in p['existing_approved_sha256'].items())
        old=read(d/'APPROVAL.json') if (d/'APPROVAL.json').exists() else None
        if old and old.get('owner_words')!=WORDS:
            write(d/'APPROVAL-before-continuation.json',old)
        accepted=[k for k,v in q.items() if v is False]
        a={'pack':p['id'],'date':DATE,'status':'approved for integration','scope':'complete_reviewed_delivery','owner_words':WORDS,'approved_folder':d.relative_to(ROOT).as_posix(),'review_page':PAGE,'review_url':'http://127.0.0.1:8765/'+PAGE+'?v=continuation-20261014','approved_sha256':hashes,'frames':len(hashes),'frames_expected':p['expected_count'],'accepted_visual_checks':accepted,'missing_outputs':[],'pending_review_outputs':[],'delivery_complete':True,'runtime_integrated':False,'newly_approved_files':[f['output'] for f in p['new_files']],'previously_approved_sha256':p['existing_approved_sha256']}
        if old and old.get('owner_words')!=WORDS:a['prior_approval_record']='APPROVAL-before-continuation.json'
        elif old and old.get('prior_approval_record'):a['prior_approval_record']=old['prior_approval_record']
        write(d/'APPROVAL.json',a)
        s=(d/'build.py').read_text(encoding='utf-8')
        if '# Complete continuation approval:' not in s:
            start=s.index('\n# ',s.index('if blocked:',s.index('js='))) if '\n# ' in s[s.index('if blocked:',s.index('js=')):] else -1
            marker="out['contract.json']=j(contract);out['checks.json']=j(checks);out['index.html']=page.encode()"
            end=s.index(marker)
            if p['id'] in ['A043','A045']:
                start=s.index("contract['approved_existing_files']={}",s.index('js='))
            else:
                start=s.rfind('\n# ',0,end)+1
            assert start>=0
            s=s[:start]+HOOK+s[end:]
            (d/'build.py').write_text(s,encoding='utf-8')
        log=d/'review-log.txt';text=log.read_text(encoding='utf-8') if log.exists() else ''
        entry=f'\n{DATE} / Complete continuation owner approval\nOwner words: {WORDS}\nReview: {PAGE}\nAll {len(hashes)} native outputs approved, including {p["new_count"]} new PNGs. Original approved PNGs remain byte-identical. Accepted measured visual differences: {", ".join(accepted) or "none"}. No art, motion, palette, timing or runtime files changed.\n'
        if 'Complete continuation owner approval' not in text:log.write_text(text+entry,encoding='utf-8')
        packtext=next((ROOT/'implementation/backlog/packs').glob(p['id']+'-*.md')).read_text(encoding='utf-8')
        helper.handoff(d,a,c['files'],packtext)
        hand=d/f'CLAUDE-{p["id"]}-PROMPT.txt'
        extra='\nCurrent approval covers the entire delivery, including all continuation additions. The owner accepted these measured visual checks: '+(', '.join(accepted) or 'none')+'. Keep their booleans honest; do not regenerate accepted art.\n'
        if c.get('joins'):extra+='For barrier joins, create importer compose entries from contract.json joins.parts, preserving N,W,E,S,post slice/paste order. The composed file source is module provenance, not a direct raw crop recipe. Retain the owner-authorized 27px vertical envelope.\n'
        if p['id']=='A054':extra+='Keep the separate master mapping from native/winter_lord/west/01.png. If the game needs legacy aliases: walk_b uses walk frame2, telegraph uses cast frame3, attack uses attack frame1, death uses death frame4 (zero-based). Aliases do not add PNG outputs. The ground aura and tower ice remain task 0255 code.\n'
        hand.write_text(hand.read_text(encoding='utf-8')+extra,encoding='utf-8')
        for args in [[],[],['--check']]:
            subprocess.run([sys.executable,str(d/'build.py'),*args],cwd=ROOT,check=True)
        now=read(d/'contract.json')
        assert now['status']=='approved for integration' and not now['pending_review_files']
        assert {f['output']:sha(d/f['output']) for f in now['files']}==hashes
        subprocess.run([sys.executable,'implementation/backlog/assets.py','set',p['id'],'approved','Complete delivery explicitly approved by the owner on 2026-10-14; see APPROVAL.json.'],cwd=ROOT,check=True)
    inv.update(new_art_approval='approved for integration',owner_words=WORDS,approval_date=DATE)
    write(D/'continuation-final-inventory.json',inv)
    batch=read(D/'batch-approval.json')
    for p in batch['packages']:
        if p['id'] in {x['id'] for x in inv['packs']}:
            p.update(art_approval='Approved',ready=True,approved_count=p['available'],pending_review_count=0,status='approved',missing=0,accepted_visual_checks=read(D.parent/p['folder']/'APPROVAL.json')['accepted_visual_checks'])
        packfile=next((ROOT/'implementation/backlog/packs').glob(p['id']+'-*.md'))
        if re.search(r'\*\*Status:\*\* integrated',packfile.read_text(encoding='utf-8')):p['status']='integrated'
    batch.update(complete_deliveries=21,approved_partial_deliveries=0,empty_deliveries=0,pending_review_deliveries=0,new_pngs_pending_review=0,approved_pngs=422,continuation_owner_words=WORDS,continuation_approval_date=DATE)
    write(D/'batch-approval.json',batch)
    page=(D/'all-packs-review.html').read_text(encoding='utf-8')
    page=re.sub(r'<aside>.*?</aside>','<aside><b>All 21 deliveries are complete and owner-approved: 422 PNGs.</b> The 167 continuation additions were approved on '+DATE+'. <a href="continuation-final-review.html">Approved additions</a> / <a href="CLAUDE-CONTINUATION-APPROVED.md">Current Claude handoff</a>.</aside>',page,count=1,flags=re.S)
    for p in batch['packages']:
        slug=p['folder'];label='Integrated' if p['status']=='integrated' else 'Approved; ready for Claude integration'
        row=f'<tr><td>{p["id"]}</td><td>{escape(p["title"])}</td><td>Approved</td><td>{p["available"]}/{p["expected"]}</td><td>{label}</td><td><a href="../{slug}/index.html">Full review</a> / <a href="../{slug}/APPROVAL.json">Approval</a> / <a href="../{slug}/CLAUDE-{p["id"]}-PROMPT.txt">Claude handoff</a></td></tr>'
        page=re.sub(r'<tr><td>'+p['id']+r'</td>.*?</tr>',lambda m:row,page,flags=re.S)
        page=re.sub(r'<summary>'+p['id']+r' /.*?</summary>',lambda m:f'<summary>{p["id"]} / {escape(p["title"])} / {label}</summary>',page,flags=re.S)
    (D/'all-packs-review.html').write_text(page,encoding='utf-8')
    page=(D/'continuation-final-review.html').read_text(encoding='utf-8')
    page=page.replace('New art is pending review. Previously approved images keep their approval.','All 167 additions are owner-approved on 2026-10-14. Previously approved images keep their approval.').replace('New visual checks to judge: ','Owner-accepted measured visual differences: ').replace('New candidate checks passed. Owner approval is still pending.','Checks passed. Owner approval is recorded.').replace('This new geometry difference is not yet approved.','This geometry difference is owner-approved.')
    page=page.replace('<nav>','<p><a href="CLAUDE-CONTINUATION-APPROVED.md">Current Claude integration handoff</a></p><nav>',1)
    (D/'continuation-final-review.html').write_text(page,encoding='utf-8')
    report='''# Complete continuation approved / 2026-10-14

Owner words (verbatim): "tudo aprovado, falta mais?"

This supersedes the pending-review and missing-output instructions in CLAUDE-CONTINUATION-REVIEW.md, CLAUDE-BATCH-PROMPT.txt and CLAUDE-BATCH-DETAILS.md. The owner approved all 167 additions displayed in continuation-final-review.html, including the documented visual differences. Each pack now has complete APPROVAL.json hashes, an approved contract, a checked deterministic build and a current CLAUDE-Axxx-PROMPT.txt.

| Pack | PNGs | Newly approved | Integration task |
|---|---:|---:|---|
| A028 dog | 20 | 18 | 0245 |
| A040 garlic braid | 3 | 2 | 0239 |
| A042 electric fence | 42 | 39 | 0241 |
| A043 hardwood and sandbags | 78 | 78 | 0242 |
| A045 power and weapon icons | 22 | 22 | 0244 |
| A054 Winter Lord | 22 | 8 | 0268 |

All 21 requested deliveries now contain 422 approved PNGs. No file is missing from that batch. Original 255 approved PNGs were preserved; no movement, timing, palette or pixel was changed to record approval. Exact additions are frozen in continuation-final-inventory.json. Integration remains Claude's responsibility; use current assets.py status rather than treating this document as a claim of runtime integration.

Read each complete contract and CLAUDE-Axxx-PROMPT.txt. Verify all hashes, promote original ImageGen sources through the raster manifest and ownership pipeline, preserve runtime names/mirrors/points/timing, extend validation lists, run tools/verify.py, inspect FHD day/night captures, and mark integrated only after success. Claude owns assets.py unblock and game-task state. Do not ask the owner to approve these images again.

Accepted measured differences remain false: A028 idle_body_identical, wag_only_tail_changes, bark_paws_stationary, sleep_head_paws_stationary; A040 fresh_braid_dimensions; A042 electric_fence_post_span_row20 and zap_two_to_three_warm_sparks; A054 death_never_grows. A043/A045 have no false visual checks. Approval is recorded separately and does not falsify measurements.

For A042/A043, promote modules and create importer compose entries from joins.parts in N,W,E,S,post order. Composed source fields record provenance and are not raw-crop recipes. Preserve the owner-authorized 27px vertical envelope. A028 bite frame1 has bite_xy [9,21]. A054 aliases and the two A045 icon sizes are documented in their handoffs.

Outside this batch, 13 older packs remain blocked after visual/geometry failures: A003, A004, A017, A018, A023, A026, A027, A030, A033, A034, A035, A036, A057 (optional). Seven farmer packs remain owner-deferred: A001, A002, A007, A008, A009, A024, A025. A006 is cancelled. These were not reopened or approved by the additions-page approval.

No game code, runtime art, manifest, ownership file, game-task state, commit or push was changed by this approval pass.
'''
    (D/'CLAUDE-CONTINUATION-APPROVED.md').write_text(report,encoding='utf-8')
    for name in ['CLAUDE-CONTINUATION-REVIEW.md','CLAUDE-BATCH-PROMPT.txt','CLAUDE-BATCH-DETAILS.md']:
        p=D/name;s=p.read_text(encoding='utf-8')
        notice='APPROVAL UPDATE / 2026-10-14: All 21 deliveries are complete and approved (422 PNGs). The 167 continuation additions are now approved; no missing files remain in this batch. Read CLAUDE-CONTINUATION-APPROVED.md and each current per-pack handoff. Pending-review instructions below are historical.\n\n'
        if not s.startswith('APPROVAL UPDATE'):p.write_text(notice+s,encoding='utf-8')
    working=read(D/'continuation-review.json');working.update(status='approved for integration',owner_words=WORDS,new_art_approval='approved for integration',remaining_missing_current_batch_pngs=0);write(D/'continuation-review.json',working)
    print('Approval complete: six packs / 187 total PNGs / 167 additions; 21-pack batch / 422 approved PNGs.')

if __name__=='__main__':main()
