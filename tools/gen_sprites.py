# -*- coding: utf-8 -*-
"""Turn the ASCII maps in `tools/sprite_maps.py` into the PNGs the game loads.

    python tools/gen_sprites.py            write sprites/ and the atlas
    python tools/gen_sprites.py --check    fail if anything is out of date
    python tools/gen_sprites.py --list     what would be written, and its size

**The maps are the source and the PNGs are build output.** They are committed,
so a fresh clone runs without a build step, but nothing hand-edits them: the way
to change a sprite is to change its map. That is what keeps the whole set on one
palette, and it is why `--check` exists - a PNG that no longer matches its map
is a PNG somebody painted over.

Output is deterministic: the same maps produce byte-identical files, every time,
on any machine. PNG carries a timestamp by default and that alone would make
every regeneration a diff, so it is written out explicitly.
"""
import hashlib
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import palette                                    # noqa: E402
import art_ownership                              # noqa: E402
from sprite_maps import SPRITES                   # noqa: E402

OUT = os.path.join(ROOT, "sprites")

# One tile, in pixels. `GameData.TILE_SIZE` is the same number on the other
# side; `headless_check` asserts the atlas matches it rather than trusting
# two files to agree.
TILE_PX = 16

# The palette, again, in GDScript.
#
# **Generated, not typed twice.** The view needs the night ramp and the game is
# not going to read a .py file at runtime; a hand-kept second copy would drift
# the first time somebody tuned a colour, and the drift would be invisible
# because both copies would look plausible.
PALETTE_GD = os.path.join(ROOT, "src", "ui", "palette_data.gd")

# The terrain atlas, as a grid of named rows.
#
# **One texture, and a layout the view can name rather than count.** Row 0 is
# `Farm.Terrain` order because that is the order the terrain byte is in, and
# everything after it is what task 0072 added - variants, animation frames and
# the composited edges. `None` is an empty cell, which exists because an atlas
# has to be rectangular and the rows are not all the same length.
#
# The edge rows are written by `edge_row()` rather than listed: sixteen tiles
# from four maps, which is the whole reason this is not a hand-drawn blob set.
ATLAS_ROWS = [
    ["grass", "soil", "water", "rock", "path", "floor"],
    ["water", "water_b", "water_c"],
    ["grass", "grass_b", "grass_c", "grass_d"],
]

# Rows of sixteen, each composited from four side maps. The name is the prefix
# its four maps share: `edge_n`, `edge_e`, `edge_s`, `edge_w`.
EDGE_ROWS = ["edge", "shore"]

TERRAIN_ORDER = ATLAS_ROWS[0]
ATLAS_PATH = "terrain/atlas.png"

# Which bit of an edge mask each side is. North is 1, east 2, south 4, west 8,
# and the view builds the same number from the same four neighbours.
EDGE_SIDES = ["n", "e", "s", "w"]

# Corner caps occupy unused row-zero cells. Existing rows/enum/masks and the
# 256x80 atlas stay intact; only view-owned diagonal joins use these slots.
CORNER_ORDER = ["nw", "ne", "se", "sw"]
CORNER_START = {"edge": 6, "shore": 10}


# **The rim light, derived rather than drawn.** Task 0074 wants the enemies to
# read against task 0071's night ramp, and what does it is one line of a colour
# the ramp exempts: `moon` is 0.849 bright and the exemption starts at 0.80, so
# the rim keeps its own colour after dark while the body goes blue with
# everything else.
#
# It is applied here instead of being written into the maps because placing it
# by hand is wrong by default. The first attempt put an `m` at the end of each
# row of ASCII, and a row of ASCII does not know where the body is: the mark
# landed outside the figure where the row was narrow and *inside* it where the
# row had a gap, so the walker wore a glowing stripe down its stomach and a
# second one hovering beside its arm. The rightmost lit pixel of a row is a
# fact about the drawing, and the machine can find it every time.
RIM_COLOUR = "moon"
RIM = ["enemies/walker", "enemies/runner", "enemies/tank",
       "enemies/breaker", "enemies/giant"]


