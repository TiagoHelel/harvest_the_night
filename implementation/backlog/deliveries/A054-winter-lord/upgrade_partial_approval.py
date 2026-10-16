"""Approval remains scoped to the original 14 images, not the new eight."""
from pathlib import Path
D=Path(__file__).resolve().parent;p=D/'build.py';s=p.read_text()
start=s.index('# Owner approval changes delivery metadata only;');end=s.index("out['contract.json']=j(contract)",start)
s=s[:start]+'''# Preserve exact original approval, leaving additions pending.
if A:
 approved={k.replace('preview/candidates/','native/',1):v for k,v in A['approved_sha256'].items()}
 for old,expected in A['approved_sha256'].items():assert sha((D/old).read_bytes())==expected,old
 for f in files:
  if f['output'] in approved:assert sha(out[f['output']])==approved[f['output']],'Approved art changed'
 pending=[f['output'] for f in files if f['output'] not in approved]
 contract['owner_approval']={'date':A['date'],'owner_words':A['owner_words'],'scope':A['scope']}
 contract['approved_existing_files']=approved;contract['pending_review_files']=pending;contract['status']='review' if pending else 'approved for integration'
 checks['approved_art_hashes_match']=all(sha(out[k])==v for k,v in approved.items())
 checks['owner_accepted_visual_checks']=A.get('accepted_visual_checks',[])
 page=page.replace('</h1>','</h1><aside>14 original frames are owner-approved and byte-identical. Walk4 and cast4 are new and await review. <a href="APPROVAL.json">Existing approval</a></aside>',1)
''' +s[end:]
s=s[:s.index('unaccepted=[k for k in failed')]+'''technical=['frame_count_matches','binary_alpha','no_empty_frame','canvas_and_pivot_consistent','colours_allowed','grounded_on_pivot','one_scale_per_animation','points_on_opaque','importer_recipe_matches','raw_provenance_matches','reference_hashes_match','prompts_match_calls','approved_art_hashes_match']
if any(checks.get(k) is not True for k in technical):raise SystemExit(2)
'''
p.write_text(s,encoding='utf-8')
