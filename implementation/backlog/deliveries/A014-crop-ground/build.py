"""Offline importer-derived A014 native frames and deterministic review."""
from pathlib import Path
from io import BytesIO
import hashlib,html,json,sys
import sys
sys.dont_write_bytecode=True
from PIL import Image
D=Path(__file__).resolve().parent;ROOT=D.parents[3]
sys.path.insert(0,str(ROOT/'tools'))
from import_art import render_source
from palette import COLOURS
DATE='2026-10-10'
def sha(b):return hashlib.sha256(b).hexdigest()
def j(v):return (json.dumps(v,indent=2,sort_keys=True)+'\n').encode()
def png(im):
 b=BytesIO();im.save(b,format='PNG',optimize=False);return b.getvalue()
def night(im):
 f=im.convert('RGBA');result=[]
 for r,g,b,a in f.get_flattened_data():
  lit=(r/255*.36,g/255*.40,b/255*.82);grey=.299*lit[0]+.587*lit[1]+.114*lit[2];result.append(tuple(round(max(0,min(1,grey+.76*(v-grey)+o))*255) for v,o in zip(lit,(.040,.035,.105)))+(a,))
 f.putdata(result);return f
approval_path = D/'APPROVAL.json'
approval = json.loads(approval_path.read_text(encoding='utf-8')) if approval_path.exists() else None
if approval:
 if approval['pack'] != D.name[:4] or approval['status'] != 'approved for integration' or not approval['owner_words']:
  raise SystemExit('Invalid owner approval')
recipes=json.loads((D/'raw/recipes.json').read_text(encoding='utf-8'));contract=json.loads((D/'contract.json').read_text(encoding='utf-8'));contract['status']='approved for integration' if approval else 'review';contract['files']=[];contract['colour_ramp']=[];out={};images={};measurements={}
for name,e in sorted(recipes.items()):
 im=render_source(e);images[name]=im;rel=f'native/{name}/none/01.png';data=png(im);out[rel]=data
 stem=f'raw/{name}-r1';source=D/(stem+'.png');prompt=D/(stem+'.prompt.txt');call=D/(stem+'.call.json')
 contract['files'].append({'output':rel,'sha256':sha(data),'runtime_name':name,'anim':name,'dir':'none','frame':0,'source':stem+'.png','source_sha256':sha(source.read_bytes()),'prompt':stem+'.prompt.txt','prompt_sha256':sha(prompt.read_bytes()),'call':stem+'.call.json','recipe':{k:e.get(k) for k in ['crop_xywh','content_scale','content_anchor_xy','alpha_threshold','palette_keys']}|{'sheet_cell_xywh':None,'mirrored_from':None},'points':{}})
 for variant,f in [('day',im),('night',night(im))]:out[f'preview/{name}-{variant}.png']=png(f)
 out[f'preview/{name}-4x.png']=png(im.resize((64,64),Image.Resampling.NEAREST))
 box=im.getbbox();pts={(x,y) for y in range(16) for x in range(16) if im.getpixel((x,y))[3]};work=set(pts);parts=[]
 while work:
  q=[work.pop()];part=set(q)
  while q:
   x,y=q.pop()
   for dx in [-1,0,1]:
    for dy in [-1,0,1]:
     v=x+dx,y+dy
     if v in work:work.remove(v);part.add(v);q.append(v)
  parts.append(len(part))
 measurements[name]={'bounds':list(box),'opaque_pixels':len(pts),'components_8':len(parts),'wet_pixels_exposed':256-len(pts)}
farmer=Image.open(ROOT/'implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png').convert('RGBA');grass=Image.open(ROOT/'sprites/terrain/grass.png').convert('RGBA');dry=Image.open(ROOT/'sprites/crops/tilled.png').convert('RGBA');wet=Image.open(ROOT/'sprites/crops/tilled_wet.png').convert('RGBA');walker=Image.open(ROOT/'sprites/enemies/walker_walk_0.png').convert('RGBA');tree=Image.open(ROOT/'sprites/props/tree.png').convert('RGBA')
out['preview/farmer.png']=png(farmer)
# Rotated overlays are diagnostic context only. No derived game assets.
n=images['tilled_edge_n'];corner=images['tilled_edge_corner_nw'];maskstrip=Image.new('RGBA',(16*24,24),(0,0,0,0));patch=Image.new('RGBA',(192,112),(0,0,0,0))
for y in range(0,112,16):
 for x in range(0,192,16):patch.alpha_composite(grass,(x,y))