def rimmed(pixels, colour):
    """The same sprite with the right-hand edge of every row lit."""
    lit = palette.rgba(colour)
    out = []
    for row in pixels:
        row = list(row)
        for x in range(len(row) - 1, -1, -1):
            if row[x][3]:
                row[x] = lit
                break
        out.append(row)
    return out


# **The other poses, derived from the drawn one.**
#
# Task 0074 wants a walk, an attack and a death for each of five enemies, and
# a telegraph for the Giant. Drawn by hand that is sixteen more ASCII maps,
# and sixteen maps drawn to a deadline are sixteen mediocre maps. These three
# are derived instead, the way the rim light above is and the way task 0072's
# edge tiles are composited from four sides rather than drawn as forty-seven.
#
# **They are derivations and the journal says so.** A hand-drawn stride reads
# better than a bob and a hand-drawn slump better than a rotation; what these
# buy is five enemies that all animate, consistently, today, from one drawing
# each. If the art ever matters more than that, the maps are where to put the
# work and nothing else has to change.
#
#   walk_b     the whole sprite a pixel higher - a bob rather than a stride.
#              Universal: it works on the runner, which leans, and on the
#              Giant, which is not shaped like a person at all. A leg-swap by
#              mirroring the lower third would have broken both.
#   attack     the top two thirds shifted along, which reads as reaching for
#              the thing in front of it. Two pixels was invisible on a sheet
#              at three times zoom; four is a lean you can see.
#   death      rotated flat. A body on the ground, and the one derivation
#              that looks deliberate rather than cheap.
DERIVED = ["walker", "runner", "tank", "breaker", "giant"]


def _blank_row(width):
    return [(0, 0, 0, 0)] * width


def bobbed(pixels):
    """A pixel higher, for the second frame of a walk."""
    return pixels[1:] + [_blank_row(len(pixels[0]))]


def lunging(pixels, by=4):
    """The top two thirds shifted along, reaching."""
    cut = (len(pixels) * 2) // 3
    out = []
    for y, row in enumerate(pixels):
        if y >= cut:
            out.append(list(row))
            continue
        out.append([(0, 0, 0, 0)] * by + list(row[:-by]))
    return out


def fallen(pixels):
    """Rotated flat and dropped to the bottom of its own canvas."""
    height = len(pixels)
    width = len(pixels[0])
    # Quarter turn: the new row y is the old column, read bottom to top.
    turned = [[pixels[height - 1 - x][y] for x in range(height)]
              for y in range(width)]
    out = [_blank_row(height) for _ in range(height - width)]         if height > width else []
    out.extend(turned)
    return out[-height:] if len(out) > height else out


# **Buildings are drawn whole and sliced afterwards.**
#
# A house is three tiles by three and the view asks for it a tile at a time,
# as `house_0_0` through `house_2_2`. Drawing nine separate sixteen by sixteen
# maps means drawing a house you cannot see: the roof line has to meet across
# three files and the only way to check is to build it and look. So the map is
# one forty-eight by forty-eight drawing and this cuts it up.
#
# The names are `id_column_row`, which is what `WorldView._art_for()` asks for.
SLICED = {
    "buildings/house": ("house", 3, 3),
    "buildings/workshop": ("workshop", 2, 2),
    "buildings/kitchen": ("kitchen", 2, 2),
}

# **Towers grow.** Task 0075 asks that a level one and a level three tower be
# told apart instantly, and the answer that reads at sixteen pixels is height:
# a tower with two more stages in it is a different shape on the skyline, and
# counting studs is not instant.
#
# Each entry is the row range of the stage that repeats - a plain section of
# post with nothing on it - and the derivation stacks one more copy per level,
# pushing everything above it up. The tower gets taller and stays the same
# tower, which is the other half of the requirement.
# Six rows of plain post on the three that stand on one, so a level three is
# twelve pixels taller than a level one - three quarters of a tile, which is a
# difference you see rather than measure. Four rows was eight pixels and the
# check said so.
#
# The mortar is the exception and stays squat: it sits on the ground rather
# than on a post, and the only thing it has to repeat is its barrel. Making it
# as tall as the others would take away the one thing its silhouette has.
GROWS = {
    "buildings/gun_tower": (17, 23),
    "buildings/flame_tower": (17, 23),
    "buildings/mortar": (16, 20),
    "buildings/auto_crossbow": (17, 23),
}
LEVELS = 3

