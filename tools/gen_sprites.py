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
from sprite_maps import SPRITES                   # noqa: E402

OUT = os.path.join(ROOT, "sprites")

# The palette, again, in GDScript.
#
# **Generated, not typed twice.** The view needs the night ramp and the game is
# not going to read a .py file at runtime; a hand-kept second copy would drift
# the first time somebody tuned a colour, and the drift would be invisible
# because both copies would look plausible.
PALETTE_GD = os.path.join(ROOT, "src", "ui", "palette_data.gd")

# The terrain tiles, in `Farm.Terrain` order, packed into one strip so the
# TileMapLayer has a single atlas rather than six textures.
TERRAIN_ORDER = ["grass", "soil", "water", "rock", "path", "floor"]
ATLAS_PATH = "terrain/atlas.png"


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
    return width, height, pixels


def build_atlas():
    """The six terrain tiles side by side, left to right in Terrain order."""
    tiles = []
    for terrain in TERRAIN_ORDER:
        key = "terrain/" + terrain
        if key not in SPRITES:
            raise KeyError("the atlas wants %s and there is no map for it" % key)
        tiles.append(render(key, SPRITES[key]))

    height = tiles[0][1]
    width = sum(t[0] for t in tiles)
    for name, (w, h, _) in zip(TERRAIN_ORDER, tiles):
        if h != height:
            raise ValueError("terrain/%s is %d tall and the atlas is %d"
                             % (name, h, height))

    pixels = []
    for y in range(height):
        row = []
        for _w, _h, tile in tiles:
            row.extend(tile[y])
        pixels.append(row)
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
        lines.append("## Anything the palette drew brighter than this keeps")
        lines.append("## its own colour: firelight, a lit window, the moon.")
        lines.append("const %s_WARM_KEEP := %.3f"
                     % (ramp_name.upper(), ramp.get("warm_keep", 1.0)))
        lines.append("## How wide that threshold is, so a flame has no hard")
        lines.append("## outline where the exemption stops.")
        lines.append("const %s_WARM_EDGE := %.3f"
                     % (ramp_name.upper(), ramp.get("warm_edge", 0.06)))
        lines.append("")
    return "\n".join(lines).encode("utf-8")


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

def everything():
    """Every output file, as {path: bytes}."""
    out = {}
    for name, spec in sorted(SPRITES.items()):
        w, h, pixels = render(name, spec)
        out[name + ".png"] = png_bytes(w, h, pixels)
    w, h, pixels = build_atlas()
    out[ATLAS_PATH] = png_bytes(w, h, pixels)
    return out


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
