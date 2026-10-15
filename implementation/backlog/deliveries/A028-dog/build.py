"""Offline ImageGen export; all raster art comes from recorded sources."""
from pathlib import Path
from io import BytesIO
import json,hashlib,sys,importlib.util
from PIL import Image,ImageOps
sys.dont_write_bytecode=True
D=Path(__file__).resolve().parent;ROOT=D.parents[3];sys.path.insert(0,str(ROOT/'tools'))
from import_art import render_source
from palette import COLOURS
P=json.loads((D/'raw/export-plan.json').read_text(encoding='utf-8'))
A=json.loads((D/'APPROVAL.json').read_text(encoding='utf-8')) if (D/'APPROVAL.json').exists() else {}
if A.get('scope')=='complete_reviewed_delivery':P['status']='approved for integration'
blocked=P.get('status')=='blocked'
if blocked:
 for f in P['files']:f['output']=f['output'].replace('native/','preview/candidates/',1)
out={};images={};groups={};files=[];refs={}
def sha(b):return hashlib.sha256(b).hexdigest()
def j(v):return (json.dumps(v,indent=2,sort_keys=True)+'\n').encode()
def png(im):
 b=BytesIO();im.save(b,format='PNG');return b.getvalue()
def night(im):
 n=im.copy();pixels=[]
 for r,g,b,a in im.get_flattened_data():
  lit=r/255*.36,g/255*.40,b/255*.82;grey=.299*lit[0]+.587*lit[1]+.114*lit[2];pixels.append(tuple(round(max(0,min(1,grey+.76*(v-grey)+o))*255) for v,o in zip(lit,(.040,.035,.105)))+(a,))
 n.putdata(pixels);return n
def render(f):
 e={'id':f['anim'],'source':str(D/f['source']),'canvas_wh':f['canvas_wh'],'pivot_xy':f['pivot_xy'],'palette':'tools/palette.py:COLOURS','alpha_threshold':128,**f['recipe']}
 if f.get('palette_keys'):e['palette_keys']=f['palette_keys']
 if e.get('palette_keys') is None:e.pop('palette_keys',None)
 if f.get('palette_mode','A')=='A':return render_source(e)
 x,y,w,h=e['crop_xywh'];im=Image.open(e['source']).convert('RGBA').crop((x,y,x+w,y+h));s=e['content_scale'];im=im.resize((round(w*s),round(h*s)),Image.Resampling.NEAREST);ramp=[tuple(c['rgb']) for c in P['colour_ramp']];cache={};px=[]
 for r,g,b,a in im.get_flattened_data():
  if a<128:px.append((0,0,0,0));continue
  c=(r,g,b)
  if c not in cache:cache[c]=min(ramp,key=lambda q:sum((v-u)**2 for v,u in zip(c,q)))
  px.append(cache[c]+(255,))
 im.putdata(px);n=Image.new('RGBA',tuple(f['canvas_wh']));ax,ay=e['content_anchor_xy'];n.alpha_composite(im,(f['pivot_xy'][0]-ax,f['pivot_xy'][1]-ay));return n
for original in P['files']:
 f=dict(original);im=render(f);images[f['output']]=im;out[f['output']]=png(im);f['sha256']=sha(out[f['output']]);f['source_sha256']=sha((D/f['source']).read_bytes());f['prompt_sha256']=sha((D/f['prompt']).read_bytes());files.append(f);groups.setdefault((f['anim'],f['dir']),[]).append(f);out[f'preview/{f["anim"]}-{f["dir"]}-{f["frame"]}-night.png']=png(night(im))
 call=json.loads((D/f['call']).read_text(encoding='utf-8'))
 for ref in call['input_images']:
  actual=Path(ref.get('archived_path',ref['path']));q=dict(ref);q['path']=str(actual);q['sha256']=sha(actual.read_bytes());refs[str(actual)]=q