# **The muzzle, for the frame where something comes out of it.** One point per
# tower, because a flash belongs where the barrel is and only the drawing
# knows where that is. Derived like everything else here: the flash is stamped
# on, so a tower that grows still fires from the same place relative to its
# head.
FIRES = {
    "buildings/gun_tower": (13, 5),
    "buildings/flame_tower": (11, 3),
    "buildings/mortar": (10, 9),
    "buildings/auto_crossbow": (14, 7),
}

# A small blossom of light. `flame_hot` in the middle, `flame` around it, and
# both are above task 0071's night exemption - so a tower firing after dark
# lights itself, which is the cheapest version of task 0076's job and stops
# a gun line reading as scenery.
FLASH = [
    "  .  ",
    " .o. ",
    ".ohho",
    " .o. ",
    "  .  ",
]


def flashing(pixels, at):
    """The same tower with its muzzle lit."""
    hot = palette.rgba("flame_hot")
    warm = palette.rgba("flame")
    out = [list(r) for r in pixels]
    ox, oy = at
    for ry, row in enumerate(FLASH):
        for rx, ch in enumerate(row):
            if ch == " ":
                continue
            x = ox + rx - len(row) // 2
            y = oy + ry - len(FLASH) // 2
            if 0 <= y < len(out) and 0 <= x < len(out[0]):
                out[y][x] = hot if ch == "h" else warm
    return out

# Everything that can be hit gets a damaged and a destroyed state. Derived,
# for the reason the enemies' poses are: drawing two more of each by hand is
# thirty more maps and the damage that reads is not detail, it is holes.
HURT = ["buildings/gun_tower", "buildings/flame_tower", "buildings/mortar",
        "buildings/auto_crossbow", "buildings/wall", "buildings/fence",
        "buildings/barricade"]


def _lit(pixel):
    return pixel[3] != 0


def holed(pixels, every, seed):
    """The same thing with pixels knocked out of it.

    **A deterministic scatter, not a random one.** `every`-th lit pixel goes,
    counted along the row, which puts the holes in a different place on each
    row without anything drawing a number. A wall with a bite out of one
    corner reads as damaged; a wall that is evenly speckled reads as a
    texture, so the count carries across rows rather than resetting.
    """
    out = []
    n = seed
    for row in pixels:
        line = []
        for px in row:
            if _lit(px):
                n += 1
                if n % every == 0:
                    line.append((0, 0, 0, 0))
                    continue
            line.append(px)
        out.append(line)
    return out


def rubble(pixels):
    """What is left when it comes down: the bottom third, holed."""
    height = len(pixels)
    keep = height - height // 3
    out = [[(0, 0, 0, 0)] * len(pixels[0]) for _ in range(keep)]
    out.extend(holed(pixels[keep:], 3, 1))
    return out


def grown(pixels, band, levels):
    """One more copy of `band` per level above the first.

    **The canvas grows with it.** The first version kept the canvas the same
    height and took the extra rows off the top, which is the one place a
    tower cannot spare them: a level three gun tower came out as a post with
    a platform and no gun on it. The view bottom-aligns anything taller than
    a tile onto the cell, so a taller image simply stands taller - the feet
    stay on the same grid line and the head goes up into the row above.
    """
    low, high = band
    stage = [list(r) for r in pixels[low:high]]
    out = [list(r) for r in pixels]
    for _extra in range(levels - 1):
        out = out[:low] + [list(r) for r in stage] + out[low:]
    return out


def _sliced(name, pixels, cols, rows, tile):
    out = {}
    for col in range(cols):
        for row in range(rows):
            piece = [r[col * tile:(col + 1) * tile]
                     for r in pixels[row * tile:(row + 1) * tile]]
            out["buildings/%s_%d_%d" % (name, col, row)] = (tile, tile, piece)
    return out


