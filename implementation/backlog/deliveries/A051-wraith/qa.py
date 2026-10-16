"""Wraith contact, float, palette, alpha and portrait checks."""
from pathlib import Path
from PIL import Image,ImageChops
import sys,numpy as np
ROOT=Path(__file__).resolve().parents[4];sys.path.insert(0,str(ROOT/'tools'));from palette import COLOURS;from check_enemy_art import silhouette
def check(images,p):
 by={}
 for f in p['files']:by.setdefault(f['anim'],[]).append((f,images[f['output']]))
 b=lambda im:im.getbbox();h=lambda im:b(im)[3]-b(im)[1];m=by['wraith'][0][1];ss=silhouette(m);ds={n:sum(a!=c for a,c in zip(ss,silhouette(Image.open(ROOT/f'sprites/enemies/{n}.png').convert('RGBA')))) for n in ['walker','runner','tank','breaker']};body=[(f,im) for n,fs in by.items() if n.startswith('wraith') for f,im in fs];ret={'silhouette_distances':ds,'silhouette_distinct':min(ds.values())>=16,'master_size_ok':18<=b(m)[2]-b(m)[0]<=24 and 30<=h(m)<=32,'body_border_centre':all(b(im)[0]>=1 and b(im)[1]>=1 and b(im)[2]<=63 and b(im)[3]==44 and abs((b(im)[0]+b(im)[2])/2-32)<=1 for f,im in body),'float_height_ok':all(30<=h(im)<=32 for f,im in by['wraith']+by['wraith_walk']+[by['wraith_attack'][2]])}
 hs=[h(im) for f,im in by['wraith_death']];ret['death_heights']=hs;ret['death_settles']=all(a>=c for a,c in zip(hs,hs[1:])) and hs[-1]<=6;ret['frames_distinct']=all(len({im.tobytes() for f,im in fs})==len(fs) for n,fs in by.items());ret['float_not_vertical_shift']=all(a[1].tobytes()!=ImageChops.offset(c[1],0,dy).tobytes() for i,a in enumerate(by['wraith_walk']) for c in by['wraith_walk'][i+1:] for dy in range(-2,3))
 audit={}
 for source in sorted({f['source'] for f,im in body}):
  a=np.array(Image.open(Path(__file__).parent/source).getchannel('A'));mask=a>=128;pad=np.pad(mask,((18,18),(0,0)));v=np.zeros_like(mask)
  for i in range(37):v|=pad[i:i+a.shape[0],:]
  pad=np.pad(v,((0,0),(18,18)));d=np.zeros_like(mask)
  for i in range(37):d|=pad[:,i:i+a.shape[1]]
  audit[source]=int(a[~d].max()) if (~d).any() else 0
 ret['raw_outside_alpha_max']=audit;ret['source_halo_absent']=max(audit.values())<=1
 f,head=by['head_wraith'][0];q=b(head);ret['icon_bounds_ok']=q[3]==15 and q[0]>=1 and q[1]>=1 and q[2]<=15 and q[2]-q[0]<=13 and 12<=h(head)<=13;rgb={px[:3] for f,im in body for px in im.get_flattened_data() if px[3]};ret['head_body_palette_only']=all(px[:3] in rgb for px in head.get_flattened_data() if px[3]);ret['head_eyes_bone']=all(head.getpixel(tuple(pt)) in [COLOURS['bone']+(255,),COLOURS['bone_dark']+(255,)] for pt in f['inspection_eye_xy']);return ret
