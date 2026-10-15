"""Check complete source-owned farm stations, authored states and quarter migration."""
import sys
from PIL import Image
import import_art

# A031's machines (task 0213): each in the box 0188 settled over its
# footprint, at full density, in four states - idle, active, hurt and the
# wreck that stands at 0 HP - every state a variant of the idle one at its
# scale and independently drawn, grounded on its pivot, with the canvas
# offset its footprint gives. The jar's firebox light and stovepipe smoke sit
# on opaque pixels of every state but the wreck, which has neither.
MACHINES={'keg':([48,56],[24,52],(2,2)),'preserves_jar':([48,56],[24,52],(2,2)),
          'dairy':([64,64],[32,60],(3,2)),'loom':([64,64],[32,60],(3,2)),'mill':([64,96],[32,92],(3,3))}
JAR_POINTS={'light_xy':[21,47],'smoke_xy':[35,22]}

# A030's coop and barn (task 0212): whole, hurt and the wreck that stands at
# 0 HP, at full density over the footprint 0183 settled - the coop 64x64 at
# (32,60) over 3x2, the barn 96x100 at (48,96) over 5x4 - with the canvas
# offset that footprint gives. Every state is A030's composition from its
# own components, grounded on its pivot and its own drawing. The whole and
# hurt ones carry the lantern and their glass (`windows_xy` on opaque pixels,
# each inside its pane); a wreck carries no light at all.
HOMES={'coop':([64,64],[32,60],(3,2)),'barn':([96,100],[48,96],(5,4))}

# A034's shut stall (task 0216): the legacy `shop`'s 32x40 at (16,36) drawn
# at 2.0 like it, A034's composition of the shop and its shutters - every
# pixel outside the shutter opening (x 6-25, y 18-27) the shop's own.
STALL_OPENING=(6,18,26,28)

FAMILY={'workshop':('buildings',[48,48],[24,44]),'kitchen':('buildings',[48,48],[24,44]),'press':('props',[48,48],[24,44]),'generator':('props',[48,48],[24,44]),'shop':('props',[32,40],[16,36]),'well':('props',[24,32],[12,30])}

def check_homes(entries,files,images):
    for name,(canvas,pivot,(fw,fh)) in HOMES.items():
        seen=[]
        for suffix in ('','_hurt','_wreck'):
            ident='buildings/'+name+suffix;e=entries[ident];im=images[ident]
            if e.get('generation_task')!='A030' or e['canvas_wh']!=canvas or e['pivot_xy']!=pivot or e.get('draw_scale',1)!=1:
                raise ValueError('Home off its box: '+ident)
            if e.get('cell_offset_xy')!=[fw*8-pivot[0],fh*16-pivot[1]]:
                raise ValueError('Home canvas offset is not its footprint\'s: '+ident)
            if e.get('operation')!='compose' or 'source' in e or any(entries[p['input']].get('assembly_component_of')!='A030' for p in e['parts']):
                raise ValueError('A layered home not promoted as its composition: '+ident)
            box=im.getbbox()
            if not box or box[3]!=pivot[1]:
                raise ValueError('Home floats above its footing: '+ident)
            if im.tobytes() in seen:raise ValueError('A home state repeats: '+ident)
            seen.append(im.tobytes())
            lit=suffix!='_wreck'
            if lit!=('windows_xy' in e) or lit!=('light_xy' in e):
                raise ValueError('Home light on the wrong state: '+ident)
            for point in e.get('windows_xy',[]):
                if im.getpixel(tuple(point))[3]!=255:
                    raise ValueError('A window lamp off its glass: '+ident)
            if (import_art.ROOT/e['output']).read_bytes()!=files[e['output']]:
                raise ValueError('Home runtime diverges from approved source: '+ident)
    return 3*len(HOMES)


