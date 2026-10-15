"""Compose preview-only HUD rows from PNGs; never generate icon art with code."""
from pathlib import Path
from PIL import Image
from io import BytesIO
def render(images,p,out):
 root=Path(__file__).resolve().parents[4];base=root/'implementation/backlog/deliveries';ids=['decoy','beehive','catapult','garlic_braid','searchlight','electric_fence','wall_2','sandbag_wall'];powers=['farm_bell','call_dog','emergency_repair']
 def save(rel,im):
  b=BytesIO();im.save(b,format='PNG');out[rel]=b.getvalue()
 def own(name):return images[f'native/{name}/none/01.png']
 def prior(pack,name):return Image.open(base/pack/'native'/name/'none/01.png').convert('RGBA')
 old=[prior('A005-night-icons','icon_'+n) for n in ['gun_tower','flame_tower','mortar','auto_crossbow','fence','wall','barricade','mine']]+[prior('A037-decoy','icon_zombie_bait')]
 row=Image.new('RGBA',((len(old)+len(ids))*20+4,24),(26,24,48,255))
 for i,im in enumerate(old+[own('icon_'+name) for name in ids]):row.alpha_composite(im,(4+i*20,4))
 save('preview/mixed-hotbar.png',row)
 html='<section id="hud-rows"><h2>Actual HUD rows / not relit</h2><p>Eight earlier defences, zombie bait, eight new defences. Image1x and FHD4x. World lighting previews above are reference only; the HUD keeps its source colours.</p><img src="preview/mixed-hotbar.png"><img src="preview/mixed-hotbar.png" width="'+str(row.width*4)+'">'
 for size,prefix in [(16,'icon'),(10,'hud')]:
  oldflare=prior('A005-night-icons',prefix+'_flare');ims=[oldflare]+[own(prefix+'_'+n) for n in powers];r=Image.new('RGBA',(4*(size+4)+4,size+8),(46,42,78,255))
  for i,im in enumerate(ims):r.alpha_composite(im,(4+i*(size+4),4))
  rel=f'preview/powers-{size}.png';save(rel,r);html+=f'<h3>Powers / {size}×{size}: flare · bell · dog · repair</h3><img src="{rel}"><img src="{rel}" width="{r.width*4}">'
 pairs=[('electric_fence',Image.open(root/'sprites/ui/icon_energy.png').convert('RGBA'),'energy bolt'),('sandbag_wall',prior('A032-artisan-goods','icon_sandbag'),'single sack'),('wall_2',prior('A005-night-icons','icon_wall'),'stone wall')]
 for name,old,label in pairs:
  r=Image.new('RGBA',(44,24),(26,24,48,255));r.alpha_composite(own('icon_'+name),(4,4));r.alpha_composite(old,(24,4));rel=f'preview/confusion-{name}.png';save(rel,r);html+=f'<h3>{name} vs {label}</h3><img src="{rel}"><img src="{rel}" width="176">'
 html+='<h3>All new cuts / night, night-light and panel backgrounds</h3>'
 for bgname,color in [('night',(26,24,48,255)),('night-light',(46,42,78,255)),('light',(227,222,210,255))]:
  r=Image.new('RGBA',(len(ids+powers)*32+4,52),color)
  for i,name in enumerate(ids+powers):r.alpha_composite(own('icon_'+name),(4+i*32,4));r.alpha_composite(own('hud_'+name),(7+i*32,28))
  rel=f'preview/new-icons-{bgname}.png';save(rel,r);html+=f'<p>{bgname}</p><img src="{rel}"><img src="{rel}" width="{r.width*4}">'
 return html+'</section>'
