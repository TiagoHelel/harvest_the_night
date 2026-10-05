"""Pack two four-pose ImageGen sheets without repainting or resampling."""
from pathlib import Path
from PIL import Image
import json,hashlib
ROOT=Path(__file__).resolve().parent
SOURCE=ROOT.parents[4]/'assets/art_source/player-fhd/pilots/2026-10-04/walk-up-right'
cells=[];report=[]
for name in ('transition-a-r2.png','transition-b-r2.png'):
 im=Image.open(SOURCE/name).convert('RGBA');xs=[0,round(im.width/2),im.width];ys=[0,round(im.height/2),im.height]
 for i in range(4):
  box=(xs[i%2],ys[i//2],xs[i%2+1],ys[i//2+1]);cell=im.crop(box)
  b=cell.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
  assert b and b[0]>0 and b[1]>0 and b[2]<cell.width and b[3]<cell.height,(name,i,b)
  cells.append(cell);report.append({'frame':len(cells),'source':name,'source_cut':box,'opaque_bbox':b,'cut_sha256':hashlib.sha256(cell.tobytes()).hexdigest()})
# An isolated source has its own canvas scale. Calibrate once to contact5 hat
# width, not dynamic body/foot bounds, before placing this one source in cell6.
def opaque_bbox(im):
 return im.getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
def hat_box(im):
 b=opaque_bbox(im)
 return im.crop((0,b[1],im.width,b[1]+round((b[3]-b[1])*.22))).getchannel('A').point(lambda a:255 if a>=128 else 0).getbbox()
ref=cells[4];rb=opaque_bbox(ref);rh=hat_box(ref)
raw=Image.open(SOURCE/'phase-06-r1.png').convert('RGBA');raw=raw.crop(opaque_bbox(raw));ah=hat_box(raw)
scale=(rh[2]-rh[0])/(ah[2]-ah[0]);small=raw.resize((round(raw.width*scale),round(raw.height*scale)),Image.Resampling.NEAREST);sh=hat_box(small)
replacement=Image.new('RGBA',cells[5].size)
position=(round((rh[0]+rh[2])/2-(sh[0]+sh[2])/2),rb[1])
replacement.paste(small,position)
b=opaque_bbox(replacement);assert b[3]<replacement.height,(b,replacement.size)
cells[5]=replacement
report[5]={'frame':6,'source':'phase-06-r1.png','operation':'one isolated-source scale calibration to contact5 hat width; nearest, no painting','scale':scale,'position':position,'opaque_bbox':b,'prepared_cell_sha256':hashlib.sha256(replacement.tobytes()).hexdigest()}
w=max(c.width for c in cells);h=max(c.height for c in cells);out=Image.new('RGBA',(4*w,2*h))
for i,cell in enumerate(cells):
 offset=((w-cell.width)//2,(h-cell.height)//2);out.paste(cell,(i%4*w+offset[0],i//4*h+offset[1]));report[i]['padding_offset']=offset
out.save(SOURCE/'tracking-r1.png')
(ROOT/'transition-packing.json').write_text(json.dumps({'operation':'seven lossless source cuts plus isolated phase6 calibrated once to contact5 hat width; transparent padding, no painting or reflection','canvas':out.size,'cells':report},indent=2)+'\n',encoding='utf-8')
print(SOURCE/'tracking-r1.png')
