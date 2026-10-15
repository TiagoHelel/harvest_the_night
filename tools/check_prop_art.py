"""Validate complete source-owned prop species, variants, alpha and contacts."""
import sys
from PIL import Image
import art_ownership
import import_art
import palette

NAMES = ("tree", "tree_b", "stump", "rock", "rock_b", "seam", "seam_b", "ore", "ore_b", "cow", "chicken",
         "truffle_spot")

# A013's seasons of both trees (task 0164): every one a variant of props/tree at
# its scale, grounded on row 43 like it. Summer keeps today's trees.
SEASONAL_TREES = ("tree_spring", "tree_autumn", "tree_winter",
                  "tree_b_spring", "tree_b_autumn", "tree_b_winter")
# A013's snow caps and the hosts they settle on, at the host's canvas origin:
# a 1x1 node's generic cap on the ore and the rock it was fitted to, and the
# 2x2 cap on the stump drawn twice the size (the hardwood stump's stand-in).
CAPS = {"stump_snow": ("stump",), "rock_snow": ("rock",), "rock_b_snow": ("rock_b",),
        "ore_snow": ("ore",), "ore_b_snow": ("ore_b",), "seam_snow": ("seam",),
        "seam_b_snow": ("seam_b",), "snow_cap": ("ore", "rock"), "snow_cap_2x2": ("stump2x",)}
# The owner's one accepted exception (APPROVAL.json, 2026-10-10, "aprovado"):
# tree_b_spring keeps exactly one isolated pale blossom pixel. It is bound to
# that file's pixels, and the measured rule still reports it.
BLOSSOM_EXCEPTION = {"tree_b_spring": 1}


def groups(points):
    """8-connected parts of a set of pixels, by size."""
    points, sizes = set(points), []
    while points:
        todo = [points.pop()]
        size = 1
        while todo:
            x, y = todo.pop()
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    neighbor = x + dx, y + dy
                    if neighbor in points:
                        points.remove(neighbor)
                        todo.append(neighbor)
                        size += 1
        sizes.append(size)
    return sizes


def opaque(image):
    return {(x, y) for y in range(image.height) for x in range(image.width) if image.getpixel((x, y))[3]}


def validate_season(image, name):
    """A013's own measures: spring blooms a fifth to two fifths of its leaves
    in clusters of three or more; autumn has next to no green, little flame
    and no flame_hot - leaves, not fire; winter is bare branches."""
    crown = {(x, y) for x, y in opaque(image) if y < 33}
    colour = lambda p: image.getpixel(p)[:3]
    green = {v for k, v in palette.COLOURS.items() if "grass" in k or "leaf" in k}
    wood = {palette.COLOURS[k] for k in ("wood_dark", "wood", "wood_light", "soil_dark", "soil", "soil_light", "gold_dark")}
    blooms = {palette.COLOURS[k] for k in ("bone", "bone_dark", "roof_light", "skin_light")}
    leaves = {p for p in crown if colour(p) not in wood}
    flowers = {p for p in leaves if colour(p) in blooms}
    greens = sum(colour(p) in green for p in crown)
    if name.endswith("spring"):
        clusters = groups(flowers)
        singles = sum(size < 3 for size in clusters)
        if not 0.2 <= len(flowers) / max(len(leaves), 1) <= 0.4 or singles != BLOSSOM_EXCEPTION.get(name, 0):
            raise ValueError("Spring blossom out of its measure: %s (%d small clusters)" % (name, singles))
        return singles
    if name.endswith("autumn"):
        flame = sum(colour(p) == palette.COLOURS["flame"] for p in crown)
        hot = sum(colour(p) == palette.COLOURS["flame_hot"] for p in crown)
        if greens > 0.1 * len(crown) or flame > 0.08 * len(crown) or hot:
            raise ValueError("Autumn reads as fire or as summer: " + name)
        return 0
    box = image.getbbox()
    if greens > 3 or box[2] - box[0] < 26:
        raise ValueError("Winter tree is not bare branches: " + name)
    return 0


