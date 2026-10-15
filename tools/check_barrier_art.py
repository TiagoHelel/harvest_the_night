"""Verify exact source-owned barrier joins, honest occupancy extents and wear."""
from pathlib import Path
import json
import import_art
import gen_sprites

ROOT=import_art.ROOT

def main():
    data=import_art.load_manifest()
    files,images=import_art.build(data)
    entries=[e for e in data['assets'] if e.get('generation_task')=='0014']
    assert len(entries)==84,('Barrier contract incomplete',len(entries))
    # Task 0236: A037's decoy and bait, on the ground beside the barriers.
    decoy=[e for e in data['assets'] if e.get('generation_task')=='A037' and e['id'].startswith('buildings/')]
    assert len(decoy)==10,('Decoy contract incomplete',len(decoy))
    # Task 0239: A040's garlic braid, fresh, wilted and spent.
    garlic=[e for e in data['assets'] if e.get('generation_task')=='A040']
    assert len(garlic)==3,('Garlic braid contract incomplete',len(garlic))
    # Task 0241: A042's electric fence - six modules, the wreck and 32
    # composed masks - joined as the wooden fence is.
    electric=[e for e in data['assets'] if e.get('generation_task')=='A042' and e['id'].startswith('buildings/')]
    assert len(electric)==39,('Electric fence contract incomplete',len(electric))
    by_id={e['id']:e for e in entries+decoy+garlic+electric}
    for e in entries+decoy+garlic+electric:
        assert (ROOT/e['output']).read_bytes()==files[e['output']],e['id']
        assert all(p[3] in (0,255) for p in import_art.samples(images[e['id']])),e['id']
    for family in ('wall','fence','electric_fence'):
        for suffix in ('','_hurt'):
            for mask in range(16):
                ident='buildings/'+family+(f'_join_{mask}' if mask else '')+suffix
                e=by_id[ident];image=images[ident];a=image.getchannel('A');box=a.getbbox()
                assert e['canvas_wh']==[16,32] and e['pivot_xy']==[8,28] and e['cell_offset_xy']==[0,-12],ident
                assert e['join_mask']==mask and e['operation']=='compose',ident
                assert len(e['parts'])==1+mask.bit_count(),ident
                parents={p['input'] for p in e['parts']}
                assert parents <= {f'buildings/modules/{family}_{role}{suffix}' for role in ('post','horizontal','vertical')},ident
                assert e['parts'][-1]['input']==f'buildings/modules/{family}_post{suffix}',ident
                assert e['input']==e['parts'][-1]['input'],('Primary source is not the contact post',ident)
                assert bool(a.crop((0,0,1,32)).getbbox())==bool(mask&8),('West arm does not match occupancy',ident)
                assert bool(a.crop((15,0,16,32)).getbbox())==bool(mask&2),('East arm does not match occupancy',ident)
                post=images[f'buildings/modules/{family}_post{suffix}'].getchannel('A').getbbox()
                assert (box[1]<post[1])==bool(mask&1),('North arm does not match occupancy',ident,box,post)
                assert (box[3]>20)==bool(mask&4),('South arm does not match occupancy',ident,box)
                whole=images['buildings/'+family+(f'_join_{mask}' if mask else '')]
                damaged=images['buildings/'+family+(f'_join_{mask}' if mask else '')+'_hurt']
                changed=sum(p!=q for p,q in zip(import_art.samples(whole),import_art.samples(damaged)))
                assert changed>=3,('Wear vanished at native size',family,mask,changed)
                assert whole.getchannel('A').tobytes()!=damaged.getchannel('A').tobytes(),('Wear only changes tint',family,mask)
                # Every connected east/west cut shares opaque rows at the cell
                # boundary, for wood/stone and whole/hurt mixed neighbors.
                if mask&2 and family!='electric_fence':
                    for other in ('wall','fence'):
                        for other_suffix in ('','_hurt'):
                            neighbor=images['buildings/'+other+'_join_8'+other_suffix]
                            touch=sum(bool(image.getpixel((15,y))[3] and neighbor.getpixel((0,y))[3]) for y in range(32))
                            assert touch>=2,('Open seam between occupied cells',ident,other,other_suffix)
                if mask&1 and family!='electric_fence':
                    for other in ('wall','fence'):
                        for other_suffix in ('','_hurt'):
                            neighbor=images['buildings/'+other+'_join_4'+other_suffix]
                            touch=sum(bool(image.getpixel((x,y))[3] and neighbor.getpixel((x,y+16))[3])
                                      for y in range(16) for x in range(16))
                            assert touch>=2,('Open north/south projection seam',ident,other,other_suffix,touch)
        scales={by_id[f'buildings/modules/{family}_{role}{suffix}']['content_scale'] for role in ('post','horizontal','vertical') for suffix in ('','_hurt')}
        assert len(scales)==1,('Physical scale drift',family)
        wreck=images[f'buildings/{family}_wreck']
        assert wreck.getchannel('A').getbbox()[3]-wreck.getchannel('A').getbbox()[1]<=8,('Standing wreck',family)
    # Task 0236: A037's decoy stands on the walls' one-cell canvas.
    for family,suffixes,canvas,pivot in [('barricade',('','_hurt','_wreck'),[16,24],[8,20]),('mine',('','_triggered','_spent'),[16,16],[8,14]),('decoy',('','_hurt','_wreck'),[16,32],[8,28]),('garlic_braid',('','_wilted','_spent'),[16,24],[8,20])]:
        frames=[by_id['buildings/'+family+s] for s in suffixes]
        assert len({e['content_scale'] for e in frames})==1,family
        assert len({files[e['output']] for e in frames})==3,('Duplicate states',family)
        for e in frames:assert e['canvas_wh']==canvas and e['pivot_xy']==pivot,e['id']
        # Task 0239: the braid's stake stands on its pivot's row in every state.
        if family=='garlic_braid':
            for e in frames:assert images[e['id']].getbbox()[3]==pivot[1],('Floats or sinks',e['id'],images[e['id']].getbbox())
    # Task 0236: the decoy's two sways, three frames each on its canvas and
    # pivot, one scale a strip, and the bait lying on the mine's.
    for sway in ('decoy_sway','decoy_hurt_sway'):
        frames=[by_id['buildings/%s_%d'%(sway,i)] for i in range(3)]
        assert len({e['content_scale'] for e in frames})==1,sway
        assert len({files[e['output']] for e in frames})==3,('Duplicate frames',sway)
        for i,e in enumerate(frames):assert e['canvas_wh']==[16,32] and e['pivot_xy']==[8,28] and e['frame']==i and not e['loop'],e['id']
    bait=by_id['buildings/zombie_bait'];assert bait['canvas_wh']==[16,16] and bait['pivot_xy']==[8,14],'Bait off the ground'
    assert gen_sprites.migrated_barriers()=={'buildings/'+f for f in ('wall','fence','barricade','mine')},'Incomplete legacy migration'
    # The wire meets the wooden fence: a straight run's east edge shares
    # opaque rows with the fence's west arm, whole and hurt.
    for suffix in ('','_hurt'):
        run=images['buildings/electric_fence_join_10'+suffix];wood=images['buildings/fence_join_8'+suffix]
        touch=sum(bool(run.getpixel((15,y))[3] and wood.getpixel((0,y))[3]) for y in range(32))
        assert touch>=2,('Wire and wood never meet',suffix,touch)
    print('OK: 84 exact source-owned outputs, A037 decoy/bait 10, A040 garlic braid 3 and A042 electric fence 39, all 96 occupancy masks/wear states, physical scale and mixed material seams')

if __name__=='__main__':main()
