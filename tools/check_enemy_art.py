"""Verify source ownership, authored motion, contact envelopes and silhouette identity."""
import itertools
from PIL import Image, ImageChops
import import_art
import gen_sprites

FAMILIES = ('walker','runner','tank','breaker')
COUNTS = {'master':1,'walk':4,'attack':3,'death':4}
# The ordinary enemies' frame: the canvas, the pivot, the cell offset that
# stands the pivot on the cell's contact, and how low a death ends.
ORDINARY = {'canvas':[64,48],'pivot':[32,44],'offset':[-24,-28],'counts':COUNTS,'dead':16}
# The packs' ordinary enemies (task 0260 on), each its own pack and frame:
# the spitter on the four's; the rat (task 0261) on its own 24x16 at
# (12,14), three death frames lying no taller than 6.
PACK_FAMILIES = {
    'spitter':dict(ORDINARY,task='A046'),
    'rat':{'task':'A047','canvas':[24,16],'pivot':[12,14],'offset':[-4,2],
           'counts':{'master':1,'walk':4,'attack':3,'death':3},'dead':6},
    # The flying exception (task 0262): the crow flies, lands, pecks and
    # falls on 32x24 at (16,22). Flying and falling frames are clear of the
    # ground row but one body - no shadow baked in, 0249's stays code - and
    # its aliases name the flight, the peck and the fall.
    'crow':{'task':'A048','canvas':[32,24],'pivot':[16,22],'offset':[-8,-6],
            'counts':{'master':1,'fly':4,'land':1,'peck':3,'death':4},'dead':8,
            'aloft':('fly','death'),'aliases':(('walk_b','fly_2'),('attack','peck_1'),('death','death_3'))},
    # The digger (task 0263): the four's frame and motion, and its burrow,
    # its mound under a fence and its emerging, every frame on the ground.
    'digger':dict(ORDINARY,task='A049',counts={'master':1,'walk':4,'burrow':4,'mound':3,'emerge':4,'attack':3,'death':4}),
}

def bodies(image):
    """How many 8-connected opaque parts an image has."""
    alpha=image.getchannel('A');w,h=image.size
    points={(x,y) for y in range(h) for x in range(w) if alpha.getpixel((x,y))}
    parts=0
    while points:
        todo=[points.pop()];parts+=1
        while todo:
            x,y=todo.pop()
            for dx in (-1,0,1):
                for dy in (-1,0,1):
                    if (x+dx,y+dy) in points:
                        points.remove((x+dx,y+dy));todo.append((x+dx,y+dy))
    return parts

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

def spec_of(family):
    return PACK_FAMILIES.get(family,dict(ORDINARY,task='0015'))

def main():
    data=import_art.load_manifest(); files,images=import_art.build(data)
    entries={e['id']:e for e in data['assets']}
    if not {'enemies/'+f for f in FAMILIES}.issubset(gen_sprites.migrated_enemies()):
        raise ValueError('Incomplete authored enemy ownership')
    old=gen_sprites.everything(dispatch=False)
    signatures={};poses=0;aliases=0
    for family in FAMILIES+tuple(PACK_FAMILIES):
        spec=spec_of(family);task=spec['task'];canvas=spec['canvas'];pivot=spec['pivot']
        for motion,count in spec['counts'].items():
            frames=[e for e in data['assets'] if e.get('enemy_family')==family and e.get('enemy_motion')==motion and 'source' in e]
            if len(frames)!=count or sorted(e['frame'] for e in frames)!=list(range(count)):
                raise ValueError('Missing authored frames: '+family+'/'+motion)
            scales={e['content_scale'] for e in frames}
            if len(scales)!=1 or len({e['source'] for e in frames})!=1:
                raise ValueError('Per-frame source or scale drift: '+family+'/'+motion)
            seen=[];heights=[]
            for e in sorted(frames,key=lambda x:x['frame']):
                if e.get('generation_task')!=task or not e['source'].startswith('assets/art_source/enemies/'+family+'/'):
                    raise ValueError('Another identity or provisional recipe owns '+e['id'])
                if e['canvas_wh']!=canvas or e['pivot_xy']!=pivot or e['cell_offset_xy']!=spec['offset']:
                    raise ValueError('Enemy ground/contact drift: '+e['id'])
                image=images[e['id']]; box=image.getbbox()
                aloft=motion in spec.get('aloft',())
                if not box or box[0]<1 or box[1]<1 or box[2]>=canvas[0] or (box[3]>pivot[1] if aloft else box[3]!=pivot[1]):
                    raise ValueError('Floating or clipped pose: '+e['id'])
                if aloft and bodies(image)!=1:
                    raise ValueError('A shadow or a stray part baked into a flying frame: '+e['id'])
                if any(p[3] not in (0,255) for p in import_art.samples(image)):
                    raise ValueError('Enemy alpha halo: '+e['id'])
                if image.tobytes() in seen:
                    raise ValueError('Repeated motion drawing: '+e['id'])
                seen.append(image.tobytes());heights.append(box[3]-box[1])
                if (import_art.ROOT/e['output']).read_bytes()!=files[e['output']]:
                    raise ValueError('Runtime enemy diverges from source: '+e['id'])
                if e['output'].removeprefix('sprites/') in old:
                    raise ValueError('Old procedural drawing still produced: '+e['id'])
                poses+=1
            if motion=='death' and (heights[-1]>spec['dead'] or any(a<b for a,b in zip(heights,heights[1:]))):
                raise ValueError('Collapse enlarges/stands back up: '+family)
            if motion=='walk':
                # A row shift must never stand in for articulation.
                for a,b in itertools.combinations(frames,2):
                    ia,ib=images[a['id']],images[b['id']]
                    for dy in range(-2,3):
                        if ImageChops.difference(ImageChops.offset(ia,0,dy),ib).getbbox() is None:
                            raise ValueError('Translated walk clone: '+family)
        signatures[family]=silhouette(images['enemies/'+family])
        last='death_%d'%(spec['counts']['death']-1)
        for alias,target in spec.get('aliases',(('walk_b','walk_2'),('attack','attack_1'),('death',last))):
            e=entries['enemies/'+family+'_'+alias]
            if e.get('alias_of')!='enemies/'+family+'_'+target or e.get('operation')!='copy' or e['input']!=e['alias_of']:
                raise ValueError('Stale legacy compatibility alias: '+e['id'])
            if files[e['output']]!=files[entries[e['input']]['output']]:
                raise ValueError('Compatibility alias changes source pixels: '+e['id'])
            aliases+=1
    distances={a+'/'+b:sum(x!=y for x,y in zip(signatures[a],signatures[b])) for a,b in itertools.combinations(FAMILIES+tuple(PACK_FAMILIES),2)}
    if min(distances.values())<16:raise ValueError('Ambiguous black enemy silhouettes: '+str(distances))
    print('OK: %d authored enemy poses, %d exact aliases, fixed contacts, each family its own frame and motion; silhouette differences %s'%(poses,aliases,distances))

if __name__=='__main__':main()
