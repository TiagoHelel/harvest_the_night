"""Check all source-owned crop stages, grounded geometry and exposed wet soil."""
import sys
import art_ownership
import import_art

KINDS=('wheat','corn','carrot')

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
    measured=[]
    for kind in KINDS:
        stages=[images['crops/'+kind+'_'+str(i)] for i in range(4)]
        heights=[]
        for i,im in enumerate(stages):
            e=entries['crops/'+kind+'_'+str(i)]
            canvas,pivot=([16,24],[8,22]) if kind=='corn' else ([16,16],[8,14])
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
    print('OK: 14 source-exact crop/soil outputs; progressive stages; grounded tall corn; wet cue exposed under every stage')
    for key,height,exposed in measured:print(key,'height',height,'exposed wet pixels',exposed)
    return 0

if __name__=='__main__':
    try:sys.exit(main())
    except (ValueError,KeyError,OSError) as error:
        print('FAIL: '+str(error));sys.exit(1)
