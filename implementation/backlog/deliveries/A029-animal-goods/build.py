"""Deterministic mode-A icon exports using the project's importer unchanged."""
from pathlib import Path
import argparse,json,hashlib,io,sys
from PIL import Image,ImageDraw
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
sys.path.insert(0,str(ROOT/'tools'))
from import_art import render_source
import palette
from static_checks import enrich
IDS=['egg', 'milk', 'wool', 'truffle', 'truffle_spot']
def digest(data):return hashlib.sha256(data).hexdigest()
def png(im):
    out=io.BytesIO();im.save(out,format='PNG');return out.getvalue()
def night(im):
    im=im.copy()
    for y in range(im.height):
        for x in range(im.width):
            r,g,b,a=im.getpixel((x,y));lit=(r/255*.36,g/255*.4,b/255*.82);grey=sum(v*k for v,k in zip(lit,(.299,.587,.114)))
            im.putpixel((x,y),(*[round(max(0,min(1,grey+.76*(v-grey)+k))*255) for v,k in zip(lit,(.04,.035,.105))],a))
    return im
def candidate(stem):
    source=HERE/f'raw/{stem}.png';im=Image.open(source).convert('RGBA');assert im.getchannel('A').getextrema()==(0,255)
    box=im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox();x,y,xe,ye=box;w,h=xe-x,ye-y
    asset=stem.rsplit('-r',1)[0];pair=[];sheet=Image.new('RGBA',(220,120),(26,24,48,255));d=ImageDraw.Draw(sheet)
    cuts=[('prop',16,12)] if asset=='truffle_spot' else [('icon',16,14),('hud',10,8)]
    for prefix,size,visible in cuts:
        scale=visible/w if prefix=='prop' else visible/max(w,h);sw,sh=round(w*scale),round(h*scale)
        recipe={'id':'A029/'+prefix+'_'+asset,'source':source.relative_to(ROOT).as_posix(),'crop_xywh':[x,y,w,h],'content_scale':scale,'content_anchor_xy':[sw//2,sh//2],'alpha_threshold':128,'palette':'tools/palette.py:COLOURS','palette_keys':sorted(palette.COLOURS),'canvas_wh':[size,size],'pivot_xy':[size//2,size//2]}
        if prefix=='prop':recipe.update(pivot_xy=[8,14],content_anchor_xy=[sw//2,sh],id='A029/truffle_spot')
        native=render_source(recipe);pair.append({'anim':asset if prefix=='prop' else prefix+'_'+asset,'asset':asset,'stem':stem,'importer':recipe})
        origin=8 if prefix=='icon' else 125;sheet.alpha_composite(native,(origin,24));sheet.alpha_composite(native.resize((size*4,size*4),Image.Resampling.NEAREST),(origin,48));d.text((origin,4),prefix+' '+str(native.getbbox()),fill=(230,221,197))
    sheet.save(HERE/f'preview/{stem}-candidate.png');(HERE/f'preview/{stem}-recipes.json').write_text(json.dumps(pair,indent=2)+'\n')
    print(json.dumps({'stem':stem,'crop':box,'native_bounds':[render_source(r['importer']).getbbox() for r in pair]}))
def build(check=False):
    recipes=json.loads((HERE/'recipes.json').read_text()) if (HERE/'recipes.json').exists() else []
    outputs={};files=[];animations=[];frames={};bounds_ok=True;margin_ok=True;pair_ok=True
    def add(name,im):outputs[name]=png(im)
    farmer=Image.open(ROOT/'implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png').convert('RGBA');add('preview/farmer.png',farmer)
    grass=Image.open(ROOT/'sprites/terrain/grass.png').convert('RGBA');panel=Image.open(ROOT/'sprites/ui/panel.png').convert('RGBA')
    for r in recipes:
        entry=r['importer'];im=render_source(entry);anim=r['anim'];size=im.width;bb=im.getbbox();x,y,xe,ye=bb;limit=14 if size==16 else 8;frames[anim]=im
        bounds_ok &= (11<=xe-x<=13 and 7<=ye-y<=9 and ye==14 and abs((x+xe)/2-8)<=1) if anim=='truffle_spot' else (xe-x<=limit and ye-y<=limit and abs((x+xe)/2-size/2)<=1 and abs((y+ye)/2-size/2)<=1)
        margin_ok &= min(x,y)>=1 and max(xe,ye)<=size-1
        name='native/'+anim+'/none/01.png';add(name,im)
        stem=r['stem'];source=f'raw/{stem}.png';prompt=f'raw/{stem}.prompt.txt';call=f'raw/{stem}.call.json'
        files.append({'output':name,'sha256':digest(outputs[name]),'runtime_name':anim,'anim':anim,'dir':'none','frame':0,'source':source,'source_sha256':digest((HERE/source).read_bytes()),'prompt':prompt,'prompt_sha256':digest((HERE/prompt).read_bytes()),'call':call,'recipe':{**{k:v for k,v in entry.items() if k not in ['id','source','canvas_wh','pivot_xy']},'mirrored_from':None},'points':{}})
        animations.append({'anim':anim,'dir':'none','frames':1,'poses':['Static '+r['asset']],'frame_seconds':.55 if anim=='truffle_spot' else 1,'loop':False,'canvas_wh':[size,size],'pivot_xy':entry['pivot_xy'],'draw_scale':1,'mirror':'none','points':{}})
        for label,colour in [('light',(223,221,208,255)),('dark',(26,24,48,255)),('night_light',(46,42,78,255)),('checker',(42,51,54,255)),('grass',None),('panel',None)]:
            bg=Image.new('RGBA',(size,size),colour or (0,0,0,0));d=ImageDraw.Draw(bg)
            if label=='checker':
                for yy in range(0,size,4):
                    for xx in range(0,size,4):
                        if (xx//4+yy//4)%2:d.rectangle((xx,yy,xx+3,yy+3),fill=(76,85,87,255))
            if label in ['grass','panel']:bg.alpha_composite((grass if label=='grass' else panel).crop((0,0,size,size)))
            bg.alpha_composite(im);add(f'preview/{anim}-{label}.png',bg)
        add(f'preview/{anim}-world-night.png',night(im));add(f'preview/{anim}-day.png',im)
        overlay=im.copy();ImageDraw.Draw(overlay).rectangle((x,y,xe-1,ye-1),outline=(232,91,211,255));add(f'preview/{anim}-metadata.png',overlay)
    for asset in IDS:
        pair=[r for r in recipes if r['asset']==asset]
        if pair and asset!='truffle_spot':pair_ok &= len(pair)==2 and pair[0]['importer']['source']==pair[1]['importer']['source'] and pair[0]['importer']['crop_xywh']==pair[1]['importer']['crop_xywh']
    refs=json.loads((HERE/'references.json').read_text());checks={'frames_expected':9,'frames_found':len(frames),'full_pack_complete':len(frames)==9,'canvas_and_pivot_consistent':all(r['importer']['canvas_wh'] in [[16,16],[10,10]] for r in recipes),'one_scale_per_animation':True,'binary_alpha':all(p[3] in [0,255] for im in frames.values() for p in im.getdata()),'no_empty_frame':all(im.getbbox() is not None for im in frames.values()),'colours_allowed':all(p[:3] in palette.COLOURS.values() for im in frames.values() for p in im.getdata() if p[3]),'grounded_on_pivot':True,'mirror_pairs_exact':True,'points_on_opaque':True,'importer_recipe_matches':all(render_source(r['importer']).tobytes()==frames[r['anim']].tobytes() for r in recipes),'icon_bounds_ok':bool(bounds_ok),'icon_margin_ok':bool(margin_ok),'same_crop_per_pair':bool(pair_ok)}
    proofs=json.loads((HERE/'determinism.json').read_text()).get('artifacts',{}) if (HERE/'determinism.json').exists() else {}
    checks['rebuild_identical']=bool(proofs) and all(name in outputs and digest(outputs[name])==hash_ for name,hash_ in proofs.items())
    for row,ids in [('hotbar',IDS[:8]),('hud',IDS[8:]),('all-inventory',IDS),('all-compact',IDS)]:
        prefix='hud' if row in ['hud','all-compact'] else 'icon';size=10 if prefix=='hud' else 16;strip=Image.new('RGBA',(len(ids)*24+8,32),(26,24,48,255))
        for i,asset in enumerate(ids):
            im=frames.get(prefix+'_'+asset)
            if im:strip.alpha_composite(im,(8+i*24,8))
        add('preview/'+row+'.png',strip)
    # Regenerate proof-listed scene images as part of the deterministic payload.
    if proofs:checks['rebuild_identical']=all(name in outputs and digest(outputs[name])==hash_ for name,hash_ in proofs.items())
    failed=[key for key,value in checks.items() if value is False]
    contract={'pack':'A029','slug':HERE.name,'title':'Animal goods','date':'2026-10-07','status':'review' if not failed else 'generating','runtime_integrated':False,'palette_mode':'A','palette':'tools/palette.py:COLOURS','palette_keys':None,'colour_ramp':[],'alpha_threshold':128,'tool':'built-in ImageGen','references':refs,'animations':animations,'mirror_pairs':{},'files':files,'deviations':[],'supersedes':[],'exemptions':{'grounded_on_pivot':'UI icons are centred on their visual pivot; no ground contact.','points_on_opaque':'No gameplay points required for static icons.'},'final_approval_pending':True}
    parts=[]
    for asset in IDS:
        row=[]
        for prefix,size in [('icon',16),('hud',10)]:
            anim=prefix+'_'+asset
            if anim not in frames:continue
            visuals=''.join(f'<figure>{label}<br><img src="preview/{anim}-{label}.png" width="{size*4}" height="{size*4}"></figure>' for label in ['day','light','dark','night_light','checker','panel','grass','world-night','metadata'])
            row.append(f'<div class="row"><figure>{size}x{size} native 1x<br><img src="native/{anim}/none/01.png" width="{size}" height="{size}"></figure>{visuals}</div>')
        family=ROOT/f'sprites/buildings/{asset+"_join_10" if asset in ["wall","fence"] else asset}.png'
        if family.exists():
            im=Image.open(family).convert('RGBA');add('preview/'+asset+'-world.png',im);row.append(f'<p>Defence identity at draw scale 1</p><img src="preview/{asset}-world.png" width="{im.width}"><img src="preview/{asset}-world.png" width="{im.width*4}">')
        if row:parts.append('<section><h2>'+asset+'</h2>'+''.join(row)+'</section>')
    # The proof covers exported pixels and scenes; JSON/HTML are additionally compared by --check.
    for legacy in ['wood','iron','money']:
        for prefix in ['icon','hud']:add('preview/legacy-'+prefix+'_'+legacy+'.png',Image.open(ROOT/f'sprites/ui/{prefix}_{legacy}.png').convert('RGBA'))
    if proofs:checks['rebuild_identical']=all(name in outputs and digest(outputs[name])==hash_ for name,hash_ in proofs.items())
    failed=[k for k,v in checks.items() if v is False];contract['status']='review' if not failed else 'generating'
    rejected=''.join('<p>'+p.stem.replace('.reason','')+': '+p.read_text()+'</p>' for p in sorted((HERE/'rejected').glob('*.reason.txt')))
    mock=''.join(f'<figure>{label}<br><img src="preview/{label}.png"><br><img src="preview/{label}.png" style="width:{(len(IDS[:8]) if label=="hotbar" else len(IDS[8:]) if label=="hud" else len(IDS))*96+32}px"></figure>' for label in ['hotbar','hud','all-inventory','all-compact'])
    comparison=''.join(f'<img src="preview/legacy-{prefix}_{legacy}.png" width="{64 if prefix=="icon" else 40}">' for legacy in ['wood','iron','money'] for prefix in ['icon','hud'])
    page='<!doctype html><html lang="en"><meta charset="utf-8"><title>A029 / animal goods</title><style>body{background:#1b2527;color:#e7dfcb;font:16px system-ui;margin:28px}img{image-rendering:pixelated}a{color:#a8dbbc}.row{display:flex;gap:20px;align-items:end;flex-wrap:wrap}figure{margin:10px 0}section{border-top:1px solid #475854;padding:15px 0}</style><h1>A029 / animal goods / final review pending</h1><p>'+str(len(frames))+' of 9 files. Known incomplete checks: '+(', '.join(failed) or 'none')+'. World relight is for reference only: the HUD is not relit.</p><p><a href="contract.json">Contract</a> Â· <a href="checks.json">Checks</a> Â· <a href="review-log.txt">Review log</a></p><div class="row">'+mock+'</div><h2>Approved resource icons</h2>'+comparison+'<h2>Farmer scale</h2><img src="preview/farmer.png"><img src="preview/farmer.png" width="160">'+''.join(parts)+'<details><summary>Rejected</summary>'+rejected+'</details></html>'
    extras=enrich(HERE,ROOT,frames,recipes,outputs,contract,checks,add,night)
    if proofs:checks['rebuild_identical']=all(name in outputs and digest(outputs[name])==hash_ for name,hash_ in proofs.items())
    failed=[k for k,v in checks.items() if v is False];contract['status']='review' if not failed else 'generating'
    page=page.replace('</html>','<p>Current QA failures: '+(', '.join(failed) or 'none')+'</p>'+extras+'</html>')
    approval_path=HERE/'APPROVAL.json'
    if approval_path.exists():
        approval=json.loads(approval_path.read_text(encoding='utf-8'))
        expected={f['output']:f['sha256'] for f in files}
        if (approval.get('pack')!='A029' or approval.get('status')!='approved for integration'
                or approval.get('approved_folder')!=HERE.relative_to(ROOT).as_posix()
                or not approval.get('owner_words') or approval.get('frames')!=9
                or approval.get('approved_sha256')!=expected or failed):
            raise SystemExit('Approval does not match the complete, passing export.')
        contract['status']='approved for integration'
        contract['final_approval_pending']=False
        contract['approval']='APPROVAL.json'
        page=page.replace('A029 / animal goods / final review pending','A029 / animal goods / approved for integration')
    outputs['build-manifest.json']=(json.dumps(sorted(list(outputs)+['index.html','contract.json','checks.json','build-manifest.json']),indent=2)+'\n').encode()
    outputs['index.html']=page.encode();outputs['contract.json']=(json.dumps(contract,indent=2)+'\n').encode();outputs['checks.json']=(json.dumps(checks,indent=2)+'\n').encode()
    changes=[name for name,data in outputs.items() if not (HERE/name).exists() or (HERE/name).read_bytes()!=data]
    if check and changes:raise SystemExit('Rebuild mismatch: '+', '.join(changes))
    if not check:
        for name,data in sorted(outputs.items()):
            p=HERE/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
    print(json.dumps({'frames':len(frames),'failed_checks':failed,'identical':not changes,'check':check}))
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--candidate');p.add_argument('--check',action='store_true');args=p.parse_args()
    if args.candidate:candidate(args.candidate)
    else:build(args.check)
