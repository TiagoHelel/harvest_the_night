"""Crow in existing world rasters, 10px runtime lift and code shadow reference."""
from pathlib import Path
import json
from PIL import Image
import review_base
D=Path(__file__).resolve().parent;ROOT=D.parents[3]
def render(images,p,out):
 html=review_base.render(images,p,out);by={}
 for f in p['files']:by.setdefault(f['anim'],[]).append((f,images[f['output']]))
 def load(n):return Image.open(ROOT/n).convert('RGBA')
 grass=load('sprites/terrain/grass.png');wall=load('sprites/buildings/wall_join_10.png');shadow=load('sprites/actors/shadow.png');crop=load('sprites/crops/corn_3.png');soil=load('sprites/crops/tilled.png')
 bg=Image.new('RGBA',(144,72))
 for y in range(0,72,16):
  for x in range(0,144,16):bg.alpha_composite(grass,(x,y))
 for x in [64,80,96]:bg.alpha_composite(wall,(x,28))
 bg.alpha_composite(soil,(24,48));bg.alpha_composite(crop,(24,48));bg.alpha_composite(load('implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png'),(104,22))
 out['preview/crow-world-background.png']=review_base.png(bg)
 im=bg.copy();im.alpha_composite(shadow,(80-shadow.width//2,52-shadow.height//2));im.alpha_composite(by['crow_fly'][1][1],(64,20));im.alpha_composite(by['crow_peck'][1][1],(16,32));out['preview/crow-world.png']=review_base.png(im);out['preview/crow-world-night.png']=review_base.png(review_base.night(im))
 html+='<h2>Flight over the wall, landing and pecking corn</h2><p>Existing game scene, native1x / FHD4x / night4x. Flight is lifted10px; shadow remains on the ground. Neither is baked into sprites.</p>'+''.join('<img src="preview/crow-world'+s+'.png" width="'+str(144*z)+'" height="'+str(72*z)+'">' for s,z in [('',1),('',4),('-night',4)])
 seq=[f['output'] for f,im in by['crow_fly']]+[by['crow_land'][0][0]['output']]+[f['output'] for f,im in by['crow_peck']]*3+[by['crow_land'][0][0]['output']]
 html+='<p>Animated flight → landing → pecking → take-off:</p><canvas id="crow-scene" width="144" height="72" style="width:576px;height:288px;image-rendering:pixelated"></canvas><script>(async()=>{const load=s=>new Promise(r=>{const i=new Image;i.onload=()=>r(i);i.src=s});const paths='+json.dumps(seq)+';const bg=await load("preview/crow-world-background.png"),sh=await load("../../../../sprites/actors/shadow.png"),fs=await Promise.all(paths.map(load)),c=document.getElementById("crow-scene").getContext("2d");c.imageSmoothingEnabled=false;let n=0;setInterval(()=>{c.clearRect(0,0,144,72);c.drawImage(bg,0,0);const i=n++%fs.length,x=i<4?100-i*20:16,y=i<4?20:32;c.drawImage(sh,x+16-sh.width/2,y+22+(i<4?10:0)-sh.height/2);c.drawImage(fs[i],x,y)},120)})()</script>'
 row=Image.new('RGBA',(112,48),(26,24,48,255));row.alpha_composite(by['head_crow'][0][1],(0,8));row.alpha_composite(by['crow'][0][1],(0,24))
 for i,n in enumerate(['walker','runner','tank','breaker','giant'],1):row.alpha_composite(load('sprites/ui/head_'+n+'.png'),(16*i,8))
 out['preview/forecast-row.png']=review_base.png(row);html+='<h2>Forecast row, original HUD colours</h2><img src="preview/forecast-row.png" width="448" height="192"><p>Judge black-feather readability at1x, fixed feet during pecking, four wing poses, ground-contact beak and corpse size. Approval remains pending.</p>'
 return html