# --------------------------------------------------------------- the renderer

def render(name, spec):
    """One sprite, as (width, height, list of RGBA rows)."""
    width, height = spec["size"]
    rows = spec["rows"]
    legend = spec["legend"]

    if len(rows) != height:
        raise ValueError("%s: %d rows, expected %d" % (name, len(rows), height))

    pixels = []
    for y, row in enumerate(rows):
        if len(row) != width:
            raise ValueError("%s: row %d is %d wide, expected %d"
                             % (name, y, len(row), width))
        out = []
        for x, ch in enumerate(row):
            if ch == ".":
                out.append((0, 0, 0, 0))
                continue
            if ch not in legend:
                raise ValueError("%s: row %d column %d is %r, which the legend "
                                 "does not know" % (name, y, x, ch))
            colour = legend[ch]
            out.append((0, 0, 0, 0) if colour is None
                       else palette.rgba(colour))
        pixels.append(out)
    if name in RIM:
        pixels = rimmed(pixels, RIM_COLOUR)
    return width, height, pixels


def tile_of(name, raster=None):
    """One terrain tile by name, as a list of RGBA rows."""
    key = "terrain/" + name
    if art_ownership.registry().get("sprites/" + key + ".png") == "raster":
        from import_art import load_manifest, build
        # Local to this atlas build: reuse validated sources, never stale globals
        # or runtime PNGs. Each new invocation rechecks manifest/source hashes.
        if raster is None:
            raster = {}
        if "images" not in raster:
            raster["images"] = build(load_manifest())[1]
        image = raster["images"][key]
        if image.size != (TILE_PX, TILE_PX):
            raise ValueError("Raster terrain must remain 16x16: " + key)
        from import_art import samples
        pixels = list(samples(image.convert("RGBA")))
        return [pixels[y * TILE_PX:(y + 1) * TILE_PX] for y in range(TILE_PX)]
    if key not in SPRITES:
        raise KeyError("the atlas wants %s and there is no map for it" % key)
    width, height, pixels = render(key, SPRITES[key])
    if (width, height) != (TILE_PX, TILE_PX):
        raise ValueError("terrain/%s is %dx%d and a tile is %dx%d"
                         % (name, width, height, TILE_PX, TILE_PX))
    return pixels


def over(under, above):
    """`above` laid on `under`, honouring alpha as all-or-nothing.

    The palette has no partial alpha in it - a pixel is a colour or it is not
    there - so this is a copy where the top is opaque and nothing where it is
    not. Blending would invent colours that are not in the palette, which is
    the one thing the whole pipeline exists to prevent.
    """
    return [[a if a[3] else u for u, a in zip(u_row, a_row)]
            for u_row, a_row in zip(under, above)]


def blank_tile():
    return [[(0, 0, 0, 0)] * TILE_PX for _ in range(TILE_PX)]


def edge_row(prefix, raster=None):
    """Sixteen tiles, one per combination of the four sides.

    **This is the autotiling, and it is four maps rather than forty-seven.**
    Tile `n` has the side maps whose bits are set in `n` laid over each other,
    so a cell with grass north and west gets `edge_n` and `edge_w` together -
    which is a corner that nobody drew. The view computes the same four bits
    from the same four neighbours and reads the tile straight off.
    """
    sides = [tile_of("%s_%s" % (prefix, side), raster) for side in EDGE_SIDES]
    row = []
    for mask in range(16):
        tile = blank_tile()
        for bit, side in enumerate(sides):
            if mask & (1 << bit):
                tile = over(tile, side)
        row.append(tile)
    return row