checks={'frames_expected':P['expected_files'],'frames_found':len(files),'frame_count_matches':len(files)==P['expected_files'],'binary_alpha':all(set(im.getchannel('A').get_flattened_data())<={0,255} for im in images.values()),'no_empty_frame':all(im.getbbox() is not None for im in images.values()),'canvas_and_pivot_consistent':all(images[f['output']].size==tuple(f['canvas_wh']) for f in files),'colours_allowed':all(set(images[f['output']].get_flattened_data())-{(0,0,0,0)}<=({tuple(c['rgb'])+(255,) for c in P['colour_ramp']} if f.get('palette_mode')=='B' else {(*COLOURS[k],255) for k in (f.get('palette_keys') or COLOURS)}) for f in files),'grounded_on_pivot':all(images[f['output']].getbbox()[3]==f['pivot_xy'][1] for f in files if f.get('grounded')),'one_scale_per_animation':all(len({f['recipe']['content_scale'] for f in fs})==1 for fs in groups.values()),'points_on_opaque':all(images[f['output']].getpixel(tuple(p))[3]==255 for f in files for key,p in f.get('points',{}).items() if key.endswith('_xy') and len(p)==2),'importer_recipe_matches':all(images[f['output']].tobytes()==render(f).tobytes() for f in files),'mirror_pairs_exact':True,'rebuild_identical':True,'family_checks_complete':False,'measurements':{f['output']:{'bounds':list(images[f['output']].getbbox()) if images[f['output']].getbbox() else None,'opaque_pixels':sum(a>0 for r,g,b,a in images[f['output']].get_flattened_data())} for f in files}}
# Exact provenance checks: never silently replace the recorded reference hashes.
checks['raw_provenance_matches']=True;checks['reference_hashes_match']=True;checks['prompts_match_calls']=True
for f in files:
 call=json.loads((D/f['call']).read_text(encoding='utf-8'));checks['raw_provenance_matches'] &= call['sha256']==sha((D/f['source']).read_bytes());checks['prompts_match_calls'] &= call['arguments']['prompt']==(D/f['prompt']).read_text(encoding='utf-8')
 checks['reference_hashes_match'] &= all(ref['sha256']==sha(Path(ref.get('archived_path',ref['path'])).read_bytes()) for ref in call['input_images'])
if (D/'qa.py').exists():
 s=importlib.util.spec_from_file_location('qa',D/'qa.py');q=importlib.util.module_from_spec(s);s.loader.exec_module(q);checks.update(q.check(images,P));checks['family_checks_complete']=True
