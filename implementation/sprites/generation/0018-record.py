"""Keep exact raw icon returns and build measured review cuts, without painting."""
from pathlib import Path
import hashlib,json,shutil,sys
from PIL import Image
ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'tools'))
import import_art

def main():
    ident,returned=sys.argv[1:3]
    plan=next(p for p in json.loads((HERE/'0018-plan.json').read_text(encoding='utf-8')) if p['id']==ident)
    dest=ROOT/f'assets/art_source/ui/{ident}.png'
    dest.parent.mkdir(parents=True,exist_ok=True)
    if dest.exists():
        assert dest.read_bytes()==Path(returned).read_bytes(),'Preserve prior tool return'
    else:
        shutil.copyfile(returned,dest)
    raw=Image.open(dest).convert('RGBA');alpha=raw.getchannel('A')
    mask=alpha.point(lambda a:255 if a>=128 else 0);box=mask.getbbox()
    assert box and 0<box[0]<box[2]<raw.width and 0<box[1]<box[3]<raw.height,'Clipped/missing source'
    w,h=box[2]-box[0],box[3]-box[1]
    sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    prompt=HERE/f'0018-{ident}.prompt.txt'
    actual=json.loads((HERE/f'0018-{ident}-arguments.json').read_text(encoding='utf-8'))
    assert actual['prompt']==prompt.read_text(encoding='utf-8')
    call=dict(id=ident,revision=0,tool='built-in ImageGen',returned_file=returned,source=dest.relative_to(ROOT).as_posix(),source_sha256=sha(dest),source_wh=list(raw.size),source_alpha_range=list(alpha.getextrema()),crop_xywh=[box[0],box[1],w,h],prompt=prompt.relative_to(ROOT).as_posix(),prompt_sha256=sha(prompt),references=plan['references'],reference_hashes={p:sha(ROOT/p) for p in plan['references']},actual_submitted_arguments=actual,decision='Pending all-icons and actual UI review')
    cuts=[]
    review=ROOT/'implementation/sprites/reviews/0018';review.mkdir(parents=True,exist_ok=True)
    for size,visible,prefix in [(16,14,'icon'),(10,8,'hud')]:
        scale=visible/max(w,h);rw,rh=[max(1,round(n*scale)) for n in (w,h)]
        e=dict(id=f'ui/{prefix}_{ident}',owner='raster',source=call['source'],source_sha256=call['source_sha256'],crop_xywh=call['crop_xywh'],canvas_wh=[size,size],pivot_xy=[size//2,size//2],content_scale=scale,content_anchor_xy=[rw//2,rh//2],alpha_threshold=128,palette='tools/palette.py:COLOURS',animation=f'ui/{prefix}_{ident}',frame=0,seconds=1.0,loop=False,output=f'sprites/ui/{prefix}_{ident}.png',prompt=call['prompt'],prompt_sha256=call['prompt_sha256'],references=[dict(path=p,sha256=call['reference_hashes'][p],role='As indexed in exact submitted prompt') for p in plan['references']],tool='built-in ImageGen',generation_task='0018',revision=0,resource_id=ident,display_role='inventory' if size==16 else 'compact_hud')
        art=import_art.render_source(e);e['output_sha256']=import_art.sha(import_art.png(art));cuts.append(e)
        art.save(review/f'{prefix}_{ident}-native.png')
        art.resize((size*3,size*3),Image.Resampling.NEAREST).save(review/f'{prefix}_{ident}-3x.png')
    call['entries']=cuts
    (HERE/f'0018-{ident}-call.json').write_text(json.dumps(call,indent=2)+'\n',newline='\n')
    print(json.dumps(dict(source=call['source'],wh=raw.size,crop=call['crop_xywh'],native_bounds=[Image.open(review/f'{p}_{ident}-native.png').getbbox() for p in ('icon','hud')])))

if __name__=='__main__':main()
