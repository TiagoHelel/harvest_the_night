"""Search uniform scale/placement recipes; never repaint or reshape cap source pixels."""
from pathlib import Path
import json,sys,math
from PIL import Image
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];sys.path.insert(0,str(ROOT/'tools'))
from import_art import render_source
CAPS={'stump_snow':['stump'],'rock_snow':['rock'],'rock_b_snow':['rock_b'],'ore_snow':['ore'],'ore_b_snow':['ore_b'],'seam_snow':['seam'],'seam_b_snow':['seam_b'],'snow_cap':['ore','rock'],'snow_cap_2x2':['stump2x']}
def host(name):
    im=Image.open(ROOT/f'sprites/props/{"stump" if name=="stump2x" else name}.png').convert('RGBA')
    return im.resize((32,32),Image.Resampling.NEAREST) if name=='stump2x' else im
def groups(points):
    points=set(points);count=0
    while points:
        todo=[points.pop()];count+=1
        while todo:
            x,y=todo.pop()
            for dx in [-1,0,1]:
                for dy in [-1,0,1]:
                    q=x+dx,y+dy
                    if q in points:points.remove(q);todo.append(q)
    return count
def fit(cap,hosts):
    cp={(x,y) for y in range(cap.height) for x in range(cap.width) if cap.getpixel((x,y))[3]};result=[]
    for name in hosts:
        hp=host(name);hs={(x,y) for y in range(hp.height) for x in range(hp.width) if hp.getpixel((x,y))[3]};tops={x:min(y for xx,y in hs if xx==x) for x in {xx for xx,y in hs}};overlap=len(cp&hs);hb=hp.getbbox();cb=cap.getbbox();within=all(x in tops and tops[x]-2<=y<=tops[x]+5 for x,y in cp);width=cb[2]-cb[0];hw=hb[2]-hb[0]
        ok=within and overlap>=.6*len(cp) and overlap<=.35*len(hs) and 2<=cb[3]-cb[1]<=6 and .55*hw<=width<=.8*hw and groups(cp)==1 and abs((cb[0]+cb[2]-hb[0]-hb[2])/2)<=1
        result.append({'host':name,'pass':bool(ok),'within_column_top_band':within,'cap_pixels':len(cp),'host_pixels':len(hs),'overlap_pixels':overlap,'overlap_fraction':overlap/len(cp),'host_covered_fraction':overlap/len(hs),'width_fraction':width/hw,'cap_bounds':cb})
    return result
def candidate(stem):
    name=stem.rsplit('-r',1)[0];hosts=CAPS[name];size=32 if name=='snow_cap_2x2' else 16;pivot=[size//2,size-2];source=HERE/f'raw/{stem}.png';im=Image.open(source).convert('RGBA');lo,hi=im.getchannel('A').getextrema();assert lo==0 and hi>=128
    x,y,xe,ye=im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox();w,h=xe-x,ye-y;hw=host(hosts[0]).getbbox();minw=math.ceil((hw[2]-hw[0])*.55);maxw=math.floor((hw[2]-hw[0])*.8);options=[]
    for width in range(minw,maxw+1):
        scale=width/w;sw,sh=round(w*scale),round(h*scale)
        if not 2<=sh<=6:continue
        for left in range(size-sw+1):
            if abs(left+sw/2-(hw[0]+hw[2])/2)>1:continue
            for top in range(size-sh+1):
                entry={'id':'A013/'+name,'source':source.relative_to(ROOT).as_posix(),'crop_xywh':[x,y,w,h],'content_scale':scale,'content_anchor_xy':[pivot[0]-left,pivot[1]-top],'alpha_threshold':128,'palette':'tools/palette.py:COLOURS','palette_keys':['bone','moon','bone_dark','stone_light','night'],'canvas_wh':[size,size],'pivot_xy':pivot}
                cap=render_source(entry);proof=fit(cap,hosts);passed=sum(p['pass'] for p in proof);score=(passed,-sum(not p['within_column_top_band'] for p in proof),-sum(max(0,.6-p['overlap_fraction'])+max(0,p['host_covered_fraction']-.35) for p in proof),sum(p['overlap_fraction'] for p in proof),-top)
                options.append((score,entry,cap,proof))
    assert options,'Raw cap aspect ratio cannot fit native2-6row height';score,entry,cap,proof=max(options,key=lambda q:q[0]);r={'anim':name,'stem':stem,'importer':entry,'host_fit':proof};(HERE/f'preview/{stem}-recipe.json').write_text(json.dumps(r,indent=2)+'\n');cap.save(HERE/f'preview/{stem}-native.png');cap.resize((size*10,size*10),Image.Resampling.NEAREST).save(HERE/f'preview/{stem}-10x.png')
    overview=Image.new('RGBA',(size*3*len(hosts),size),(29,39,42,255))
    for i,name in enumerate(hosts):
        hp=host(name);overview.alpha_composite(hp,(i*size*3,0));joined=hp.copy();joined.alpha_composite(cap);overview.alpha_composite(joined,(i*size*3+size,0));overlay=joined.copy()
        for yy in range(size):
            for xx in range(size):
                if cap.getpixel((xx,yy))[3] and not hp.getpixel((xx,yy))[3]:overlay.putpixel((xx,yy),(240,70,70,255))
        overview.alpha_composite(overlay,(i*size*3+size*2,0))
    overview.resize((overview.width*6,size*6),Image.Resampling.NEAREST).save(HERE/f'preview/{stem}-host-fit-6x.png');print(json.dumps({'stem':stem,'fits':proof,'all_fit':all(p['pass'] for p in proof)}))
if __name__=='__main__':candidate(sys.argv[1])
