"""Offline link, file-count, approved-hash and preview-source validation."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit,unquote
import json,hashlib
D=Path(__file__).resolve().parent;inv=json.loads((D/'continuation-final-inventory.json').read_text(encoding='utf-8'));checked=0
class Links(HTMLParser):
 def __init__(self,base):super().__init__();self.base=base
 def handle_starttag(self,tag,attrs):
  global checked
  for key,value in attrs:
   if key in ['href','src'] and value:
    url=urlsplit(value)
    if url.scheme or not url.path:continue
    p=(self.base/unquote(url.path)).resolve();assert p.exists(),p;checked+=1
   if key=='data-files':
    for value in json.loads(value):assert (self.base/value).exists(),value;checked+=1
for pack in inv['packs']:
 d=D.parent/pack['slug'];c=json.loads((d/'contract.json').read_text(encoding='utf-8'));q=json.loads((d/'checks.json').read_text(encoding='utf-8'));assert len(c['files'])==q['frames_expected']
 for f in c['files']:assert hashlib.sha256((d/f['output']).read_bytes()).hexdigest()==f['sha256'],f['output']
 for path,h in pack['existing_approved_sha256'].items():assert hashlib.sha256((d/path).read_bytes()).hexdigest()==h,path
 Links(d).feed((d/'index.html').read_text(encoding='utf-8'))
Links(D).feed((D/'continuation-final-review.html').read_text(encoding='utf-8'));Links(D).feed((D/'all-packs-review.html').read_text(encoding='utf-8'))
assert inv['new_pngs']==167 and inv['previously_approved_pngs_preserved']==20
approved=all(json.loads((D.parent/p['slug']/'APPROVAL.json').read_text(encoding='utf-8')).get('scope')=='complete_reviewed_delivery' for p in inv['packs'])
if approved:
 for pack in inv['packs']:
  d=D.parent/pack['slug'];a=json.loads((d/'APPROVAL.json').read_text(encoding='utf-8'));c=json.loads((d/'contract.json').read_text(encoding='utf-8'))
  assert a['approved_sha256']=={f['output']:f['sha256'] for f in c['files']}
report={'new_pngs':167,'previously_approved_pngs_preserved':20,'six_pack_native_files':187,'all_expected_files_present':True,'all_png_hashes_match_contract':True,'all_html_local_links_exist':True,'local_references_checked':checked,'new_art_approved':approved,'runtime_integrated':False}
(D/'continuation-validation.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print(report)
