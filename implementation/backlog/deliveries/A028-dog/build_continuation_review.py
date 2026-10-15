"""Additions-only batch review; never changes owner approval or pack status."""
from pathlib import Path
from PIL import Image
from html import escape
import json,hashlib,re
D=Path(__file__).resolve().parent;ROOT=D.parents[3];deliveries=D.parent
packs=['A028-dog','A040-garlic-braid','A042-electric-fence','A043-strong-walls','A045-power-weapon-icons','A054-winter-lord']
if (D/'continuation-final-inventory.json').exists():
 snapshot=json.loads((D/'continuation-final-inventory.json').read_text(encoding='utf-8'))
 if snapshot.get('new_art_approval')=='approved for integration':
  for pack in snapshot['packs']:
   for f in pack['new_files']:assert hashlib.sha256((deliveries/pack['slug']/f['output']).read_bytes()).hexdigest()==f['sha256']
  print('Approved additions review is frozen; 167 reviewed hashes verified. No review or approval files rewritten.')
  raise SystemExit(0)
cards=[];inventory=[];total_new=0;total_old=0;preserved={}
for slug in packs:
 d=deliveries/slug;c=json.loads((d/'contract.json').read_text(encoding='utf-8'));q=json.loads((d/'checks.json').read_text(encoding='utf-8'));a=json.loads((d/'APPROVAL.json').read_text(encoding='utf-8')) if (d/'APPROVAL.json').exists() else {}
 approved={p.replace('preview/candidates/','native/',1):v for p,v in a.get('approved_sha256',{}).items()}
 for path,h in approved.items():
  full=d/path;assert full.exists() and hashlib.sha256(full.read_bytes()).hexdigest()==h,(slug,path)
 preserved[slug]=approved
 new=[f for f in c['files'] if f['output'] not in approved];old=[f for f in c['files'] if f['output'] in approved];total_new+=len(new);total_old+=len(old)
 failed=[k for k,v in q.items() if v is False];accepted=a.get('accepted_visual_checks',[]);new_issues=[k for k in failed if k not in accepted]
 inventory.append({'id':slug[:4],'slug':slug,'new_count':len(new),'existing_approved_count':len(old),'complete_count':len(c['files']),'expected_count':q.get('frames_expected'),'new_files':[{'output':f['output'],'sha256':f['sha256'],'runtime_name':f.get('runtime_name')} for f in new],'existing_approved_sha256':approved,'new_review_issues':new_issues,'checks':f'../{slug}/checks.json'})
 # Animated previews stay in their pack and use file-relative paths (works offline).
 groups={}
 for f in new:
  name=f['anim']
  if f.get('operation')=='compose':name=c['joins'][name]['family']+'_all_masks_'+c['joins'][name]['state']
  groups.setdefault((name,f['dir']),[]).append(f)
 gallery=''
 for (anim,direction),fs in groups.items():
  fs.sort(key=lambda f:f['frame']);w,h=fs[0]['canvas_wh'];loop=fs[0]['loop'];seconds=fs[0]['seconds'];paths=[f'../{slug}/'+f['output'] for f in fs]
  if len(fs)>1 and not fs[0].get('operation')=='compose':
   gallery+='<div class="motion"><b>'+escape(anim)+' / '+escape(direction)+'</b><canvas class="anim" width="'+str(w)+'" height="'+str(h)+'" style="width:'+str(w*4)+'px;height:'+str(h*4)+'px" data-files="'+escape(json.dumps(paths),quote=True)+'" data-seconds="'+str(seconds)+'" data-loop="'+str(loop).lower()+'"></canvas><button class="pause">Pause</button><button class="restart">Restart</button><button class="prev">Previous</button><button class="next">Next</button><span class="frame"></span><div class="frames">'
  else:gallery+='<div class="motion"><b>'+escape(anim)+'</b><div class="frames">'
  for f,path in zip(fs,paths):
   label=('Mask '+str(c['joins'][f['anim']]['mask'])) if f.get('operation')=='compose' else f'{f["frame"]+1:02}'
   gallery+=f'<figure><img loading="lazy" src="{path}" style="width:{w*4}px;height:{h*4}px"><figcaption>{label} / {w}×{h}</figcaption></figure>'
  gallery+='</div></div>'
 warning='<p class="issue">New visual checks to judge: '+escape(', '.join(new_issues))+'</p>' if new_issues else '<p class="ok">New candidate checks passed. Owner approval is still pending.</p>'
 if slug.startswith('A043'):warning+='<p>27 px vertical envelope follows the earlier owner decision. Horizontal source beams are cropped at the shared scale to the tile length; the hardwood lower face is cropped to the eight-pixel seam height. No pixels were repainted.</p>'
 if slug.startswith('A042'):warning+='<p>Judge copper-wire contrast and seams at night. Wire rows are 13/17; the thin span ends on row17, while the post ends on row19. This new geometry difference is not yet approved.</p>'
 cards.append(f'<section id="{slug[:4]}"><h2>{escape(c["title"])} · {slug[:4]}</h2><p>{len(new)} new / {len(old)} previously approved / {len(c["files"])} total. <a href="../{slug}/index.html">Full day/night review</a> · <a href="../{slug}/checks.json">Checks</a> · <a href="../{slug}/raw/export-plan.json">Sources and recipes</a></p>'+warning+gallery+'</section>')
