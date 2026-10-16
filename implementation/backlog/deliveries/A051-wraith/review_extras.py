"""World fade reference: CSS only, native art remains opaque."""
from pathlib import Path
from PIL import Image
import review_base
D=Path(__file__).resolve().parent;ROOT=D.parents[3]
def render(images,p,out):
 html=review_base.render(images,p,out);by={}
 for f in p['files']:by.setdefault(f['anim'],[]).append(f)
 bg=Image.new('RGBA',(144,80));grass=Image.open(ROOT/'sprites/terrain/grass.png').convert('RGBA')
 for y in range(0,80,16):
  for x in range(0,144,16):bg.alpha_composite(grass,(x,y))
 bg.alpha_composite(Image.open(ROOT/'sprites/buildings/gun_tower.png').convert('RGBA'),(104,20));bg.alpha_composite(Image.open(ROOT/'sprites/effects/flare_2.png').convert('RGBA'),(36,40));out['preview/world-bg-night.png']=review_base.png(review_base.night(bg));im=images[by['wraith_walk'][0]['output']];out['preview/world-wraith-night.png']=review_base.png(review_base.night(im));html+='<h2>Inside flare light: solid / outside light:35%</h2><p>Native1x and FHD4x. Fade is CSS only, original PNGs keep binary alpha. Dark rim remains visible over night grass.</p>'
 for z in [1,4]:
  html+='<div style="position:relative;width:'+str(144*z)+'px;height:'+str(80*z)+'px;display:inline-block;margin:8px;background-image:url(preview/world-bg-night.png);background-size:100% 100%">'
  for x,opacity in [(16,1),(72,.35)]:html+='<img src="preview/world-wraith-night.png" style="position:absolute;margin:0;left:'+str(x*z)+'px;top:'+str(20*z)+'px;width:'+str(64*z)+'px;height:'+str(48*z)+'px;opacity:'+str(opacity)+'">'
  html+='</div>'
 html+='<script>document.querySelectorAll("section[data-animation]").forEach(s=>{const c=s.querySelector("canvas.live.night");if(c){const t=document.createElement("p");t.textContent="Same night view at35%opacity — shader reference only";s.append(t);const n=c.cloneNode(true);n.style.opacity="0.35";s.append(n)}})</script>'
 row=Image.new('RGBA',(112,48),(26,24,48,255));row.alpha_composite(images[by['head_wraith'][0]['output']],(0,0));row.alpha_composite(images[by['wraith'][0]['output']],(-16,4))
 for i,n in enumerate(['walker','runner','tank','breaker','giant'],1):row.alpha_composite(Image.open(ROOT/f'sprites/ui/head_{n}.png').convert('RGBA'),(16*i,0))
 out['preview/forecast-row.png']=review_base.png(row);html+='<h2>Forecast row — HUD original colours</h2><img src="preview/forecast-row.png" width="448" height="192">';return html
