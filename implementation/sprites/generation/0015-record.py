"""Copy exact tool returns and measure alpha-bounded source cells; never paint art."""
from pathlib import Path
import hashlib
import json
import shutil
import sys
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent

def main():
    ident, kind, returned = sys.argv[1:4]
    base_kind = kind.split('-r')[0]
    plan = next(p for p in json.loads((HERE / '0015-plan.json').read_text()) if p['id']==ident and p['kind']==base_kind)
    dest = ROOT / f'assets/art_source/enemies/{ident}/{kind}.png'
    dest.parent.mkdir(parents=True,exist_ok=True)
    if dest.exists():
        assert dest.read_bytes() == Path(returned).read_bytes(), 'Do not replace a retained return'
    else:
        shutil.copyfile(returned,dest)
    prompt = HERE / f'0015-{ident}-{kind}.prompt.txt'
    refs = plan['references'] if '-r' not in kind else [f'assets/art_source/enemies/{ident}/{base_kind}.png','docs/reference-sheet.png']
    refs = plan.get('revision_references',{}).get(kind.split('-r')[-1],refs)
    raw = Image.open(dest).convert('RGBA')
    mask = raw.getchannel('A').point(lambda a:255 if a>=128 else 0)
    def spans(image,axis):
        out,start=[],None
        for n in range(image.size[axis]+1):
            box=(n,0,n+1,image.height) if axis==0 else (0,n,image.width,n+1)
            on=n<image.size[axis] and image.crop(box).getbbox() is not None
            if on and start is None:start=n
            if not on and start is not None:out.append((start,n));start=None
        return out
    def split(image,axis,count):
        runs=spans(image,axis)
        assert len(runs)>=count,(ident,kind,'Missing separated objects',runs)
        gaps=sorted(range(len(runs)-1),key=lambda i:runs[i+1][0]-runs[i][1],reverse=True)[:count-1]
        cuts=[0]+sorted((runs[i][1]+runs[i+1][0])//2 for i in gaps)+[image.size[axis]]
        return cuts
    rejected = '--rejected' in sys.argv
    modules=[] if rejected else plan['modules']
    layout=plan.get('revision_layout',{}).get(kind.split('-r')[-1],plan.get('layout'))
    if rejected:cells=[]
    elif len(modules)==1:cells=[(0,0,raw.width,raw.height)]
    elif len(modules)==3 or layout=='row' or '-r' in kind and base_kind=='whole' and layout!='grid':
        cuts=split(mask,0,len(modules))
        cells=[(a,0,b,raw.height) for a,b in zip(cuts,cuts[1:])]
    else:
        ys=split(mask,1,2)
        cells=[]
        for a,b in zip(ys,ys[1:]):
            xs=split(mask.crop((0,a,raw.width,b)),0,2)
            cells.extend((x,a,y,b) for x,y in zip(xs,xs[1:]))
    measures=[]
    for role,cell in zip(modules,cells):
        x,y,x1,y1=cell
        box=mask.crop(cell).getbbox()
        # A measured empty separator may be only one source pixel wide.
        # It cannot belong to both integer cells. All alpha remains inside
        # one selected cell; only the outer sheet must retain a clear border.
        assert box and 0<=box[0]<box[2]<=x1-x and 0<box[1]<box[3]<y1-y,(role,'Invalid source boundary',box)
        assert (x>0 or box[0]>0) and (x1<raw.width or box[2]<x1-x),(role,'Clipped outer sheet',box)
        measures.append(dict(role=role,sheet_cell_xywh=[x,y,x1-x,y1-y],crop_xywh=[x+box[0],y+box[1],box[2]-box[0],box[3]-box[1]]))
    h=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
    call=dict(id=ident,kind=kind,revision=int(kind.split('-r')[1]) if '-r' in kind else 0,tool='built-in ImageGen',returned_file=returned,
              source=dest.relative_to(ROOT).as_posix(),source_sha256=h(dest),source_wh=list(raw.size),source_alpha_range=list(raw.getchannel('A').getextrema()),
              prompt=prompt.relative_to(ROOT).as_posix(),prompt_sha256=h(prompt),references=refs,reference_hashes={p:h(ROOT/p) for p in refs},
              tool_arguments=dict(transparent_background=True,referenced_image_paths=[str(ROOT/p) for p in refs]),
              measurements=measures,decision='Rejected: no clear transparent column between adjacent death frames' if rejected else 'Pending native and runtime review')
    path=HERE/f'0015-{ident}-{kind}-call.json'
    assert not path.exists(),'Preserve original call record'
    path.write_text(json.dumps(call,indent=2)+'\n',encoding='utf-8',newline='\n')
    print(json.dumps(dict(source=call['source'],wh=raw.size,modules=measures)))

if __name__=='__main__':main()