def main():
    data=import_art.load_manifest();files,images=import_art.build(data)
    entries={e['id']:e for e in data['assets']}
    homes=check_homes(entries,files,images)
    shut=entries['props/shop_closed'];im=images['props/shop_closed'];shop=images['props/shop']
    if shut.get('generation_task')!='A034' or shut['canvas_wh']!=[32,40] or shut['pivot_xy']!=[16,36] or shut.get('draw_scale')!=2:
        raise ValueError('The shut stall leaves the shop\'s box or scale')
    if shut.get('operation')!='compose' or any(entries[p['input']].get('assembly_component_of')!='A034' for p in shut['parts']):
        raise ValueError('The shut stall is not A034\'s composition')
    x0,y0,x1,y1=STALL_OPENING
    moved=[(x,y) for y in range(40) for x in range(32) if not (x0<=x<x1 and y0<=y<y1) and im.getpixel((x,y))!=shop.getpixel((x,y))]
    if moved or im.tobytes()==shop.tobytes():
        raise ValueError('The shut stall is not the shop with shutters: %d pixels moved'%len(moved))
    if (import_art.ROOT/shut['output']).read_bytes()!=files[shut['output']]:
        raise ValueError('Shut stall runtime diverges')
    print('OK: the shut stall: the shop at 2.0 with its shutters, nothing moved outside the opening')
    print('OK: %d coop and barn states, full density over their footprints, grounded, lit whole and hurt, dark wrecked'%homes)
    for name,(folder,canvas,pivot) in FAMILY.items():
        master=entries[folder+'/'+name]
        states=['','_active','_hurt'] if canvas==[48,48] else ['']
        previous=[]
        for suffix in states:
            ident=folder+'/'+name+suffix;e=entries[ident];im=images[ident]
            if 'source' not in e or e['canvas_wh']!=canvas or e['pivot_xy']!=pivot or e['content_scale']!=master['content_scale']:
                raise ValueError('Station loses its independent source/shared scale/contact: '+ident)
            if e.get('generation_task')!='0012' or not e['source'].startswith('assets/art_source/buildings/'+name+'/'):
                raise ValueError('Station borrows another family or legacy state: '+ident)
            if suffix and e.get('variant_of')!=master['id']:
                raise ValueError('State is not tied to its identity master: '+ident)
            box=im.getbbox()
            if not box or box[0]<1 or box[1]<1 or box[2]>=canvas[0] or box[3]!=pivot[1]:
                raise ValueError('Station clips its canvas or floats above its contact: '+ident)
            if im.tobytes() in previous:raise ValueError('Missing independently authored state: '+ident)
            previous.append(im.tobytes())
            if any(p[3] not in (0,255) for p in import_art.samples(im)):
                raise ValueError('Runtime station has alpha halos: '+ident)
            if 'smoke_xy' in e and im.getpixel(tuple(e['smoke_xy']))[3]!=255:
                raise ValueError('Station exhaust leaves its source in this state: '+ident)
            if (import_art.ROOT/e['output']).read_bytes()!=files[e['output']]:
                raise ValueError('Station runtime diverges from approved source: '+ident)
        if len(states)>1:
            if name in ('workshop','kitchen','generator'):
                active=entries[folder+'/'+name+'_active']
                lamp=tuple(active['light_xy']);chimney=tuple(active['smoke_xy'])
                on=images[active['id']].getpixel(lamp)
                off=images[master['id']].getpixel(lamp)
                if on[3]!=255 or images[active['id']].getpixel(chimney)[3]!=255:
                    raise ValueError('Station emission floats outside its source: '+name)
                if (on[2]<=off[2] if name=='generator' else on[0]<=off[0]):
                    raise ValueError('Station light misses its authored active indicator: '+name)
            cells=[entries[folder+'/'+name+s]['sheet_cell_xywh'] for s in states]
            if not all(cells[i][0]+cells[i][2]<=cells[i+1][0] for i in range(2)):
                raise ValueError('State cuts overlap/borrow another pose: '+name)
            assembled=Image.new('RGBA',(48,48));area=0
            for x in range(2):
                for y in range(2):
                    q=entries[folder+'/'+name+'_%d_%d'%(x,y)]
                    if q.get('input')!=master['id'] or q.get('operation')!='slice' or q['slice_xywh']!=[x*24,y*24,24,24]:
                        raise ValueError('Stale quarter-based source: '+q['id'])
                    assembled.paste(images[q['id']],(x*24,y*24));area+=576
                    if (import_art.ROOT/q['output']).read_bytes()!=files[q['output']]:raise ValueError('Quarter is stale: '+q['id'])
            if area!=2304 or assembled.tobytes()!=images[master['id']].tobytes():
                raise ValueError('Quarter migration loses or duplicates station pixels: '+name)
    for name,(canvas,pivot,footprint) in MACHINES.items():
        master=entries['buildings/'+name]
        offset=[footprint[0]*8-pivot[0],footprint[1]*16-pivot[1]]
        previous=[]
        for suffix in ('','_active','_hurt','_wreck'):
            ident='buildings/'+name+suffix;e=entries[ident];im=images[ident]
            if e.get('generation_task')!='A031' or not e.get('source','').startswith('assets/art_source/buildings/machines/'):
                raise ValueError('Machine state lacks its A031 source: '+ident)
            if e['canvas_wh']!=canvas or e['pivot_xy']!=pivot or e.get('cell_offset_xy')!=offset or e.get('draw_scale',1.0)!=1.0:
                raise ValueError('Machine off its settled box, base or density: '+ident)
            if suffix and (e.get('variant_of')!=master['id'] or e['content_scale']!=master['content_scale']):
                raise ValueError('Machine state is not a same-scale variant of its idle drawing: '+ident)
            box=im.getbbox()
            if not box or box[0]<1 or box[1]<1 or box[2]>=canvas[0] or box[3]!=pivot[1]:
                raise ValueError('Machine clips its canvas or floats above its base: '+ident)
            if any(p[3] not in (0,255) for p in import_art.samples(im)):
                raise ValueError('Machine has alpha halos: '+ident)
            if im.tobytes() in previous:raise ValueError('Machine state is another state drawn again: '+ident)
            previous.append(im.tobytes())
            points={k:e[k] for k in ('light_xy','smoke_xy') if k in e}
            wanted=JAR_POINTS if name=='preserves_jar' and suffix!='_wreck' else {}
            if points!=wanted or any(im.getpixel(tuple(p))[3]!=255 for p in points.values()):
                raise ValueError('Machine emission points drift or float: '+ident)
            if (import_art.ROOT/e['output']).read_bytes()!=files[e['output']]:
                raise ValueError('Machine runtime diverges from approved source: '+ident)
    print('OK: 6 coherent masters/fixtures, 12 distinct authored production states, 16 exact migrated quarters, fixed canvas/contact/scale and binary alpha'
          '; 5 A031 machines in 4 states each, on their bases, the jar lit and smoking where A031 drew its firebox')
    return 0

if __name__=='__main__':
    try:sys.exit(main())
    except (ValueError,KeyError,OSError) as error:print('FAIL: '+str(error));sys.exit(1)
