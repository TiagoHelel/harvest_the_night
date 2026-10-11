from pathlib import Path
from PIL import Image
import itertools
D=Path(__file__).resolve().parent;ROOT=D.parents[3]
def check(images,plan):
 fs=plan['files'];bounds=all(im.getbbox()[0]>=1 and im.getbbox()[1]>=1 and im.getbbox()[2]<im.width and im.getbbox()[3]<im.height for im in images.values());density=all(sum(a>0 for r,g,b,a in im.get_flattened_data())>(7 if im.width==10 else 24) for im in images.values());colour=all(len({p[:3] for p in im.get_flattened_data() if p[3]})>=2 for im in images.values());unique=all(len({im.tobytes() for im in images.values() if im.width==size})==sum(im.width==size for im in images.values()) for size in [10,16,32]);samecrop=all(len({tuple(f['recipe']['crop_xywh']) for f in fs if f['resource_id']==id})==1 for id in {f['resource_id'] for f in fs});centred=all(abs((im.getbbox()[0]+im.getbbox()[2])/2-im.width/2)<=1 and abs((im.getbbox()[1]+im.getbbox()[3])/2-im.height/2)<=1 for im in images.values());existing=[Image.open(p).convert('RGBA').tobytes() for p in (ROOT/'sprites/ui').glob('*.png')];different=all(im.tobytes() not in existing for im in images.values());ret={'icon_bounds_ok':bounds,'icon_margin_ok':bounds,'icon_density':density,'icon_colours_at_least2':colour,'icons_unique':unique,'same_crop_per_pair':samecrop,'centred_on_pivot':centred,'different_from_existing_icons':different}
 if D.name.startswith('A022'):
  masks=[list(im.getchannel('A').get_flattened_data()) for im in images.values() if im.width==32];dist=[sum(a!=b for a,b in zip(x,y)) for x,y in itertools.combinations(masks,2)];ret['silhouettes_distinct']=all(d>=24 for d in dist);ret['silhouette_min_distance']=min(dist) if dist else None
 return ret
