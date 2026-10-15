from pathlib import Path
from PIL import Image
from import_art import png
D=Path(__file__).resolve().parent;ROOT=D.parents[3]
def night(im):
 n=im.copy();pixels=[]
 for r,g,b,a in im.get_flattened_data():
  lit=r/255*.36,g/255*.40,b/255*.82;grey=.299*lit[0]+.587*lit[1]+.114*lit[2];pixels.append(tuple(round(max(0,min(1,grey+.76*(v-grey)+o))*255) for v,o in zip(lit,(.040,.035,.105)))+(a,))
 n.putdata(pixels);return n
def render(images,p,out):
 ordered=[images[f['output']] for f in p['files']];strip=Image.new('RGBA',(64,24))
 for i,im in enumerate(ordered):strip.alpha_composite(im,(i*24,0))
 out['preview/continuation-states.png']=png(strip);out['preview/continuation-states-night.png']=png(night(strip));out['preview/continuation-states-8x.png']=png(strip.resize((512,192),Image.Resampling.NEAREST))
 grass=Image.open(ROOT/'sprites/terrain/grass.png').convert('RGBA');context=Image.new('RGBA',(192,52));ground=44
 for y in range(0,52,16):
  for x in range(0,192,16):context.alpha_composite(grass,(x,y))
 for x,im in zip([8,32,56],ordered):context.alpha_composite(im,(x,ground-20))
 context.alpha_composite(Image.open(ROOT/'sprites/buildings/barricade.png').convert('RGBA'),(84,ground-20))
 context.alpha_composite(Image.open(ROOT/'implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png').convert('RGBA'),(112,ground-36))
 context.alpha_composite(Image.open(ROOT/'sprites/enemies/walker_walk_0.png').convert('RGBA'),(136,ground-44))
 out['preview/continuation-context-day.png']=png(context);out['preview/continuation-context-night.png']=png(night(context));out['preview/continuation-context-4x.png']=png(context.resize((768,208),Image.Resampling.NEAREST))
 return '<section><h2>Completed states: fresh / wilted / spent</h2><p>Fresh remains approved. Only wilted and spent are new review candidates. One family scale; same 16x24 canvas and (8,20) pivot.</p><img src="preview/continuation-states.png" width="64" height="24"><img src="preview/continuation-states.png" width="256" height="96"><img src="preview/continuation-states-night.png" width="256" height="96"><h3>Three night states beside the barricade, farmer and walker</h3><p>Native 1x / FHD integer 4x / night 4x. All feet share one ground line.</p><img src="preview/continuation-context-day.png" width="192" height="52"><img src="preview/continuation-context-day.png" width="768" height="208"><img src="preview/continuation-context-night.png" width="768" height="208"></section>'
