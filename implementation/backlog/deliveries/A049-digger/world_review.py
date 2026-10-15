"""Fence-crossing review composed from existing rasters only."""
from pathlib import Path
import json
from PIL import Image
import review_base
D=Path(__file__).resolve().parent;ROOT=D.parents[3]
def render(images,p,out):
 html=review_base.render(images,p,out);bg=Image.new('RGBA',(160,80));grass=Image.open(ROOT/'sprites/terrain/grass.png').convert('RGBA')
 for y in range(0,80,16):
  for x in range(0,160,16):bg.alpha_composite(grass,(x,y))
 fences=[Image.open(ROOT/f'sprites/buildings/fence_join_{n}.png').convert('RGBA') for n in [2,10,8]]
 by={}
 for f in p['files']:by.setdefault(f['anim'],[]).append(f)
 def pose(anim,i):return images[by[anim][i]['output']]
 panels=[]
 for anim,i,x in [('digger_walk',0,112),('digger_burrow',1,96),('digger_mound',1,72),('digger_emerge',2,40)]:
  im=bg.copy();im.alpha_composite(pose(anim,i),(x-32,16))
  for j,fe in enumerate(fences):im.alpha_composite(fe,(64+j*16,32))
  name='preview/crossing-'+anim+'.png';out[name]=review_base.png(im);out[name.replace('.png','-night.png')]=review_base.png(review_base.night(im));panels.append('<p>'+anim+'</p><img src="'+name+'" width="640" height="320"><img src="'+name.replace('.png','-night.png')+'" width="640" height="320">')
 html+='<h2>Walk → burrow → mound under fence → emerge</h2><p>Diagnostic only.16px cells, original game fence; compare soil crest against grass at night. Known walk and return-pose faults remain above.</p>'+''.join(panels)
 row=Image.new('RGBA',(112,48),(26,24,48,255));row.alpha_composite(pose('head_digger',0),(0,0));row.alpha_composite(pose('digger',0),(-16,4))
 for i,n in enumerate(['walker','runner','tank','breaker','giant'],1):row.alpha_composite(Image.open(ROOT/f'sprites/ui/head_{n}.png').convert('RGBA'),(16*i,0))
 out['preview/forecast-row.png']=review_base.png(row);html+='<h2>Forecast row — HUD not relit</h2><img src="preview/forecast-row.png" width="448" height="192">';return html
