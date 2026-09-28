# -*- coding: utf-8 -*-
"""Draw the icon, at every size a platform asks for.

    python tools/gen_icon.py            write assets/icon*.png
    python tools/gen_icon.py --check    fail if any of them is out of date
    python tools/gen_icon.py --report   what is in it, and at what sizes

## Sixteen by sixteen, and everything else is a whole multiple of it

The done-when is "the 16x16 icon is still recognisable", and the only way to
be sure of that is for **16x16 to be the drawing** rather than the last stop
on the way down from 1024. Every other size is this map scaled by a whole
number - 2x, 3x, 4x, 8x, 16x, 32x, 64x - so a 512 pixel icon is the same
sixteen pixel icon with bigger pixels, and nothing is resampled, blurred or
guessed at.

That also means there is exactly one drawing to change, and no chance of the
big one and the small one drifting into two different pictures.

## It says farm and night in one image

A moon over a house with a lit window, standing on ploughed rows. The moon
says night, the rows say farm, and the window says somebody is still in there
- which is the whole game in three marks.

The first drawing had a crescent and offset furrows. At sixteen pixels the
crescent read as a bracket and the furrows read as brickwork, which is what
opening the file rather than trusting the description is for.

## Where it goes

`assets/icon.png` is what `project.godot` points at and what a taskbar gets.
The rest are for task 0100's exports and for the store page at 0107, which
want 16 through 1024 and would otherwise each resize it themselves.
"""
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import gen_sprites                                    # noqa: E402
import palette                                        # noqa: E402

OUT = os.path.join(ROOT, "assets")

## What each character in the map is painted with.
LEGEND = {
    "n": "night",           # the sky
    "m": "moon",            # the moon over it
    "r": "roof",            # the roof
    "w": "wood",            # the walls
    "g": "gold_light",      # the window, with somebody still in it
    "s": "soil_dark",       # the field
    "t": "soil",            # and the ploughed rows across it
}

## **The drawing.** Sixteen by sixteen, because that is the size it has to
## work at; everything bigger is this with bigger pixels.
ROWS = [
    "nnnnnnnnnnmmmnnn",
    "nnnnnnnnnmmmmmnn",
    "nnnnnnnnnmmmmmnn",
    "nnnnnnnnnmmmmmnn",
    "nnnnnnnnnnmmmnnn",
    "nnnnnnnrrnnnnnnn",
    "nnnnnnrrrrnnnnnn",
    "nnnnnrrrrrrnnnnn",
    "nnnnrrrrrrrrnnnn",
    "nnnnnwwggwwnnnnn",
    "nnnnnwwggwwnnnnn",
    "nnnnnwwwwwwnnnnn",
    "ssssssssssssssss",
    "tttttttttttttttt",
    "ssssssssssssssss",
    "tttttttttttttttt",
]

## The sizes, and the whole-number scale each one is.
##
## Sixteen is the drawing. Thirty-two and forty-eight are what Windows puts in
## a taskbar, 128 is what Godot wants for `config/icon`, 256 is what itch
## shows, and 512 and 1024 are what a store asks for and what nobody should
## have to make by hand twice.
SIZES = [16, 32, 48, 64, 128, 256, 512, 1024]


def base():
    """The map as (width, height, rows of RGBA)."""
    height = len(ROWS)
    width = len(ROWS[0])
    for y, row in enumerate(ROWS):
        if len(row) != width:
            raise ValueError("row %d is %d wide, expected %d"
                             % (y, len(row), width))
        for ch in row:
            if ch not in LEGEND:
                raise ValueError("row %d has no colour for %r" % (y, ch))
    pixels = [[palette.rgba(LEGEND[ch]) for ch in row] for row in ROWS]
    return width, height, pixels


def scaled(size):
    """The drawing at `size`, by repeating pixels a whole number of times."""
    width, height, pixels = base()
    if size % width or size % height:
        raise ValueError("%d is not a whole multiple of %dx%d"
                         % (size, width, height))
    by = size // width
    out = []
    for row in pixels:
        wide = []
        for pixel in row:
            wide.extend([pixel] * by)
        for _ in range(by):
            out.append(wide)
    return size, size, out


def everything():
    out = {}
    for size in SIZES:
        width, height, pixels = scaled(size)
        name = "icon.png" if size == 128 else "icon_%d.png" % size
        out[name] = gen_sprites.png_bytes(width, height, pixels)
    return out


def report():
    width, height, pixels = base()
    used = {}
    for row in ROWS:
        for ch in row:
            used[ch] = used.get(ch, 0) + 1
    print("  the drawing is %dx%d" % (width, height))
    for ch in sorted(used):
        print("  %-2s %-12s %4d pixels" % (ch, LEGEND[ch], used[ch]))
    print("  written at %s" % ", ".join(str(s) for s in SIZES))


def main():
    args = sys.argv[1:]
    files = everything()

    if "--report" in args:
        report()

    if "--check" in args:
        bad = []
        for name, data in sorted(files.items()):
            full = os.path.join(OUT, name)
            if not os.path.exists(full):
                bad.append("%s is missing" % name)
            elif io.open(full, "rb").read() != data:
                bad.append("%s does not match the map" % name)
        if bad:
            for line in bad:
                print("  " + line)
            print("FAIL  run: python tools/gen_icon.py")
            return 1
        print("OK    %d icon sizes match the one drawing" % len(files))
        return 0

    os.makedirs(OUT, exist_ok=True)
    written = 0
    for name, data in sorted(files.items()):
        full = os.path.join(OUT, name)
        if os.path.exists(full) and io.open(full, "rb").read() == data:
            continue
        io.open(full, "wb").write(data)
        written += 1
    print("icon: %d sizes, %d written, %d unchanged"
          % (len(files), written, len(files) - written))
    return 0


if __name__ == "__main__":
    sys.exit(main())
