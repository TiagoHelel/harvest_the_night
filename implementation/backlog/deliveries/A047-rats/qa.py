"""Native rat/scurry/portrait acceptance measurements; no drawing."""
from pathlib import Path
import sys
from PIL import ImageChops
ROOT=Path(__file__).resolve().parents[4];sys.path.insert(0,str(ROOT/'tools'));from palette import COLOURS
def check(images,p):
 by={}
 for f in p['files']:by.setdefault(f['anim'],[]).append((f,images[f['output']]))
 for fs in by.values():fs.sort(key=lambda q:q[0]['frame'])
 b=lambda im:im.getbbox();height=lambda im:b(im)[3]-b(im)[1];body=[(f,im) for n,fs in by.items() if n.startswith('rat') for f,im in fs];master=by['rat'][0][1];ret={'master_size_ok':15<=b(master)[2]-b(master)[0]<=20 and 7<=height(master)<=9,'body_clear_border':all(b(im)[0]>=1 and b(im)[1]>=1 and b(im)[2]<=23 and b(im)[3]==14 for f,im in body),'body_contact_centred':all(abs((q[0]+q[2])/2-12)<=1 for f,im in body for q in [im.getchannel('A').crop((0,12,24,14)).getbbox()]),'standing_height_7_to_9':all(7<=height(im)<=9 for f,im in by['rat']+by['rat_walk']+[by['rat_attack'][2]]),'walk_length_at_most20':all(b(im)[2]-b(im)[0]<=20 for f,im in by['rat_walk']),'body_frames_distinct':all(len({im.tobytes() for f,im in fs})==len(fs) for n,fs in by.items() if n.startswith('rat')),'walk_not_vertical_shift':all(a[1].tobytes()!=ImageChops.offset(c[1],0,dy).tobytes() for i,a in enumerate(by['rat_walk']) for c in by['rat_walk'][i+1:] for dy in range(-2,3))}
 hs=[height(im) for f,im in by['rat_death']];ret['death_heights']=hs;ret['death_settles']=all(a>=c for a,c in zip(hs,hs[1:])) and hs[-1]<=6;atk=[b(im)[0] for f,im in by['rat_attack']];ret['bite_forward_one_to_three']=1<=atk[0]-atk[1]<=3
 f,h=by['head_rat'][0];box=b(h);ret['icon_bounds_ok']=box[3]==15 and box[0]>=1 and box[1]>=1 and box[2]<=15 and box[2]-box[0]<=13 and 12<=height(h)<=13;rgb={px[:3] for f,im in body for px in im.get_flattened_data() if px[3]};ret['head_body_palette_only']=all(px[:3] in rgb for px in h.get_flattened_data() if px[3]);ret['head_eye_bone']=h.getpixel(tuple(f['inspection_eye_xy'])) in [COLOURS['bone']+(255,),COLOURS['bone_dark']+(255,)];return ret
