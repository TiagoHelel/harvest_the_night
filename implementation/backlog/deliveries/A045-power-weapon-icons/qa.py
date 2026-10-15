from pathlib import Path
from PIL import Image
def check(images,p):
 root=Path(__file__).resolve().parents[4];pairs={};dims=[];margins=[];areas=[];colour=[]
 for f in p['files']:
  im=images[f['output']];b=im.getbbox();w,h=f['canvas_wh'];maxdim=14 if w==16 else 8;cx,cy=f['pivot_xy'];dims.append(max(b[2]-b[0],b[3]-b[1])<=maxdim and abs((b[0]+b[2])/2-cx)<=1 and abs((b[1]+b[3])/2-cy)<=1);margins.append(b[0]>=1 and b[1]>=1 and b[2]<=w-1 and b[3]<=h-1);areas.append(sum(a>0 for r,g,b,a in im.get_flattened_data())>(24 if w==16 else 7));colour.append(len(set(im.get_flattened_data())-{(0,0,0,0)})>=2);pairs.setdefault(f['source'],[]).append(f)
 old=[]
 for folder in [root/'sprites/ui',root/'implementation/backlog/deliveries/A005-night-icons/native']:
  for path in folder.rglob('*.png'):
   try:im=Image.open(path).convert('RGBA');old.append((im.size,im.tobytes()))
   except OSError:pass
 return {'owner_reference_exception_recorded':any(d.get('owner_words')=='Sim, usar candidatas como referência' for d in p['deviations']),'twenty_two_icons_complete':len(p['files'])==22 and len(pairs)==11,'icon_bounds_ok':all(dims),'icon_margin_ok':all(margins),'icon_opaque_counts_ok':all(areas),'at_least_two_colours':all(colour),'same_crop_per_pair':all(len(fs)==2 and fs[0]['recipe']['crop_xywh']==fs[1]['recipe']['crop_xywh'] for fs in pairs.values()),'unique_icons':len({(im.size,im.tobytes()) for im in images.values()})==len(images),'not_existing_icons':all((im.size,im.tobytes()) not in old for im in images.values()),'no_zombie_bait_output':all('zombie_bait' not in f['anim'] for f in p['files'])}
