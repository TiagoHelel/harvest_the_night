"""Recorded importer reductions and deterministic winter/spring review compositions."""
from pathlib import Path
import argparse,json,hashlib,io,sys,collections
from PIL import Image,ImageDraw
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];sys.path.insert(0,str(ROOT/'tools'))
from import_art import render_source
import palette
NAMES=['grass_winter','grass_b_winter','grass_c_winter','grass_d_winter','path_winter','soil_winter','tilled_winter','tilled_wet_winter','edge_n_winter','shore_n_winter','shore_corner_nw_winter']
OPAQUE=set(NAMES[:8]);GRASS=NAMES[:4]
def sha(b):return hashlib.sha256(b).hexdigest()
def encoded(im):
    s=io.BytesIO();im.save(s,format='PNG');return s.getvalue()
def night(im):
    out=im.copy()
    for y in range(im.height):
        for x in range(im.width):
            r,g,b,a=im.getpixel((x,y));v=[r/255*.36,g/255*.40,b/255*.82];grey=sum(c*k for c,k in zip(v,(.299,.587,.114)))
            out.putpixel((x,y),(*[round(max(0,min(1,grey+.76*(c-grey)+k))*255) for c,k in zip(v,(.04,.035,.105))],a))
    return out
def parts(points,diagonal=False):
    points=set(points);groups=[];ds=[(x,y) for x in [-1,0,1] for y in [-1,0,1] if (x or y) and (diagonal or abs(x)+abs(y)==1)]
    while points:
        todo=[points.pop()];group=set(todo)
        while todo:
            x,y=todo.pop()
            for dx,dy in ds:
                q=x+dx,y+dy
                if q in points:points.remove(q);group.add(q);todo.append(q)
        groups.append(group)
    return groups
def borders(im):return tuple(im.getpixel((x,0)) for x in range(16))+tuple(im.getpixel((x,15)) for x in range(16))+tuple(im.getpixel((0,y)) for y in range(16))+tuple(im.getpixel((15,y)) for y in range(16))
def mean(im):return sum(sum(p[:3])/3 for p in im.getdata())/256
def seamless(im):return all(im.getpixel((x,0))==im.getpixel((x,15)) and im.getpixel((0,x))==im.getpixel((15,x)) for x in range(16))
def field(tiles,winter):
    out=Image.new('RGBA',(384,224));kinds={}
    def current(name):return Image.open(ROOT/f'sprites/{"crops" if name.startswith("tilled") else "terrain"}/{name}.png').convert('RGBA')
    def art(name):return tiles.get(name+'_winter',current(name)) if winter else current(name)
    for y in range(14):
        for x in range(24):
            kind='path' if x in [11,12] or y==7 else 'soil' if 3<=x<=9 and 2<=y<=5 else 'water' if 16<=x<=21 and 2<=y<=6 else 'rock' if 18<=x<=21 and 10<=y<=12 else 'floor' if 3<=x<=8 and 10<=y<=12 else 'grass'
            kinds[x,y]=kind
            if kind=='grass':
                h=abs((x*73856093)^(y*19349663))%32;variant='grass_d' if h==31 else 'grass_c' if h>=25 else 'grass_b' if h>=18 else 'grass';tile=art(variant)
            else:tile=art(kind)
            out.alpha_composite(tile,(x*16,y*16))
            if kind=='soil' and 4<=x<=8 and 3<=y<=4:out.alpha_composite(art('tilled_wet' if x>=7 else 'tilled'),(x*16,y*16))
    neighbours=[(0,-1),(1,0),(0,1),(-1,0)];diags=[(-1,-1),(1,-1),(1,1),(-1,1)];adjacent=[9,3,6,12]
    for (x,y),kind in kinds.items():
        if kind=='grass':continue
        water=kind=='water';prefix='shore' if water else 'edge';side=art(prefix+'_n');mask=0
        for bit,(dx,dy) in enumerate(neighbours):
            other=kinds.get((x+dx,y+dy));touch=other is not None and (other!='water' if water else other=='grass')
            if touch:mask|=1<<bit;out.alpha_composite(side.rotate(-90*bit),(x*16,y*16))
        cap=art('shore_corner_nw') if water else Image.new('RGBA',(16,16))
        if not water:cap.alpha_composite(side.crop((0,0,1,1)),(0,0))
        for bit,(dx,dy) in enumerate(diags):
            other=kinds.get((x+dx,y+dy));touch=other is not None and (other!='water' if water else other=='grass')
            if not mask&adjacent[bit] and touch:out.alpha_composite(cap.rotate(-90*bit),(x*16,y*16))
    farmer=Image.open(ROOT/'implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png').convert('RGBA');out.alpha_composite(farmer,(140,124))
    return out
