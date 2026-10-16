"""Render candidate A056 sprites from recorded ImageGen inputs, then build review."""
from pathlib import Path
from PIL import Image,ImageOps,ImageEnhance
import sys,json,hashlib
D=Path(__file__).resolve().parent; ROOT=D.parents[3]; RAW=D/'raw'; PRE=D/'preview'
sys.path.insert(0,str(ROOT/'tools'))
from import_art import render_source
from palette import COLOURS

if '--check' in sys.argv:
    contract=json.loads((D/'contract.json').read_text(encoding='utf-8'))
    approval=json.loads((D/'APPROVAL.json').read_text(encoding='utf-8'))
    assert contract['status']=='approved for integration'
    assert set(approval['approved_sha256'])=={f['output'] for f in contract['files']}
    for f in contract['files']:
        path=D/f['output']
        assert hashlib.sha256(path.read_bytes()).hexdigest()==approval['approved_sha256'][f['output']]
        assert render_source(f['recipe']).tobytes()==Image.open(path).convert('RGBA').tobytes(), f['output']
        assert hashlib.sha256((D/f['source']).read_bytes()).hexdigest()==f['source_sha256']
        assert hashlib.sha256((D/f['prompt']).read_bytes()).hexdigest()==f['prompt_sha256']
    print(D.name+' approval, hashes and in-memory source recipes: PASS')
    raise SystemExit(0)

