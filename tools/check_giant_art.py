"""Validate complete Giant ownership, body/contact scale and all authored poses."""
from PIL import ImageChops
import import_art
import gen_sprites

COUNTS = {'master':1,'walk':4,'windup':3,'slam':3,'death':5}

def main():
    data=import_art.load_manifest();files,images=import_art.build(data)
    entries={e['id']:e for e in data['assets']}
    if gen_sprites.migrated_enemies() != {'enemies/'+f for f in ('walker','runner','tank','breaker','giant')}:
        raise ValueError('All five enemy families must have complete ownership')
    old=gen_sprites.everything(dispatch=False)
    for motion,count in COUNTS.items():
        frames=sorted((e for e in data['assets'] if e.get('enemy_family')=='giant' and e.get('enemy_motion')==motion and 'source' in e),key=lambda e:e['frame'])
        if len(frames)!=count or [e['frame'] for e in frames]!=list(range(count)):
            raise ValueError('Missing Giant motion: '+motion)
        if len({e['content_scale'] for e in frames})!=1 or len({e['source'] for e in frames})!=1:
            raise ValueError('Giant per-frame source/scale drift: '+motion)
        shapes=[];heights=[]
        for e in frames:
            if e.get('generation_task')!='0016' or not e['source'].startswith('assets/art_source/enemies/giant/'):
                raise ValueError('Unowned Giant pose: '+e['id'])
            if e['canvas_wh']!=[80,64] or e['pivot_xy']!=[40,60] or e['cell_offset_xy']!=[-32,-44]:
                raise ValueError('Giant contact drift: '+e['id'])
            image=images[e['id']];box=image.getbbox()
            if not box or box[0]<1 or box[1]<1 or box[2]>=80 or box[3]!=60:
                raise ValueError('Clipped or floating Giant: '+e['id'])
            if image.tobytes() in shapes:
                raise ValueError('Repeated Giant pose: '+e['id'])
            shapes.append(image.tobytes());heights.append(box[3]-box[1])
            if any(pixel[3] not in (0,255) for pixel in import_art.samples(image)):
                raise ValueError('Giant alpha fringe: '+e['id'])
            if (import_art.ROOT/e['output']).read_bytes()!=files[e['output']] or e['output'].removeprefix('sprites/') in old:
                raise ValueError('Giant source/runtime/legacy mismatch: '+e['id'])
        if motion=='windup' and not (heights[0]<heights[1]<heights[2] and heights[2]>=50):
            raise ValueError('Wind-up does not visibly raise the striking arm')
        if motion=='death' and (heights[-1]>20 or any(a<b for a,b in zip(heights,heights[1:]))):
            raise ValueError('Giant collapse does not finish low')
        if motion=='walk':
            for i,a in enumerate(frames):
                for b in frames[i+1:]:
                    for dy in range(-2,3):
                        if ImageChops.difference(ImageChops.offset(images[a['id']],0,dy),images[b['id']]).getbbox() is None:
                            raise ValueError('Giant walk is only a shifted body')
    giant=images['enemies/giant'].getbbox();gw,gh=giant[2]-giant[0],giant[3]-giant[1]
    for family in ('walker','runner','tank','breaker'):
        box=images['enemies/'+family].getbbox()
        if not (gw>box[2]-box[0] and gh>=1.3*(box[3]-box[1])):
            raise ValueError('Giant does not dominate the visible ordinary body: '+family)
    for alias,target in (('walk_b','walk_2'),('attack','slam_0'),('death','death_4'),('telegraph','windup_2')):
        e=entries['enemies/giant_'+alias]
        if e.get('alias_of')!='enemies/giant_'+target or e.get('operation')!='copy' or files[e['output']]!=files[entries[e['input']]['output']]:
            raise ValueError('Stale Giant compatibility pose: '+alias)
    print(f'OK: 16 authored Giant poses, four exact aliases, 80x64/(40,60), visible master {gw}x{gh}, real wind-up/collapse')

if __name__=='__main__':main()
