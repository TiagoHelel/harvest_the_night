"""Inspect connected masks as tiled structures and mixed-material seams."""
from PIL import Image
from io import BytesIO
from pathlib import Path
def render(images,plan,out):
 root=Path(__file__).resolve().parents[4]
 def save(rel,im):
  b=BytesIO();im.save(b,format='PNG');out[rel]=b.getvalue()
  n=im.copy();px=[]
  for r,g,blue,a in im.get_flattened_data():
   lit=r/255*.36,g/255*.40,blue/255*.82;grey=.299*lit[0]+.587*lit[1]+.114*lit[2];px.append(tuple(round(max(0,min(1,grey+.76*(v-grey)+o))*255) for v,o in zip(lit,(.040,.035,.105)))+(a,))
  n.putdata(px);b=BytesIO();n.save(b,format='PNG');out[rel.replace('.png','-night.png')]=b.getvalue()
 def scene(w,h):
  im=Image.new('RGBA',(w,h));grass=Image.open(root/'sprites/terrain/grass.png').convert('RGBA')
  for y in range(0,h,16):
   for x in range(0,w,16):im.alpha_composite(grass,(x,y))
  return im
 html='<section id="connections"><h2>Connected runs / actual tile spacing</h2><p>Whole, hurt, all masks, mixed wooden-fence seam. Native connections are shown at actual tile spacing.</p>'
 families=list({v['family'] for v in plan['joins'].values()})
 for family in sorted(families):
  for suffix in ['', '_hurt']:
   sheet=scene(16*16,40)
   for m in range(16):
    name=family+('' if m==0 else f'_join_{m}')+suffix;sheet.alpha_composite(images[f'native/{name}/none/01.png'],(m*16,4))
   rel=f'preview/{family}{suffix}-all-masks.png';save(rel,sheet);html+=f'<h3>{family}{suffix} / masks 0..15</h3><img src="{rel}" width="{sheet.width*4}">'
  im=scene(256,144)
  # Actual neighbour masks for a straight line, corner, T and cross.
  sets=[[(0,0),(1,0),(2,0),(3,0)],[(0,0),(1,0),(1,1),(1,2)],[(0,0),(1,0),(2,0),(1,1)],[(1,0),(0,1),(1,1),(2,1),(1,2)]]
  for kind,cells in enumerate(sets):
   cells=set(cells)
   for x,y in cells:
    mask=sum(bit for dx,dy,bit in [(0,-1,1),(1,0,2),(0,1,4),(-1,0,8)] if (x+dx,y+dy) in cells)
    for row,suffix in enumerate(['','_hurt']):
     name=family+('' if not mask else f'_join_{mask}')+suffix;im.alpha_composite(images[f'native/{name}/none/01.png'],(kind*64+x*16,8+row*64+y*16))
  rel=f'preview/{family}-connected-scenes.png';save(rel,im);html+=f'<img src="{rel}" width="{im.width*4}">'
  # Mixed straight seam at x16: incumbent and candidate use their exact native geometry.
  mixed=scene(128,52);wood=Image.open(root/'sprites/buildings/fence_join_10.png').convert('RGBA')
  for i in range(6):mixed.alpha_composite(wood if i%2==0 else images[f'native/{family}_join_10/none/01.png'],(8+i*16,8))
  rel=f'preview/{family}-mixed-seam.png';save(rel,mixed);html+=f'<p>Mixed seam with existing timber fence</p><img src="{rel}" width="512">'
 html+='<h3>Night connections and mixed-material seams</h3>'
 for rel in list(out):
  if rel.endswith(('-connected-scenes-night.png','-mixed-seam-night.png')):
   w=Image.open(BytesIO(out[rel])).width;html+=f'<img src="{rel}" width="{w*4}">'
 return html+'</section>' 