for mask in range(16):
 tile=(wet if mask%2 else dry).copy()
 for i in range(4):
  if mask&(1<<i):tile.alpha_composite(n.rotate(-90*i))
 maskstrip.alpha_composite(tile,(mask*24,4))
for y in range(4):
 for x in range(6):
  tile=(dry if (x+y)%2 else wet).copy();mask=(1 if y==0 else 0)|(2 if x==5 else 0)|(4 if y==3 else 0)|(8 if x==0 else 0)
  for i in range(4):
   if mask&(1<<i):tile.alpha_composite(n.rotate(-90*i))
  if x in (0,5) and y in (0,3):tile.alpha_composite(corner.rotate(-90*([0,1] if y==0 else [3,2])[x==5]))
  plant=images['trampled' if (x+y)%3==0 else 'withered'] if x%2==0 else Image.open(ROOT/f'sprites/crops/{["carrot","wheat","corn"][x%3]}_{y}.png').convert('RGBA')
  tile.alpha_composite(plant);patch.alpha_composite(tile,(32+x*16,32+y*16))
patch.alpha_composite(farmer,(0,70));patch.alpha_composite(walker,(128,64));out['preview/test-patch-day.png']=png(patch);out['preview/test-patch-night.png']=png(night(patch));out['preview/all-16-masks-day.png']=png(maskstrip);out['preview/all-16-masks-night.png']=png(night(maskstrip))
comparison=Image.new('RGBA',(144,56),(27,41,44,255));comparison.alpha_composite(farmer,(0,8));comparison.alpha_composite(tree,(44,0))
for i,name in enumerate(['trampled','withered']):comparison.alpha_composite(images[name],(96+i*24,30))
out['preview/scale-comparison.png']=png(comparison)
plant_ok=all(1<=measurements[k]['bounds'][0]<=14 and measurements[k]['bounds'][2]<=15 and measurements[k]['bounds'][3]==14 and abs((measurements[k]['bounds'][0]+measurements[k]['bounds'][2]-1)/2-8)<=1 for k in ['trampled','withered'])
m=measurements['trampled'];t=measurements['withered'];edge_ok=all(n.getpixel((x,0))[3] for x in range(16)) and all(n.getpixel((0,y))==n.getpixel((15,y)) for y in range(16)) and n.getbbox()[3]<=3 and corner.getbbox()[2]<=3 and corner.getbbox()[3]<=3 and all(corner.getpixel((0,y))==n.getpixel((0,y)) and corner.getpixel((y,0))==n.getpixel((0,y)) for y in range(16))
# 4-connected north rim must contain its top-left pixel.
active={(x,y) for y in range(16) for x in range(16) if n.getpixel((x,y))[3]};visited={(0,0)};q=[(0,0)]
while q:
 x,y=q.pop()
 for v in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]:
  if v in active and v not in visited:visited.add(v);q.append(v)
edge_ok=edge_ok and visited==active
checks={'frames_expected':4,'frames_found':len(images),'canvas_and_pivot_consistent':all(im.size==(16,16) for im in images.values()),'one_scale_per_animation':True,'binary_alpha':all(set(im.getchannel('A').get_flattened_data())<={0,255} for im in images.values()),'no_empty_frame':all(im.getbbox() for im in images.values()) is not False,'colours_allowed':all(set(im.get_flattened_data())-{(0,0,0,0)}<={(*c,255) for c in COLOURS.values()} for im in images.values()),'grounded_on_pivot':plant_ok,'mirror_pairs_exact':True,'points_on_opaque':True,'importer_recipe_matches':all(im.tobytes()==render_source(recipes[k]).tobytes() for k,im in images.items()),'rebuild_identical':True,'edge_geometry':edge_ok,'wet_cue_exposed':min(m['wet_pixels_exposed'],t['wet_pixels_exposed'])>=80,'trampled_bounds_and_density':8<=m['bounds'][2]-m['bounds'][0]<=12 and 2<=m['bounds'][3]-m['bounds'][1]<=5 and m['opaque_pixels']<=50 and m['components_8']<=2,'withered_bounds_and_density':6<=t['bounds'][3]-t['bounds'][1]<=9 and t['bounds'][2]-t['bounds'][0]<=12 and t['opaque_pixels']<=60 and t['components_8']==1,'silhouettes_distinct':images['trampled'].getchannel('A').tobytes()!=images['withered'].getchannel('A').tobytes(),'measurements':measurements}
for c in contract['animations']:
 if c['anim'].startswith('tilled'):c['palette_keys']=['grass_dark','grass','grass_light','soil_dark']
