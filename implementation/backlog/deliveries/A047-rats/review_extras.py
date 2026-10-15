"""Review scenes made only from existing native rasters; never runtime art."""
from pathlib import Path
from PIL import Image
import review_base
D=Path(__file__).resolve().parent;ROOT=D.parents[3]
def render(images,p,out):
 html=review_base.render(images,p,out);by={}
 for f in p['files']:by.setdefault(f['anim'],[]).append((f,images[f['output']]))
 def scene(name,im,caption):
  out['preview/'+name+'.png']=review_base.png(im);out['preview/'+name+'-night.png']=review_base.png(review_base.night(im));return '<h2>'+caption+'</h2><p>Native1x / FHD4x / night4x</p>'+''.join('<img src="preview/'+name+s+'.png" width="'+str(im.width*z)+'" height="'+str(im.height*z)+'">' for s,z in [('',1),('',4),('-night',4)])
 grass=Image.open(ROOT/'sprites/terrain/grass.png').convert('RGBA');mine=Image.open(ROOT/'sprites/buildings/mine.png').convert('RGBA');farmer=Image.open(ROOT/'implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png').convert('RGBA');walker=Image.open(ROOT/'sprites/enemies/walker.png').convert('RGBA')
 def ground(w,h):
  im=Image.new('RGBA',(w,h))
  for y in range(0,h,16):
   for x in range(0,w,16):im.alpha_composite(grass,(x,y))
  return im
 fs=sorted(by['rat_walk'],key=lambda q:q[0]['frame']);im=ground(192,72);im.alpha_composite(mine,(78,40));im.alpha_composite(farmer,(4,18));im.alpha_composite(walker,(124,10))
 for i in range(6):im.alpha_composite(fs[i%4][1],(54+(i%3)*16,24+(i//3)*16))
 html+=scene('six-rats-grid',im,'Six rats on adjacent16px cells crossing a mine, beside farmer32px and walker29px')
 im=ground(112,64);im.alpha_composite(mine,(50,34))
 for i,(x,y) in enumerate([(-7,-4),(0,-2),(7,0),(-4,2),(4,4),(0,6)]):im.alpha_composite(fs[i%4][1],(46+x,32+y))
 html+=scene('six-rats-overlap',im,'Six-rat overlap test: same-cell crowd at actual game spread')
 heads=['walker','runner','tank','breaker','giant'];im=Image.new('RGBA',(16*7,48),(26,24,48,255));im.alpha_composite(by['head_rat'][0][1],(0,16));im.alpha_composite(by['rat'][0][1],(0,32))
 for i,n in enumerate(heads,1):im.alpha_composite(Image.open(ROOT/f'sprites/ui/head_{n}.png').convert('RGBA'),(i*16,16))
 html+=scene('forecast-row',im,'Rat head and rat body beside integrated forecast heads; HUD colours are not relit (night copy is reference only)')
 return html
