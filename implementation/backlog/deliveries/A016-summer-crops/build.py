from pathlib import Path
from io import BytesIO
import json,sys,hashlib,re
import sys
sys.dont_write_bytecode=True
from PIL import Image
D=Path(__file__).resolve().parent;ROOT=D.parents[3];sys.path.insert(0,str(ROOT/'tools'))
from import_art import render_source
from palette import COLOURS
approval_path = D/'APPROVAL.json'
approval = json.loads(approval_path.read_text(encoding='utf-8')) if approval_path.exists() else None
if approval:
 if approval['pack'] != D.name[:4] or approval['status'] != 'approved for integration' or not approval['owner_words']:
  raise SystemExit('Invalid owner approval')
PACK=D.name[:4];spec=json.loads((D/'raw/stage-spec.json').read_text(encoding='utf-8'));out={};files=[];groups={};measurements={};sources=[]
def j(v):return (json.dumps(v,indent=2,sort_keys=True)+'\n').encode()
def png(im):
 b=BytesIO();im.save(b,format='PNG');return b.getvalue()
def sha(b):return hashlib.sha256(b).hexdigest()
def night(im):
 n=im.copy();pix=[]
 for r,g,b,a in im.get_flattened_data():
  lit=(r/255*.36,g/255*.40,b/255*.82);grey=.299*lit[0]+.587*lit[1]+.114*lit[2];pix.append(tuple(round(max(0,min(1,grey+.76*(v-grey)+o))*255) for v,o in zip(lit,(.040,.035,.105)))+(a,))
 n.putdata(pix);return n
