# -*- coding: utf-8 -*-
"""Cut the owner's character sheet into the frames the game loads.

    python tools/cut_sheet.py            write sprites/actors/
    python tools/cut_sheet.py --check    fail if anything is out of date
    python tools/cut_sheet.py --report   what was found, and what was not used

**This is the one exception to "art comes from an ASCII map".** Task 0073 says
so in as many words: the character was drawn, by hand, in `docs/`, and an
ASCII map of it would be a worse drawing of somebody else's work. Everything
else in `sprites/` still comes from `tools/sprite_maps.py`.

## The frames are not on a grid

They are painted across the sheet at whatever width each pose needed - a swung
axe is wider than a pair of folded arms - so the cut is found rather than
counted. Rows of non-transparent pixels give the bands; columns within a band
give the frames; a frame more than half again the typical width is two that
touch, and is split at its thinnest column. What the tool cannot know is which
pose is which, so **that part is the data below** and the rest is code.

## One scale for every frame

Each frame is cropped tight and then scaled by the **same** factor, which is
worked out once from the height of a reference pose. Scaling each frame to fit
its own box would make the farmer grow and shrink as they swung an axe.

They are then placed on a canvas of one size, aligned by the **feet** - the
middle of the opaque pixels along the bottom of the frame - rather than by the
bounding box, because a raised tool moves the box and does not move the man.

## Deterministic

The same sheet produces byte-identical PNGs: Pillow's resampling is
deterministic, the alpha is thresholded rather than blended, and the PNG is
written by `gen_sprites.png_bytes`, which carries no timestamp.
"""
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import gen_sprites                                  # noqa: E402

SHEET = os.path.join(ROOT, "docs", "sprites_sem_fundo.png")
OUT = os.path.join(ROOT, "sprites", "actors")

# Below this, a pixel is the sheet's soft glow rather than the drawing. The
# requirement is "the glow keyed out, so a frame has hard alpha and no halo
# over the grass", and this is the line it is keyed at: everything above
# becomes fully opaque, everything below disappears.
ALPHA_CUT = 40

# How few pixels a column must have before a wide run is two frames rather
# than one pose holding a long tool. See `_split()`.
JOIN_PX = 8

# **32 wide by 48 tall, over a 16 pixel grid.** Task 0073 asks for the size to
# be decided before anything is cut and the reason written down, so:
#
# The sheet is a painting - half a million distinct colours, frames about
# 90x150 - and the game is 480x270 on 16 pixel tiles. Those cannot both be
# true. Downscaling to 16x24 would throw the drawing away, and raising the
# whole game to 32 pixel tiles would mean redrawing every other sprite in the
# project. Drawing the player two tiles wide and three tall over an unchanged
# grid costs nothing else and is what Stardew does with the same problem.
#
# The canvas is wider than the character so that a raised axe or a cast line
# has somewhere to be without the farmer shrinking to make room.
BODY_HEIGHT = 44
CANVAS = (48, 52)
# Where the feet sit on that canvas. Low, and in the middle.
FEET = (24, 50)

# Which pose is which. The only part of this file a person has to read the
# sheet to write, and the reason the rest can be code.
#
# **All the side art faces west.** There is no east-facing set on the sheet;
# `flip` mirrors the west frames, which is what the drawing is for.
FRAMES = {
    "walk_south": [(0, 0), (0, 1), (0, 2), (0, 3)],
    "walk_north": [(0, 4), (0, 5), (0, 6), (0, 7)],
    "walk_west": [(0, 8), (0, 9), (0, 10), (0, 11)],
    "idle_south": [(1, 0), (1, 1), (1, 2)],
    "idle_north": [(1, 3), (1, 4), (1, 5)],
    "idle_west": [(1, 6), (1, 7), (1, 8)],
    "chop": [(2, 0), (2, 1), (2, 2), (2, 3)],
    "mine": [(2, 4), (2, 5)],
    "till": [(2, 6), (2, 7), (2, 8)],
    # There is no pose of somebody at a workbench on the sheet, so crafting
    # borrows the one empty-handed standing frame. Named here rather than
    # quietly falling through to idle, so the next person can see it is a
    # stand-in and not a choice.
    "craft": [(2, 9)],
    "water": [(2, 10), (3, 0), (3, 1), (3, 2)],
    "fish": [(3, 3)],
    "plant": [(3, 4), (3, 5), (3, 6)],
    "harvest": [(3, 7)],
    "carry": [(3, 8), (3, 9)],
}

# The pose every measurement is taken from. Its height sets the scale for all
# of them, so it has to be one the farmer is standing straight up in.
REFERENCE = (1, 0)


# --------------------------------------------------------------- the finding

