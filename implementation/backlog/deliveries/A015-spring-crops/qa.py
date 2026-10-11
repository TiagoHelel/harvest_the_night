from pathlib import Path
import importlib.util
D=Path(__file__).resolve().parent
s=importlib.util.spec_from_file_location('spring_base',D/'qa_base.py');m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
def check(images,plan):
 r=m.check(images,plan);by={}
 for f in plan['files']:by.setdefault(f['anim'],[]).append((f,images[f['output']]))
 limits={'potato':[(2,3),(4,5),(7,8),(10,12)],'garlic':[(2,3),(4,6),(7,9),(10,12)],'strawberry':[(2,3),(4,5),(6,7),(8,10)]};height=lambda im:im.getbbox()[3]-im.getbbox()[1]
 r['stage_targets']=all(lo<=height(im)<=hi for id,ll in limits.items() for (f,im),(lo,hi) in zip(by[id],ll));r['stages_rise']=all(all(height(a[1])<height(b[1]) for a,b in zip(by[id],by[id][1:])) for id in limits);r['regrow_height']=6<=height(by['strawberry_regrow'][0][1])<=10
 r['wet_cue_exposed']=all(sum(im.getpixel((x,y))[3]>0 for x in range(im.width) for y in range(max(0,f['pivot_xy'][1]-16),f['pivot_xy'][1]))<=150 for f in plan['files'] if f['grounded'] for im in [images[f['output']]])
 r['packets_same_box']=all(list(im.getbbox())==([2,1,14,15] if im.width==16 else [2,1,9,9]) for f in plan['files'] if '_seed' in f['anim'] for im in [images[f['output']]])
 return r
