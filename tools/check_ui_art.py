"""Check every UI icon family at both native sizes and code-owned frame profiles.

The resource icons of task 0018 are checked against their generation plans. The
Codex packs' icon pairs (task 0147 on) are checked by the same rules against the
hard-coded lists below - one source and one crop per pair, the native canvas and
centred pivot, a clear margin, binary alpha, no copy of another icon - and against
their approved delivery: each runtime file decodes to the approved export's exact
RGBA pixels (the importer writes its own PNG encoding, so the file bytes differ).
"""
import json
from PIL import Image
import import_art
import art_ownership
import gen_sprites
import palette

## Codex packs of icon pairs: every id is cut twice from one source and one crop,
## `ui/icon_<id>` 16x16 at (8,8) and `ui/hud_<id>` 10x10 at (5,5).
PAIRS = {
    # Task 0147: the hotbar's eight defences and the night bar's four controls.
    'A005': ['gun_tower', 'auto_crossbow', 'flame_tower', 'mortar', 'mine', 'fence',
             'wall', 'barricade', 'flare', 'start', 'speed', 'dawn_moon'],
    # Task 0161: the calendar's four seasons and three night marks.
    'A010': ['spring', 'summer', 'autumn', 'winter', 'full_moon', 'boss_night', 'calm_night'],
    # Task 0202: the four tools at basic/iron/gold and the rod at bamboo/fibre/iron.
    'A019': ['hoe_basic', 'hoe_iron', 'hoe_gold', 'can_basic', 'can_iron', 'can_gold',
             'axe_basic', 'axe_iron', 'axe_gold', 'pickaxe_basic', 'pickaxe_iron', 'pickaxe_gold',
             'rod_bamboo', 'rod_fibre', 'rod_iron'],
    # Task 0203: the materials of the forge (0176), the hardwood (0177) and the barn (0184).
    'A020': ['copper', 'gold', 'coal', 'hardwood', 'hay', 'straw'],
    # Task 0211: the barn's and the coop's goods (0184) and the pig's truffle (0185).
    'A029': ['egg', 'milk', 'wool', 'truffle'],
    # Task 0198: spring's produce (0168) and its four seed packets (0170).
    'A015': ['potato', 'garlic', 'strawberry', 'carrot_seed', 'potato_seed', 'garlic_seed',
             'strawberry_seed'],
    # Task 0199: summer's produce (0168) and its four seed packets (0170).
    'A016': ['pepper', 'sunflower', 'melon', 'corn_seed', 'pepper_seed', 'sunflower_seed',
             'melon_seed'],
    # Task 0206: the worm and the fish bait (0181), and the fish book's tab (0182).
    'A023': ['worm', 'bait', 'book_fish'],
    # Task 0201: the three sprinklers' build-list icons (0178).
    'A018': ['copper_sprinkler', 'iron_sprinkler', 'gold_sprinkler'],
    # Task 0200: autumn's produce (0168) and its four seed packets (0170).
    'A017': ['pumpkin', 'grape', 'beet', 'wheat_seed', 'pumpkin_seed', 'grape_seed',
             'beet_seed'],
    # Task 0214: the machines' goods (0187, 0188) and the kitchen's bread (0192).
    'A032': ['wine', 'juice', 'jelly', 'pickles', 'cheese', 'butter', 'cloth', 'sandbag',
             'flour', 'sugar', 'bread'],
    # Task 0205: the twelve fish (0179) and the four legendaries (0182).
    'A022': ['carp', 'bream', 'catfish', 'dorado', 'eel', 'perch', 'pike', 'salmon', 'sturgeon',
             'sunfish', 'tilapia', 'trout', 'old_catfish', 'golden_queen', 'ghost_pike', 'ice_sturgeon'],
    # Task 0236: the zombie bait's kit (0225).
    'A037': ['zombie_bait'],
    # Task 0244: the powers' pictures and the new defences' icons.
    'A045': ['farm_bell', 'call_dog', 'emergency_repair', 'decoy', 'beehive', 'catapult',
             'garlic_braid', 'searchlight', 'electric_fence', 'wall_2', 'sandbag_wall'],
}

## A022's book portraits (task 0205): each species' third cut, 32x32 at
## (16,16), from its icon pair's source and crop. The book draws a fish never
## landed as its portrait in black, so no two portraits share a silhouette:
## 24 or more alpha pixels apart.
PORTRAITS = {'A022': PAIRS['A022']}

