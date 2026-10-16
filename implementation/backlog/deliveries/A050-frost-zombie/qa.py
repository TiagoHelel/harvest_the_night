"""Frost size/contact, ice burst envelope and head colour checks."""
from pathlib import Path
from PIL import Image,ImageChops
import sys
ROOT=Path(__file__).resolve().parents[4];sys.path.insert(0,str(ROOT/'tools'));from palette import COLOURS;from check_enemy_art import silhouette
def check(images,p):
 by={}
 for f in p['files']:by.setdefault(f['anim'],[]).append((f,images[f['output']]))
 b=lambda im:im.getbbox();h=lambda im:b(im)[3]-b(im)[1];m=by['frost_zombie'][0][1];ss=silhouette(m);ds={n:sum(a!=c for a,c in zip(ss,silhouette(Image.open(ROOT/f'sprites/enemies/{n}.png').convert('RGBA')))) for n in ['walker','runner','tank','breaker']};body=[(f,im) for n,fs in by.items() if n.startswith('frost_zombie') for f,im in fs];ret={'silhouette_distances':ds,'silhouette_distinct':min(ds.values())>=16,'master_size_ok':18<=b(m)[2]-b(m)[0]<=24 and 28<=h(m)<=30,'body_border':all(b(im)[0]>=1 and b(im)[1]>=1 and b(im)[2]<=63 and b(im)[3]==44 for f,im in body),'footcontact_centred':all(abs((q[0]+q[2])/2-32)<=1 for f,im in body for q in [im.getchannel('A').crop((0,39,64,44)).getbbox()]),'standing_height_ok':all(28<=h(im)<=30 for f,im in by['frost_zombie']+by['frost_zombie_walk']+[by['frost_zombie_attack'][2]])}
 import numpy as np
 f=by['frost_zombie_walk'][0][0];a=np.array(Image.open(Path(__file__).parent/f['source']).getchannel('A'));mask=a>=128;pad=np.pad(mask,((18,18),(0,0)));v=np.zeros_like(mask)
 for i in range(37):v|=pad[i:i+a.shape[0],:]
 pad=np.pad(v,((0,0),(18,18)));d=np.zeros_like(mask)
 for i in range(37):d|=pad[:,i:i+a.shape[1]]
 ret['source_outside_alpha_max']=int(a[~d].max());ret['source_halo_absent']=ret['source_outside_alpha_max']<=1
 hs=[h(im) for f,im in by['frost_zombie_death']];ret['death_heights']=hs;ret['death_settles']=all(a>=c for a,c in zip(hs,hs[1:])) and hs[-1]<=16;ret['frames_distinct']=all(len({im.tobytes() for f,im in fs})==len(fs) for n,fs in by.items());ret['walk_not_vertical_shift']=all(a[1].tobytes()!=ImageChops.offset(c[1],0,dy).tobytes() for i,a in enumerate(by['frost_zombie_walk']) for c in by['frost_zombie_walk'][i+1:] for dy in range(-2,3))
 fx=[im for f,im in by['ice_shatter']];areas=[sum(a>0 for a in im.getchannel('A').get_flattened_data()) for im in fx];ret['effect_expands_then_fades']=areas[0]<areas[1] and areas[3]<areas[1];ret['effect_peak_and_border']=b(fx[1])[2]-b(fx[1])[0]<=22 and h(fx[1])<=18 and all(b(im)[0]>=1 and b(im)[1]>=1 and b(im)[2]<=23 and b(im)[3]<=23 for im in fx)
 f,head=by['head_frost_zombie'][0];q=b(head);ret['icon_bounds_ok']=q[3]==15 and q[0]>=1 and q[1]>=1 and q[2]<=15 and q[2]-q[0]<=13 and 12<=h(head)<=13;rgb={px[:3] for f,im in body for px in im.get_flattened_data() if px[3]};ret['head_body_palette_only']=all(px[:3] in rgb for px in head.get_flattened_data() if px[3]);ret['head_eye_bone']=head.getpixel(tuple(f['inspection_eye_xy'])) in [COLOURS['bone']+(255,),COLOURS['bone_dark']+(255,)];return ret