def build(check=False):
    recipes=json.loads((HERE/'recipes.json').read_text()) if (HERE/'recipes.json').exists() else [];tiles={};outputs={};files=[];animations=[];sections=[];references=json.loads((HERE/'references.json').read_text())
    def add(n,im):outputs[n]=encoded(im)
    provenance=True;raw_alpha=True;import_ok=True;quiet=True
    for r in recipes:
        name=r['anim'];im=render_source(r['importer']);tiles[name]=im;stem=r['stem'];source=HERE/f'raw/{stem}.png';callpath=HERE/f'raw/{stem}.call.json';call=json.loads(callpath.read_text());request=json.loads((HERE/f'raw/{stem}.request.json').read_text())
        provenance &= call['arguments']==request and sha(source.read_bytes())==call['raw_sha256'] and call['arguments']['prompt']==(HERE/f'raw/{stem}.prompt.txt').read_text(encoding='utf-8')
        lo,hi=Image.open(source).convert('RGBA').getchannel('A').getextrema();raw_alpha &= lo==255 if name in OPAQUE else lo==0 and hi>=128
        for ref in call['input_images']:
            p=Path(ref.get('retained_copy_path',ref['path']));p=p if p.is_absolute() else HERE/p;provenance &= p.exists() and sha(p.read_bytes())==ref['sha256'];references.append({'path':str(p),'sha256':ref['sha256'],'role':ref['role']})
        output=f'native/{name}/none/01.png';add(output,im);add(f'preview/{name}-day.png',im);add(f'preview/{name}-night.png',night(im));runtime='sprites/'+('crops/' if name.startswith('tilled') else 'terrain/')+name+'.png'
        files.append({'output':output,'sha256':sha(outputs[output]),'anim':name,'dir':'none','frame':0,'source':f'raw/{stem}.png','source_sha256':sha(source.read_bytes()),'prompt':f'raw/{stem}.prompt.txt','prompt_sha256':sha((HERE/f'raw/{stem}.prompt.txt').read_bytes()),'call':f'raw/{stem}.call.json','runtime_name':runtime,'recipe':r['importer'],'points':{}})
        animations.append({'anim':name,'dir':'none','frames':1,'poses':['Static winter '+name],'canvas_wh':[16,16],'pivot_xy':[8,16],'draw_scale':1,'frame_seconds':.55,'loop':False,'mirror':'none','points':{}})
        repeat=Image.new('RGBA',(96,64))
        for yy in range(4):
            for xx in range(6):repeat.alpha_composite(im,(16*xx,16*yy))
        add(f'preview/{name}-repeat.png',repeat)
        metadata=im.copy();md=ImageDraw.Draw(metadata);md.line((0,15,15,15),fill=(220,90,170,255));add(f'preview/{name}-metadata.png',metadata)
        sections.append(f'<section><h2>{name}</h2><img src="{output}"><img src="{output}" width="64"><img src="preview/{name}-night.png" width="64"><img src="preview/{name}-metadata.png" width="64"><br><img src="preview/{name}-repeat.png" width="384"></section>')
    complete=set(tiles)==set(NAMES);opaque=complete and all(all(p[3]==255 for p in tiles[n].getdata()) and seamless(tiles[n]) for n in OPAQUE)
    quiet=complete
    for n in NAMES[:6]:
        if n not in tiles:quiet=False;continue
        im=tiles[n];counts=collections.Counter(im.getdata());base,num=counts.most_common(1)[0];need=232 if n in GRASS else 220 if n=='path_winter' else 200
        quiet &= num>=need and all(len(p)>=2 for p in parts({(x,y) for y in range(16) for x in range(16) if im.getpixel((x,y))!=base},True))
    overlay=complete
    for n in NAMES[8:]:
        if n not in tiles:overlay=False;continue
        im=tiles[n];p={(x,y) for y in range(16) for x in range(16) if im.getpixel((x,y))[3]};b=im.getbbox()
        overlay &= bool(p) and (0,0) in p and len(parts(p))==1 and b[0]==0 and b[1]==0 and b[3]<=3 and all(im.getpixel((0,y))==im.getpixel((15,y)) for y in range(16)) if n!='shore_corner_nw_winter' else bool(p) and (0,0) in p and len(parts(p))==1 and b[2]<=3 and b[3]<=3
        if n!='shore_corner_nw_winter':overlay &= b[2]==16 and all((x,0) in p for x in range(16))
        if n=='edge_n_winter':overlay &= all((0,y) not in p and (15,y) not in p for y in range(1,16))
    if complete:
        corner=tiles[NAMES[-1]];shore=tiles['shore_n_winter'];overlay &= all(corner.getpixel((0,y))==shore.getpixel((0,y)) and corner.getpixel((y,0))==shore.getpixel((0,y)) for y in range(16))
    rows=[1,4,5,8,9,12,13];grooves=[2,3,6,7,10,11,14,15]
    def rowmean(im,ys):return sum(sum(im.getpixel((x,y))[:3])/3 for y in ys for x in range(16))/(16*len(ys))
    checks={'frames_expected':11,'frames_found':len(tiles),'full_pack_complete':complete,'canvas_and_pivot_consistent':all(im.size==(16,16) for im in tiles.values()),'one_scale_per_animation':True,'binary_alpha':all(p[3] in [0,255] for im in tiles.values() for p in im.getdata()),'no_empty_frame':all(im.getbbox() for im in tiles.values()),'colours_allowed':all(p[:3] in palette.COLOURS.values() for im in tiles.values() for p in im.getdata() if p[3]),'importer_recipe_matches':all(render_source(r['importer']).tobytes()==tiles[r['anim']].tobytes() for r in recipes),'grounded_on_pivot':True,'mirror_pairs_exact':True,'points_on_opaque':True,'provenance_hashes_match':bool(provenance),'raw_alpha_correct':bool(raw_alpha),'opaque_and_seamless':bool(opaque),'quiet_cluster_density':bool(quiet),'overlay_geometry':bool(overlay),'grass_border_pairs_match':complete and all(borders(tiles[n])==borders(tiles[GRASS[0]]) for n in GRASS),'grass_scale_shared':len({r['importer']['content_scale'] for r in recipes if r['anim'] in GRASS})==1 and sum(r['anim'] in GRASS for r in recipes)==4,'opaque_tiles_distinct':complete and len({tiles[n].tobytes() for n in OPAQUE})==8,'snow_above_path_soil':complete and all(mean(tiles['grass_winter'])>=mean(tiles[n])+25 for n in ['path_winter','soil_winter']),'furrow_rows_preserved':complete and all(rowmean(tiles[n],rows)>rowmean(tiles[n],grooves) for n in ['tilled_winter','tilled_wet_winter']),'wet_darker_by_20':complete and mean(tiles['tilled_winter'])>=mean(tiles['tilled_wet_winter'])+20}
    if complete:
        for label,winter in [('winter',True),('spring',False)]:
            scene=field(tiles,winter);add('preview/'+label+'-field-day.png',scene);add('preview/'+label+'-field-night.png',night(scene));grid=scene.copy();dr=ImageDraw.Draw(grid)
            for x in range(0,384,16):dr.line((x,0,x,223),fill=(88,94,100,255))
            for y in range(0,224,16):dr.line((0,y,383,y),fill=(88,94,100,255))
            add('preview/'+label+'-field-grid.png',grid)
            sections.insert(0,f'<section><h2>{label} field / farmer soles on row160</h2><button onclick="this.nextElementSibling.classList.toggle(\'grid\')">Toggle16px grid</button><div><img class="plain" src="preview/{label}-field-day.png"><img class="gridded" src="preview/{label}-field-grid.png"><br><img src="preview/{label}-field-night.png"><br><img src="preview/{label}-field-day.png" width="1536"></div></section>')
    proof=json.loads((HERE/'determinism.json').read_text()).get('artifacts',{}) if (HERE/'determinism.json').exists() else {};checks['rebuild_identical']=bool(proof) and all(n in outputs and sha(outputs[n])==v for n,v in proof.items());failed=[k for k,v in checks.items() if v is False]
    contract={'pack':'A012','slug':HERE.name,'date':'2026-10-07','status':'review' if not failed else 'generating','runtime_integrated':False,'final_approval_pending':True,'palette_mode':'A','palette':'tools/palette.py:COLOURS','alpha_threshold':128,'tool':'built-in ImageGen','references':list({(r['path'],r['sha256']):r for r in references}.values()),'animations':animations,'files':files,'mirror_pairs':{},'deviations':[],'supersedes':[],'exemptions':{'grounded_on_pivot':'Ground tiles cover cells; alpha overlays attach to the north edge, not to actor feet.','points_on_opaque':'Static terrain has no gameplay attachment points.','mirror_pairs_exact':'No mirrored deliverables; rotated edge/shore pieces shown only in review compositions.'}}
    page='<html lang="en"><meta charset="utf-8"><title>A012 winter ground</title><style>body{background:#1b2527;color:#e8e0cf;font:16px system-ui;margin:24px}img{image-rendering:pixelated;margin:10px;vertical-align:top}section{border-top:1px solid #52605e;padding:16px}.gridded{display:none}.grid .plain{display:none}.grid .gridded{display:inline}a{color:#a8dbbc}</style><h1>A012 winter ground / final review pending</h1><p>'+str(len(tiles))+' of11tiles; failed checks: '+(', '.join(failed) or 'none')+'</p><a href="contract.json">Contract</a> <a href="checks.json">Checks</a>'+''.join(sections)+'</html>'
    approval_path=HERE/'APPROVAL.json'
    if approval_path.exists():
        approval=json.loads(approval_path.read_text(encoding='utf-8'))
        expected={f['output']:f['sha256'] for f in files}
        if (approval.get('pack')!='A012' or approval.get('status')!='approved for integration'
                or approval.get('approved_folder')!=HERE.relative_to(ROOT).as_posix()
                or not approval.get('owner_words') or approval.get('frames')!=len(files)
                or approval.get('approved_sha256')!=expected or failed):
            raise SystemExit('Approval does not match the complete, passing export.')
        contract['status']='approved for integration'
        contract['final_approval_pending']=False
        contract['approval']='APPROVAL.json'
        page=page.replace('A012 winter ground / final review pending','A012 winter ground / approved for integration')
    outputs['index.html']=page.encode();outputs['contract.json']=(json.dumps(contract,indent=2)+'\n').encode();outputs['checks.json']=(json.dumps(checks,indent=2)+'\n').encode();outputs['build-manifest.json']=(json.dumps(sorted(list(outputs)+['build-manifest.json']),indent=2)+'\n').encode()
    changed=[n for n,b in outputs.items() if not (HERE/n).exists() or (HERE/n).read_bytes()!=b]
    if check and changed:raise SystemExit('Rebuild mismatch: '+','.join(changed))
    if not check:
        for n,b in sorted(outputs.items()):(HERE/n).parent.mkdir(parents=True,exist_ok=True);(HERE/n).write_bytes(b)
    print(json.dumps({'frames':len(tiles),'failed_checks':failed,'identical':not changed,'check':check}))
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--check',action='store_true');build(p.parse_args().check)
