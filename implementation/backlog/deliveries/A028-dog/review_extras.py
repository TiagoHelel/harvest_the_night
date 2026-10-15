"""Preview-only flips, onion skin and animated strips."""
from PIL import Image,ImageOps
from io import BytesIO
from pathlib import Path
def render(images,plan,out):
 def save(rel,im):
  b=BytesIO();im.save(b,format='PNG');out[rel]=b.getvalue()
 groups={}
 for f in plan['files']:groups.setdefault(f['anim'],[]).append(f)
 html='<section id="all-movements"><h2>All seven movements / new frames pending review</h2><p>Sitting is already approved. All other frames require a new review. Measured visual differences remain listed above.</p>'
 master=images['native/dog_wag/west/01.png']
 for name,fs in groups.items():
  frames=[];fs.sort(key=lambda f:f['frame']);onions=Image.new('RGBA',(len(fs)*44,32));east=Image.new('RGBA',(len(fs)*44,32))
  for i,f in enumerate(fs):
   im=images[f['output']];base=master.copy();base.putalpha(base.getchannel('A').point(lambda a:round(a*.3)));base.alpha_composite(im);onions.alpha_composite(base,(i*44,0));east.alpha_composite(ImageOps.mirror(im),(i*44,0))
   scene=Image.new('RGBA',(64,40),(30,43,45,255));scene.alpha_composite(im,(12,4));frames.append(scene.convert('RGB').resize((256,160),Image.Resampling.NEAREST))
  b=BytesIO();frames[0].save(b,format='GIF',save_all=True,append_images=frames[1:],duration=round(fs[0]['seconds']*1000),loop=0 if fs[0]['loop'] else 1,disposal=2);out[f'preview/{name}.gif']=b.getvalue()
  save(f'preview/{name}-east.png',east);save(f'preview/{name}-onion.png',onions)
  html+=f'<h3>{name}</h3><img src="preview/{name}.gif"><p>East (preview flip only)</p><img src="preview/{name}-east.png" width="{east.width*4}"><p>Onion skin over standing master</p><img src="preview/{name}-onion.png" width="{onions.width*4}">'
 root=Path(__file__).resolve().parents[4]
 grass=Image.open(root/'sprites/terrain/grass.png').convert('RGBA')
 def ground(w,h):
  im=Image.new('RGBA',(w,h))
  for y in range(0,h,16):
   for x in range(0,w,16):im.alpha_composite(grass,(x,y))
  return im
 def night(im):
  result=im.copy();px=[]
  for r,g,b,a in im.get_flattened_data():
   lit=r/255*.36,g/255*.40,b/255*.82;grey=.299*lit[0]+.587*lit[1]+.114*lit[2];px.append(tuple(round(max(0,min(1,grey+.76*(v-grey)+o))*255) for v,o in zip(lit,(.040,.035,.105)))+(a,))
  result.putdata(px);return result
 family=ground(204,56)
 for direction,x in [('down',0),('left',36)]:family.alpha_composite(Image.open(root/f'implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/{direction}/01.png').convert('RGBA'),(x,12))
 family.alpha_composite(master,(78,18));family.alpha_composite(Image.open(root/'sprites/props/cow.png').convert('RGBA'),(126,26));family.alpha_composite(Image.open(root/'sprites/props/chicken.png').convert('RGBA'),(168,26))
 bite=ground(112,64);bite.alpha_composite(Image.open(root/'sprites/enemies/walker_walk_0.png').convert('RGBA'),(30,12));bite.alpha_composite(images['native/dog_bite/west/02.png'],(53,26))
 for name,im in [('family',family),('bite-alignment',bite)]:
  save(f'preview/{name}-day.png',im);save(f'preview/{name}-night.png',night(im));html+=f'<h3>{name} / native and FHD4x</h3><img src="preview/{name}-day.png"><img src="preview/{name}-day.png" width="{im.width*4}"><img src="preview/{name}-night.png" width="{im.width*4}">'
 html+='<p>Family line: farmer front, farmer side, standing dog, current cow and current hen (owner-authorized references). Bite faces west toward the walker: dog pivot (73,56), walker pivot (62,56), jaw contact (62,47). Use the metadata toggle above to see bite_xy on the native lunge.</p>'
 return html+'</section>'
