# -*- coding: utf-8 -*-
"""Draw the game's name, out of the game's own letters.

    python tools/gen_logo.py            write assets/logo.png
    python tools/gen_logo.py --check    fail if it is out of date
    python tools/gen_logo.py --report   its size and what is in it

## Composed, not drawn again

Task 0091 asks for a logo "generated with the same tools as everything else",
and the obvious reading is an ASCII map in `sprite_maps.py`. A wordmark two
hundred pixels wide is eight thousand characters of hand-drawing, and the
whole reason `tools/font_maps.py` exists is that drawing the same E twice is
two chances to draw it differently.

So the logo is **the game's own letters at four times their size**, which is
the same argument as task 0080's heading face: a whole-number scale of a
bitmap is still a bitmap. The moon behind it is drawn here because a circle
is not a letter, and the palette does the colouring, as it does everywhere.

A logo that is the game's own type is also a logo that cannot drift away from
the game's look, which a separately drawn one would do the first time the
font moved.
"""
import io
import math
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import font_maps                                    # noqa: E402
import gen_font                                     # noqa: E402
import gen_sprites                                  # noqa: E402
import palette                                      # noqa: E402

OUT = os.path.join(ROOT, "assets")

## The two lines, and how many times the drawn size each is.
##
## **Four, not five.** At five the whole thing is two hundred and thirty
## pixels of a four hundred and eighty pixel screen and there is nowhere left
## to put a menu under it.
LINES = [("HARVEST", 4, "gold_light"), ("THE NIGHT", 4, "moon")]

## Pixels between the two lines, at final size.
GAP = 6

## Space either side, so the moon has somewhere to be.
MARGIN = 10

## The moon, which gets its own room on the right rather than sitting on the
## last letter - it was over the T of HARVEST and you could read the word but
## you could see it had been asked to share.
MOON_ROOM = 30
MOON_RADIUS = 20
MOON_BITE = (0.32, -0.30)


def _drawn(text, scale):
    """One line of text as rows of `True`, at `scale` times the drawn size."""
    glyphs = gen_font.every_glyph()
    widths = gen_font.measure(glyphs)
    height = font_maps.ROWS * scale
    rows = [[] for _ in range(height)]
    for i, ch in enumerate(text):
        if ch == " ":
            for y in range(height):
                rows[y] += [False] * (gen_font.SPACE_WIDTH * scale)
            continue
        if ch not in glyphs:
            raise SystemExit("gen_logo: no glyph for %r" % ch)
        left, wide = widths[ch]
        for y in range(height):
            source = glyphs[ch][y // scale]
            for column in range(wide):
                at = left + column
                lit = 0 <= at < len(source) and source[at] == "#"
                rows[y] += [lit] * scale
        if i < len(text) - 1:
            for y in range(height):
                rows[y] += [False] * (gen_font.TRACKING * scale)
    return rows


def build():
    """The logo, as (width, height, rows of RGBA)."""
    drawn = [(_drawn(text, scale), tint) for text, scale, tint in LINES]
    wide = max(len(rows[0]) for rows, _t in drawn)
    tall = sum(len(rows) for rows, _t in drawn) + GAP
    width = wide + MARGIN * 2 + MOON_ROOM
    height = tall + MARGIN * 2

    colours = palette.COLOURS
    pixels = [[(0, 0, 0, 0)] * width for _ in range(height)]

    # **The moon first, so the words sit in front of it.** It is the one
    # thing here that is not a letter, and it is the whole of the premise:
    # a farm, and something coming.
    middle_x = width - MARGIN - MOON_RADIUS
    middle_y = MARGIN + MOON_RADIUS
    bite_x = middle_x + int(MOON_RADIUS * MOON_BITE[0])
    bite_y = middle_y + int(MOON_RADIUS * MOON_BITE[1])
    moon = colours["moon"]
    for y in range(height):
        for x in range(width):
            if math.hypot(x - middle_x, y - middle_y) > MOON_RADIUS:
                continue
            if math.hypot(x - bite_x, y - bite_y) < MOON_RADIUS * 0.86:
                continue
            pixels[y][x] = (moon[0], moon[1], moon[2], 190)

    # Then the words, each centred, with a hard shadow a pixel down so they
    # read against the moon as well as against the sky.
    ink = colours["ink"]
    top = MARGIN
    for rows, tint in drawn:
        colour = colours[tint]
        left = MARGIN + (wide - len(rows[0])) // 2
        for y, row in enumerate(rows):
            for x, lit in enumerate(row):
                if not lit:
                    continue
                for dx, dy, c in [(1, 1, ink), (0, 0, colour)]:
                    at_x, at_y = left + x + dx, top + y + dy
                    if 0 <= at_x < width and 0 <= at_y < height:
                        pixels[at_y][at_x] = (c[0], c[1], c[2], 255)
        top += len(rows) + GAP
    return width, height, pixels


def everything():
    width, height, pixels = build()
    return {"logo.png": gen_sprites.png_bytes(width, height, pixels)}


def main():
    args = sys.argv[1:]
    files = everything()

    if "--report" in args:
        width, height, pixels = build()
        lit = sum(1 for row in pixels for p in row if p[3] > 0)
        print("  logo %dx%d, %d pixels lit" % (width, height, lit))
        for text, scale, tint in LINES:
            print("  '%s' at %dx in %s" % (text, scale, tint))

    if "--check" in args:
        bad = []
        for name, data in sorted(files.items()):
            full = os.path.join(OUT, name)
            if not os.path.exists(full):
                bad.append("%s is missing" % name)
            elif io.open(full, "rb").read() != data:
                bad.append("%s does not match the letters it came from" % name)
        if bad:
            for line in bad:
                print("  " + line)
            print("FAIL  run: python tools/gen_logo.py")
            return 1
        print("OK    the logo matches the font it is made of")
        return 0

    os.makedirs(OUT, exist_ok=True)
    written = 0
    for name, data in sorted(files.items()):
        full = os.path.join(OUT, name)
        if os.path.exists(full) and io.open(full, "rb").read() == data:
            continue
        io.open(full, "wb").write(data)
        written += 1
    print("logo: %d written, %d unchanged" % (written, len(files) - written))
    return 0


if __name__ == "__main__":
    sys.exit(main())