def build_atlas():
    """The terrain atlas: a grid of tiles, row by row.

    Row 0 is `Farm.Terrain` order and everything after it is a variant, an
    animation frame or a composited edge. Short rows are padded with empty
    tiles, because an atlas has to be a rectangle.
    """
    rows, raster = [], {}
    for names in ATLAS_ROWS:
        rows.append([tile_of(name, raster) for name in names])
    for prefix in EDGE_ROWS:
        rows.append(edge_row(prefix, raster))
    for prefix, start in CORNER_START.items():
        for index, corner in enumerate(CORNER_ORDER):
            while len(rows[0]) <= start + index:
                rows[0].append(blank_tile())
            rows[0][start + index] = tile_of(prefix + "_corner_" + corner, raster)

    across = max(len(row) for row in rows)
    width = across * TILE_PX
    height = len(rows) * TILE_PX

    pixels = []
    for row in rows:
        padded = row + [blank_tile()] * (across - len(row))
        for y in range(TILE_PX):
            line = []
            for tile in padded:
                line.extend(tile[y])
            pixels.append(line)
    return width, height, pixels


# ------------------------------------------------------------------- the PNG

def png_bytes(width, height, pixels):
    """A PNG, written by hand so that nothing about it varies run to run.

    Pillow is not a dependency of the game and writes a timestamp chunk by
    default; a build output that changes every time it is built is a build
    output nobody can check. This writes the four chunks a viewer needs and
    nothing else.
    """
    import struct
    import zlib

    raw = bytearray()
    for row in pixels:
        raw.append(0)                       # filter type 0: none
        for r, g, b, a in row:
            raw += bytes((r, g, b, a))

    def chunk(kind, payload):
        out = struct.pack(">I", len(payload)) + kind + payload
        return out + struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF)

    header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    # Level 9 and a fixed strategy, so the compressed bytes are a function of
    # the pixels and of nothing else.
    body = zlib.compress(bytes(raw), 9)

    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", header)
            + chunk(b"IDAT", body)
            + chunk(b"IEND", b""))


def palette_gd():
    """`src/ui/palette_data.gd`, written from `tools/palette.py`."""
    lines = [
        "class_name PaletteData",
        "extends RefCounted",
        "",
        "## The palette, generated from `tools/palette.py` by",
        "## `tools/gen_sprites.py`. **Do not edit.**",
        "##",
        "## The sprites are drawn against these colours and the night ramp is",
        "## applied over them at runtime, so the two have to be the same numbers.",
        "## `python tools/gen_sprites.py --check` fails when this file and the",
        "## palette disagree.",
        "",
        "const COLOURS := {",
    ]
    for name in sorted(palette.COLOURS):
        r, g, b = palette.COLOURS[name]
        lines.append('	&"%s": Color8(%d, %d, %d),' % (name, r, g, b))
    lines.append("}")
    lines.append("")
    for ramp_name in sorted(palette.RAMPS):
        ramp = palette.RAMPS[ramp_name]
        tint = ramp["tint"]
        lift = ramp["lift"]
        lines.append("## The %s ramp: what the same pixels look like %s." % (
            ramp_name, "by day" if ramp_name == "day" else "after dark"))
        lines.append("const %s_TINT := Color(%.3f, %.3f, %.3f)"
                     % (ramp_name.upper(), tint[0], tint[1], tint[2]))
        lines.append("const %s_LIFT := Color(%.3f, %.3f, %.3f)"
                     % (ramp_name.upper(), lift[0], lift[1], lift[2]))
        lines.append("const %s_SATURATION := %.3f"
                     % (ramp_name.upper(), ramp["saturation"]))
        # Every ramp declares one now, so the four are the same record and a
        # lerp between two of them does not have to ask which fields exist.
        lines.append("## Legacy brightness threshold; 1 disables all material exemptions.")
        lines.append("## Actual fire/window cores use semantic emission layers.")
        lines.append("const %s_WARM_KEEP := %.3f"
                     % (ramp_name.upper(), ramp.get("warm_keep", 1.0)))
        lines.append("## How wide that threshold is, so a flame has no hard")
        lines.append("## outline where the exemption stops.")
        lines.append("const %s_WARM_EDGE := %.3f"
                     % (ramp_name.upper(), ramp.get("warm_edge", 0.06)))
        lines.append("")
    return "\n".join(lines).encode("utf-8")


def migrated_towers():
    """Skip old drawings only after all three levels/four states have owners."""
    owners = art_ownership.registry()
    return {key for key in GROWS if all(
        owners.get("sprites/" + key + ("_%d" % level if level > 1 else "") + suffix + ".png") == "raster"
        for level in range(1, LEVELS + 1) for suffix in ("", "_hurt", "_fire", "_wreck"))}