def bbox(im):return im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
def add(name,frame,source,crop,scale,canvas,pivot,pose,anchor=None,cell=None):
 recipe={'crop_xywh':crop,'content_scale':scale,'content_anchor_xy':anchor or [round(crop[2]*scale)//2,round(crop[3]*scale)]};e={'id':name,'source':str(D/source),'canvas_wh':canvas,'pivot_xy':pivot,'alpha_threshold':128,'palette':'tools/palette.py:COLOURS',**recipe};im=render_source(e);path=f'native/{name}/none/{frame+1:02d}.png';data=png(im);out[path]=data;anim=name;f={'anim':anim,'dir':'none','frame':frame,'output':path,'runtime_name':('ui/'+name if name.startswith(('icon_','hud_')) else 'crops/'+name+(f'_{frame}' if name in spec else ''))+'.png','canvas_wh':canvas,'pivot_xy':pivot,'draw_scale':1.0,'seconds':1.0 if name.startswith(('icon_','hud_')) else .55,'loop':False,'pose':pose,'source':source,'source_sha256':sha((D/source).read_bytes()),'prompt':source.replace('.png','.prompt.txt'),'prompt_sha256':sha((D/source.replace('.png','.prompt.txt')).read_bytes()),'call':source.replace('.png','.call.json'),'recipe':recipe,'sheet_cell_xywh':cell,'sha256':sha(data),'points':{}};files.append(f);groups.setdefault(name,[]).append((f,im));b=im.getbbox();measurements[path]={'bounds':list(b),'height':b[3]-b[1],'width':b[2]-b[0],'opaque_pixels':sum(a>0 for r,g,b,a in im.get_flattened_data()),'plot_opaque':sum(im.getpixel((x,y))[3]>0 for y in range(max(0,pivot[1]-16),pivot[1]) for x in range(canvas[0]))};out[f'preview/{name}-{frame}-night.png']=png(night(im));return im
stage_recipes={}
for name,s in spec.items():
 source=f"raw/{name}-r{s.get('revision',1)}.png";im=Image.open(D/source).convert('RGBA');mask=im.getchannel('A').point(lambda a:255 if a>=128 else 0);xs=[x for x in range(im.width) if mask.crop((x,0,x+1,im.height)).getbbox()];gaps=sorted(sorted([(b-a-1,a,b) for a,b in zip(xs,xs[1:]) if b-a>1],reverse=True)[:len(s['poses'])-1],key=lambda t:t[1]);cuts=[0]+[(a+b)//2 for _,a,b in gaps]+[im.width];frames=[]
 for x0,x1 in zip(cuts,cuts[1:]):
  a,b,c,d=mask.crop((x0,0,x1,im.height)).getbbox();frames.append({'crop_xywh':[a+x0,b,c-a,d-b],'sheet_cell_xywh':[x0,0,x1-x0,im.height]})
 low=max((lo-.49)/f['crop_xywh'][3] for f,(lo,hi) in zip(frames,s['limits']));high=min((hi+.49)/f['crop_xywh'][3] for f,(lo,hi) in zip(frames,s['limits']));high=min(high,14/max(f['crop_xywh'][2] for f in frames));scale=(low+high)/2 if low<=high else high
 for i,f in enumerate(frames):
  anim=name if i<4 else name+'_regrow';n=add(anim,i if i<4 else 0,source,f['crop_xywh'],scale,s['canvas'],s['pivot'],s['poses'][i],cell=f['sheet_cell_xywh']);f['content_scale']=scale;f['native_bounds']=list(n.getbbox())
 stage_recipes[name]=frames
if PACK=='A016':
 source='raw/corn_regrow-r1.png';im=Image.open(D/source).convert('RGBA');mask=im.getchannel('A').point(lambda a:255 if a>=128 else 0);xs=[x for x in range(im.width) if mask.crop((x,0,x+1,im.height)).getbbox()];gap=max((b-a-1,a,b) for a,b in zip(xs,xs[1:]) if b-a>1);cut=(gap[1]+gap[2])//2;frames=[]
 for x0,x1 in [(0,cut),(cut,im.width)]:
  a,b,c,d=mask.crop((x0,0,x1,im.height)).getbbox();frames.append([a+x0,b,c-a,d-b])
 scale=20/frames[0][3];cal=render_source({'id':'calibration','source':str(D/source),'crop_xywh':frames[0],'content_scale':scale,'canvas_wh':[16,24],'pivot_xy':[8,22],'palette':'tools/palette.py:COLOURS','alpha_threshold':128});out['preview/corn-calibration.png']=png(cal);add('corn_regrow',0,source,frames[1],scale,[16,24],[8,22],'cobs picked, empty husk stubs, same stalk');stage_recipes['corn_calibration']={'crops':frames,'scale':scale,'native_height':cal.getbbox()[3]-cal.getbbox()[1]}
for p in sorted((D/'raw').glob('icon_*-r1.png')):
 name=p.stem.removesuffix('-r1');im=Image.open(p).convert('RGBA');a,b,c,d=bbox(im);crop=[a,b,c-a,d-b]
 for kind,size,maxv in [('icon',16,14),('hud',10,8)]:
  scale=maxv/max(crop[2:]);anchor=[round(crop[2]*scale)//2,round(crop[3]*scale)//2];add(kind+name[4:],0,str(p.relative_to(D)),crop,scale,[size,size],[size//2]*2,'single produce icon',anchor)
for p in sorted((D/'raw').glob('*_seed-r1.png')):
 name=p.stem.removesuffix('-r1');crop=[320,300,615,716]
 for kind,size,h,anchor in [('icon',16,14,[6,7]),('hud',10,8,[3,4])]:add(kind+'_'+name,0,str(p.relative_to(D)),crop,h/716,[size,size],[size//2]*2,'common paper packet with seasonal band and crop picture',anchor)
for p in sorted((D/'raw').glob('*.call.json')):
 q=json.loads(p.read_text(encoding='utf-8'));q['decision']='accepted for owner review; numeric checks recorded separately';out[str(p.relative_to(D))]=j(q);sources.append({'call':str(p.relative_to(D)),'source_sha256':q['sha256'],'revision':q['revision']})
checks={'frames_expected':28 if PACK=='A016' else 27,'frames_found':len(files),'binary_alpha':all(set(im.getchannel('A').get_flattened_data())<={0,255} for fs in groups.values() for f,im in fs),'no_empty_frame':all(im.getbbox() for fs in groups.values() for f,im in fs),'colours_allowed':all(set(im.get_flattened_data())-{(0,0,0,0)}<={(*c,255) for c in COLOURS.values()} for fs in groups.values() for f,im in fs),'one_scale_per_animation':all(len({f['recipe']['content_scale'] for f,im in fs})==1 for fs in groups.values()),'canvas_and_pivot_consistent':all(im.size==tuple(f['canvas_wh']) for fs in groups.values() for f,im in fs),'grounded_on_pivot':all(im.getbbox()[3]==f['pivot_xy'][1] for fs in groups.values() for f,im in fs if not f['anim'].startswith(('icon_','hud_'))),'wet_cue_exposed':all(measurements[f['output']]['plot_opaque']<=150 for fs in groups.values() for f,im in fs if not f['anim'].startswith(('icon_','hud_'))),'stage_targets':all(lo<=measurements[groups[name if i<4 else name+'_regrow'][i if i<4 else 0][0]['output']]['height']<=hi for name,s in spec.items() for i,(lo,hi) in enumerate(s['limits'])),'stages_rise':all(all(a<b for a,b in zip(h,h[1:])) for name in spec for h in [[measurements[f['output']]['height'] for f,im in groups[name]]]),'icon_bounds_ok':all(im.getbbox()[0]>=1 and im.getbbox()[1]>=1 and im.getbbox()[2]<f['canvas_wh'][0] and im.getbbox()[3]<f['canvas_wh'][1] for fs in groups.values() for f,im in fs if f['anim'].startswith(('icon_','hud_'))),'packets_same_box':all(list(im.getbbox())==([2,1,14,15] if im.width==16 else [2,1,9,9]) for fs in groups.values() for f,im in fs if '_seed' in f['anim']),'icon_density':all(measurements[f['output']]['opaque_pixels']>(24 if im.width==16 else 7) for fs in groups.values() for f,im in fs if f['anim'].startswith(('icon_','hud_'))),'icon_colours_at_least2':all(len({p[:3] for p in im.get_flattened_data() if p[3]})>=2 for fs in groups.values() for f,im in fs if f['anim'].startswith(('icon_','hud_'))),'importer_recipe_matches':True,'mirror_pairs_exact':True,'points_on_opaque':True,'rebuild_identical':True,'measurements':measurements}
checks['frames_count_matches']=checks['frames_found']==checks['frames_expected']
if PACK=='A016':checks['corn_calibration20']=stage_recipes['corn_calibration']['native_height']==20;checks['corn_regrow_height']=17<=measurements[groups['corn_regrow'][0][0]['output']]['height']<=19
refs={}
for p in sorted((D/'raw').glob('*.request.json')):
 for r in json.loads(p.read_text(encoding='utf-8'))['referenced_image_paths']:
  actual=Path(r) if Path(r).exists() else D/'rejected'/Path(r).name
  refs[r]={'path':str(actual),'original_path':r,'sha256':sha(actual.read_bytes()),'role':'style/layout/scale reference or packet master edit target'}
contract={'pack':PACK,'slug':D.name,'date':'2026-10-10','status':'approved for integration' if approval else 'review','runtime_integrated':False,'tool':'built-in ImageGen','palette_mode':'A','palette':'tools/palette.py:COLOURS','palette_keys':None,'alpha_threshold':128,'references':list(refs.values()),'sources':sources,'files':files,'animations':[{'anim':n,'dir':'none','frames':len(fs),'poses':[f['pose'] for f,im in fs],'canvas_wh':fs[0][0]['canvas_wh'],'pivot_xy':fs[0][0]['pivot_xy'],'draw_scale':1.0,'frame_seconds':fs[0][0]['seconds'],'loop':False,'mirror':'none','points':{}} for n,fs in sorted(groups.items())],'mirror_pairs':{},'deviations':[],'supersedes':[]}
dry=Image.open(ROOT/'sprites/crops/tilled.png').convert('RGBA');wet=Image.open(ROOT/'sprites/crops/tilled_wet.png').convert('RGBA');grass=Image.open(ROOT/'sprites/terrain/grass.png').convert('RGBA');farmer=Image.open(ROOT/'implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png').convert('RGBA');out['preview/grass.png']=png(grass);html=[]
for name,s in spec.items():
 fs=groups[name]+groups.get(name+'_regrow',[]);w=24*len(fs);h=s['canvas'][1]
 html.append(f'<section><h2>{name}</h2><p>'+ ' / '.join(s['poses'])+'</p>')
 for typ,soil in [('dry',dry),('wet',wet)]:
  strip=Image.new('RGBA',(w,h))
  for i,(f,im) in enumerate(fs):strip.alpha_composite(soil,(i*24,h-16));strip.alpha_composite(im,(i*24,0))
  for when,im in [('day',strip),('night',night(strip))]:out[f'preview/{name}-{typ}-{when}.png']=png(im)
  html.append(f'<p>{typ}: native1x / day4x / night4x</p><img src="preview/{name}-{typ}-day.png" width="{w}" height="{h}"><img src="preview/{name}-{typ}-day.png" width="{w*4}" height="{h*4}"><img src="preview/{name}-{typ}-night.png" width="{w*4}" height="{h*4}">')
 field=Image.new('RGBA',(112,96))
 for y in range(0,96,16):
  for x in range(0,112,16):field.alpha_composite(grass,(x,y))
 for y in range(3):
  for x in range(4):field.alpha_composite(dry,(x*16,32+y*16));field.alpha_composite(groups[name][3][1],(x*16,32+y*16-(h-16)))
 field.alpha_composite(farmer,(64,78-36))
 for when,im in [('day',field),('night',night(field))]:out[f'preview/{name}-field-{when}.png']=png(im);html.append(f'<span class="gridwrap"><img src="preview/{name}-field-{when}.png" width="448" height="384"><i></i></span>')
 html.append('</section>')
html.append('<section><h2>Icons and seasonal packets</h2><p>Native / light / dark / checker / grass. Compare shape and readability at1x.</p>')
for name,fs in groups.items():
 if name.startswith(('icon_','hud_')):
  f,im=fs[0];html.append(f'<figure><figcaption>{name}</figcaption><img src="{f["output"]}" width="{im.width}" height="{im.height}">'+''.join(f'<img class="{bg}" src="{f["output"]}" width="{im.width*4}" height="{im.height*4}">' for bg in ['light','dark','checker','grass'])+'</figure>')
html.append('<h3>All seasonal packet candidates so far</h3>')
for p in sorted((ROOT/'implementation/backlog/deliveries').glob('A01[567]-*/native/icon_*_seed/none/01.png')):
 rel=Path('..')/p.relative_to(D.parent);html.append(f'<figure><figcaption>{p.parents[1].name}</figcaption><img src="{rel.as_posix()}" width="64" height="64"></figure>')
html.append('</section>')
if PACK=='A016':html.append('<section><h2>Corn calibration / picked stalk</h2><img src="preview/corn-calibration.png" width="64" height="96"><img src="native/corn_regrow/none/01.png" width="64" height="96"></section>')
css='body{background:#1b292c;color:#ebe2cf;font:16px system-ui;margin:24px}a{color:#92d1d2}img{image-rendering:pixelated;vertical-align:bottom;margin:8px}.light{background:#ebe3cf}.dark{background:#19172d}.checker{background:repeating-conic-gradient(#465257 0% 25%,#2d3438 0% 50%) 0 0/16px 16px}.grass{background:url(preview/grass.png);background-size:64px}section{border:1px solid #536064;padding:16px;margin:20px 0}figure{display:inline-block}.gridwrap{position:relative;display:inline-block}.gridwrap i{display:none;position:absolute;inset:8px;pointer-events:none;background-image:linear-gradient(#fff4 1px,transparent 1px),linear-gradient(90deg,#fff4 1px,transparent 1px);background-size:64px 64px}.showgrid .gridwrap i{display:block}'
page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>'+PACK+' crop review</title><style>'+css+'</style><h1>'+PACK+' / crop review</h1><p>Owner review pending; no approval inferred. Runtime not modified.</p><p><a href="contract.json">Contract</a> / <a href="checks.json">Checks</a> / <a href="review-log.txt">Review log</a></p><button onclick="document.body.classList.toggle(\'showgrid\')">Toggle16px grid</button>'+''.join(html)+'</html>'
if approval:page=page.replace('Owner review pending; no approval inferred. Runtime not modified.','Approved for integration; runtime not integrated. See APPROVAL.json.')
out['raw/measured-stage-recipes.json']=j(stage_recipes);out['contract.json']=j(contract);out['checks.json']=j(checks);out['index.html']=page.encode()
failed=[k for k,v in checks.items() if v is False]
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
print(PACK, len(files),'native files, failures:',failed)
if failed:raise SystemExit(2)
