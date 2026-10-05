"""Pack four unmodified source cells and four generated intermediate poses.

Only lossless crops, alpha threshold, transparent padding and one uniform
reference-size conversion for the new pair are used. No joint deformation.
"""
from pathlib import Path
import hashlib,json,statistics
from PIL import Image

ROOT=Path(__file__).resolve().parent
SRC=ROOT.parents[4]/'assets/art_source/player-fhd/pilots/2026-10-04/walk-up-right'
def clean(im):
    im=im.convert('RGBA');im.putalpha(im.getchannel('A').point(lambda a:255 if a>=128 else 0));return im
def hat(cell):
    b=cell.getbbox()
    # Equivalent to top22% of character: the brim defines reference width.
    return cell.crop((0,b[1],cell.width,b[1]+round((b[3]-b[1])*.22))).getbbox()
base=clean(Image.open(SRC/'materials-r3.png'))
xs=[round(i*base.width/4) for i in range(5)];ys=[0,round(base.height/2),base.height]
cells=[base.crop((xs[c],ys[r],xs[c+1],ys[r+1])) for r in range(2) for c in range(4)]
replacements={};factors={}
for name,indices in [('reach-04-08-r1.png',(3,7)),('passing-03-07-r1.png',(2,6))]:
    pair=clean(Image.open(SRC/name));mid=round(pair.width/2)
    new=[pair.crop((0,0,mid,pair.height)),pair.crop((mid,0,pair.width,pair.height))]
    target=statistics.median(hat(cells[i])[2]-hat(cells[i])[0] for i in indices)
    factor=target/statistics.median(hat(c)[2]-hat(c)[0] for c in new)
    factors[name]=factor
    for j,i in enumerate(indices):replacements[i]=(new[j],factor,name,j)
out=Image.new('RGBA',(1776,888));entries=[]
for i,cell in enumerate(cells):
    b=cell.getbbox();hc=hat(cell);center=(hc[0]+hc[2])/2
    if i in replacements:
        raw,factor,name,j=replacements[i];rb=raw.getbbox();rh=hat(raw)
        small=raw.resize((round(raw.width*factor),round(raw.height*factor)),Image.Resampling.NEAREST)
        sb=small.getbbox();x=round(center-(rh[0]+rh[2])/2*factor);y=b[1]-sb[1]
        tile=Image.new('RGBA',(444,444));tile.alpha_composite(small,(x,y))
        entry={'frame':i+1,'source':name,'pair_cell':j,
               'uniform_scale':factor,'placement':[x,y]}
    else:
        tile=Image.new('RGBA',(444,444));tile.alpha_composite(cell,(0,0))
        entry={'frame':i+1,'source':'materials-r3.png','cut':[xs[i%4],ys[i//4],xs[i%4+1],ys[i//4+1]],'uniform_scale':1}
    assert tile.getbbox()[3]<444,('Source clipping',i+1,tile.getbbox())
    out.alpha_composite(tile,(i%4*444,i//4*444))
    entry['tile_sha256']=hashlib.sha256(tile.tobytes()).hexdigest();entries.append(entry)
out.save(SRC/'materials-r4.png')
(ROOT/'continuous-packing.json').write_text(json.dumps({'selected_source':'materials-r4.png','pair_common_head_reference_scales':factors,'frames':entries,'operations':'cut, threshold alpha, pad; each new pair uniformly resampled once by common hat width; no limb painting or deformation'},indent=2)+'\n',encoding='utf-8')
print('Packed continuous candidate:',factors)
