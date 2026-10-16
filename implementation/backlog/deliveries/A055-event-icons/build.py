"""Deterministic native-size reductions and local review page for A055."""
from pathlib import Path
from PIL import Image,ImageOps
import json,hashlib,sys
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

def write(p,v): p.write_text(json.dumps(v,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
ids=['fog','rain','blood_moon']; plans=[]; refs={}
for icon,stem in zip(ids,['fog-r1','rain-r1','blood-moon-r1']):
  call=json.loads((RAW/f'{stem}.call.json').read_text(encoding='utf-8')); raw=RAW/f'{stem}.png'; im=Image.open(raw).convert('RGBA'); mask=im.getchannel('A').point(lambda a:255 if a>=128 else 0); box=mask.getbbox(); x,y,r,b=box; w,h=r-x,b-y
  moon_full=Image.open(ROOT/'implementation/backlog/deliveries/A010-calendar-icons/native/icon_full_moon/none/01.png').convert('RGBA') if icon=='blood_moon' else None
  for target,dim,canvas,pivot in [('icon',14,[16,16],[8,8]),('hud',8,[10,10],[5,5])]:
    scale=dim/max(w,h); sw,sh=round(w*scale),round(h*scale)
    recipe={'id':f'{target}_{icon}','source':str(raw.resolve()),'crop_xywh':[x,y,w,h],'sheet_cell_xywh':[0,0,*im.size],'content_scale':scale,'content_anchor_xy':[sw//2,sh//2],'canvas_wh':canvas,'pivot_xy':pivot,'alpha_threshold':128,'palette':'tools/palette.py:COLOURS'}
    out=render_source(recipe); rel=f'native/{target}_{icon}/none/01.png'; p=D/rel; p.parent.mkdir(parents=True,exist_ok=True); out.save(p)
    plans.append({'name':f'{target}_{icon}','id':icon,'source':f'raw/{stem}.png','call':f'raw/{stem}.call.json','recipe':recipe,'output':rel,'bounds':out.getbbox(),'sha256':sha(p)})
  for ref in call.get('input_images',[]):
    q=Path(ref['path']); refs[str(q)]={'path':str(q),'sha256':sha(q),'role':ref['role']}
write(D/'contract.json',{'pack':'A055','slug':D.name,'title':'Fog, Rain and the Blood Moon','date':'2026-10-14','status':'review','runtime_integrated':False,'tool':'built-in ImageGen','palette_mode':'A','palette':'tools/palette.py:COLOURS','alpha_threshold':128,'files':plans,'references':list(refs.values())})
checks={'six_files':len(plans)==6,'canvas_and_pivot':all(Image.open(D/f['output']).size==tuple(f['recipe']['canvas_wh']) for f in plans),'binary_alpha':all(set(Image.open(D/f['output']).getchannel('A').get_flattened_data())<={0,255} for f in plans),'bounds_ok':all(f['bounds'] and f['bounds'][0]>=1 and f['bounds'][1]>=1 and f['bounds'][2]<=f['recipe']['canvas_wh'][0]-1 and f['bounds'][3]<=f['recipe']['canvas_wh'][1]-1 for f in plans),'palette_allowed':all(set(Image.open(D/f['output']).get_flattened_data())<={c+(255,) for c in COLOURS.values()}|{(0,0,0,0)} for f in plans),'pairs_from_same_source':all(plans[i]['source']==plans[i+1]['source'] for i in [0,2,4]),'blood_disc_matches_full_moon':False,'blood_moon_grayscale_distinct':False,'importer_recipe_matches':False,'rebuild_identical':False}
full=Image.open(ROOT/'implementation/backlog/deliveries/A010-calendar-icons/native/icon_full_moon/none/01.png').convert('RGBA')
blood=Image.open(D/'native/icon_blood_moon/none/01.png').convert('RGBA')
def count(im): return sum(a>0 for a in im.getchannel('A').getdata())
bb=blood.getbbox(); fb=full.getbbox()
checks['blood_disc_matches_full_moon']=abs((bb[2]-bb[0])-(fb[2]-fb[0]))<=1 and abs((bb[3]-bb[1]-1)-(fb[3]-fb[1]))<=1
def grey(im): return ImageOps.grayscale(im.convert('RGB'))
fullg,bloodg=grey(full),grey(blood); checks['blood_moon_grayscale_distinct']=sum(a!=b for a,b in zip(fullg.get_flattened_data(),bloodg.get_flattened_data()))>=5
for name,im in [('full-moon-grey',fullg),('blood-moon-grey',bloodg)]:
  out=Image.new('RGBA',im.size); out.putdata([(v,v,v,full.getpixel((i%im.width,i//im.width))[3]) for i,v in enumerate(im.get_flattened_data())]); out.resize((64,64),Image.Resampling.NEAREST).save(PRE/(name+'-8x.png'))
checks['importer_recipe_matches']=all(render_source(f['recipe']).tobytes()==Image.open(D/f['output']).convert('RGBA').tobytes() for f in plans)
checks['rebuild_identical']=checks['importer_recipe_matches'] and all(sha(D/f['output'])==f['sha256'] for f in plans)
write(D/'checks.json',checks)
items=[]
for f in plans:
  im=Image.open(D/f['output']).convert('RGBA'); large=im.resize((im.width*8,im.height*8),Image.Resampling.NEAREST); p=PRE/(f['name']+'-8x.png'); p.parent.mkdir(parents=True,exist_ok=True); large.save(p)
  items.append(f"<article><h2>{f['name']}</h2><img src='{f['output']}' width='{im.width*4}' height='{im.height*4}'><img src='preview/{p.name}'><p>Bounds {f['bounds']}; {im.width}x{im.height}, exact source crop and scale in contract.</p></article>")
full.resize((64,64),Image.Resampling.NEAREST).save(PRE/'full-moon-8x.png'); blood.resize((64,64),Image.Resampling.NEAREST).save(PRE/'blood-moon-8x.png')
page="<!doctype html><html lang='en'><meta charset='utf-8'><title>A055 event icons review</title><style>body{background:#1b292c;color:#eee4d3;font:16px system-ui;margin:24px}article{display:inline-block;vertical-align:top;padding:16px;margin:12px;border:1px solid #657273;background:#1a1830}img{image-rendering:pixelated;vertical-align:top;margin:8px;background:repeating-conic-gradient(#555 0 25%,#333 0 50%) 0 0/16px 16px}section{padding:12px;background:#eee;color:#222}a{color:#89ced0}</style><h1>A055 / Fog, Rain and Blood Moon / review</h1><p>Candidate only; no runtime integration or approval. Native 1x and 4x pixel-scaled views. HUD remains unchanged at night.</p><p><a href='contract.json'>Contract</a> · <a href='checks.json'>Checks</a></p><section><h2>Blood Moon vs Full Moon — grayscale cue check</h2><img src='preview/full-moon-8x.png'><img src='preview/blood-moon-8x.png'><br><img src='preview/full-moon-grey-8x.png'><img src='preview/blood-moon-grey-8x.png'></section>"+''.join(items)+"</html>"
(D/'index.html').write_text(page,encoding='utf-8')
print(json.dumps({'files':len(plans),'checks':checks},indent=2))


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
