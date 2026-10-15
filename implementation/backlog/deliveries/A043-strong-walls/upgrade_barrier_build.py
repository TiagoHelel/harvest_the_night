"""Extend the offline renderer with the contract's exact module composition."""
from pathlib import Path
D=Path(__file__).resolve().parent;p=D/'build.py';s=p.read_text()
s=s.replace('def render(f):\n','''def render(f):
 if f.get('operation')=='compose':
  im=Image.new('RGBA',tuple(f['canvas_wh']))
  for part in f['parts']:
   x,y,w,h=part['slice_xywh'];source=images[part['input']]
   im.alpha_composite(source.crop((x,y,x+w,y+h)),tuple(part['paste_xy']))
  return im
''')
s=s.replace("['colour_ramp','comparison','deviations','supersedes']","['colour_ramp','comparison','deviations','supersedes','joins']")
if '# Owner approval changes delivery metadata only;' in s:
 start=s.index('# Owner approval changes delivery metadata only;');end=s.index("out['contract.json']=j(contract)",start)
 s=s[:start]+'''# The existing zap approval never approves newly generated modules.
if A:
 approved={k.replace('preview/candidates/','native/',1):v for k,v in A['approved_sha256'].items()}
 for old,expected in A['approved_sha256'].items():assert sha((D/old).read_bytes())==expected,old
 for f in files:
  if f['output'] in approved:assert sha(out[f['output']])==approved[f['output']],'Approved art changed'
 pending=[f['output'] for f in files if f['output'] not in approved]
 contract['owner_approval']={'date':A['date'],'owner_words':A['owner_words'],'scope':A['scope']}
 contract['approved_existing_files']=approved;contract['pending_review_files']=pending
 checks['approved_art_hashes_match']=all(sha(out[k])==v for k,v in approved.items())
 page=page.replace('</h1>','</h1><aside>The original zap3 is approved and unchanged. New39 modules/wreck/joins await review. <a href="APPROVAL.json">Existing approval</a></aside>',1)
''' +s[end:]
if 'unaccepted=[k for k in failed' in s:s=s[:s.index('unaccepted=[k for k in failed')]
else:
 s=s[:s.rfind('if failed:')] if 'if failed:' in s else s
s+='''\ntechnical=['frame_count_matches','binary_alpha','no_empty_frame','canvas_and_pivot_consistent','colours_allowed','grounded_on_pivot','one_scale_per_animation','points_on_opaque','importer_recipe_matches','raw_provenance_matches','reference_hashes_match','prompts_match_calls']
if any(checks.get(k) is not True for k in technical):raise SystemExit(2)
'''
p.write_text(s,encoding='utf-8')