def validate_cap(cap, host, name):
    """A013's fit: the cap lies on the host's top band, mostly over it, two to
    six rows deep, 55-80% of its width, centred on it, in one piece."""
    cp, hs = opaque(cap), opaque(host)
    tops = {x: min(y for xx, y in hs if xx == x) for x in {xx for xx, y in hs}}
    hb, cb = host.getbbox(), cap.getbbox()
    within = all(x in tops and tops[x] - 2 <= y <= tops[x] + 5 for x, y in cp)
    width, host_width = cb[2] - cb[0], hb[2] - hb[0]
    if not (within and len(cp & hs) >= 0.6 * len(cp) and len(cp & hs) <= 0.35 * len(hs)
            and 2 <= cb[3] - cb[1] <= 6 and 0.55 * host_width <= width <= 0.8 * host_width
            and len(groups(cp)) == 1 and abs((cb[0] + cb[2] - hb[0] - hb[2]) / 2) <= 1):
        raise ValueError("Snow cap does not sit on its host: %s on %s" % (name, host.info.get("name", "?")))


# A021's nodes (task 0204): the forge's copper, coal and gold, each with its
# `_b` at its master's scale, and the hardwood stump whole and chipped over
# its 2x2 footprint - on the pivots 0176 and 0177 settled, inside the
# envelopes the delivery recorded (width and height ranges), and distinct.
NODES = {"copper_ore": ("copper_ore_b", [16, 16], [8, 14], (10, 14), (8, 11)),
         "coal_seam": ("coal_seam_b", [16, 16], [8, 14], (10, 14), (6, 8)),
         "gold_ore": ("gold_ore_b", [16, 16], [8, 14], (10, 14), (8, 11)),
         "hardwood_stump": ("hardwood_stump_chipped", [32, 32], [16, 30], (26, 30), (16, 18))}
# Their ramps beside the iron ore's and the stone's: copper's skin and light
# roof hues, which no stone wears; gold's gold ramp without the iron ore's
# rust; coal's night, a fifth of it or more, with no warm hue at all.
COPPER = {"skin", "skin_dark", "skin_light", "roof_light"}
GOLD = {"gold", "gold_dark", "gold_light"}
RUST = {"roof_dark", "roof", "flame"}
WARM = COPPER | GOLD | RUST | {"flame_hot"}
# The caps they wear in winter (A013's, by `SeasonView.cap_for`): the generic
# one on copper and gold, the seam's on coal. The 2x2 cap on the big stump
# sits as A013 fitted it on its stand-in, but for its left tip: 4 pixels
# hang off the stump's sloping shoulder, the most this check allows.
CAPPED = {"copper_ore": "snow_cap", "copper_ore_b": "snow_cap", "gold_ore": "snow_cap",
          "gold_ore_b": "snow_cap", "coal_seam": "seam_snow", "coal_seam_b": "seam_snow"}
STUMP_CAP_OVERHANG = 4


def keys_of(image):
    names = {v: k for k, v in palette.COLOURS.items()}
    counts = {}
    for p in import_art.samples(image):
        if p[3]:
            counts[names[p[:3]]] = counts.get(names[p[:3]], 0) + 1
    return counts


def validate_shape(image, name, canvas, pivot):
    if image.size != tuple(canvas) or image.getbbox() is None:
        raise ValueError("Missing prop silhouette/canvas: " + name)
    x0,y0,x1,y1 = image.getbbox()
    if x0 < 1 or y0 < 1 or x1 >= canvas[0] or y1 != pivot[1] or y1 >= canvas[1]:
        raise ValueError("Clipped or ungrounded prop: " + name)
    if {p[3] for p in import_art.samples(image)} != {0,255}:
        raise ValueError("Prop alpha must be clean binary transparency: " + name)
    lit = {(x,y) for y in range(image.height) for x in range(image.width) if image.getpixel((x,y))[3]}
    seen, active = {next(iter(lit))}, [next(iter(lit))]
    while active:
        x,y = active.pop()
        for dx in (-1,0,1):
            for dy in (-1,0,1):
                neighbor = x+dx,y+dy
                if neighbor in lit and neighbor not in seen:
                    seen.add(neighbor)
                    active.append(neighbor)
    if lit != seen:
        raise ValueError("Detached prop pixels: " + name)


# Task 0245: A028's dog - every pose's frames, drawn facing west on a 40x32
# canvas standing on (20,30), mirrored east at runtime.
DOG = {'sit': 2, 'wag': 2, 'walk': 4, 'bark': 3, 'sleep': 2, 'run': 4, 'bite': 3}