## A019's tiers of one tool share the recorded scale of each cut (task 0202):
## no tier is enlarged on its own.
SAME_SCALE = {'A019': ('hoe', 'can', 'axe', 'pickaxe', 'rod')}

## A020's own measures (task 0203): copper's and gold's ingots are iron's,
## as wide and within a row as tall; gold has no flame orange, so it never
## reads as money; and coal shows the steel of its facets at both sizes.
INGOTS = ('copper', 'gold')
STEEL = {palette.COLOURS['stone'], palette.COLOURS['stone_light']}

## A029's cream goods (task 0211): milk and wool keep their restricted
## cream ramps, with none of the orange skin or flame colours.
CREAM = ('milk', 'wool')
WARM = {palette.COLOURS[k] for k in ('skin', 'skin_dark', 'skin_light', 'flame', 'flame_hot')}

## The forecast's heads (task 0162): `ui/head_<kind>` 16x16 at (8,8), an exact
## crop of the enemy's live walk frame 0 - its own colours, never reduced - that
## stands on row 14 with row 15 clear. Later enemies add themselves here.
HEADS = {
    'A011': ['walker', 'runner', 'tank', 'breaker', 'giant'],
}
## The later enemies' heads, drawn by their own packs (task 0260 on): the
## same 16x16 at (8,8) standing on row 14 with row 15 clear, in the pack's
## palette rather than an exact crop.
PACK_HEADS = {
    'A046': ['spitter'],
    'A047': ['rat'],
    'A048': ['crow'],
}


## A023's fishing pieces (task 0206): the bar's frame round its 90x6 track
## at (5,5), the green's 8x6 three-patch - two pixels of cap each side, fully
## opaque - the 5x12 needle and the hit and miss flashes, three one-shot
## frames of 0.065 s on 12x12; and the 8x8 bobber standing on (4,6): its
## float, two frames round and round at 0.4 s, and its bite, three of 0.1 s
## sinking, each with the point its line ties to. The frame and the green are
## A023's compositions from its own components; nothing here emits.
FISHING = {'ui/fishbar_frame': ([100, 16], [50, 8], 1, 1, False),
           'ui/fishbar_zone': ([8, 6], [4, 3], 1, 1, False),
           'ui/fishbar_marker': ([5, 12], [2, 6], 1, 1, False),
           'ui/fishbar_hit': ([12, 12], [6, 6], 3, 0.065, False),
           'ui/fishbar_miss': ([12, 12], [6, 6], 3, 0.065, False),
           'effects/bobber_float': ([8, 8], [4, 6], 2, 0.4, True),
           'effects/bobber_bite': ([8, 8], [4, 6], 3, 0.1, False)}


## A004's cursor (task 0146): seven looks of a two-frame 0.4 s pulse, 16x16 at
## (8,8) drawn at 1.0, every frame its approved composition from A004's own
## components. No light point - it is unlit over the night - every frame its
## own, the middle clear but for aim's plus, exactly (7..9,8) and (8,7..9).
CURSOR_LOOKS = ('neutral', 'place', 'blocked', 'upgrade', 'sell', 'repair', 'aim')
AIM_PLUS = {(7, 8), (8, 8), (9, 8), (8, 7), (8, 9)}


