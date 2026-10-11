"""Check all source-owned crop stages, grounded geometry and exposed wet soil."""
import sys
from PIL import Image
import art_ownership
import import_art

KINDS=('wheat','corn','carrot','potato','garlic','strawberry','pepper','melon','sunflower')
# Every crop's box but the one-tile default: corn's 16x24 and the tall
# crops' 16x32 (0168), A016's sunflower the first of those (task 0199).
BOXES={'corn':([16,24],[8,22]),'sunflower':([16,32],[8,30])}
# A crop that regrows after picking (0172) shows its own stage meanwhile, at
# the crop's box: A015's strawberry (task 0198).
REGROW={'strawberry':([16,16],[8,14]),'pepper':([16,16],[8,14]),'corn':([16,24],[8,22])}
# A014's overlays (task 0197): what a crop leaves on its tile when the season
# or the horde ends it, and the turf a bed on the lawn wears, turned at
# runtime - N, E, S, W are 0-3 quarter-turns clockwise of the north edge, and
# a corner the diagonal's turn of the north-west one.
OVERLAYS=('trampled','withered')
TURF=('tilled_edge_n','tilled_edge_corner_nw')

def main():
    data=import_art.load_manifest();files,images=import_art.build(data)
    entries={e['id']:e for e in data['assets']}
    owners=art_ownership.registry()
    names=[kind+'_'+str(stage) for kind in KINDS for stage in range(4)]+['tilled','tilled_wet']
    for name in names:
        key='crops/'+name;e=entries[key]
        if owners[e['output']]!='raster' or 'source' not in e:
            raise ValueError('Crop lacks raw species/soil source: '+name)
        if (art_ownership.ROOT/e['output']).read_bytes()!=files[e['output']]:
            raise ValueError('Crop differs from its accepted source: '+name)
    soil=[images['crops/'+n] for n in ('tilled','tilled_wet')]
    for im in soil:
        if im.size!=(16,16) or im.getchannel('A').getextrema()!=(255,255):
            raise ValueError('Soil must fill one opaque logical cell')
    brightness=lambda im:sum(sum(p[:3])/3 for p in import_art.samples(im))/256
    if brightness(soil[0])-brightness(soil[1])<20:
        raise ValueError('Wet soil loses its dark moisture cue')
    # A012's winter soil (task 0163): its own sources, opaque, the wet cue
    # kept, and snow only on the ridges - today's furrow rows stay dark.
    winter=[]
    for n in ('tilled','tilled_wet'):
        key='crops/'+n+'_winter';e=entries[key]
        if owners[e['output']]!='raster' or 'source' not in e:
            raise ValueError('Winter soil lacks its raw source: '+n)
        if (art_ownership.ROOT/e['output']).read_bytes()!=files[e['output']]:
            raise ValueError('Winter soil differs from its accepted source: '+n)
        im=images[key]
        if im.size!=(16,16) or im.getchannel('A').getextrema()!=(255,255):
            raise ValueError('Winter soil must fill one opaque logical cell: '+n)
        winter.append(im)
    if brightness(winter[0])-brightness(winter[1])<20:
        raise ValueError('Winter wet soil loses its dark moisture cue')
    rows=lambda im:[sum(sum(im.getpixel((x,y))[:3])/3 for x in range(16))/16 for y in range(16)]
    furrows=[y for y,r in enumerate(rows(soil[0])) if r<sum(rows(soil[0]))/16]
    for im in winter:
        mean=sum(rows(im))/16
        if not furrows or any(rows(im)[y]>=mean for y in furrows):
            raise ValueError('Winter soil lost a furrow under the snow')
    measured=[]
    for kind,(canvas,pivot) in REGROW.items():
        key='crops/'+kind+'_regrow';e=entries[key];im=images[key];bbox=im.getbbox()
        if owners[e['output']]!='raster' or 'source' not in e or (art_ownership.ROOT/e['output']).read_bytes()!=files[e['output']]:
            raise ValueError('Regrowing stage lacks its exact source: '+kind)
        if e['canvas_wh']!=canvas or e['pivot_xy']!=pivot or not bbox or bbox[0]<1 or bbox[1]<1 or bbox[2]>15 or bbox[3]!=pivot[1]:
            raise ValueError('Clipped/misplaced regrowing stage: '+kind)
        if {p[3] for p in import_art.samples(im)}!={0,255}:
            raise ValueError('Regrowing stage transparency is not binary: '+kind)
        exposed=sum(1 for y in range(16) for x in range(16) if (not 0<=y+pivot[1]-16<im.height or im.getpixel((x,y+pivot[1]-16))[3]==0) and soil[0].getpixel((x,y))!=soil[1].getpixel((x,y)))
        if exposed<80:
            raise ValueError('Regrowing foliage hides the moisture cue: '+kind)
        measured.append((key,bbox[3]-bbox[1],exposed))
    for kind in KINDS:
        stages=[images['crops/'+kind+'_'+str(i)] for i in range(4)]
        heights=[]
        for i,im in enumerate(stages):
            e=entries['crops/'+kind+'_'+str(i)]
            canvas,pivot=BOXES.get(kind,([16,16],[8,14]))
            bbox=im.getbbox()
            if e['canvas_wh']!=canvas or e['pivot_xy']!=pivot or not bbox or bbox[0]<1 or bbox[1]<1 or bbox[2]>15 or bbox[3]!=pivot[1]:
                raise ValueError('Clipped/misplaced native crop: '+e['id'])
            if {p[3] for p in import_art.samples(im)}!={0,255}:
                raise ValueError('Crop transparency is not binary')
            heights.append(bbox[3]-bbox[1])
            exposed=sum(1 for y in range(16) for x in range(16) if (not 0<=y+pivot[1]-16<im.height or im.getpixel((x,y+pivot[1]-16))[3]==0) and soil[0].getpixel((x,y))!=soil[1].getpixel((x,y)))
            if exposed<80:
                raise ValueError('Foliage hides the moisture cue: '+e['id'])
            measured.append((e['id'],heights[-1],exposed))
        if heights!=sorted(set(heights)) or len({im.tobytes() for im in stages})!=4:
            raise ValueError('Growth does not progress through four distinct stages: '+kind)
    for name in OVERLAYS+TURF:
        key='crops/'+name;e=entries[key]
        if owners[e['output']]!='raster' or 'source' not in e:
            raise ValueError('Overlay lacks its raw source: '+name)
        if (art_ownership.ROOT/e['output']).read_bytes()!=files[e['output']]:
            raise ValueError('Overlay differs from its accepted source: '+name)
        if {p[3] for p in import_art.samples(images[key])}!={0,255}:
            raise ValueError('Overlay transparency is not binary: '+name)
    wet=[(x,y) for y in range(16) for x in range(16) if soil[0].getpixel((x,y))!=soil[1].getpixel((x,y))]
    for name in OVERLAYS:
        e=entries['crops/'+name];im=images['crops/'+name];bbox=im.getbbox()
        if e['canvas_wh']!=[16,16] or e['pivot_xy']!=[8,14] or not bbox or bbox[0]<1 or bbox[1]<1 or bbox[2]>15 or bbox[3]!=14:
            raise ValueError('Overlay off its crop tile or ungrounded: '+name)
        exposed=sum(1 for x,y in wet if not 0<=y-2<16 or im.getpixel((x,y-2))[3]==0)
        if exposed<len(wet)*3//4:
            raise ValueError('Overlay hides the moisture cue: '+name)
        measured.append(('crops/'+name,bbox[3]-bbox[1],exposed))
    edge,corner=images['crops/tilled_edge_n'],images['crops/tilled_edge_corner_nw']
    for name in TURF:
        e=entries['crops/'+name]
        if e['canvas_wh']!=[16,16] or e['pivot_xy']!=[8,16]:
            raise ValueError('Turf off its ground tile: '+name)
    x0,y0,x1,y1=edge.getbbox()
    if (x0,y0,x1)!=(0,0,16) or y1>3:
        raise ValueError('The bed edge must run the whole top of the tile, at most 3 rows deep')
    x0,y0,x1,y1=corner.getbbox()
    if (x0,y0)!=(0,0) or x1>3 or y1>3:
        raise ValueError('The bed corner must sit in the top-left, at most 3x3')
    turned=lambda im,k:im.rotate(-90*k)
    covered=lambda im:{(x,y) for y in range(16) for x in range(16) if im.getpixel((x,y))[3]}
    edges=[covered(turned(edge,k)) for k in range(4)]
    corners=[covered(turned(corner,k)) for k in range(4)]
    # Each of the 16 masks, with every corner the rule could add (a diagonal
    # whose two cardinals are both closed): the turf stays on the open sides,
    # out of the tile's middle, and leaves at least half the wet cue showing -
    # a lone plot, grass all round, is the worst.
    worst=len(wet)
    for mask in range(16):
        cover=set()
        for bit in range(4):
            if mask&(1<<bit):
                cover|=edges[bit]
            if not mask&(1<<bit) and not mask&(1<<((bit+3)%4)):
                cover|=corners[bit]
        if any(3<=x<=12 and 3<=y<=12 for x,y in cover):
            raise ValueError('Turf reaches the middle of the bed in mask %d' % mask)
        worst=min(worst,sum(1 for p in wet if p not in cover))
    if worst<len(wet)//2:
        raise ValueError('Turf hides the moisture cue: %d of %d wet pixels left' % (worst,len(wet)))
    print('OK: %d source-exact crop/soil outputs; progressive stages; grounded tall corn; wet cue exposed under every stage; winter soil: 2 exact, wet cue and furrows kept'
          '; A014: trampled and withered grounded, turf edge and corner on all 16 masks, %d of %d wet pixels left at worst' % (4*len(KINDS)+2+len(REGROW),worst,len(wet)))
    for key,height,exposed in measured:print(key,'height',height,'exposed wet pixels',exposed)
    return 0

if __name__=='__main__':
    try:sys.exit(main())
    except (ValueError,KeyError,OSError) as error:
        print('FAIL: '+str(error));sys.exit(1)
