"""Preserve partial owner approval when the missing dog frames are added."""
from pathlib import Path
D=Path(__file__).resolve().parent
p=D/'build.py';s=p.read_text(encoding='utf-8')
start=s.index('# Owner approval changes delivery metadata only;')
end=s.index("out['contract.json']=j(contract)",start)
block='''# Existing approval covers only the two unchanged sitting artifacts.
if A:
 approved={k.replace('preview/candidates/','native/',1):v for k,v in A['approved_sha256'].items()}
 for old,expected in A['approved_sha256'].items():assert sha((D/old).read_bytes())==expected, old
 for f in files:
  if f['output'] in approved:assert sha(out[f['output']])==approved[f['output']], 'Approved art changed'
 pending=[f['output'] for f in files if f['output'] not in approved]
 contract['owner_approval']={'date':A['date'],'owner_words':A['owner_words'],'scope':A['scope']}
 contract['approved_existing_files']=approved;contract['pending_review_files']=pending
 contract['status']='review' if pending else 'approved for integration'
 checks['approved_sitting_unchanged']=all(sha(out[k])==v for k,v in approved.items())
 checks['owner_visual_approval_recorded']=True;checks['owner_accepted_visual_checks']=A.get('accepted_visual_checks',[])
 banner='<aside style="padding:16px;background:#244533;color:#eef5df"><b>Two sitting frames are owner-approved and byte-identical.</b> The other 18 frames are new candidates awaiting review. <a href="APPROVAL.json">Existing approval</a></aside>'
 page=page.replace('</h1>','</h1>'+banner,1)
 page=page.replace('Known incomplete checks: ','Measured visual checks still requiring review: ')
'''
s=s[:start]+block+s[end:]
# Build verification and visual review are separate: never fake false visual checks.
s=s[:s.index('unaccepted=[k for k in failed')]+'''technical=['frame_count_matches','binary_alpha','no_empty_frame','canvas_and_pivot_consistent','colours_allowed','grounded_on_pivot','one_scale_per_animation','points_on_opaque','importer_recipe_matches','raw_provenance_matches','reference_hashes_match','prompts_match_calls','approved_sitting_unchanged']
if any(checks.get(k) is not True for k in technical):raise SystemExit(2)
'''
s=s.replace("'mirror_pairs':P.get('mirror_pairs',{})})","'mirror_pairs':P.get('mirror_pairs',{})})")
s=s.replace("animations.append(a);strip=", "a['points']={k:v for e in entries for k,v in e['points'].items()};animations.append(a);strip=")
p.write_text(s,encoding='utf-8')
