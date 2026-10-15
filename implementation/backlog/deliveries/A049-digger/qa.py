"""Digger contract geometry and source-motion measurements."""
from pathlib import Path
from PIL import Image,ImageChops,ImageFilter
import sys
ROOT=Path(__file__).resolve().parents[4];sys.path.insert(0,str(ROOT/'tools'));from palette import COLOURS;from check_enemy_art import silhouette
def check(images,p):
 by={}
 for f in p['files']:by.setdefault(f['anim'],[]).append((f,images[f['output']]))
 b=lambda im:im.getbbox();h=lambda im:b(im)[3]-b(im)[1];m=by['digger'][0][1];ss=silhouette(m);ds={n:sum(a!=c for a,c in zip(ss,silhouette(Image.open(ROOT/f'sprites/enemies/{n}.png').convert('RGBA')))) for n in ['walker','runner','tank','breaker']};ret={'silhouette_distances':ds,'silhouette_distinct':min(ds.values())>=16,'master_size_ok':20<=b(m)[2]-b(m)[0]<=26 and 25<=h(m)<=27,'walk_leg_alternation_review':False,'emerge_matches_walk_pose':False,'mixed_body_clod_palette_verified':False}
 body=[(f,im) for n,fs in by.items() if n.startswith('digger') for f,im in fs];ret['body_border_and_centre']=all(b(im)[0]>=1 and b(im)[1]>=1 and b(im)[2]<=63 and b(im)[3]==44 and abs((b(im)[0]+b(im)[2])/2-32)<=1 for f,im in body);ret['standing_scale_ok']=all(25<=h(im)<=27 for f,im in by['digger']+by['digger_walk']+[by['digger_emerge'][3],by['digger_attack'][2]])
 hs=[h(im) for f,im in by['digger_death']];ret['death_heights']=hs;ret['death_settles']=all(a>=c for a,c in zip(hs,hs[1:])) and hs[-1]<=16
 a=by['digger_burrow'][3][1];c=by['digger_mound'][0][1];ret['burrow_meets_mound']=abs(h(a)-h(c))<=1 and abs((b(a)[2]-b(a)[0])-(b(c)[2]-b(c)[0]))<=1;ret['burrow_mound_bounds']=[b(a),b(c)]
 ret['frames_distinct']=all(len({im.tobytes() for f,im in fs})==len(fs) for n,fs in by.items());ret['walk_mound_not_vertical_shift']=all(a[1].tobytes()!=ImageChops.offset(c[1],0,dy).tobytes() for n in ['digger_walk','digger_mound'] for i,a in enumerate(by[n]) for c in by[n][i+1:] for dy in range(-2,3));ret['mound_height_ok']=all(5<=h(im)<=7 for f,im in by['digger_mound']);f,head=by['head_digger'][0];q=b(head);ret['icon_bounds_ok']=q[3]==15 and q[0]>=1 and q[1]>=1 and q[2]<=15 and q[2]-q[0]<=13 and 12<=h(head)<=13;ret['head_eye_bone']=head.getpixel(tuple(f['inspection_eye_xy'])) in [COLOURS['bone']+(255,),COLOURS['bone_dark']+(255,)];return ret
