"""Record candidates separately from the owner's original two-frame approval."""
import json,hashlib
from pathlib import Path
D=Path(__file__).resolve().parent
def write(p,v):p.write_text(json.dumps(v,indent=2)+'\n',encoding='utf-8')
p=D/'APPROVAL.json';a=json.loads(p.read_text());c=json.loads((D/'contract.json').read_text());checks=json.loads((D/'checks.json').read_text())
a['status']='Two sitting images approved; 18 new images await review';a['delivery_complete']=True;a['missing_outputs']=[];a['pending_review_outputs']=c['pending_review_files'];write(p,a)
plan=json.loads((D/'raw/export-plan.json').read_text());selected={f['source'] for f in plan['files']}
for source in selected:
 p=D/source.replace('.png','.call.json');call=json.loads(p.read_text());call['decision']='selected for candidate review; not newly owner-approved';write(p,call)
with (D/'review-log.txt').open('a',encoding='utf-8') as log:
 log.write('\n2026-10-14 / Continuation: 20/20 native frames produced; original two sitting SHA-256 values unchanged. Added wag2, walk4, bark3, sleep2, run4, bite3. Bite jaw point measured at (9,21), opaque. One scale per animation, binary alpha, palette/provenance and deterministic --check pass. Residual new-frame visual checks remain false: '+', '.join(k for k,v in checks.items() if v is False and k!='idle_body_identical')+'. These are explicitly NOT waived or approved. Review the animated candidates at the end of the batch. No game integration.\n')
r=json.loads((D/'continuation-review.json').read_text());r['completed_for_review']=[v for v in r['completed_for_review'] if v['id']!='A028']+[{'id':'A028','new_outputs':c['pending_review_files'],'index':'index.html','new_count':18,'preserved_sitting_sha256':a['approved_sha256'],'remaining_visual_checks':[k for k,v in checks.items() if v is False and k!='idle_body_identical']}];r['remaining_missing_current_batch_pngs']=147;r['next_working_pack']='A054';write(D/'continuation-review.json',r)
html=(D/'all-packs-review.html').read_text(encoding='utf-8').replace('2/20','20/20').replace('Delivery incomplete: 18 outputs missing','Two sitting frames approved; 18 new frames pending review');(D/'all-packs-review.html').write_text(html,encoding='utf-8')