def migrated_barriers():
    """No hole/ruin fallback once every occupied-neighbor join has an owner."""
    owners = art_ownership.registry()
    complete = {"buildings/" + family for family in ("wall", "fence") if all(
        owners.get("sprites/buildings/" + family + ("_join_%d" % mask if mask else "") + state + ".png") == "raster"
        for mask in range(16) for state in ("", "_hurt")) and
        owners.get("sprites/buildings/" + family + "_wreck.png") == "raster"}
    if all(owners.get("sprites/buildings/barricade" + suffix + ".png") == "raster"
           for suffix in ("", "_hurt", "_wreck")):
        complete.add("buildings/barricade")
    if all(owners.get("sprites/buildings/mine" + suffix + ".png") == "raster"
           for suffix in ("", "_triggered", "_spent")):
        complete.add("buildings/mine")
    return complete


def migrated_enemies():
    """Stop procedural motion only when the complete authored family owns it."""
    owners = art_ownership.registry()
    complete = {'enemies/' + family for family in ('walker', 'runner', 'tank', 'breaker') if all(
        owners.get('sprites/enemies/' + family + suffix + '.png') == 'raster'
        for suffix in ('', '_walk_b', '_attack', '_death') + tuple('_walk_%d' % i for i in range(4))
        + tuple('_attack_%d' % i for i in range(3)) + tuple('_death_%d' % i for i in range(4)))}
    giant_suffixes = ('', '_walk_b', '_attack', '_death', '_telegraph') + tuple('_walk_%d' % i for i in range(4)) + tuple('_windup_%d' % i for i in range(3)) + tuple('_slam_%d' % i for i in range(3)) + tuple('_death_%d' % i for i in range(5))
    if all(owners.get('sprites/enemies/giant' + suffix + '.png') == 'raster' for suffix in giant_suffixes):
        complete.add('enemies/giant')
    return complete


def derived_sprites():
    """{name: (w, h, pixels)} for every pose that is not drawn by hand."""
    out = {}
    migrated = migrated_towers() | migrated_barriers() | migrated_enemies()

    # Buildings, cut into the tiles the view asks for.
    for key, (name, cols, rows) in sorted(SLICED.items()):
        width, height, pixels = render(key, SPRITES[key])
        if (width, height) != (cols * TILE_PX, rows * TILE_PX):
            raise ValueError("%s is %dx%d and %s is %d by %d tiles"
                             % (key, width, height, name, cols, rows))
        out.update(_sliced(name, pixels, cols, rows, TILE_PX))

    # Towers, at the levels the player can pay for.
    for key, band in sorted(GROWS.items()):
        if key in migrated:
            continue
        width, height, pixels = render(key, SPRITES[key])
        for level in range(2, LEVELS + 1):
            tall = grown(pixels, band, level)
            out["%s_%d" % (key, level)] = (width, len(tall), tall)

    # The frame where a tower is firing, at every level it can be.
    for key, at in sorted(FIRES.items()):
        if key in migrated:
            continue
        width, height, pixels = render(key, SPRITES[key])
        out[key + "_fire"] = (width, height, flashing(pixels, at))
        for level in range(2, LEVELS + 1):
            tall = grown(pixels, GROWS[key], level)
            # **The muzzle does not move.** `grown()` inserts its extra stages
            # at the band, which is below the head, so every row above it
            # keeps its index and the barrel is where it always was.
            out["%s_%d_fire" % (key, level)] = (width, len(tall),
                                                flashing(tall, at))

    # And what everything that can be hit looks like on the way down.
    for key in sorted(HURT):
        if key in migrated:
            continue
        width, height, pixels = render(key, SPRITES[key])
        out[key + "_hurt"] = (width, height, holed(pixels, 7, 0))
        flat = rubble(pixels)
        out[key + "_wreck"] = (width, len(flat), flat)
        if key in GROWS:
            for level in range(2, LEVELS + 1):
                tall = grown(pixels, GROWS[key], level)
                out["%s_%d_hurt" % (key, level)] = (width, len(tall),
                                                    holed(tall, 7, 0))

    for kind in DERIVED:
        key = "enemies/" + kind
        if key in migrated:
            continue
        width, height, pixels = render(key, SPRITES[key])
        out["enemies/%s_walk_b" % kind] = (width, height, bobbed(pixels))
        out["enemies/%s_attack" % kind] = (width, height, lunging(pixels))
        flat = fallen(pixels)
        out["enemies/%s_death" % kind] = (height, len(flat), flat)
    # **The Giant's telegraph is its own pose**, which the task asks for by
    # name: a bigger reach than an attack, so the second before it swings
    # looks different from the swing.
    if 'enemies/giant' not in migrated:
        width, height, pixels = render("enemies/giant", SPRITES["enemies/giant"])
        out["enemies/giant_telegraph"] = (width, height, lunging(pixels, 5))
    return out


