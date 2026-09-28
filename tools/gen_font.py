# -*- coding: utf-8 -*-
"""Turn `tools/font_maps.py` into the bitmap font the game loads.

    python tools/gen_font.py            write assets/fonts/
    python tools/gen_font.py --check    fail if anything is out of date
    python tools/gen_font.py --report   coverage, widths and the two sizes

Output is a BMFont `.fnt` beside a PNG page, which Godot imports as a
`FontFile`. The page is the `.fnt`'s own business - Godot reads it through the
font importer rather than as a texture - so there is nothing here that has to
turn filtering off: a bitmap font is drawn a pixel at a time at whatever whole
size it is asked for, and asking for a size it was not drawn at is the only
way to blur it. `UiKit.FONT_SIZE` is why nothing does.

**Two sizes, one design.** The HUD face is the maps at their drawn size and
the heading face is the same maps at exactly twice that. A whole-number scale
of a bitmap is still a bitmap; a face drawn separately at double the size
would be a second font to keep in step, and the one thing worse than a font
with no headings is two fonts that drift apart.

## Proportional, except the digits

Each glyph is trimmed to its ink, so `I` is narrow and `M` is wide. **Digits
are not trimmed**: all ten are given the same advance, so a counter going from
9 to 10 to 99 moves nothing around it. That is task 0080's second done-when
and it is the whole reason the trimming has an exception in it.
"""
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import font_maps                                    # noqa: E402
import gen_sprites                                  # noqa: E402

OUT = os.path.join(ROOT, "assets", "fonts")

## The two faces: name, how many times the drawn size, and the file stem.
FACES = [("hud", 1), ("heading", 2)]

## A space is drawn as nothing, so its width comes from here instead.
SPACE_WIDTH = 3

## Pixels between one glyph and the next.
TRACKING = 1

## White, so anything drawing the font can tint it. A bitmap font baked in a
## colour is a font that can only ever be that colour.
INK = (255, 255, 255, 255)


def _rows(spec):
    out = spec.split("/")
    if len(out) != font_maps.ROWS:
        raise ValueError("%r has %d rows, expected %d"
                         % (spec, len(out), font_maps.ROWS))
    for row in out:
        if len(row) != font_maps.COLS:
            raise ValueError("%r has a row %d wide, expected %d"
                             % (spec, len(row), font_maps.COLS))
    return out


def _over(under, above):
    """One glyph's rows laid on another's. Ink wins."""
    return ["".join("#" if a == "#" or b == "#" else "."
                    for a, b in zip(u, v))
            for u, v in zip(under, above)]


def every_glyph():
    """{character: rows} for the whole of the font, composed included."""
    out = {}
    for ch, spec in font_maps.GLYPHS.items():
        out[ch] = _rows(spec)
    for ch, spec in font_maps.EXTRA.items():
        out[ch] = _rows(spec)
    for ch, spec in font_maps.LATIN1_REST.items():
        out[ch] = _rows(spec)
    # **Composed, not drawn again.** An accented letter is a letter with a
    # mark on it, and drawing fifty of them by hand would be fifty chances to
    # draw the same E slightly differently.
    for ch, (base, mark) in font_maps.ACCENTED.items():
        if base not in font_maps.GLYPHS:
            raise KeyError("%r wants a base %r that is not drawn" % (ch, base))
        out[ch] = _over(_rows(font_maps.GLYPHS[base]),
                        _rows(font_maps.MARKS[mark]))
    for ch, base in font_maps.CEDILLAS.items():
        out[ch] = _over(_rows(font_maps.GLYPHS[base]),
                        _rows(font_maps.CEDILLA))
    return out


def _ink_columns(rows):
    """(first, last) columns with anything in them, or None when empty."""
    used = [x for row in rows for x, ch in enumerate(row) if ch == "#"]
    return (min(used), max(used)) if used else None


