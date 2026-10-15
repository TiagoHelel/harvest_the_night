"""Enemy, projectile and forecast measurements; never alter art."""
from pathlib import Path
import sys
from PIL import Image,ImageChops
ROOT=Path(__file__).resolve().parents[4];sys.path.insert(0,str(ROOT/'tools'))
from check_enemy_art import silhouette
from palette import COLOURS
def check(images,p):
 by={}
 for f in p['files']:by.setdefault(f['anim'],[]).append((f,images[f['output']]))
 for fs in by.values():fs.sort(key=lambda q:q[0]['frame'])
 b=lambda im:im.getbbox();height=lambda im:b(im)[3]-b(im)[1];ret={};master=by['spitter'][0][1];mask=silhouette(master);dist={n:sum(a!=c for a,c in zip(mask,silhouette(Image.open(ROOT/f'sprites/enemies/{n}.png').convert('RGBA')))) for n in ['walker','runner','tank','breaker']};ret['silhouette_distances']=dist;ret['silhouette_distinct']=all(v>=16 for v in dist.values());ret['master_dimensions']=18<=b(master)[2]-b(master)[0]<=24 and 28<=height(master)<=30
 body=[(f,im) for n,fs in by.items() if n.startswith('spitter') for f,im in fs];ret['body_clear_border']=all(b(im)[0]>=1 and b(im)[1]>=1 and b(im)[2]<=63 and b(im)[3]==44 for f,im in body);ret['contact_band_centred']=all(abs((q[0]+q[2])/2-32)<=1 for f,im in body for q in [im.getchannel('A').crop((0,39,64,44)).getbbox()]);ret['standing_heights']=all(28<=height(im)<=30 for f,im in by['spitter']+by['spitter_walk']+[by['spitter_attack'][2]])
 deaths=[height(im) for f,im in by['spitter_death']];ret['death_heights']=deaths;ret['death_settles']=all(a>=b for a,b in zip(deaths,deaths[1:])) and deaths[-1]<=16;ret['walk_leg_alternation_review']=False
 ret['body_frames_distinct']=all(len({im.tobytes() for f,im in fs})==len(fs) for n,fs in by.items() if n.startswith('spitter'));ret['walk_not_vertical_translation']=all(a[1].tobytes()!=ImageChops.offset(b[1],0,dy).tobytes() for i,a in enumerate(by['spitter_walk']) for b in by['spitter_walk'][i+1:] for dy in range(-2,3))
 for n in ['spit','spit_splat']:
  fs=by[n];ret[n+'_clear_border']=all(b(im)[0]>=1 and b(im)[1]>=1 and b(im)[2]<im.width and b(im)[3]<im.height for f,im in fs);ret[n+'_distinct']=len({im.tobytes() for f,im in fs})==len(fs)
 ret['spit_size_4_to_6']=all(4<=max(b(im)[2]-b(im)[0],height(im))<=6 for f,im in by['spit']);areas=[sum(a>0 for r,g,b,a in im.get_flattened_data()) for f,im in by['spit_splat']];ret['effect_expands_then_fades']=areas[1]>areas[0] and areas[2]<areas[1]
 f,h=by['head_spitter'][0];box=b(h);ret['icon_bounds_ok']=box[3]==15 and box[0]>=1 and box[1]>=1 and box[2]<=15 and box[2]-box[0]<=13 and 12<=height(h)<=13;body_rgb={px[:3] for f,im in body for px in im.get_flattened_data() if px[3]};ret['head_uses_body_colours']=all(px[:3] in body_rgb for px in h.get_flattened_data() if px[3]);ret['head_eye_bone']=h.getpixel(tuple(f['inspection_eye_xy'])) in [COLOURS['bone']+(255,),COLOURS['bone_dark']+(255,)];return ret