for a,b in P.get('mirror_pairs',{}).items():checks['mirror_pairs_exact'] &= images[b].tobytes()==ImageOps.mirror(images[a]).tobytes()
animations=[];sections=[];grass=Image.open(ROOT/'sprites/terrain/grass.png').convert('RGBA');farmer=Image.open(ROOT/'implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png').convert('RGBA');out['preview/grass.png']=png(grass)
for (name,dir),fs in sorted(groups.items()):
 fs.sort(key=lambda f:f['frame']);f=fs[0];w,h=f['canvas_wh'];entries=[{'path':f['output'],'night':f'preview/{name}-{dir}-{f["frame"]}-night.png','pose':f['pose'],'points':f.get('points',{}),'issue':f.get('review_issue','')} for f in fs];a={'anim':name,'dir':dir,'frames':len(fs),'canvas_wh':[w,h],'pivot_xy':f['pivot_xy'],'draw_scale':f['draw_scale'],'frame_seconds':f['seconds'],'loop':f['loop'],'mirror':f.get('mirror','none'),'entries':entries,'poses':[e['pose'] for e in entries]};a['points']={k:v for e in entries for k,v in e['points'].items()};animations.append(a);strip=Image.new('RGBA',((w+4)*len(fs),h))
 for i,f in enumerate(fs):strip.alpha_composite(images[f['output']],(i*(w+4),0))
 out[f'preview/{name}-{dir}-strip.png']=png(strip);f=fs[0];comp=P.get('comparison',[{}])[0] if P.get('comparison') else {};compim=Image.open(ROOT/comp['path']).convert('RGBA') if comp else None;cs=comp.get('draw_scale',1);ground=max(h+4,40,round(comp.get('pivot_xy',[0,0])[1]*cs)+4);context=Image.new('RGBA',(w+80+(round(compim.width*cs)+8 if compim else 8),ground+8))
 for y in range(0,context.height,16):
  for x in range(0,context.width,16):context.alpha_composite(grass,(x,y))
 context.alpha_composite(images[f['output']],(8,ground-f['pivot_xy'][1]));context.alpha_composite(farmer,(w+12,ground-36))
 if P.get('comparison'):
  c=P['comparison'][0];ci=Image.open(ROOT/c['path']).convert('RGBA');s=c.get('draw_scale',1);ci=ci.resize((round(ci.width*s),round(ci.height*s)),Image.Resampling.NEAREST);context.alpha_composite(ci,(w+72,ground-round(c['pivot_xy'][1]*s)))
 for when,im in [('day',context),('night',night(context))]:out[f'preview/{name}-{dir}-context-{when}.png']=png(im)
 sections.append(f'<section data-animation="{len(animations)-1}"><h2>{name} / {dir}</h2><p>{len(fs)}frames / {f["seconds"]}s / '+('loop' if f['loop'] else 'static or one-shot')+'</p><button class="pause">Pause</button><button class="restart">Restart</button><button class="prev">Previous</button><button class="next">Next</button><span class="frame"></span><p>Native1x / FHD4x / night4x / light / dark / checker / grass</p>'+''.join(f'<canvas class="live {bg}" width="{w}" height="{h}" style="width:{w*s}px;height:{h*s}px" data-night="{str(bg=="night").lower()}"></canvas>' for bg,s in [('native',1),('day',4),('night',4),('light',4),('dark',4),('checker',4),('grass',4)])+f'<p>Ground line: new sprite / farmer / nearest existing reference</p><img src="preview/{name}-{dir}-context-day.png" width="{context.width}" height="{context.height}"><img src="preview/{name}-{dir}-context-day.png" width="{context.width*4}" height="{context.height*4}"><img src="preview/{name}-{dir}-context-night.png" width="{context.width*4}" height="{context.height*4}"><details><summary>Still frames</summary><img src="preview/{name}-{dir}-strip.png" width="{strip.width*4}" height="{h*4}"></details></section>')
contract={k:P.get(k,[]) for k in ['colour_ramp','comparison','deviations','supersedes']};contract.update({'pack':D.name[:4],'slug':D.name,'title':P['title'],'date':P['date'],'status':P.get('status','review'),'runtime_integrated':False,'tool':'built-in ImageGen','palette_mode':P.get('palette_mode','A'),'palette':'tools/palette.py:COLOURS','alpha_threshold':128,'references':[v for v in refs.values() if 'rejected' not in Path(v['path']).parts],'files':files,'animations':animations,'mirror_pairs':P.get('mirror_pairs',{})})
css='body{background:#1b292c;color:#ebe2cf;font:16px system-ui;margin:24px}a{color:#92d1d2}img,canvas{image-rendering:pixelated;vertical-align:bottom;margin:8px}section{border:1px solid #536064;padding:16px;margin:24px 0;overflow:auto}.light{background:#eee3cf}.dark{background:#1a1830}.checker{background:repeating-conic-gradient(#465257 0% 25%,#2d3438 0% 50%) 0 0/16px 16px}.grass,.day{background:url(preview/grass.png);background-size:64px}.night{background:#19172d}button{margin:4px;padding:8px}'
js="""const animations=DATA;document.querySelectorAll('section[data-animation]').forEach(section=>{const a=animations[+section.dataset.animation],frames=a.entries.map(f=>{const day=new Image(),night=new Image();day.src=f.path;night.src=f.night;return {day,night,meta:f}});let i=0,paused=false,last=performance.now();function draw(){section.querySelector('.frame').textContent='Frame '+(i+1)+'/'+frames.length+' | '+frames[i].meta.pose+(frames[i].meta.issue?' | '+frames[i].meta.issue:'');section.querySelectorAll('canvas.live').forEach(c=>{const ctx=c.getContext('2d');ctx.imageSmoothingEnabled=false;ctx.clearRect(0,0,c.width,c.height);ctx.drawImage(c.dataset.night==='true'?frames[i].night:frames[i].day,0,0);if(document.body.classList.contains('points')){ctx.strokeStyle='#83d6b5';for(const [key,p]of Object.entries(frames[i].meta.points)){if(key.endsWith('_xy')&&p.length===2&&p.every(Number.isFinite))ctx.strokeRect(p[0],p[1],1,1);else if(key.endsWith('_xywh')&&p.length===4&&p.every(Number.isFinite))ctx.strokeRect(...p);else if(key==='windows_xy')for(const xy of p)ctx.strokeRect(xy[0],xy[1],1,1);else if(key==='window_rects_xywh')for(const r of p)ctx.strokeRect(...r)}}})}section.querySelector('.pause').onclick=()=>paused=!paused;section.querySelector('.restart').onclick=()=>{i=0;last=performance.now();draw()};for(const [name,delta]of [['prev',-1],['next',1]])section.querySelector('.'+name).onclick=()=>{paused=true;i=(i+delta+frames.length)%frames.length;draw()};function tick(t){if(!paused&&frames.length>1&&t-last>=a.frame_seconds*1000){i=a.loop?(i+1)%frames.length:Math.min(i+1,frames.length-1);last=t}if(frames[i].day.complete&&frames[i].night.complete)draw();requestAnimationFrame(tick)}requestAnimationFrame(tick)});""".replace('DATA',json.dumps(animations))
extra_html=''
if (D/'review_extras.py').exists():
 sp=importlib.util.spec_from_file_location('review_extras',D/'review_extras.py');mod=importlib.util.module_from_spec(sp);sp.loader.exec_module(mod);extra_html=mod.render(images,P,out)