def measure(glyphs):
    """{character: (left, width)} - where the ink starts and how wide it is.

    Digits all take the widest digit's box, which is what makes them tabular.
    """
    out = {}
    for ch, rows in glyphs.items():
        span = _ink_columns(rows)
        out[ch] = (0, SPACE_WIDTH) if span is None \
            else (span[0], span[1] - span[0] + 1)

    digits = [c for c in "0123456789" if c in out]
    if digits:
        widest = max(out[c][1] for c in digits)
        for c in digits:
            left, width = out[c]
            # Centred in the shared box, so a 1 sits in the middle of the
            # space a 0 would take rather than hugging its left edge.
            out[c] = (left - (widest - width) // 2, widest)
    return out


def page(glyphs, widths, scale):
    """The texture, as (width, height, rows of RGBA) plus {char: x}."""
    order = sorted(glyphs, key=ord)
    cell_h = font_maps.ROWS * scale
    xs = {}
    x = 0
    for ch in order:
        xs[ch] = x
        x += widths[ch][1] * scale
    width = max(x, 1)

    pixels = [[(0, 0, 0, 0)] * width for _ in range(cell_h)]
    for ch in order:
        left, wide = widths[ch]
        rows = glyphs[ch]
        for y, row in enumerate(rows):
            for column in range(wide):
                source = left + column
                if source < 0 or source >= len(row) or row[source] != "#":
                    continue
                for sy in range(scale):
                    for sx in range(scale):
                        pixels[y * scale + sy][xs[ch] * 1 + column * scale
                                               + sx] = INK
    return width, cell_h, pixels, xs


def fnt(glyphs, widths, xs, page_width, page_height, scale, png_name):
    """The BMFont description Godot imports."""
    line_h = font_maps.ROWS * scale
    base = font_maps.BASELINE * scale
    out = [
        "info face=\"harvest\" size=%d bold=0 italic=0 charset=\"\" "
        "unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=0,0"
        % line_h,
        "common lineHeight=%d base=%d scaleW=%d scaleH=%d pages=1 packed=0"
        % (line_h, base, page_width, page_height),
        "page id=0 file=\"%s\"" % png_name,
        "chars count=%d" % len(glyphs),
    ]
    for ch in sorted(glyphs, key=ord):
        wide = widths[ch][1] * scale
        out.append(
            "char id=%d x=%d y=0 width=%d height=%d xoffset=0 yoffset=0 "
            "xadvance=%d page=0 chnl=15"
            % (ord(ch), xs[ch], wide, line_h, wide + TRACKING * scale))
    return ("\n".join(out) + "\n").encode("utf-8")


def everything():
    """{path: bytes} for the whole font."""
    glyphs = every_glyph()
    widths = measure(glyphs)
    out = {}
    for name, scale in FACES:
        png_name = "harvest_%s.png" % name
        w, h, pixels, xs = page(glyphs, widths, scale)
        out[png_name] = gen_sprites.png_bytes(w, h, pixels)
        out["harvest_%s.fnt" % name] = fnt(glyphs, widths, xs, w, h, scale,
                                           png_name)
    return out, glyphs, widths


def main():
    args = sys.argv[1:]
    files, glyphs, widths = everything()

    if "--report" in args:
        print("  %d glyphs" % len(glyphs))
        drawn = (len(font_maps.GLYPHS) + len(font_maps.EXTRA)
                 + len(font_maps.LATIN1_REST))
        print("  %d drawn, %d composed from %d marks"
              % (drawn, len(glyphs) - drawn, len(font_maps.MARKS) + 1))
        digits = sorted({widths[c][1] for c in "0123456789"})
        print("  digit widths: %s (one value means tabular)" % digits)
        for name, scale in FACES:
            print("  %s: %d pixels a line at %dx"
                  % (name, font_maps.ROWS * scale, scale))

    if "--check" in args:
        bad = []
        for name, data in sorted(files.items()):
            full = os.path.join(OUT, name)
            if not os.path.exists(full):
                bad.append("%s is missing" % name)
            elif io.open(full, "rb").read() != data:
                bad.append("%s does not match the maps" % name)
        if bad:
            for line in bad:
                print("  " + line)
            print("FAIL  run: python tools/gen_font.py")
            return 1
        print("OK    %d font files match the maps" % len(files))
        return 0

    os.makedirs(OUT, exist_ok=True)
    written = 0
    for name, data in sorted(files.items()):
        full = os.path.join(OUT, name)
        if os.path.exists(full) and io.open(full, "rb").read() == data:
            continue
        io.open(full, "wb").write(data)
        written += 1
    print("font: %d files, %d written, %d unchanged"
          % (len(files), written, len(files) - written))
    return 0


if __name__ == "__main__":
    sys.exit(main())
