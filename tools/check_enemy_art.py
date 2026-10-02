"""Verify source ownership, authored motion, contact envelopes and silhouette identity."""
import itertools
from PIL import Image, ImageChops
import import_art
import gen_sprites

FAMILIES = ('walker','runner','tank','breaker')
COUNTS = {'master':1,'walk':4,'attack':3,'death':4}

def silhouette(image):
    alpha=image.getchannel('A'); box=alpha.getbbox()
    crop=alpha.crop(box)
    # Occupancy at 16x16, independent of transparent animation clearance.
    mask=[]
    for y in range(16):
        for x in range(16):
            x0,y0=x*crop.width//16,y*crop.height//16
            x1,y1=max(x0+1,(x+1)*crop.width//16),max(y0+1,(y+1)*crop.height//16)
            mask.append(crop.crop((x0,y0,x1,y1)).getbbox() is not None)
    return mask

def main():
    data=import_art.load_manifest(); files,images=import_art.build(data)
    entries={e['id']:e for e in data['assets']}
    if gen_sprites.migrated_enemies() != {'enemies/'+f for f in FAMILIES}:
        raise ValueError('Incomplete authored enemy ownership')
    old=gen_sprites.everything(dispatch=False)
    signatures={}
    for family in FAMILIES:
        for motion,count in COUNTS.items():
            frames=[e for e in data['assets'] if e.get('enemy_family')==family and e.get('enemy_motion')==motion and 'source' in e]
            if len(frames)!=count or sorted(e['frame'] for e in frames)!=list(range(count)):
                raise ValueError('Missing authored frames: '+family+'/'+motion)
            scales={e['content_scale'] for e in frames}
            if len(scales)!=1 or len({e['source'] for e in frames})!=1:
                raise ValueError('Per-frame source or scale drift: '+family+'/'+motion)
            seen=[];heights=[]
            for e in sorted(frames,key=lambda x:x['frame']):
                if e.get('generation_task')!='0015' or not e['source'].startswith('assets/art_source/enemies/'+family+'/'):
                    raise ValueError('Another identity or provisional recipe owns '+e['id'])
                if e['canvas_wh']!=[64,48] or e['pivot_xy']!=[32,44] or e['cell_offset_xy']!=[-24,-28]:
                    raise ValueError('Enemy ground/contact drift: '+e['id'])
                image=images[e['id']]; box=image.getbbox()
                if not box or box[0]<1 or box[1]<1 or box[2]>=64 or box[3]!=44:
                    raise ValueError('Floating or clipped pose: '+e['id'])
                if any(p[3] not in (0,255) for p in import_art.samples(image)):
                    raise ValueError('Enemy alpha halo: '+e['id'])
                if image.tobytes() in seen:
                    raise ValueError('Repeated motion drawing: '+e['id'])
                seen.append(image.tobytes());heights.append(box[3]-box[1])
                if (import_art.ROOT/e['output']).read_bytes()!=files[e['output']]:
                    raise ValueError('Runtime enemy diverges from source: '+e['id'])
                if e['output'].removeprefix('sprites/') in old:
                    raise ValueError('Old procedural drawing still produced: '+e['id'])
            if motion=='death' and (heights[-1]>16 or any(a<b for a,b in zip(heights,heights[1:]))):
                raise ValueError('Collapse enlarges/stands back up: '+family)
            if motion=='walk':
                # A row shift must never stand in for articulation.
                for a,b in itertools.combinations(frames,2):
                    ia,ib=images[a['id']],images[b['id']]
                    for dy in range(-2,3):
                        if ImageChops.difference(ImageChops.offset(ia,0,dy),ib).getbbox() is None:
                            raise ValueError('Translated walk clone: '+family)
        signatures[family]=silhouette(images['enemies/'+family])
        for alias,target in (('walk_b','walk_2'),('attack','attack_1'),('death','death_3')):
            e=entries['enemies/'+family+'_'+alias]
            if e.get('alias_of')!='enemies/'+family+'_'+target or e.get('operation')!='copy' or e['input']!=e['alias_of']:
                raise ValueError('Stale legacy compatibility alias: '+e['id'])
            if files[e['output']]!=files[entries[e['input']]['output']]:
                raise ValueError('Compatibility alias changes source pixels: '+e['id'])
    distances={a+'/'+b:sum(x!=y for x,y in zip(signatures[a],signatures[b])) for a,b in itertools.combinations(FAMILIES,2)}
    if min(distances.values())<16:raise ValueError('Ambiguous black enemy silhouettes: '+str(distances))
    print('OK: 48 authored enemy poses, 12 exact aliases, fixed contacts, 4/3/4 motion; silhouette differences '+str(distances))

if __name__=='__main__':main()