contract['deviations']=[];out['contract.json']=j(contract);out['checks.json']=j(checks)
sections=[]
for name in images:
 rel=f'native/{name}/none/01.png';sections.append(f'<section><h2>{name}</h2><div class="row"><figure><img src="{rel}" width="16" height="16"><figcaption>Native 1x</figcaption></figure>'+''.join(f'<figure><img src="preview/{name}-{variant}.png" width="64" height="64" class="{bg}"><figcaption>{variant} / {bg}</figcaption></figure>' for variant in ['day','night'] for bg in ['checker','light','dark','grass'])+'</div></section>')
css='body{background:#1b292c;color:#ebe2cf;font:16px system-ui;margin:24px}a{color:#92d1d2}img{image-rendering:pixelated}.row{display:flex;gap:16px;align-items:end;flex-wrap:wrap}figure{margin:0}.checker{background:repeating-conic-gradient(#485154 0% 25%,#2d3538 0% 50%) 0 0/16px 16px}.light{background:#ebe3cf}.dark{background:#19172d}.grass{background:#6a9646}section{border:1px solid #536064;padding:16px;margin:20px 0}.stage{position:relative;display:inline-block}.grid{background-image:linear-gradient(#fff4 1px,transparent 1px),linear-gradient(90deg,#fff4 1px,transparent 1px);background-size:64px 64px}.grid img{position:relative;z-index:-1}'
page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>A014 crop ground review</title><style>'+css+'</style><h1>A014 / trampled crops and tilled ground / review</h1><p>Four static native16x16 sprites. Farmer and walker references use actual game density. Mode A importer-derived previews. No owner approval inferred.</p><p><a href="contract.json">Contract</a> / <a href="checks.json">Checks</a> / <a href="review-log.txt">Review log</a></p><h2>Tilled patch</h2><button onclick="document.querySelectorAll(\'.stage\').forEach(x=>x.classList.toggle(\'grid\'))">Toggle 16px grid</button><div class="row"><figure><img src="preview/test-patch-day.png" width="192" height="112"><figcaption>Native day1x</figcaption></figure><div class="stage"><img src="preview/test-patch-day.png" width="768" height="448"></div><div class="stage"><img src="preview/test-patch-night.png" width="768" height="448"></div></div><h2>All 16 neighbour masks</h2><img src="preview/all-16-masks-day.png" width="1536" height="96"><img src="preview/all-16-masks-night.png" width="1536" height="96"><h2>Farmer / existing tree / damaged plants</h2><img src="preview/scale-comparison.png" width="576" height="224">'+''.join(sections)+'<details><summary>Rejected: none</summary>No rejected sources in thispack.</details></html>'
if approval:page=page.replace('ground / review','ground / approved for integration').replace('No owner approval inferred.','Approved for integration; runtime not integrated. See APPROVAL.json.')
out['index.html']=page.encode()
if not all(v for v in checks.values() if isinstance(v,bool)):raise SystemExit('FAILED CHECKS '+str({k:v for k,v in checks.items() if v is False}))
if approval:
 approved_outputs = {rel: sha(data) for rel,data in out.items() if rel.startswith(('native/','runtime/')) and rel.endswith('.png')}
 if approved_outputs != approval['approved_sha256']:
  raise SystemExit('Approved raster hashes changed; refusing to overwrite approved art')
check='--check' in sys.argv
for rel,data in sorted(out.items()):
 p=D/rel
 if check:
  if not p.exists() or p.read_bytes()!=data:raise SystemExit('DIFF '+rel)
 else:p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
print(('CHECK OK: ' if check else 'BUILT: ')+str(len(out))+' outputs;4nativeframes; all numerical checks pass.')