def write(path, data):
    """Write only when the bytes changed, so an unchanged sprite keeps its
    modification time and Godot does not re-import the world every run."""
    full = os.path.join(OUT, *path.split("/"))
    os.makedirs(os.path.dirname(full), exist_ok=True)
    if os.path.exists(full):
        with open(full, "rb") as f:
            if f.read() == data:
                return False
    with open(full, "wb") as f:
        f.write(data)
    return True


# ----------------------------------------------------------------- the driver

def everything(dispatch=True):
    """Every output file, as {path: bytes}."""
    out = {}
    migrated = migrated_towers() | migrated_barriers() | migrated_enemies()
    for name, spec in sorted(SPRITES.items()):
        if name in migrated:
            continue
        w, h, pixels = render(name, spec)
        out[name + ".png"] = png_bytes(w, h, pixels)
    for name, (w, h, pixels) in sorted(derived_sprites().items()):
        out[name + ".png"] = png_bytes(w, h, pixels)
    w, h, pixels = build_atlas()
    out[ATLAS_PATH] = png_bytes(w, h, pixels)
    return art_ownership.owned(out, "ascii") if dispatch else out


def palette_target():
    """(path on disk, bytes) for the generated GDScript palette."""
    return PALETTE_GD, palette_gd()


def main():
    check = "--check" in sys.argv
    listing = "--list" in sys.argv

    try:
        files = everything()
    except (ValueError, KeyError) as e:
        print("FAIL  %s" % e)
        return 1

    gd_path, gd_bytes = palette_target()

    if listing:
        for path in sorted(files):
            print("  %-28s %5d bytes" % (path, len(files[path])))
        print("  %-28s %5d bytes"
              % (os.path.relpath(gd_path, ROOT), len(gd_bytes)))
        print("%d files" % (len(files) + 1))
        return 0

    if check:
        stale = []
        for path, data in sorted(files.items()):
            full = os.path.join(OUT, *path.split("/"))
            if not os.path.exists(full):
                stale.append(path + " (missing)")
                continue
            with open(full, "rb") as f:
                if f.read() != data:
                    stale.append(path + " (edited by hand, or the map moved)")
        if not os.path.exists(gd_path) or open(gd_path, "rb").read() != gd_bytes:
            stale.append(os.path.relpath(gd_path, ROOT)
                         + " (the palette moved)")
        if stale:
            print("FAIL  %d sprite(s) out of date:" % len(stale))
            for s in stale:
                print("        " + s)
            print("      run: python tools/gen_sprites.py")
            return 1
        print("OK    %d sprites match their maps" % len(files))
        return 0

    written = 0
    for path, data in sorted(files.items()):
        if write(path, data):
            written += 1
    if not os.path.exists(gd_path) or open(gd_path, "rb").read() != gd_bytes:
        with open(gd_path, "wb") as f:
            f.write(gd_bytes)
        written += 1
    digest = hashlib.sha256(
        b"".join(files[p] for p in sorted(files))).hexdigest()[:12]
    print("sprites: %d files, %d written, %d unchanged  [%s]"
          % (len(files), written, len(files) - written, digest))
    return 0


if __name__ == "__main__":
    sys.exit(main())
