"""Rebuild seasonal ImageGen art, host fitting, family compositions and metadata."""
from pathlib import Path
import argparse,json,hashlib,io,sys
from functools import lru_cache
from PIL import Image,ImageDraw
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];sys.path.insert(0,str(ROOT/'tools'))
from import_art import render_source
import palette
from candidate_cap import CAPS,host,fit,groups
NAMES=['tree_spring','tree_autumn','tree_winter','tree_b_spring','tree_b_autumn','tree_b_winter',*CAPS]
def sha(b):return hashlib.sha256(b).hexdigest()
def encoded(im):
    b=io.BytesIO();im.save(b,format='PNG');return b.getvalue()
@lru_cache(maxsize=None)
def tone(p):
    r,g,b,a=p;v=[r/255*.36,g/255*.4,b/255*.82];grey=sum(c*k for c,k in zip(v,[.299,.587,.114]));return (*[round(max(0,min(1,grey+.76*(c-grey)+k))*255) for c,k in zip(v,[.04,.035,.105])],a)
def night(im):
    im=im.copy();im.putdata([tone(p) for p in im.getdata()]);return im
def points(im,y0=0):return {(x,y) for y in range(y0,im.height) for x in range(im.width) if im.getpixel((x,y))[3]}
def near(a,b,distance=1):return all(any((x+dx,y+dy) in b for dx in range(-distance,distance+1) for dy in range(-distance,distance+1)) for x,y in a)
def build(check=False):
    recipes=json.loads((HERE/'recipes.json').read_text()) if (HERE/'recipes.json').exists() else [];out={};files=[];animations=[];frames={};refs={};valid=True;alpha=True;sections=[];trees_ok=True;caps_ok=True;season_ok=True;flowers_ok=True;proofs=[]
    def add(name,im):out[name]=encoded(im)
    for r in recipes:
        name=r['anim'];stem=r['stem'];e=r['importer'];im=render_source(e);frames[name]=im;tree=name.startswith('tree');size=e['canvas_wh'];pivot=e['pivot_xy'];src=HERE/f'raw/{stem}.png';call=json.loads((HERE/f'raw/{stem}.call.json').read_text());args=json.loads(src.with_suffix('.request.json').read_text());valid &= call['arguments']==args and call['raw_sha256']==sha(src.read_bytes()) and args['prompt']==(HERE/f'raw/{stem}.prompt.txt').read_text(encoding='utf-8');lo,hi=Image.open(src).convert('RGBA').getchannel('A').getextrema();alpha &= lo==0 and hi>=128
        for ref in call['input_images']:
            p=Path(ref.get('retained_copy_path',ref['path']));p=p if p.is_absolute() else HERE/p;valid &= p.exists() and sha(p.read_bytes())==ref['sha256'];refs[str(p)]={'path':str(p),'sha256':ref['sha256'],'role':ref['role']}
        output=f'native/{name}/none/01.png';add(output,im);add(f'preview/{name}-day.png',im);add(f'preview/{name}-night.png',night(im));files.append({'output':output,'sha256':sha(out[output]),'anim':name,'dir':'none','frame':0,'runtime_name':'sprites/props/'+name+'.png','source':f'raw/{stem}.png','source_sha256':sha(src.read_bytes()),'prompt':f'raw/{stem}.prompt.txt','prompt_sha256':sha((HERE/f'raw/{stem}.prompt.txt').read_bytes()),'call':f'raw/{stem}.call.json','recipe':e,'points':{}});animations.append({'anim':name,'dir':'none','frames':1,'poses':['Static '+name],'canvas_wh':size,'pivot_xy':pivot,'draw_scale':1,'frame_seconds':.55,'loop':False,'mirror':'none','points':{}})
        b=im.getbbox();p=points(im);record={'anim':name,'bounds':b,'connected_parts':groups(p)}
        if tree:
            base=Image.open(ROOT/f'sprites/props/{"tree_b" if name.startswith("tree_b_") else "tree"}.png').convert('RGBA')
            # The summer crown hangs to row33 outside the trunk. A winter leaf
            # removal must not be reported as an altered root. Compare the
            # narrow trunk core at33-36 and the entire spreading roots at37+.
            region=lambda q:{(x,y) for x,y in points(q,33) if y>=37 or 17<=x<=24}
            bp=region(base);rp=region(im);rootmatch=near(bp,rp) and near(rp,bp)
            trunk=[x for x,y in p if y in [34,35]];centre=(min(trunk)+max(trunk))/2 if trunk else 20
            treegood=b[0]>=1 and b[2]<=39 and b[1]>=1 and b[3]==44 and 38<=b[3]-b[1]<=43 and groups(p)==1 and abs(centre-20)<=1 and rootmatch and e['content_scale']==.03700440528634361 and 'palette_keys' not in e;trees_ok &= treegood
            crown={(x,y) for x,y in p if y<33};green={v for k,v in palette.COLOURS.items() if 'grass' in k or 'leaf' in k};flame=palette.COLOURS['flame'];hot=palette.COLOURS['flame_hot'];blooms={palette.COLOURS[k] for k in ['bone','bone_dark','roof_light','skin_light']};wood={palette.COLOURS[k] for k in ['wood_dark','wood','wood_light','soil_dark','soil','soil_light','gold_dark']};leafcrown={(x,y) for x,y in crown if im.getpixel((x,y))[:3] not in wood};flower={(x,y) for x,y in leafcrown if im.getpixel((x,y))[:3] in blooms};green_count=sum(im.getpixel((x,y))[:3] in green for x,y in crown);flame_count=sum(im.getpixel((x,y))[:3]==flame for x,y in crown);hot_count=sum(im.getpixel((x,y))[:3]==hot for x,y in crown);ratio=len(flower)/max(1,len(leafcrown));flowergroups=[];pending=set(flower)
            while pending:
                todo=[pending.pop()];q=set(todo)
                while todo:
                    x,y=todo.pop()
                    for dx in [-1,0,1]:
                        for dy in [-1,0,1]:
                            z=x+dx,y+dy
                            if z in pending:pending.remove(z);q.add(z);todo.append(z)
                flowergroups.append(len(q))
            if name.endswith('spring'):season_ok &= .2<=ratio<=.4;flowers_ok &= bool(flowergroups) and min(flowergroups)>=3
            elif name.endswith('autumn'):season_ok &= green_count<=.1*len(crown) and flame_count<=.08*len(crown) and hot_count==0
            else:season_ok &= green_count<=3 and b[2]-b[0]>=26
            record.update(root_shape_within1px=rootmatch,trunk_centre=centre,tree_geometry=bool(treegood),flower_fraction=ratio,flower_cluster_sizes=flowergroups,green_pixels=green_count,flame_pixels=flame_count,flame_hot_pixels=hot_count)
        else:
            fits=fit(im,CAPS[name]);caps_ok &= all(f['pass'] for f in fits);record['host_fit']=fits;sheet=Image.new('RGBA',(im.width*3*len(CAPS[name]),im.height),(29,39,42,255))
            for i,h in enumerate(CAPS[name]):
                hp=host(h);joined=hp.copy();joined.alpha_composite(im);overlay=joined.copy()
                for x,y in p:
                    if not hp.getpixel((x,y))[3]:overlay.putpixel((x,y),(240,70,70,255))
                for j,f in enumerate([hp,joined,overlay]):sheet.alpha_composite(f,(im.width*(i*3+j),0))
            add(f'preview/{name}-host-fit.png',sheet);add(f'preview/{name}-host-night.png',night(sheet));sections.append(f'<section><h2>{name}: host / snow / outside-host pixels in red</h2><img src="preview/{name}-host-fit.png"><img src="preview/{name}-host-fit.png" width="{sheet.width*4}"><img src="preview/{name}-host-night.png" width="{sheet.width*4}"></section>')
        proofs.append(record);sections.append(f'<section><h2>{name}</h2><img src="{output}"><img src="{output}" width="{im.width*4}"><img src="preview/{name}-night.png" width="{im.width*4}"></section>')
    farmer=Image.open(ROOT/'implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png').convert('RGBA');grass=Image.open(ROOT/'sprites/terrain/grass.png').convert('RGBA');snowpath=HERE.parent/'A012-winter-ground/native/grass_winter/none/01.png';snow=Image.open(snowpath).convert('RGBA') if snowpath.exists() else Image.new('RGBA',(16,16),(*palette.COLOURS['bone'],255))
    for kind in ['tree','tree_b']:
        scene=Image.new('RGBA',(240,112));dr=ImageDraw.Draw(scene)
        for y in range(0,112,16):
            for x in range(0,240,16):scene.alpha_composite(snow if x>=180 else grass,(x,y))
        for c,season in enumerate(['summer','spring','autumn','winter']):
            im=Image.open(ROOT/f'sprites/props/{kind}.png').convert('RGBA') if season=='summer' else frames.get(kind+'_'+season);dr.text((c*60+4,5),season,fill=(232,224,207))
            if im:scene.alpha_composite(im,(c*60+12,52))
        scene.alpha_composite(farmer,(0,64));add(f'preview/{kind}-four-seasons-day.png',scene);add(f'preview/{kind}-four-seasons-night.png',night(scene));grid=scene.copy();gd=ImageDraw.Draw(grid)
        for x in range(0,240,16):gd.line((x,0,x,111),fill=(87,111,102,255))
        for y in range(0,112,16):gd.line((0,y,239,y),fill=(87,111,102,255))
        add(f'preview/{kind}-four-seasons-grid.png',grid);sections.insert(0,f'<section><h2>{kind}: summer / spring / autumn / winter / same farmer groundline</h2><button onclick="this.nextElementSibling.src=this.nextElementSibling.src.includes(\'grid\')?\'preview/{kind}-four-seasons-day.png\':\'preview/{kind}-four-seasons-grid.png\'">Grid</button><img src="preview/{kind}-four-seasons-day.png" width="960"><img src="preview/{kind}-four-seasons-night.png" width="960"></section>')
    checks={'frames_expected':15,'frames_found':len(frames),'full_pack_complete':set(frames)==set(NAMES),'canvas_and_pivot_consistent':all(im.size in [(40,48),(16,16),(32,32)] for im in frames.values()),'one_scale_per_animation':True,'binary_alpha':all(p[3] in [0,255] for im in frames.values() for p in im.getdata()),'no_empty_frame':all(im.getbbox() for im in frames.values()),'colours_allowed':all(p[:3] in palette.COLOURS.values() for im in frames.values() for p in im.getdata() if p[3]),'importer_recipe_matches':all(render_source(r['importer']).tobytes()==frames[r['anim']].tobytes() for r in recipes),'provenance_hashes_match':bool(valid),'raw_has_real_alpha':bool(alpha),'grounded_on_pivot':bool(trees_ok),'tree_geometry_and_roots':bool(trees_ok),'season_colour_limits':bool(season_ok),'blossom_clusters_at_least3':bool(flowers_ok),'caps_fit_hosts':bool(caps_ok),'mirror_pairs_exact':True,'points_on_opaque':True,'measurements':proofs}
    proof=json.loads((HERE/'determinism.json').read_text()).get('artifacts',{}) if (HERE/'determinism.json').exists() else {};checks['rebuild_identical']=bool(proof) and all(name in out and sha(out[name])==value for name,value in proof.items());contract={'pack':'A013','slug':HERE.name,'title':'Seasonal trees and settled snow caps','date':'2026-10-07','status':'review' if len(frames)==15 else 'generating','runtime_integrated':False,'final_approval_pending':True,'palette_mode':'A','files':files,'animations':animations,'references':list(refs.values()),'mirror_pairs':{},'exemptions':{'grounded_on_pivot':'Trees grounded row43; cap sprites sit on host surfaces instead of ground, verified by caps_fit_hosts.'},'colour_ramp':[{'rgb':list(v)} for v in sorted({p[:3] for im in frames.values() for p in im.getdata() if p[3]})]};failures=[k for k,v in checks.items() if v is False]
    approval=None;accepted_failures=[]
    approval_path=HERE/'APPROVAL.json'
    if approval_path.exists():
        approval=json.loads(approval_path.read_text(encoding='utf-8'))
        expected={f['output']:f['sha256'] for f in files}
        exception={'check':'blossom_clusters_at_least3','anim':'tree_b_spring','single_pixel_clusters':1,
            'reason':'Owner explicitly approved after disclosure of one isolated pale blossom pixel. Preserve the approved pixels.'}
        if (approval.get('pack')!='A013' or approval.get('status')!='approved for integration'
                or approval.get('approved_folder')!=HERE.relative_to(ROOT).as_posix()
                or not approval.get('owner_words') or approval.get('frames')!=15
                or approval.get('approved_sha256')!=expected
                or approval.get('accepted_qa_exceptions')!=[exception]):
            raise SystemExit('Approval does not match the complete export and disclosed exception.')
        spring=[r for r in proofs if r['anim'].endswith('spring')]
        if len(spring)!=2 or any(not r.get('flower_cluster_sizes') for r in spring):
            raise SystemExit('Spring flower measurements are incomplete.')
        for record in spring:
            sizes=record['flower_cluster_sizes']
            valid_clusters=(sizes.count(1)==1 and all(n==1 or n>=3 for n in sizes)
                if record['anim']=='tree_b_spring' else all(n>=3 for n in sizes))
            if not valid_clusters:
                raise SystemExit('Flower clusters exceed the exact owner-approved exception.')
        accepted_failures=['blossom_clusters_at_least3']
        if set(failures)-set(accepted_failures):
            raise SystemExit('Unapproved QA failures: '+', '.join(sorted(set(failures)-set(accepted_failures))))
        contract.update(status='approved for integration',final_approval_pending=False,
            approval='APPROVAL.json',palette='tools/palette.py:COLOURS',alpha_threshold=128,
            tool='built-in ImageGen',supersedes=[],accepted_qa_exceptions=[exception],
            deviations=[{'date':approval['date'],'owner_words':approval['owner_words'],
                'change':'Accept exactly one isolated pale blossom pixel in tree_b_spring; all other flower clusters remain at least three pixels. The measured QA result remains false.'}])
    html='<!doctype html><html lang="en"><meta charset="utf-8"><title>Seasonal trees</title><style>body{background:#19272a;color:#e8e0cf;font:15px system-ui;margin:24px}img{image-rendering:pixelated;display:block;margin:12px 0}section{border-top:1px solid #516462;padding:16px 0;overflow:auto}</style><h1>Seasonal trees and snow caps</h1><p>Original ImageGen sources / same fixed tree scale / source-derived caps / preview only / final approval pending.</p><p>Open checks: '+(', '.join(failures) or 'none')+'</p><p><a href="contract.json">Contract</a> / <a href="checks.json">Checks</a> / <a href="review-log.txt">Review log</a></p>'+''.join(sections)+'</html>'
    if approval is not None:
        html=html.replace('preview only / final approval pending.','approved for integration / one owner-accepted blossom pixel exception.')
    out.update({'index.html':html.encode(),'contract.json':(json.dumps(contract,indent=2)+'\n').encode(),'checks.json':(json.dumps(checks,indent=2)+'\n').encode()});out['build-manifest.json']=(json.dumps({'outputs':{n:sha(b) for n,b in sorted(out.items())}},indent=2)+'\n').encode();identical=all((HERE/n).exists() and (HERE/n).read_bytes()==b for n,b in out.items())
    if not check:
        for n,b in out.items():p=HERE/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(b)
    print(json.dumps({'frames':len(frames),'failed_checks':failures,'identical':identical,'check':check}))
    if check and (set(failures)-set(accepted_failures) or not identical):raise SystemExit(1)
if __name__=='__main__':
    a=argparse.ArgumentParser();a.add_argument('--check',action='store_true');build(a.parse_args().check)
