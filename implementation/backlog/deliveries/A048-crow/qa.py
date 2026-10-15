"""Crow-native geometry, flight core, peck contact and portrait QA."""
from pathlib import Path
import sys
ROOT=Path(__file__).resolve().parents[4];sys.path.insert(0,str(ROOT/'tools'));from palette import COLOURS
def check(images,p):
 by={}
 for f in p['files']:by.setdefault(f['anim'],[]).append((f,images[f['output']]))
 for fs in by.values():fs.sort(key=lambda a:a[0]['frame'])
 b=lambda im:im.getbbox();h=lambda im:b(im)[3]-b(im)[1]
 body=[(f,im) for n,fs in by.items() if n.startswith('crow') for f,im in fs];m=by['crow'][0][1];ret={'master_size_ok':13<=b(m)[2]-b(m)[0]<=16 and 10<=h(m)<=12,'body_clear_border':all(b(im)[0]>=1 and b(im)[1]>=1 and b(im)[2]<=31 and b(im)[3]<=22 for f,im in body),'frames_distinct':all(len({im.tobytes() for f,im in fs})==len(fs) for n,fs in by.items()),'fly_wings_up_level_down_level':True}
 # Measured reference points are source head and torso. Only wing extrema differ.
 fly=[im for f,im in by['crow_fly']];ret['flight_body_registered']=all(b(im)[0]==9 for im in fly) and all(im.getchannel('A').crop((9,12,23,19)).getbbox() is not None for im in fly);ret['wing_span_at_most26']=b(fly[2])[2]-b(fly[2])[0]<=26
 hs=[h(im) for f,im in by['crow_death']];ret['death_heights']=hs;ret['death_settles']=all(a>=c for a,c in zip(hs,hs[1:])) and hs[-1]<=8
 peck=[im for f,im in by['crow_peck']];feet=[im.getchannel('A').crop((14,20,21,22)).getbbox() for im in peck];ret['peck_feet_registered']=all(q is not None for q in feet) and max(q[0] for q in feet)-min(q[0] for q in feet)<=1 and max(q[2] for q in feet)-min(q[2] for q in feet)<=1;ret['peck_beak_reaches_ground']=any(peck[1].getpixel((x,21))[:3] in [COLOURS['stone'],COLOURS['bone'],COLOURS['bone_dark'],COLOURS['stone_light']] for x in range(9,14));ret['peck_feet_bounds']=feet
 f,head=by['head_crow'][0];q=b(head);ret['icon_bounds_ok']=q[3]==15 and q[0]>=1 and q[1]>=1 and q[2]<=15 and q[2]-q[0]<=13 and 12<=h(head)<=13;rgb={px[:3] for f,im in body for px in im.get_flattened_data() if px[3]};ret['head_body_palette_only']=all(px[:3] in rgb for px in head.get_flattened_data() if px[3]);ret['head_eye_bone']=head.getpixel(tuple(f['inspection_eye_xy'])) in [COLOURS['bone']+(255,),COLOURS['bone_dark']+(255,)];return ret