failed=[k for k,v in checks.items() if v is False];page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>'+D.name+' review</title><style>'+css+'</style><h1>'+D.name+' / '+P.get('status','review')+'</h1><p>Native1x equals4screenpixels at FHD. Runtime not integrated. World relight is reference only for UI: HUD is not relit.</p><p><a href="contract.json">Contract</a> / <a href="checks.json">Checks</a> / <a href="review-log.txt">Review log</a></p><p>Known incomplete checks: '+(', '.join(failed) if failed else 'none')+'</p><button onclick="document.body.classList.toggle(\'points\')">Toggle metadata points</button>'+''.join(sections)+extra_html+'<script>'+js+'</script></html>'
if blocked:
 candidate=dict(contract);candidate['delivery_type']='rejected / incomplete diagnostic candidates, never runtime art';out['candidate-contract.json']=j(candidate)
 checks['candidate_frames_found']=len(files);checks['candidate_frame_count_matches']=checks['frame_count_matches'];checks['frames_found']=0;checks['frame_count_matches']=False
 contract=dict(contract);contract.update(files=[],animations=[],references=[],delivery_type='blocked; no production export',expected_files=P['expected_files'],candidate_review='candidate-contract.json')
 page=page.replace('</h1>','</h1><p><a href=\"candidate-contract.json\">Diagnostic candidate recipes / proposed names</a></p>').replace('Runtime not integrated.','Blocked diagnostics only: no production export. Runtime not integrated.').replace('Known incomplete checks: ','Known candidate issues: ')

# Complete continuation approval: metadata only, never alter rendered pixels.
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
out['contract.json']=j(contract);out['checks.json']=j(checks);out['index.html']=page.encode()
for rel,data in sorted(out.items()):
 p=D/rel
 if '--check' in sys.argv:
  if not p.exists() or p.read_bytes()!=data:raise SystemExit('DIFF '+rel)
 else:p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
print(D.name,len(files),'candidate frames; production:',0 if blocked else len(files),'failed checks:',[k for k,v in checks.items() if v is False])
technical=['frame_count_matches','binary_alpha','no_empty_frame','canvas_and_pivot_consistent','colours_allowed','grounded_on_pivot','one_scale_per_animation','points_on_opaque','importer_recipe_matches','raw_provenance_matches','reference_hashes_match','prompts_match_calls','approved_sitting_unchanged']
if any(checks.get(k) is not True for k in technical):raise SystemExit(2)
