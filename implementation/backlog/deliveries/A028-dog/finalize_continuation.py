"""Reconcile completeness without extending the original owner approval."""
from pathlib import Path
import json,re,hashlib
from html import escape
D=Path(__file__).resolve().parent
if (D/'continuation-final-inventory.json').exists() and json.loads((D/'continuation-final-inventory.json').read_text(encoding='utf-8')).get('new_art_approval')=='approved for integration':
 raise SystemExit('Continuation is fully approved. Historical pending-review finalizer must not overwrite current approvals.')
names=['A028-dog','A040-garlic-braid','A042-electric-fence','A043-strong-walls','A045-power-weapon-icons','A054-winter-lord']
p=D/'batch-approval.json';batch=json.loads(p.read_text(encoding='utf-8'));html=(D/'all-packs-review.html').read_text(encoding='utf-8')
new_total=0
for slug in names:
 d=D.parent/slug;c=json.loads((d/'contract.json').read_text(encoding='utf-8'));a=json.loads((d/'APPROVAL.json').read_text(encoding='utf-8')) if (d/'APPROVAL.json').exists() else {};approved={k.replace('preview/candidates/','native/',1):v for k,v in a.get('approved_sha256',{}).items()};new=[f for f in c['files'] if f['output'] not in approved];old=[f for f in c['files'] if f['output'] in approved];new_total+=len(new)
 for f in old:assert f['sha256']==approved[f['output']]
 for source in {f['source'] for f in new}:
  callpath=d/source.replace('.png','.call.json');call=json.loads(callpath.read_text(encoding='utf-8'));call['decision']='selected for final candidate review; owner approval pending';call['selected_native_exports']=[f['output'] for f in new if f['source']==source];callpath.write_text(json.dumps(call,indent=2)+'\n',encoding='utf-8')
 item=next(v for v in batch['packages'] if v['id']==slug[:4]);item.update(available=len(c['files']),missing=0,status='review',ready=False,approved_count=len(old),pending_review_count=len(new),art_approval=(str(len(old))+' previous images approved; additions pending' if old else 'New candidates pending owner review'))
 label=f'{len(old)} approved unchanged; {len(new)} new pending review'
 row=f'<tr><td>{slug[:4]}</td><td>{escape(c["title"])}</td><td>{label}</td><td>{len(c["files"])}/{item["expected"]}</td><td>Complete candidates; new art awaiting review</td><td><a href="../{slug}/index.html">Full review</a> / <a href="continuation-final-review.html#{slug[:4]}">New additions</a></td></tr>'
 html=re.sub(r'<tr><td>'+slug[:4]+r'</td>.*?</tr>',lambda m:row,html,flags=re.S)
 html=re.sub(r'<summary>'+slug[:4]+r' /.*?</summary>',lambda m:f'<summary>{slug[:4]} / {escape(c["title"])} / {label}</summary>',html,flags=re.S)
 if old:
  handoff=d/f'CLAUDE-{slug[:4]}-PROMPT.txt'
  if handoff.exists():
   s=handoff.read_text(encoding='utf-8');notice='CONTINUATION UPDATE / 2026-10-14: All required candidate files now exist. The existing APPROVAL.json still approves ONLY its original '+str(len(old))+' image(s); '+str(len(new))+' new files remain pending owner review. The earlier missing-output list below is historical. Read ../A028-dog/CLAUDE-CONTINUATION-REVIEW.md and contract.json pending_review_files. Do not integrate additions before approval.\n\n'
   if not s.startswith('CONTINUATION UPDATE'):handoff.write_text(notice+s,encoding='utf-8')
batch.update(candidate_complete_deliveries=21,empty_deliveries=0,pending_review_deliveries=6,new_pngs_pending_review=new_total,approved_pngs_preserved=255,continuation_review='continuation-final-review.html')
p.write_text(json.dumps(batch,indent=2)+'\n',encoding='utf-8')
style=re.search(r'<style>.*?</style>',html,re.S).group(0)
header='<!doctype html><html lang="en"><meta charset="utf-8"><title>21-pack art review / approvals and new additions</title>'+style+'<h1>21-pack art review</h1><aside><b>Original owner approvals remain valid.</b> The six incomplete packs now have all required candidate files: 167 new PNGs await a new review. Existing 255 approved images retain their approval. <a href="continuation-final-review.html">Open additions-only review</a> / <a href="CLAUDE-CONTINUATION-REVIEW.md">Continuation details</a>.</aside>'
html=header+html[html.index('<table>'):]
(D/'all-packs-review.html').write_text(html,encoding='utf-8')
for name in ['CLAUDE-BATCH-PROMPT.txt','CLAUDE-BATCH-DETAILS.md']:
 p=D/name;s=p.read_text(encoding='utf-8');notice='CONTINUATION UPDATE / 2026-10-14: Missing outputs have now been generated as review candidates. Previous approvals are preserved, not extended. Read CLAUDE-CONTINUATION-REVIEW.md for current counts and pending-review boundaries; earlier missing-output notes below are historical.\n\n'
 if not s.startswith('CONTINUATION UPDATE'):p.write_text(notice+s,encoding='utf-8')
print(new_total,'new PNGs pending review; zero missing files in the 21-pack batch')
