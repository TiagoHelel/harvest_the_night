"""Exact existing-sprite head crops explicitly requested by the owner."""
from pathlib import Path
import json, hashlib, io
from PIL import Image, ImageDraw
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]

def digest(data):return hashlib.sha256(data).hexdigest()
def png(im):
    out=io.BytesIO();im.save(out,format='PNG');return out.getvalue()

def build(check=False):
    spec=json.loads((HERE/'head-crops.json').read_text());outputs={};files=[];animations=[];references=[];cards=[];frames={}
    exact=True;hashes=True;margins=True;colours=True
    def add(name,image):outputs[name]=png(image)
    strip=Image.new('RGBA',(368,48),(26,24,48,255));labels=ImageDraw.Draw(strip)
    for i,r in enumerate(spec['entries']):
        kind=r['kind'];source=HERE/r['source'];body=Image.open(source).convert('RGBA')
        x,y,w,h=r['crop_xywh'];region=body.crop((x,y,x+w,y+h));trim=region.getbbox();crop=region.crop(trim)
        assert crop.width<=14 and crop.height<=14
        dx=(16-crop.width)//2;dy=15-crop.height
        head=Image.new('RGBA',(16,16));head.paste(crop,(dx,dy))
        frames[kind]=head;exact &= head.crop((dx,dy,dx+crop.width,dy+crop.height)).tobytes()==crop.tobytes()
        hashes &= digest(source.read_bytes())==r['source_sha256'] and digest((ROOT/r['original_source']).read_bytes())==r['source_sha256']
        box=head.getbbox();margins &= box[0]>=1 and box[1]>=1 and box[2]<=15 and box[3]==15
        colours &= {p for p in head.getdata() if p[3]}.issubset({p for p in body.getdata() if p[3]})
        anim='head_'+kind;name=f'native/{anim}/none/01.png';add(name,head)
        recipe={'source':r['source'],'crop_xywh':r['crop_xywh'],'trim_alpha_bbox_xyxy':list(trim),
            'placement_xy':[dx,dy],'canvas_wh':[16,16],'content_scale':1,'palette_mapping':None,
            'preserve_rgba_exact':True,'mirrored_from':None}
        files.append({'anim':anim,'dir':'none','frame':0,'output':name,'sha256':digest(outputs[name]),
            'runtime_name':f'sprites/ui/{anim}.png','source':r['source'],'source_sha256':r['source_sha256'],
            'original_source':r['original_source'],'prompt':None,'call':None,'recipe':recipe,'points':{}})
        references.append({'path':r['original_source'],'sha256':r['source_sha256'],'role':'Exact head pixel and color authority'})
        animations.append({'anim':anim,'dir':'none','frames':1,'poses':['Exact current '+kind+' head crop'],
            'frame_seconds':1,'loop':False,'canvas_wh':[16,16],'pivot_xy':[8,8],'draw_scale':1,'mirror':'none','points':{}})
        strip.alpha_composite(head,(4+i*72+28,6));labels.text((12+i*72,30),kind.title(),fill=(230,221,197))
        add(f'preview/{kind}-source.png',body)
        guide=body.copy();ImageDraw.Draw(guide).rectangle((x,y,x+w-1,y+h-1),outline=(232,91,211,255));add(f'preview/{kind}-crop-guide.png',guide)
        backgrounds=[]
        for label,colour in [('light',(225,223,211,255)),('hud',(26,24,48,255)),('checker',(46,55,58,255))]:
            bg=Image.new('RGBA',(16,16),colour)
            if label=='checker':
                draw=ImageDraw.Draw(bg)
                for yy in range(0,16,4):
                    for xx in range(0,16,4):
                        if (xx//4+yy//4)%2:draw.rectangle((xx,yy,xx+3,yy+3),fill=(75,84,87,255))
            bg.alpha_composite(head);add(f'preview/head_{kind}-{label}.png',bg)
            backgrounds.append(f'<figure>{label} / 6x<br><img src="preview/head_{kind}-{label}.png" width="96" height="96"></figure>')
        cards.append(f'<section><h2>{kind.title()}</h2><div class="row"><figure>Current sprite / 4x<br><img src="preview/{kind}-source.png" width="{body.width*4}" height="{body.height*4}"></figure><figure>Crop rectangle / 4x<br><img src="preview/{kind}-crop-guide.png" width="{body.width*4}" height="{body.height*4}"></figure><figure>Head / native 1x<br><img src="{name}" width="16" height="16"></figure>'+''.join(backgrounds)+'</div></section>')
    add('preview/forecast-heads.png',strip)
    add('preview/forecast-heads-4x.png',strip.resize((1472,192),Image.Resampling.NEAREST))
    checks={'frames_expected':5,'frames_found':len(files),'full_pack_complete':len(files)==5,
        'canvas_and_pivot_consistent':all(im.size==(16,16) for im in frames.values()),
        'binary_alpha':all(p[3] in (0,255) for im in frames.values() for p in im.getdata()),
        'no_empty_frame':all(im.getbbox() for im in frames.values()),'exact_crop_pixels':bool(exact),
        'source_hashes_match':bool(hashes),'source_colours_preserved':bool(colours),'transparent_margin_and_baseline':bool(margins),
        'all_same_size_outputs_distinct':len({im.tobytes() for im in frames.values()})==5}
    proof=json.loads((HERE/'determinism.json').read_text()).get('artifacts',{}) if (HERE/'determinism.json').exists() else {}
    checks['rebuild_identical']=bool(proof) and all(n in outputs and digest(outputs[n])==h for n,h in proof.items())
    failed=[k for k,v in checks.items() if v is False]
    contract={'pack':'A011','slug':HERE.name,'title':'Forecast heads cropped from current enemies','date':spec['date'],
        'status':'review' if not failed else 'generating','runtime_integrated':False,'final_approval_pending':True,
        'palette_mode':'existing-source-crop','palette':'unchanged current runtime RGBA','tool':'deterministic crop explicitly requested by owner',
        'animations':animations,'files':files,'references':references,'mirror_pairs':{},'supersedes':['Generated A011 heads'],
        'deviations':[{'date':spec['date'],'owner_words':spec['owner_words'],
            'change':'Use exact existing-sprite head crops instead of new ImageGen busts. Preserve original pixel scale and RGBA; original bust-specific size rules are superseded by the actual cropped heads.'}]}
    summary='Open checks: '+', '.join(failed) if failed else 'All recorded checks pass; each head matches the current sprite pixels exactly.'
    page='''<!doctype html><html lang="en"><meta charset="utf-8"><title>A011 / Current enemy head crops</title>
<style>body{background:#1b2527;color:#e7dfcb;font:16px system-ui;margin:28px}img{image-rendering:pixelated}a{color:#a8dbbc}.row{display:flex;gap:22px;align-items:end;flex-wrap:wrap}figure{margin:10px 0}section{border-top:1px solid #475854;padding:16px 0}.scroll{overflow-x:auto}</style>
<h1>A011 / Heads cropped from the current enemy sprites</h1><p>The five heads reuse the current walk frame 0 pixels. No new drawing, resizing or recoloring. Transparent padding fits each crop into its 16×16 UI canvas.</p><p>SUMMARY</p>
<p><a href="contract.json">Contract</a> · <a href="checks.json">Checks</a> · <a href="head-crops.json">Exact source rectangles and owner request</a> · <a href="../A001-farmer-bed/all-packs-review.html">All packs</a></p>
<h2>All five / native 1x</h2><img src="preview/forecast-heads.png"><h2>All five / integer 4x</h2><div class="scroll"><img src="preview/forecast-heads-4x.png" width="1472" height="192"></div>
<p>The HUD retains original colors during day and night. Magenta outlines below are crop guides only and never enter the exported heads.</p>CARDS</html>'''.replace('SUMMARY',summary).replace('CARDS',''.join(cards))
    approval_path=HERE/'APPROVAL.json'
    if approval_path.exists():
        approval=json.loads(approval_path.read_text(encoding='utf-8'))
        expected={f['output']:f['sha256'] for f in files}
        if (approval.get('pack')!='A011' or approval.get('status')!='approved for integration'
                or approval.get('approved_folder')!=HERE.relative_to(ROOT).as_posix()
                or not approval.get('owner_words') or approval.get('frames')!=len(files)
                or approval.get('approved_sha256')!=expected or failed):
            raise SystemExit('Approval does not match the complete, passing export.')
        contract['status']='approved for integration'
        contract['final_approval_pending']=False
        contract['approval']='APPROVAL.json'
        page=page.replace('<h1>A011 / Heads cropped from the current enemy sprites</h1>',
            '<h1>A011 / Heads cropped from the current enemy sprites / approved for integration</h1>')
    outputs['contract.json']=(json.dumps(contract,indent=2)+'\n').encode();outputs['checks.json']=(json.dumps(checks,indent=2)+'\n').encode();outputs['index.html']=page.encode()
    outputs['build-manifest.json']=(json.dumps(sorted(list(outputs)+['build-manifest.json']),indent=2)+'\n').encode()
    changed=[n for n,data in outputs.items() if not (HERE/n).exists() or (HERE/n).read_bytes()!=data]
    if check:
        assert not changed,'Rebuild mismatch: '+','.join(changed)
        assert not failed,failed
    else:
        for name,data in outputs.items():
            path=HERE/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
    print(json.dumps({'frames':len(frames),'failed_checks':failed,'identical':not changed,'check':check}))
    return checks