css='body{background:#19282b;color:#ece5d4;font:16px system-ui;line-height:1.5;margin:0;padding:28px}main{max-width:1400px;margin:auto}a{color:#9edbd3}nav{position:sticky;top:0;background:#19282bf2;padding:12px;z-index:10;border-bottom:1px solid #61716d}nav a{padding:8px}h1{font-size:32px}h2{font-size:26px}.banner{background:#254534;padding:18px;border-radius:8px}.issue{background:#583d28;padding:12px}.ok{color:#a5d7ae}section{border:1px solid #536669;border-radius:10px;padding:22px;margin:28px 0;scroll-margin-top:90px}.motion{padding:14px;margin:10px 0;background:#233237;border-radius:6px;overflow:auto}.motion>b{display:block}.frames{display:flex;gap:10px;align-items:end}figure{margin:10px 0;flex:none;background:repeating-conic-gradient(#334247 0 25%,#28353a 0 50%) 0/16px 16px}figcaption{font-size:12px;padding:4px;background:#233237}img,canvas{image-rendering:pixelated;image-rendering:crisp-edges;vertical-align:bottom}.anim{margin:12px;background:#1a1830}button{padding:8px;background:#3b5557;color:#eee;border:1px solid #9caeab;margin:6px}.summary{font-size:20px}small{color:#adc3be}'
js='''document.querySelectorAll('.motion:has(canvas.anim)').forEach(el=>{const c=el.querySelector('canvas'),ctx=c.getContext('2d'),files=JSON.parse(c.dataset.files),images=files.map(src=>{const i=new Image();i.src=src;return i});let i=0,paused=false,last=0;el.querySelector('.pause').onclick=()=>paused=!paused;el.querySelector('.restart').onclick=()=>{i=0;paused=false;last=performance.now()};for(const [name,delta]of [['prev',-1],['next',1]])el.querySelector('.'+name).onclick=()=>{paused=true;i=(i+delta+images.length)%images.length};function tick(t){if(!paused&&t-last>1000*+c.dataset.seconds){i=c.dataset.loop==='true'?(i+1)%images.length:Math.min(i+1,images.length-1);last=t}ctx.imageSmoothingEnabled=false;if(images[i].complete){ctx.clearRect(0,0,c.width,c.height);ctx.drawImage(images[i],0,0)}el.querySelector('.frame').textContent='Frame '+(i+1)+' / '+images.length;requestAnimationFrame(tick)}requestAnimationFrame(tick)});'''
page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Missing-art continuation / final additions review</title><style>'+css+'</style><main><h1>Missing-art continuation · additions review</h1><div class="banner"><p class="summary">'+str(total_new)+' new PNGs across six packs. '+str(total_old)+' previously approved PNGs preserved byte-for-byte.</p><p>New art is pending review. Previously approved images keep their approval. Runtime art has not been changed. Use each full review for day/night context, background comparisons and metadata points.</p><p><a href="all-packs-review.html">Original 21-pack review and prior approvals</a> · <a href="continuation-final-inventory.json">Exact new-file inventory</a></p></div><nav>'+''.join(f'<a href="#{p[:4]}">{p[:4]}</a>' for p in packs)+'</nav>'+''.join(cards)+'<script>'+js+'</script></main></html>'
(D/'continuation-final-review.html').write_text(page,encoding='utf-8');(D/'continuation-final-inventory.json').write_text(json.dumps({'date':'2026-10-14','owner_continuation_words':'entao bora continuar essa poha','new_pngs':total_new,'previously_approved_pngs_preserved':total_old,'new_art_approval':'pending owner review','runtime_integrated':False,'packs':inventory},indent=2)+'\n',encoding='utf-8')
print('Review generated:',total_new,'new;',total_old,'original hashes preserved')