def _runs(occupied):
    out, start = [], None
    for i, on in enumerate(occupied):
        if on and start is None:
            start = i
        elif not on and start is not None:
            out.append((start, i))
            start = None
    if start is not None:
        out.append((start, len(occupied)))
    return out


def _split(run, counts, typical):
    """A run much wider than the others may be two frames that touch.

    **Only at a real gap.** The first version split at the thinnest column in
    the middle, whatever it was, and that cut the axe off the man swinging it:
    a raised axe is joined to its owner by about twelve pixels of handle, and
    a cast fishing line by nine, and both are the thinnest column for a long
    way. Two frames that merely brush each other are joined by four to seven.
    So the test is the thickness at the parting, not the shape of the dip -
    below `JOIN_PX` is two poses touching and above it is a man holding
    something.
    """
    x0, x1 = run
    if x1 - x0 <= typical * 1.45:
        return [run]
    lo = x0 + int((x1 - x0) * 0.30)
    hi = x0 + int((x1 - x0) * 0.70)
    at = min(range(lo, hi), key=lambda x: counts[x])
    if counts[at] > JOIN_PX:
        return [run]
    return _split((x0, at), counts, typical) + _split((at, x1), counts,
                                                      typical)


def find_frames(image):
    """[(band_box, [frame_box, ...]), ...] for the whole sheet."""
    alpha = image.getchannel("A").load()
    width, height = image.size
    rows = [any(alpha[x, y] > ALPHA_CUT for x in range(width))
            for y in range(height)]
    bands = []
    for (y0, y1) in _runs(rows):
        counts = [sum(1 for y in range(y0, y1) if alpha[x, y] > ALPHA_CUT)
                  for x in range(width)]
        # A run under thirty pixels is a stray mark - a question mark, a heart
        # - rather than a pose, and is not a frame.
        raw = [r for r in _runs([c > 0 for c in counts]) if r[1] - r[0] >= 30]
        if not raw:
            continue
        typical = sorted(r[1] - r[0] for r in raw)[len(raw) // 2]
        frames = []
        for run in raw:
            frames.extend(_split(run, counts, typical))
        bands.append(((y0, y1), frames))
    return bands


# --------------------------------------------------------------- the cutting

def _keyed(image):
    """The sheet with its glow keyed out: hard alpha, nothing in between."""
    from PIL import Image
    out = image.copy()
    alpha = out.getchannel("A").point(
        lambda v: 255 if v > ALPHA_CUT else 0)
    out.putalpha(alpha)
    return out


def _tight(image, box, band):
    """One frame, cropped to what is actually drawn in it."""
    (y0, y1) = band
    (x0, x1) = box
    crop = image.crop((x0, y0, x1, y1))
    bounds = crop.getbbox()
    return crop.crop(bounds) if bounds else crop


def _feet_centre(frame):
    """The middle of the opaque pixels along the bottom of a frame.

    **Not the middle of the bounding box.** A raised axe or a cast line moves
    the box a long way to one side, and anchoring on it makes the farmer slide
    sideways between two frames of the same swing.
    """
    px = frame.load()
    band = max(1, frame.height // 8)
    xs = [x for y in range(frame.height - band, frame.height)
          for x in range(frame.width) if px[x, y][3]]
    if not xs:
        return frame.width // 2
    return (min(xs) + max(xs)) // 2


def cut(report=False):
    """Every frame, as {name: [PNG bytes, ...]}."""
    from PIL import Image
    sheet = _keyed(Image.open(SHEET).convert("RGBA"))
    bands = find_frames(sheet)

    ref_band, ref_index = REFERENCE
    reference = _tight(sheet, bands[ref_band][1][ref_index],
                       bands[ref_band][0])
    scale = float(BODY_HEIGHT) / float(reference.height)

    used = set()
    out = {}
    for name in sorted(FRAMES):
        pngs = []
        for (band, index) in FRAMES[name]:
            used.add((band, index))
            frame = _tight(sheet, bands[band][1][index], bands[band][0])
            feet = _feet_centre(frame)
            wide = max(1, int(round(frame.width * scale)))
            tall = max(1, int(round(frame.height * scale)))
            small = frame.resize((wide, tall), Image.LANCZOS)
            # **Hard alpha again after the resize.** Downscaling blends the
            # edge back into a halo, and a halo over the grass is the thing
            # the keying was for.
            small.putalpha(small.getchannel("A").point(
                lambda v: 255 if v > 128 else 0))

            canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
            at = (FEET[0] - int(round(feet * scale)), FEET[1] - tall)
            canvas.alpha_composite(small, _clamped(at, small.size))
            pngs.append(_png(canvas))
        out[name] = pngs

    if report:
        print("  %d bands, %d frames found" % (
            len(bands), sum(len(f) for _b, f in bands)))
        print("  scale %.3f, so a %d pixel pose becomes %d"
              % (scale, reference.height, BODY_HEIGHT))
        for band, (_box, frames) in enumerate(bands):
            spare = [i for i in range(len(frames))
                     if (band, i) not in used]
            if spare:
                print("  band %d: %d frames, unused %s"
                      % (band, len(frames), spare))
    return out


def _clamped(at, size):
    """Keep a frame on the canvas. A pose wider than the canvas is a pose the
    canvas is too small for, and it is better to lose a pixel of axe than to
    have Pillow refuse the paste."""
    return (max(0, min(at[0], CANVAS[0] - size[0])),
            max(0, min(at[1], CANVAS[1] - size[1])))


def _png(image):
    rows = []
    px = image.load()
    for y in range(image.height):
        rows.append([px[x, y] for x in range(image.width)])
    return gen_sprites.png_bytes(image.width, image.height, rows)


# ------------------------------------------------------------------ the files

FRAMES_GD = os.path.join(ROOT, "src", "ui", "player_frames.gd")


def frames_gd(frames):
    """`src/ui/player_frames.gd`, so the view never counts files.

    **Generated, not typed twice.** The same reason `palette_data.gd` is: a
    hand-kept count drifts the first time somebody adds a frame to the sheet,
    and the drift is invisible because both numbers look plausible. The view
    asks this how many frames an animation has and loads exactly that many.
    """
    lines = [
        "class_name PlayerFrames",
        "extends RefCounted",
        "",
        "## What `tools/cut_sheet.py` cut out of `docs/sprites_sem_fundo.png`.",
        "## **Do not edit.** `python tools/cut_sheet.py --check` fails when",
        "## this file and the sheet disagree.",
        "",
        "## The canvas every frame is drawn on, and where the feet sit on it.",
        "## The character is about %d pixels tall on it - two tiles wide and"
        % BODY_HEIGHT,
        "## three tall over an unchanged 16 pixel grid, which is task 0073's",
        "## answer to a painted sheet meeting a pixel-art game.",
        "const CANVAS := Vector2i(%d, %d)" % CANVAS,
        "const FEET := Vector2i(%d, %d)" % FEET,
        "",
        "## How many frames each animation has.",
        "const COUNT := {",
    ]
    for name in sorted(frames):
        lines.append('	&"%s": %d,' % (name, len(frames[name])))
    lines.append("}")
    lines.append("")
    return chr(10).join(lines).encode("utf-8")


def paths(frames):
    """{relative path: bytes}, in a fixed order."""
    out = {}
    for name in sorted(frames):
        for i, data in enumerate(frames[name]):
            out["%s_%d.png" % (name, i)] = data
    return out


def main():
    args = sys.argv[1:]
    if not os.path.exists(SHEET):
        print("no sheet at %s" % SHEET)
        return 1
    try:
        from PIL import Image                        # noqa: F401
    except ImportError:
        print("cut_sheet.py needs Pillow: python -m pip install pillow")
        print("The cut PNGs are committed, so this is only needed to re-cut.")
        return 1

    frames = cut(report="--report" in args)
    files = paths(frames)
    generated = frames_gd(frames)

    if "--check" in args:
        bad = []
        for name, data in sorted(files.items()):
            full = os.path.join(OUT, name)
            if not os.path.exists(full):
                bad.append("%s is missing" % name)
            elif io.open(full, "rb").read() != data:
                bad.append("%s does not match the sheet" % name)
        if not os.path.exists(FRAMES_GD):
            bad.append("player_frames.gd is missing")
        elif io.open(FRAMES_GD, "rb").read() != generated:
            bad.append("player_frames.gd does not match the sheet")
        if bad:
            for line in bad:
                print("  " + line)
            print("FAIL  run: python tools/cut_sheet.py")
            return 1
        print("OK    %d player frames match the sheet" % len(files))
        return 0

    os.makedirs(OUT, exist_ok=True)
    written = 0
    for name, data in sorted(files.items()):
        full = os.path.join(OUT, name)
        if os.path.exists(full) and io.open(full, "rb").read() == data:
            continue
        io.open(full, "wb").write(data)
        written += 1
    if not os.path.exists(FRAMES_GD)             or io.open(FRAMES_GD, "rb").read() != generated:
        io.open(FRAMES_GD, "wb").write(generated)
        written += 1
    print("player: %d frames, %d written, %d unchanged"
          % (len(files), written, len(files) - written))
    return 0


if __name__ == "__main__":
    sys.exit(main())