def check_icon(e, art, size, seen, files, registry):
    """One native cut: its box, a clear margin, binary alpha, something drawn,
    told apart from every other icon of its size, and its exact bytes on disk."""
    box=art.getbbox();pixels=list(import_art.samples(art));visible=[p for p in pixels if p[3]]
    assert e['canvas_wh']==[size,size] and e['pivot_xy']==[size//2]*2
    assert not e['loop'] and e['frame']==0 and registry[e['output']]=='raster'
    assert box and 0<box[0]<box[2]<size and 0<box[1]<box[3]<size,'Clipped icon: '+e['id']
    assert all(p[3] in (0,255) for p in pixels)
    assert len(visible)>(24 if size==16 else 7) and len({p[:3] for p in visible})>=2
    fingerprint=art.tobytes();assert fingerprint not in seen[size],'Duplicate silhouettes: '+e['id'];seen[size].add(fingerprint)
    assert (import_art.ROOT/e['output']).read_bytes()==files[e['output']]


def check_approved(e, art):
    """The delivery's approved native export, decoded, is the runtime art."""
    approved=[r for r in e['references'] if r['role'].startswith('Approved native export')]
    assert len(approved)==1,'No approved export recorded for '+e['id']
    with Image.open(import_art.ROOT/approved[0]['path']) as image:
        assert image.convert('RGBA').tobytes()==art.tobytes(),'Approved pixels changed: '+e['id']


def main():
    manifest=import_art.load_manifest();files,images=import_art.build(manifest)
    plans=json.loads((import_art.ROOT/'implementation/sprites/generation/0018-plan.json').read_text(encoding='utf-8'))
    entries=[e for e in manifest['assets'] if e.get('generation_task')=='0018']
    assert len(plans)==15 and len(entries)==30,'Incomplete resource family'
    registry=art_ownership.registry();seen={16:set(),10:set()}
    for plan in plans:
        resource=plan['id']
        family=[e for e in entries if e['resource_id']==resource]
        assert len(family)==2 and len({e['source'] for e in family})==1
        assert len({tuple(e['crop_xywh']) for e in family})==1
        call=json.loads((import_art.ROOT/f'implementation/sprites/generation/0018-{resource}-call.json').read_text(encoding='utf-8'))
        assert call['actual_submitted_arguments']['transparent_background'] is True
        assert call['actual_submitted_arguments']['prompt']==(import_art.ROOT/call['prompt']).read_text(encoding='utf-8')
        for e in family:
            size=16 if e['display_role']=='inventory' else 10
            assert e['id']==f'ui/{"icon" if size==16 else "hud"}_{resource}'
            check_icon(e,images[e['id']],size,seen,files,registry)
    pairs=0
    for pack,ids in PAIRS.items():
        packed=[e for e in manifest['assets'] if e.get('generation_task')==pack
                and (e['id'].startswith('ui/icon_') or e['id'].startswith('ui/hud_'))]
        assert len(packed)==2*len(ids),'Incomplete %s family' % pack
        for ident in ids:
            family=[e for e in packed if e['id'] in ('ui/icon_'+ident,'ui/hud_'+ident)]
            assert len(family)==2 and len({e['source'] for e in family})==1,'Unpaired icon: '+ident
            assert len({tuple(e['crop_xywh']) for e in family})==1,'Two crops for one icon: '+ident
            for e in family:
                size=16 if e['display_role']=='inventory' else 10
                assert e['id']==f'ui/{"icon" if size==16 else "hud"}_{ident}'
                check_icon(e,images[e['id']],size,seen,files,registry)
                check_approved(e,images[e['id']])
                pairs+=1
        for tool in SAME_SCALE.get(pack,()):
            for cut in ('icon','hud'):
                scales={e['content_scale'] for e in packed if e['id'].startswith('ui/%s_%s_' % (cut,tool))}
                assert len(scales)==1,'Tiers of one tool differ in scale: %s %s' % (cut,tool)
    iron=images['ui/icon_iron'].getbbox()
    for metal in INGOTS:
        box=images['ui/icon_'+metal].getbbox()
        assert box[2]-box[0]==iron[2]-iron[0] and abs((box[3]-box[1])-(iron[3]-iron[1]))<=1,"Not iron's ingot: "+metal
    for cut,facets in (('icon',3),('hud',1)):
        gold=[p for p in import_art.samples(images['ui/%s_gold' % cut]) if p[3]]
        assert all(p[:3]!=palette.COLOURS['flame'] for p in gold),'Flame orange on gold: '+cut
        coal=[p for p in import_art.samples(images['ui/%s_coal' % cut]) if p[3]]
        assert sum(p[:3] in STEEL for p in coal)>=facets,'Coal without its facets: '+cut
    for good in CREAM:
        for cut in ('icon','hud'):
            assert not any(p[3] and p[:3] in WARM for p in import_art.samples(images['ui/%s_%s' % (cut,good)])),'Orange on cream: %s %s' % (cut,good)
    portraits=0
    for pack,kinds in PORTRAITS.items():
        packed=[e for e in manifest['assets'] if e.get('generation_task')==pack]
        alphas={}
        for kind in kinds:
            e=next((x for x in packed if x['id']=='ui/portrait_'+kind),None)
            assert e is not None,'Missing portrait: '+kind
            assert e['canvas_wh']==[32,32] and e['pivot_xy']==[16,16] and e.get('display_role')=='book_portrait'
            assert not e['loop'] and e['frame']==0 and registry[e['output']]=='raster'
            pair=[x for x in packed if x['id'] in ('ui/icon_'+kind,'ui/hud_'+kind)]
            assert len(pair)==2 and {x['source'] for x in pair}=={e['source']},'Portrait not cut from its icons\' source: '+kind
            assert {tuple(x['crop_xywh']) for x in pair}=={tuple(e['crop_xywh'])},'Portrait not cut from its icons\' crop: '+kind
            art=images[e['id']];box=art.getbbox();pixels=list(import_art.samples(art))
            assert box and 0<box[0]<box[2]<32 and 0<box[1]<box[3]<32,'Clipped portrait: '+kind
            assert all(p[3] in (0,255) for p in pixels)
            assert (import_art.ROOT/e['output']).read_bytes()==files[e['output']]
            check_approved(e,art)
            alphas[kind]=[p[3] for p in pixels]
            portraits+=1
        for a in kinds:
            for b in kinds:
                if a<b:
                    assert sum(x!=y for x,y in zip(alphas[a],alphas[b]))>=24,'Two portraits share a silhouette: %s, %s' % (a,b)
    heads=0
    for pack,kinds in HEADS.items():
        packed=[e for e in manifest['assets'] if e.get('generation_task')==pack]
        assert len(packed)==len(kinds),'Incomplete %s heads' % pack
        for kind in kinds:
            e=next((x for x in packed if x['id']=='ui/head_'+kind),None)
            assert e is not None,'Missing head: '+kind
            assert e['palette']=='exact-source' and e['content_scale']==1,'A head is an exact crop: '+kind
            assert e['canvas_wh']==[16,16] and e['pivot_xy']==[8,8] and not e['loop'] and e['frame']==0
            assert registry[e['output']]=='raster'
            art=images[e['id']];box=art.getbbox();pixels=list(import_art.samples(art))
            assert box and 0<box[0] and 0<box[1] and box[2]<=15 and box[3]==15,'A head stands on row 14, row 15 clear: '+kind
            assert all(p[3] in (0,255) for p in pixels)
            body=Image.open(import_art.ROOT/f'sprites/enemies/{kind}_walk_0.png').convert('RGBA')
            colours={p[:3] for p in import_art.samples(body) if p[3]}
            assert all(p[:3] in colours for p in pixels if p[3]),"A head wears its own body's colours: "+kind
            fingerprint=art.tobytes();assert fingerprint not in seen[16],'Duplicate head: '+kind;seen[16].add(fingerprint)
            assert (import_art.ROOT/e['output']).read_bytes()==files[e['output']]
            check_approved(e,art)
            heads+=1
    for pack,kinds in PACK_HEADS.items():
        for kind in kinds:
            e=next((x for x in manifest['assets'] if x['id']=='ui/head_'+kind and x.get('generation_task')==pack),None)
            assert e is not None,'Missing head: '+kind
            assert e['canvas_wh']==[16,16] and e['pivot_xy']==[8,8] and not e['loop'] and e['frame']==0
            assert registry[e['output']]=='raster'
            art=images[e['id']];box=art.getbbox();pixels=list(import_art.samples(art))
            assert box and 0<box[0] and 0<box[1] and box[2]<=15 and box[3]==15,'A head stands on row 14, row 15 clear: '+kind
            assert all(p[3] in (0,255) for p in pixels)
            fingerprint=art.tobytes();assert fingerprint not in seen[16],'Duplicate head: '+kind;seen[16].add(fingerprint)
            assert (import_art.ROOT/e['output']).read_bytes()==files[e['output']]
            heads+=1
    by_id={e['id']:e for e in manifest['assets']};fishing=0
    for name,(canvas,pivot,count,seconds,loop) in FISHING.items():
        frames=[by_id[name]] if count==1 else [by_id['%s_%d'%(name,i)] for i in range(count)]
        shapes=set();lines=[]
        for i,e in enumerate(frames):
            assert e.get('generation_task')=='A023' and e['canvas_wh']==canvas and e['pivot_xy']==pivot,'Fishing piece drift: '+e['id']
            assert e['seconds']==seconds and e['loop'] is loop and e['frame']==i,'Fishing piece timing: '+e['id']
            assert not any(k in e for k in ('light_xy','lights_xy')),'A fishing piece emits: '+e['id']
            art=images[e['id']];pixels=list(import_art.samples(art))
            assert all(p[3] in (0,255) for p in pixels) and art.getbbox(),'Fishing piece alpha: '+e['id']
            assert art.tobytes() not in shapes,'Two frames alike: '+e['id'];shapes.add(art.tobytes())
            assert (import_art.ROOT/e['output']).read_bytes()==files[e['output']]
            check_approved(e,art)
            if name.startswith('effects/'):
                assert e.get('line_xy') and art.getpixel(tuple(e['line_xy']))[3]==255,'The line ties to nothing: '+e['id']
                lines.append(e['line_xy'][1])
            fishing+=1
        if name=='effects/bobber_bite':
            assert lines==sorted(lines) and lines[0]<lines[-1],'The bite does not sink: '+str(lines)
    frame=by_id['ui/fishbar_frame'];zone=by_id['ui/fishbar_zone']
    assert frame.get('track_xywh')==[5,5,90,6] and zone.get('patch_margins_lrtb')==[2,2,0,0],'Track or green margins drift'
    assert images[zone['id']].getchannel('A').getextrema()==(255,255),'The green is not fully opaque'
    for e in (frame,zone):
        assert e.get('operation')=='compose' and 'source' not in e and all(by_id[p['input']].get('assembly_component_of')=='A023' for p in e['parts']),'A layered bar piece not promoted as its composition: '+e['id']
    print('OK: %d fishing frames - the bar, its green, needle and flashes, the bobber floating and sinking' % fishing)
    cursors=set()
    for look in CURSOR_LOOKS:
        for frame in (0,1):
            e=by_id['ui/cursor_%s_%d'%(look,frame)]
            assert e.get('generation_task')=='A004' and e['canvas_wh']==[16,16] and e['pivot_xy']==[8,8]
            assert e['seconds']==0.4 and e['loop'] is True and e['frame']==frame and e.get('draw_scale',1)==1,'Cursor pulse drift: '+e['id']
            assert e.get('operation')=='compose' and 'source' not in e,'A layered cursor not promoted as its composition: '+e['id']
            assert all(by_id[p['input']].get('assembly_component_of')=='A004' for p in e['parts']),'A part from outside A004: '+e['id']
            assert not any(k in e for k in ('light_xy','lights_xy')),'The cursor emits: '+e['id']
            art=images[e['id']];pixels=list(import_art.samples(art))
            assert all(p[3] in (0,255) for p in pixels)
            middle={(x,y) for y in range(6,10) for x in range(4,12) if art.getpixel((x,y))[3]}
            assert middle==(AIM_PLUS if look=='aim' else set()),'The middle of the cell: '+e['id']
            assert art.tobytes() not in cursors,'Two cursor frames alike: '+e['id'];cursors.add(art.tobytes())
            assert (import_art.ROOT/e['output']).read_bytes()==files[e['output']]
            check_approved(e,art)
    ascii_files=gen_sprites.everything()
    for name in ('panel','tooltip','tab','button_normal','button_hover','button_pressed','button_disabled',
                 'tab_hover','tab_selected','tab_disabled','button_focus','checkbox_on','checkbox_off',
                 'checkbox_on_disabled','checkbox_off_disabled','slider_track','slider_grab','slider_grab_highlight','slider_grab_disabled'):
        path='sprites/ui/'+name+'.png'
        assert registry[path]=='ascii' and (import_art.ROOT/path).read_bytes()==ascii_files['ui/'+name+'.png']
    for name in ('panel','tooltip','tab','button_normal'):
        art=Image.open(import_art.ROOT/f'sprites/ui/{name}.png').convert('RGBA')
        center=art.getpixel((8,8));border=next(x for x in range(16) if art.getpixel((x,8))==center)
        assert border==3,'Nine-patch margin drift: '+name
    focus=Image.open(import_art.ROOT/'sprites/ui/button_focus.png').convert('RGBA')
    assert focus.getpixel((8,8))[3]==0 and focus.getpixel((1,8))[3]==255,'Focus must be a visible open ring'
    print('OK: %d cursor frames, seven looks pulsing, unlit, aim keeps its plus' % len(cursors))
    print('OK: 15 exact generated resources / 30 distinct native cuts / %d pack icons at their approved pixels (%s) / ingots, gold and coal / cream milk and wool / %d book portraits, no shared silhouette (%s) / %d exact forecast heads (%s) / clear margins / palette alpha / preserved three-pixel frame profiles / focus ring'
          % (pairs,', '.join(sorted(PAIRS)),portraits,', '.join(sorted(PORTRAITS)),heads,', '.join(sorted(HEADS))))


if __name__=='__main__':main()
