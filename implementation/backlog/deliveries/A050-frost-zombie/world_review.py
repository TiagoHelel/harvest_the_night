"""Death/shatter co-timing beside game tower; preview composition only."""
from pathlib import Path
import json
from PIL import Image
import review_base
D=Path(__file__).resolve().parent;ROOT=D.parents[3]
def render(images,p,out):
 html=review_base.render(images,p,out);by={}
 for f in p['files']:by.setdefault(f['anim'],[]).append(f)
 bg=Image.new('RGBA',(144,88));grass=Image.open(ROOT/'sprites/terrain/grass.png').convert('RGBA')
 for y in range(0,88,16):
  for x in range(0,144,16):bg.alpha_composite(grass,(x,y))
 bg.alpha_composite(Image.open(ROOT/'sprites/buildings/gun_tower.png').convert('RGBA'),(48,20));bg.alpha_composite(Image.open(ROOT/'implementation/fhd-player/pilots/2026-10-06/walk-final-mirrored/native-40/walk/down/01.png').convert('RGBA'),(104,28));paths=[];nights=[]
 for i in range(4):
  im=bg.copy();im.alpha_composite(images[by['frost_zombie_death'][i]['output']],(16,20));im.alpha_composite(images[by['ice_shatter'][i]['output']],(36,40));name=f'preview/frost-world-{i}.png';night=name.replace('.png','-night.png');out[name]=review_base.png(im);out[night]=review_base.png(review_base.night(im));paths.append(name);nights.append(night)
 html+='<h2>Death and shatter together, one tile west of a tower</h2><p>World1x, FHD4x and night4x. Shatter centred12px above enemy ground. Existing tower remains visible. Final owner review pending. Alpha-compositing audit withdrew the mistaken sourcehalo diagnosis; see review log.</p>'
 for i,(z,ps) in enumerate([(1,paths),(4,paths),(4,nights)]):html+=f'<canvas id="frost-world-{i}" width="144" height="88" style="width:{144*z}px;height:{88*z}px;image-rendering:pixelated"></canvas>'
 html+='<script>(async()=>{const load=s=>new Promise(r=>{const i=new Image;i.onload=()=>r(i);i.src=s});const day=await Promise.all('+json.dumps(paths)+'.map(load)),night=await Promise.all('+json.dumps(nights)+'.map(load));let n=0;setInterval(()=>{const j=n++%16,i=Math.min(j,3);[day,day,night].forEach((fs,k)=>{const c=document.getElementById("frost-world-"+k).getContext("2d");c.imageSmoothingEnabled=false;c.clearRect(0,0,144,88);c.drawImage(fs[i],0,0)})},100)})()</script>'
 row=Image.new('RGBA',(112,48),(26,24,48,255));row.alpha_composite(images[by['head_frost_zombie'][0]['output']],(0,0));row.alpha_composite(images[by['frost_zombie'][0]['output']],(-16,4))
 for i,n in enumerate(['walker','runner','tank','breaker','giant'],1):row.alpha_composite(Image.open(ROOT/f'sprites/ui/head_{n}.png').convert('RGBA'),(16*i,0))
 out['preview/forecast-row.png']=review_base.png(row);html+='<h2>Forecast row — original HUD palette, not relit</h2><img src="preview/forecast-row.png" width="448" height="192">';return html