def check_dog(data, files, images):
    entries = [e for e in data['assets'] if e.get('generation_task') == 'A028']
    if len(entries) != sum(DOG.values()):
        raise ValueError('Dog contract incomplete: %d' % len(entries))
    for pose, count in DOG.items():
        frames = sorted((e for e in entries if e['animation'] == 'props/dog_' + pose), key=lambda e: e['frame'])
        if [e['frame'] for e in frames] != list(range(count)):
            raise ValueError('Dog pose frames: ' + pose)
        if len({e['content_scale'] for e in frames}) != 1 or len({e['seconds'] for e in frames}) != 1:
            raise ValueError('Dog pose refits or retimes itself: ' + pose)
        seen = set()
        for e in frames:
            image = images[e['id']]
            if e['canvas_wh'] != [40, 32] or e['pivot_xy'] != [20, 30]:
                raise ValueError('Dog off its canvas: ' + e['id'])
            if e['output'] != 'sprites/props/dog_%s_%d.png' % (pose, e['frame']):
                raise ValueError('Dog frame named wrongly: ' + e['id'])
            box = image.getbbox()
            if not box or box[0] < 1 or box[1] < 1 or box[2] >= 40 or box[3] != 30:
                raise ValueError('Dog clipped or off its feet: %s %s' % (e['id'], box))
            if any(p[3] not in (0, 255) for p in import_art.samples(image)):
                raise ValueError('Dog alpha halo: ' + e['id'])
            if (import_art.ROOT / e['output']).read_bytes() != files[e['output']]:
                raise ValueError('Runtime dog diverges: ' + e['id'])
            seen.add(image.tobytes())
        if len(seen) != count:
            raise ValueError('Dog pose repeats a frame: ' + pose)
    return len(entries)


## The barnyard's animals (tasks 0209, 0210): each species' poses, facing
## west - east is the runtime mirror - on its canvas, its feet on the pivot
## row in every frame, every frame its own. A026's sheep and pig on 40x32 at
## (20,30), the pig's dig too; A027's cow on the same, and its hen on 24x24
## at (12,22).
GRAZER = {'idle': (2, 0.5, True), 'walk': (4, 0.15, True), 'eat': (2, 0.2, True), 'sleep': (2, 0.6, True)}
ANIMALS = {
    'A026': {'canvas': [40, 32], 'pivot': [20, 30],
             'species': {'sheep': GRAZER, 'pig': dict(GRAZER, dig=(3, 0.1, False))}},
    'A027 cow': {'pack': 'A027', 'canvas': [40, 32], 'pivot': [20, 30], 'species': {'cow': GRAZER}},
    'A027 hen': {'pack': 'A027', 'canvas': [24, 24], 'pivot': [12, 22], 'species': {'chicken': GRAZER}},
}


def check_animals(data, files, images):
    by_id = {e['id']: e for e in data['assets']}
    count = 0
    for label, spec in ANIMALS.items():
        pack = spec.get('pack', label)
        for kind, poses in spec['species'].items():
            seen = set()
            for pose, (frames, seconds, loop) in poses.items():
                scales = set()
                for frame in range(frames):
                    e = by_id['props/%s_%s_%d' % (kind, pose, frame)]
                    if e.get('generation_task') != pack or e['canvas_wh'] != spec['canvas'] \
                            or e['pivot_xy'] != spec['pivot'] or e['seconds'] != seconds \
                            or e['loop'] is not loop or e['frame'] != frame:
                        raise ValueError('Animal frame drift: ' + e['id'])
                    if e.get('operation') == 'compose' and any(
                            by_id[p['input']].get('assembly_component_of') != pack for p in e['parts']):
                        raise ValueError('An animal part from outside its pack: ' + e['id'])
                    if 'source' in e:
                        scales.add(e['content_scale'])
                    image = images[e['id']]
                    box = image.getbbox()
                    if not box or box[0] < 1 or box[1] < 1 or box[2] >= spec['canvas'][0] or box[3] != spec['pivot'][1]:
                        raise ValueError('An animal off its feet: %s %s' % (e['id'], box))
                    if any(p[3] not in (0, 255) for p in import_art.samples(image)):
                        raise ValueError('Animal alpha halo: ' + e['id'])
                    if (import_art.ROOT / e['output']).read_bytes() != files[e['output']]:
                        raise ValueError('Runtime animal diverges: ' + e['id'])
                    if image.tobytes() in seen:
                        raise ValueError('An animal frame repeats: ' + e['id'])
                    seen.add(image.tobytes())
                    count += 1
                if len(scales) > 1:
                    raise ValueError('A pose refits itself: %s_%s' % (kind, pose))
    return count