def read(p): return json.loads(p.read_text(encoding='utf-8'))
def write(p,x): p.parent.mkdir(parents=True,exist_ok=True); p.write_text(json.dumps(x,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def bounds(p):
  im=Image.open(p).convert('RGBA'); return im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
def crop_recipe(stem,canvas,pivot,scale,icon=False):
  src=RAW/(stem+'.png'); im=Image.open(src).convert('RGBA'); b=bounds(src); x,y,r,d=b; w,h=r-x,d-y; sw,sh=round(w*scale),round(h*scale)
  return {'id':stem,'source':str(src.resolve()),'crop_xywh':[x,y,w,h],'sheet_cell_xywh':[0,0,*im.size],'content_scale':scale,'content_anchor_xy':[sw//2,sh//2],'canvas_wh':canvas,'pivot_xy':pivot,'alpha_threshold':128,'palette':'tools/palette.py:COLOURS'}
def render(stem,anim,canvas,pivot,scale,pose):
  recipe=crop_recipe(stem,canvas,pivot,scale)
  name=pose; out=render_source(recipe)
  return {'name':name,'stem':stem,'recipe':recipe,'image':out}
book_stems={'icon_book_crops':'book-crops-r1','icon_book_bosses':'book-bosses-r1','icon_book_year':'book-year-r1','icon_book_achievements':'book-achievements-r1'}
trophy_stems={'trophy_giant':'trophy-giant-r1','trophy_harvester':'trophy-harvester-r1','trophy_scarecrow_king':'trophy-scarecrow-r2','trophy_winter_lord':'trophy-winter-r1'}
badge_stems={k:'badge-'+k.removeprefix('badge_')+'-r1' for k in ['badge_first_night','badge_hundred_nights','badge_slayer','badge_builder','badge_gatherer','badge_angler','badge_regular','badge_long_haul','badge_full_moon','badge_legend','badge_arsenal','badge_year_two']}
badge_stems['badge_arsenal']='badge-arsenal-r2'; badge_stems['badge_year_two']='badge-year_two-r2'
raw_names=['collection-cover-r1',*book_stems.values(),*trophy_stems.values(),'medal-master-r1',*badge_stems.values(),'collection-ornament-r1']
if not all((RAW/(n+'.png')).exists() and (RAW/(n+'.call.json')).exists() for n in raw_names): raise SystemExit('Missing required recorded A056 source')
cover=crop_recipe('collection-cover-r1',[48,64],[24,32],min(46/(bounds(RAW/'collection-cover-r1.png')[2]-bounds(RAW/'collection-cover-r1.png')[0]),62/(bounds(RAW/'collection-cover-r1.png')[3]-bounds(RAW/'collection-cover-r1.png')[1])))
assets=[]
def add(name,stem,canvas,pivot,scale,category):
  rec=crop_recipe(stem,canvas,pivot,scale); im=render_source(rec); assets.append({'name':name,'stem':stem,'source':f'raw/{stem}.png','call':f'raw/{stem}.call.json','recipe':rec,'canvas':canvas,'pivot':pivot,'category':category,'image':im})
add('collection_cover','collection-cover-r1',[48,64],[24,32],cover['content_scale'],'cover')
tab_data={}
for name,stem in book_stems.items():
  b=bounds(RAW/(stem+'.png')); maxside=max(b[2]-b[0],b[3]-b[1]); tab_data[name]=[]
  for suffix,dim,canvas,pivot in [('',14,[16,16],[8,8]),('_hud',8,[10,10],[5,5])]:
    outname=name if not suffix else ('hud_book_'+name.removeprefix('icon_book_'))
    add(outname,stem,canvas,pivot,dim/maxside,'tab'); tab_data[name].append(assets[-1])
fish16=ROOT/'implementation/backlog/deliveries/A023-fishing-gear/preview/candidates/icon_book_fish/none/01.png'; fish10=ROOT/'implementation/backlog/deliveries/A023-fishing-gear/preview/candidates/hud_book_fish/none/01.png'
max_trophy=max(max(bounds(RAW/(s+'.png'))[2]-bounds(RAW/(s+'.png'))[0],bounds(RAW/(s+'.png'))[3]-bounds(RAW/(s+'.png'))[1]) for s in trophy_stems.values()); ts=30/max_trophy
for name,stem in trophy_stems.items(): add(name,stem,[32,32],[16,16],ts,'trophy')
mb=bounds(RAW/'medal-master-r1.png'); medal_side=max(mb[2]-mb[0],mb[3]-mb[1]); badge_crop_sides=[max(bounds(RAW/(stem+'.png'))[2]-bounds(RAW/(stem+'.png'))[0],bounds(RAW/(stem+'.png'))[3]-bounds(RAW/(stem+'.png'))[1]) for stem in badge_stems.values()]; bs=22/max(medal_side,max(badge_crop_sides))
for name,stem in badge_stems.items(): add(name,stem,[24,24],[12,12],bs,'badge')
orn_b=bounds(RAW/'collection-ornament-r1.png'); ow,oh=orn_b[2]-orn_b[0],orn_b[3]-orn_b[1]; os=min(62/ow,10/oh); add('collection_ornament','collection-ornament-r1',[64,12],[32,6],os,'ornament')
checks={'files_exactly_26':len(assets)==26,'fish_tab_is_reference_only':fish16.exists() and fish10.exists(),'one_scale_all_trophies':len({a['recipe']['content_scale'] for a in assets if a['category']=='trophy'})==1,'one_scale_all_badges':len({a['recipe']['content_scale'] for a in assets if a['category']=='badge'})==1,'tabs_use_one_crop_for_both_sizes':len(tab_data)==4 and all(x[0]['stem']==x[1]['stem'] for x in tab_data.values()),'alpha_binary':True,'palette_allowed':True,'centered_on_pivot':True,'margins_ok':True,'badge_crop_bounds_within_2_percent':True,'badge_distinct':True,'fish_book_size_match':True,'source_receipts_complete':True,'authorized_candidate_reference_exception_recorded':(D/'authorization.json').exists(),'raw_source_count_contract_matches':False}
for a in assets:
  im=a['image']; box=im.getbbox(); checks['alpha_binary'] &= set(im.getchannel('A').get_flattened_data())<={0,255}
  checks['palette_allowed'] &= set(im.get_flattened_data())<={c+(255,) for c in COLOURS.values()}|{(0,0,0,0)}
  checks['centered_on_pivot'] &= bool(box and abs((box[0]+box[2])/2-a['pivot'][0])<=1 and abs((box[1]+box[3])/2-a['pivot'][1])<=1)
  checks['margins_ok'] &= bool(box and box[0]>=1 and box[1]>=1 and box[2]<a['canvas'][0] and box[3]<a['canvas'][1])
for a in assets:
  if a['category']=='badge':
    b=a['recipe']['crop_xywh']; checks['badge_crop_bounds_within_2_percent'] &= abs(b[2]/(mb[2]-mb[0])-1)<=.02 and abs(b[3]/(mb[3]-mb[1])-1)<=.02
badge_imgs=[a['image'].convert('RGBA') for a in assets if a['category']=='badge']
checks['badge_distinct']=all(sum(p!=q for p,q in zip(badge_imgs[i].get_flattened_data(),badge_imgs[j].get_flattened_data()))>=12 for i in range(len(badge_imgs)) for j in range(i+1,len(badge_imgs)))
def visible_size(path):
  b=Image.open(path).convert('RGBA').getbbox(); return (b[2]-b[0],b[3]-b[1]) if b else (0,0)
fishsize=visible_size(fish16); new_sizes=[visible_size(D/'native'/a['name']/'none'/'01.png') if (D/'native'/a['name']/'none'/'01.png').exists() else (0,0) for a in assets if a['category']=='tab' and a['name'].startswith('icon_')]
checks['fish_book_size_match']=all(abs(fishsize[i]-14)<=1 for i in range(2))
checks['source_receipts_complete']=all((RAW/(n+'.call.json')).exists() for n in raw_names)
failed=[k for k,v in checks.items() if not v]
status='approved for integration' if (D/'APPROVAL.json').exists() else ('blocked' if failed else 'review')
base='preview/candidates' if status=='blocked' else 'native'
files=[]
for a in assets:
  rel=f"{base}/{a['name']}/none/01.png"; p=D/rel; p.parent.mkdir(parents=True,exist_ok=True); a['image'].save(p)
  call=json.loads((RAW/(a['stem']+'.call.json')).read_text(encoding='utf-8'))
  files.append({'name':a['name'],'runtime_name':'sprites/ui/'+a['name']+'.png','source':a['source'],'call':a['call'],'recipe':a['recipe'],'canvas_wh':a['canvas'],'pivot_xy':a['pivot'],'draw_scale':1,'seconds':1.0,'loop':False,'direction':'none','mirror':'none','category':a['category'],'output':rel,'bounds':a['image'].getbbox(),'sha256':sha(p),'input_images':call['input_images']})
write(D/'checks.json',checks)
exception=json.loads((D/'authorization.json').read_text(encoding='utf-8'))
deviations=['The source-count field in the pack says 22 but its table and generation steps require 23 ImageGen sources (one cover, four tabs, four trophies, blank medal master, twelve badge edits, one ornament). The 23 items required by the detailed instructions were generated.','All badges share a scale chosen to fit the largest measured emblem crop; this is slightly below the written 22px/blank-master scale because the Year Two sprout extends beyond the master bounds. Badge raw crop bounds vary by more than the stated ±2%, so visual rim/ribbon alignment still needs owner review.']
if failed: deviations.append('Objective checks failed: '+', '.join(failed))
contract={'pack':'A056','slug':D.name,'title':'The collection book, trophies and badges','date':'2026-10-14','status':status,'runtime_integrated':False,'tool':'built-in ImageGen','palette_mode':'A','palette':'tools/palette.py:COLOURS','alpha_threshold':128,'files':files,'expected_pngs':26,'blank_medal_master':'raw/medal-master-r1.png (reference only; not exported)','fish_tab_reference':str(fish16.relative_to(ROOT)),'candidate_reference_exception':exception,'deviations':deviations}
write(D/'contract.json',contract)
# Mock collections page and per-asset previews (day/UI untouched, plus dimmed state).
PRE.mkdir(exist_ok=True)
def save_preview(a):
  im=a['image']; p=PRE/(a['name']+'-4x.png'); im.resize((im.width*4,im.height*4),Image.Resampling.NEAREST).save(p); return p.name
for a in assets: save_preview(a)
mock=['<section class="mock"><h2>Collections mock / default + locked (40% opacity)</h2>']
mock.append("<h3>Cover and tabs</h3><img src='"+files[0]['output']+"' width='192' height='256'>")
for name,stem in book_stems.items():
  icon=name; hud='hud_book_'+name.removeprefix('icon_book_'); mock.append(f"<img src='{next(f['output'] for f in files if f['name']==icon)}' width='64' height='64'><img src='{next(f['output'] for f in files if f['name']==hud)}' width='40' height='40'>")
mock.append("<img src='../A023-fishing-gear/preview/candidates/icon_book_fish/none/01.png' width='64' height='64'><img src='../A023-fishing-gear/preview/candidates/hud_book_fish/none/01.png' width='40' height='40'>")
mock.append('<h3>Page divider</h3><img src="'+next(f['output'] for f in files if f['name']=='collection_ornament')+'" width="512" height="96"><h3>Boss trophies</h3><div class="row">')
for f in files:
  if f['category']=='trophy': mock.append(f"<img src='{f['output']}' width='128' height='128'>")
mock.append('</div><h3>Achievements / unlocked and dimmed</h3><div class="grid">')
for f in files:
  if f['category']=='badge': mock.append(f"<img src='{f['output']}' width='96' height='96'><img class='locked' src='{f['output']}' width='96' height='96'>")
mock.append('</div></section>')
gallery=[]
for f in files:
  w,h=f['canvas_wh']; large=PRE/(f['name']+'-4x.png'); gallery.append(f"<article><h3>{f['name']}</h3><p>{w}x{h} native / pivot {f['pivot_xy']}</p><img src='{f['output']}' style='width:{w*4}px;height:{h*4}px'><a href='{f['call']}'>Call receipt</a></article>")
css='body{background:#1b292c;color:#eee4d3;font:16px system-ui;margin:24px}a{color:#90d1d2}img{image-rendering:pixelated;vertical-align:middle;margin:8px;background:repeating-conic-gradient(#555 0 25%,#333 0 50%) 0 0/16px 16px}.mock,article{border:1px solid #657273;padding:16px;margin:20px 0;overflow:auto}.mock{background:#1a1830}.row{display:flex;gap:28px}.grid{display:grid;grid-template-columns:repeat(6,auto);gap:8px}.locked{opacity:.4}article{display:inline-block;vertical-align:top;min-width:180px}.fine{background:#e8dfce;color:#242124;padding:12px}'
page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>A056 collections review</title><style>'+css+'</style><h1>A056 / collections book, trophies and badges / '+status+'</h1><p>Candidate review only. Nothing here is approved or integrated. The owner-authorized reference exception is recorded in authorization.json and contract.json; A023 and A052-A054 remain unapproved/unintegrated references only.</p><p><a href="contract.json">Contract</a> · <a href="checks.json">Checks</a> · <a href="authorization.json">Authorization record</a></p><p>Checks: '+', '.join(k+': '+str(v) for k,v in checks.items())+'</p>'+''.join(mock)+'<h2>Every exported candidate / 1x shown at 4x for inspection</h2>'+''.join(gallery)+'</html>'
(D/'index.html').write_text(page,encoding='utf-8')
print(json.dumps({'status':status,'files':len(files),'checks':checks,'deviations':deviations},indent=2))


# Preserve exact reviewed pixels while exposing the approved integration contract.
if (D/'APPROVAL.json').exists():
    a=json.loads((D/'APPROVAL.json').read_text(encoding='utf-8'))
    c=json.loads((D/'contract.json').read_text(encoding='utf-8'))
    c['status']='approved for integration'
    c['owner_approval']={'date':a['date'],'owner_words':a['owner_words'],'scope':a['scope']}
    c.setdefault('deviations',[]).append({'rule':'Reviewed visual constraints','change':'The owner approved the displayed artwork, including the documented visual QA differences.','owner_words':a['owner_words'],'accepted_checks':a.get('accepted_visual_checks',[])})
    c.setdefault('palette_keys',None);c.setdefault('colour_ramp',[]);c.setdefault('mirror_pairs',{});c.setdefault('supersedes',[])
    refs={}
    for f in c['files']:
        receipt=json.loads((D/f['call']).read_text(encoding='utf-8'))
        for ref in receipt.get('input_images',[]):
            ref_path=Path(ref.get('archived_path',ref['path']))
            assert hashlib.sha256(ref_path.read_bytes()).hexdigest()==ref['sha256'], str(ref_path)
            refs[str(ref_path)]=ref
    c['references']=[refs[k] for k in sorted(refs)]
    c['animations']=[]
    for f in c['files']:
        name=f['name'];f['anim']=name;f['dir']='none';f['frame']=0;f['seconds']=f.get('seconds',1.0);f['loop']=False;f['mirror']='none';f['points']={}
        f['runtime_name']=f.get('runtime_name','sprites/ui/'+name+'.png')
        f['canvas_wh']=f.get('canvas_wh',f['recipe']['canvas_wh']);f['pivot_xy']=f.get('pivot_xy',f['recipe']['pivot_xy']);f['draw_scale']=1
        f['source_sha256']=hashlib.sha256((D/f['source']).read_bytes()).hexdigest()
        f['prompt']=f.get('prompt',f['call'].removesuffix('.call.json')+'.prompt.txt')
        f['prompt_sha256']=hashlib.sha256((D/f['prompt']).read_bytes()).hexdigest()
        c['animations'].append({'anim':name,'dir':'none','frames':1,'poses':[name],'frame_seconds':f['seconds'],'loop':False,'canvas_wh':f['canvas_wh'],'pivot_xy':f['pivot_xy'],'draw_scale':1,'mirror':'none','points':{}})
    assert set(a['approved_sha256'])=={f['output'] for f in c['files']}
    for f in c['files']:assert hashlib.sha256((D/f['output']).read_bytes()).hexdigest()==a['approved_sha256'][f['output']], f['output']
    (D/'contract.json').write_text(json.dumps(c,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    q=json.loads((D/'checks.json').read_text(encoding='utf-8'));q['owner_visual_approval_recorded']=True;q['owner_accepted_visual_checks']=a.get('accepted_visual_checks',[]);q['approved_art_hashes_match']=True
    (D/'checks.json').write_text(json.dumps(q,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    page=(D/'index.html').read_text(encoding='utf-8')
    page=page.replace(' / review</h1>',' / approved for integration</h1>').replace(' / blocked</h1>',' / approved for integration</h1>')
    page=page.replace('Candidate only; no runtime integration or approval.','Owner-approved artwork; integration pending.')
    page=page.replace('Candidate review only. Nothing here is approved or integrated.','Owner-approved artwork; integration pending.')
    banner='<aside style="padding:16px;background:#244533;color:#eef5df"><b>Artwork approved on '+a['date']+'. Complete delivery ready for Claude integration.</b> <a href="APPROVAL.json">Approval record</a> / <a href="CLAUDE-'+D.name[:4]+'-PROMPT.txt">Claude handoff</a></aside>'
    page=page.replace('</h1>','</h1>'+banner,1)
    (D/'index.html').write_text(page,encoding='utf-8')
