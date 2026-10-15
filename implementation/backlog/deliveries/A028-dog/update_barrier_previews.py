"""Complete night-context reviews without changing any native raster output."""
from pathlib import Path
D=Path(__file__).resolve().parent
for slug in ['A042-electric-fence','A043-strong-walls']:
 p=D.parent/slug/'review_extras.py';s=p.read_text(encoding='utf-8')
 s=s.replace("out[rel]=b.getvalue()",'''out[rel]=b.getvalue()
  n=im.copy();px=[]
  for r,g,blue,a in im.get_flattened_data():
   lit=r/255*.36,g/255*.40,blue/255*.82;grey=.299*lit[0]+.587*lit[1]+.114*lit[2];px.append(tuple(round(max(0,min(1,grey+.76*(v-grey)+o))*255) for v,o in zip(lit,(.040,.035,.105)))+(a,))
  n.putdata(px);b=BytesIO();n.save(b,format='PNG');out[rel.replace('.png','-night.png')]=b.getvalue()''')
 s=s.replace('Existing zap approval is unchanged.','Native connections are shown at actual tile spacing.')
 s=s.replace('scene(256,128)','scene(256,144)')
 s=s.replace("return html+'</section>'",'''html+='<h3>Night connections and mixed-material seams</h3>'
 for rel in list(out):
  if rel.endswith(('-connected-scenes-night.png','-mixed-seam-night.png')):
   w=Image.open(BytesIO(out[rel])).width;html+=f'<img src="{rel}" width="{w*4}">'
 return html+'</section>' ''')
 p.write_text(s,encoding='utf-8')