## A033's shipping bin (task 0215): closed and its lid's three opening
## frames, 24x24 standing on (12,22) at 1.0, each A033's composition from its
## own components and its own drawing. The lid rises frame by frame; the body
## below the hinge - rows 12 to 23 - never moves.
BIN = ('shipping_bin', 'shipping_bin_open_0', 'shipping_bin_open_1', 'shipping_bin_open_2')


def check_bin(data, files, images):
    by_id = {e['id']: e for e in data['assets']}
    body, tops, seen = None, [], set()
    for i, name in enumerate(BIN):
        e = by_id['props/' + name]
        timing = (0.55, 0) if i == 0 else (0.1, i - 1)
        if e.get('generation_task') != 'A033' or e['canvas_wh'] != [24, 24] or e['pivot_xy'] != [12, 22] \
                or (e['seconds'], e['frame']) != timing or e['loop'] is not False or e.get('draw_scale', 1) != 1:
            raise ValueError('Bin frame drift: ' + e['id'])
        if e.get('operation') != 'compose' or 'source' in e \
                or any(by_id[p['input']].get('assembly_component_of') != 'A033' for p in e['parts']):
            raise ValueError('A layered bin frame not promoted as its composition: ' + e['id'])
        image = images[e['id']]
        box = image.getbbox()
        if not box or box[3] != 22:
            raise ValueError('The bin floats: ' + e['id'])
        rows = image.crop((0, 12, 24, 24)).tobytes()
        if body is None:
            body = rows
        elif rows != body:
            raise ValueError('The body moved under the lid: ' + e['id'])
        if image.tobytes() in seen:
            raise ValueError('A bin frame repeats: ' + e['id'])
        seen.add(image.tobytes())
        tops.append(box[1])
        if (import_art.ROOT / e['output']).read_bytes() != files[e['output']]:
            raise ValueError('Runtime bin diverges: ' + e['id'])
    if tops != sorted(tops, reverse=True) or tops[0] == tops[-1]:
        raise ValueError('The lid does not rise: %s' % tops)
    return len(BIN)


## A018's sprinklers (task 0201): each tier's idle cut and its four-frame
## spray, 16x16 standing on (8,14) at 1.0. The spray frames are A018's
## compositions from its own components, a tenth of a second each, round and
## round, every one its own: the head two pixels above the idle one, the base
## - rows 11 to 15 - unmoved, and the nozzle (`spray_xy`) on the head's top
## row.
SPRINKLERS = ('copper', 'iron', 'gold')


def check_sprinklers(data, files, images):
    by_id = {e['id']: e for e in data['assets']}
    for tier in SPRINKLERS:
        idle = by_id['props/%s_sprinkler' % tier]
        if idle.get('generation_task') != 'A018' or 'source' not in idle \
                or idle['canvas_wh'] != [16, 16] or idle['pivot_xy'] != [8, 14]:
            raise ValueError('Idle sprinkler drift: ' + tier)
        still = images[idle['id']]
        base = still.crop((0, 11, 16, 16)).tobytes()
        seen = set()
        for frame in range(4):
            e = by_id['props/%s_sprinkler_spray_%d' % (tier, frame)]
            if e.get('generation_task') != 'A018' or e['canvas_wh'] != [16, 16] or e['pivot_xy'] != [8, 14] \
                    or e['seconds'] != 0.1 or e['loop'] is not True or e['frame'] != frame:
                raise ValueError('Spray frame drift: ' + e['id'])
            if e.get('operation') != 'compose' or 'source' in e \
                    or any(by_id[p['input']].get('assembly_component_of') != 'A018' for p in e['parts']):
                raise ValueError('A layered spray frame not promoted as its composition: ' + e['id'])
            image = images[e['id']]
            box = image.getbbox()
            if box[1] != still.getbbox()[1] - 2 or box[3] != 14 or image.crop((0, 11, 16, 16)).tobytes() != base:
                raise ValueError('The head does not rise two pixels on a still base: ' + e['id'])
            if e.get('spray_xy') != [8, box[1]] or image.getpixel(tuple(e['spray_xy']))[3] != 255:
                raise ValueError('The nozzle is not on the head: ' + e['id'])
            if (import_art.ROOT / e['output']).read_bytes() != files[e['output']]:
                raise ValueError('Runtime spray frame diverges: ' + e['id'])
            seen.add(image.tobytes())
        if len(seen) != 4:
            raise ValueError('A spray frame repeats: ' + tier)
    return 4 * len(SPRINKLERS)


def main():
    data = import_art.load_manifest()
    files, images = import_art.build(data)
    entries = {e["id"]:e for e in data["assets"]}
    owners = art_ownership.registry()
    for name in NAMES:
        key = "props/"+name
        entry = entries[key]
        if owners[entry["output"]] != "raster" or "source" not in entry:
            raise ValueError("Prop lacks its accepted raw species/material source: " + name)
        if (art_ownership.ROOT/entry["output"]).read_bytes() != files[entry["output"]]:
            raise ValueError("Prop differs from the accepted source: " + name)
        canvas,pivot = ([40,48],[20,44]) if name.startswith("tree") else (([24,24],[12,22]) if name in ("cow","chicken") else ([16,16],[8,14]))
        if entry["canvas_wh"] != canvas or entry["pivot_xy"] != pivot:
            raise ValueError("Native prop contract drift: " + name)
        validate_shape(images[key],name,canvas,pivot)
    for kind in ("tree","rock","seam","ore"):
        a,b = entries["props/"+kind],entries["props/"+kind+"_b"]
        if a["content_scale"] != b["content_scale"] or images[a["id"]].tobytes() == images[b["id"]].tobytes():
            raise ValueError("Variant scale drift or duplicate shape: " + kind)
    # **A013's seasonal trees and snow caps** (task 0164).
    tree = entries["props/tree"]
    singles = 0
    for name in SEASONAL_TREES:
        key = "props/" + name
        entry = entries[key]
        if owners[entry["output"]] != "raster" or "source" not in entry:
            raise ValueError("Seasonal tree lacks its raw source: " + name)
        if (art_ownership.ROOT/entry["output"]).read_bytes() != files[entry["output"]]:
            raise ValueError("Seasonal tree differs from the accepted source: " + name)
        if entry.get("variant_of") != "props/tree" or entry["content_scale"] != tree["content_scale"] \
                or entry["canvas_wh"] != tree["canvas_wh"] or entry["pivot_xy"] != tree["pivot_xy"]:
            raise ValueError("Seasonal tree is not a same-scale variant of props/tree: " + name)
        validate_shape(images[key], name, [40,48], [20,44])
        box = images[key].getbbox()
        trunk = [x for x, y in opaque(images[key]) if y in (34, 35)]
        if not 38 <= box[3] - box[1] <= 43 or abs((min(trunk) + max(trunk)) / 2 - 20) > 1:
            raise ValueError("Seasonal tree's height or trunk moved: " + name)
        singles += validate_season(images[key], name)
    if len({images["props/" + n].tobytes() for n in SEASONAL_TREES + ("tree", "tree_b")}) != 8:
        raise ValueError("Two seasons of the trees are the same drawing")
    for name, hosts in CAPS.items():
        key = "props/" + name
        entry = entries[key]
        canvas, pivot = ([32,32],[16,30]) if name == "snow_cap_2x2" else ([16,16],[8,14])
        if owners[entry["output"]] != "raster" or "source" not in entry \
                or entry["canvas_wh"] != canvas or entry["pivot_xy"] != pivot:
            raise ValueError("Snow cap lacks its source or its host's box: " + name)
        if (art_ownership.ROOT/entry["output"]).read_bytes() != files[entry["output"]]:
            raise ValueError("Snow cap differs from the accepted source: " + name)
        if {p[3] for p in import_art.samples(images[key])} != {0,255}:
            raise ValueError("Snow cap alpha must be binary: " + name)
        for host in hosts:
            image = images["props/stump"].resize((32,32), Image.Resampling.NEAREST) if host == "stump2x" \
                else images["props/" + host]
            image.info["name"] = host
            validate_cap(images[key], image, name)
    # **A021's nodes** (task 0204).
    for master, (variant, canvas, pivot, widths, heights) in NODES.items():
        for name in (master, variant):
            key = "props/" + name
            entry = entries[key]
            if owners[entry["output"]] != "raster" or "source" not in entry:
                raise ValueError("Node lacks its raw source: " + name)
            if (art_ownership.ROOT/entry["output"]).read_bytes() != files[entry["output"]]:
                raise ValueError("Node differs from the accepted source: " + name)
            if entry["canvas_wh"] != canvas or entry["pivot_xy"] != pivot:
                raise ValueError("Node off its settled box: " + name)
            validate_shape(images[key], name, canvas, pivot)
            x0, y0, x1, y1 = images[key].getbbox()
            if not (widths[0] <= x1 - x0 <= widths[1] and heights[0] <= y1 - y0 <= heights[1]):
                raise ValueError("Node outside its envelope: %s %s" % (name, (x1 - x0, y1 - y0)))
        child, parent = entries["props/" + variant], entries["props/" + master]
        if child.get("variant_of") != "props/" + master or child["content_scale"] != parent["content_scale"] \
                or child.get("palette_keys") != parent.get("palette_keys"):
            raise ValueError("Variant drifts from its master: " + variant)
        if images["props/" + variant].tobytes() == images["props/" + master].tobytes():
            raise ValueError("Variant is its master's drawing: " + variant)
    stones = [keys_of(images["props/" + n]) for n in ("ore", "ore_b", "rock", "rock_b", "seam", "seam_b")]
    if any(set(s) & COPPER for s in stones) or not all(set(keys_of(images["props/" + n])) & RUST for n in ("ore", "ore_b")):
        raise ValueError("The iron ore and the stone changed their ramps")
    for name in ("copper_ore", "copper_ore_b"):
        if sum(v for k, v in keys_of(images["props/" + name]).items() if k in COPPER) < 8:
            raise ValueError("Copper without its copper hues: " + name)
    for name in ("gold_ore", "gold_ore_b"):
        counts = keys_of(images["props/" + name])
        if sum(v for k, v in counts.items() if k in GOLD) < 15 or set(counts) & RUST:
            raise ValueError("Gold without its ramp, or rusted like iron: " + name)
    for name in ("coal_seam", "coal_seam_b"):
        counts = keys_of(images["props/" + name])
        if counts.get("night", 0) < 0.2 * sum(counts.values()) or set(counts) & WARM:
            raise ValueError("Coal not dark, or warm: " + name)
    if max(s.get("night", 0) / sum(s.values()) for s in stones) >= 0.15:
        raise ValueError("A stone as dark as coal")
    for host, cap in CAPPED.items():
        image = images["props/" + host]
        image.info["name"] = host
        validate_cap(images["props/" + cap], image, cap)
    cap = images["props/snow_cap_2x2"]
    for host in ("hardwood_stump", "hardwood_stump_chipped"):
        stump = images["props/" + host]
        cp, hs = opaque(cap), opaque(stump)
        tops = {x: min(y for xx, y in hs if xx == x) for x in {xx for xx, y in hs}}
        off = [(x, y) for x, y in cp if not (x in tops and tops[x] - 2 <= y <= tops[x] + 5)]
        if len(off) > STUMP_CAP_OVERHANG or len(cp & hs) < 0.8 * len(cp):
            raise ValueError("The 2x2 cap no longer sits on %s: %d pixels off" % (host, len(off)))
    # **A029's truffle spot** (task 0211): the pig's mound on open grass,
    # 11-13 wide and 7-9 tall, standing on row 13 and centred on x=8 - no
    # ground patch around it.
    x0, y0, x1, y1 = images["props/truffle_spot"].getbbox()
    if not (11 <= x1 - x0 <= 13 and 7 <= y1 - y0 <= 9 and y1 == 14 and abs((x0 + x1) / 2 - 8) <= 1):
        raise ValueError("Truffle spot off its recorded box: %s" % str((x0, y0, x1, y1)))
    dogs = check_dog(data, files, images)
    sprays = check_sprinklers(data, files, images)
    animals = check_animals(data, files, images)
    bins = check_bin(data, files, images)
    print("OK: A033's shipping bin: %d frames, the lid rising on a still body" % bins)
    print("OK: the barnyard's animals: %d frames over %s, west-facing, on their feet, every frame its own"
          % (animals, ', '.join(sorted({spec.get('pack', label) for label, spec in ANIMALS.items()}))))
    print("OK: A018's sprinklers: 3 idle cuts and %d spray frames, the head risen two pixels on a still base, "
          "the nozzle on it" % sprays)
    print(("OK: %d source-owned props; 4 distinct same-scale variants; clean silhouettes and exact ground pivots"
          "; 6 seasonal trees, grounded variants of props/tree, autumn without flame_hot and winter bare"
          "; 9 snow caps fitted to their hosts; spring blossom: %d single-pixel cluster, the owner's accepted exception"
          "; the truffle spot's mound in its box"
          "; A021: 8 nodes in their envelopes and ramps, capped in winter"
          "; A028's dog: %d frames over 7 poses, grounded, distinct") % (len(NAMES), singles, dogs))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (KeyError,ValueError,OSError) as error:
        print("FAIL: " + str(error))
        sys.exit(1)
