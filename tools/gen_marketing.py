# -*- coding: utf-8 -*-
"""The store page, generated from the game rather than mocked up.

    python tools/gen_marketing.py           make the whole set
    python tools/gen_marketing.py --check   that the set can be made
    python tools/gen_marketing.py --keep    reuse the pictures already taken

One command, because a store page assembled by hand from files somebody
remembered to update is a store page that shows last month's game. Everything
below comes out of `src/tools/shot.gd` running the real build, out of
`assets/logo.png`, and out of `tools/palette.py` - the same three sources the
game itself is made of.

## Five screenshots, and which five

The done-when names them: a day, the switch, a night, a busy wave and the
tech tree. **Not five of the farm.** A store page's job is to make somebody
understand the loop in four seconds of scrolling, and four pictures of a
field say "farming game" and stop.

The switch and the night both come out of the switch strip - the one capture
in `shot.gd` that photographs a change rather than a state - because the
frame where the light is half over is the single most useful picture this
game has, and the frame after it is what the night actually looks like.

## The capsules are the game with its name on it

Nothing is drawn here that is not already in the game. A capsule is a
screenshot scaled by a whole number with `NEAREST` - never smoothed, because
a blurred pixel game on a store page is a lie about what you get - darkened
under a band of the palette's own ink, with `assets/logo.png` on it.

## What is not here

Copy written by a machine. `docs/STORE.md` is a file a person wrote in both
languages, and this copies it into the set rather than generating it. The
pitch in it is the design document's section 20, which is Portuguese, with an
English version beside it - and `--check` fails if the two drift apart.
"""
import io
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import palette                                          # noqa: E402

OUT = os.path.join(ROOT, "build", "store")
SHOTS = os.path.join(ROOT, "implementation", "shots", "store")
LOGO = os.path.join(ROOT, "assets", "logo.png")
COPY = os.path.join(ROOT, "docs", "STORE.md")
DESIGN = os.path.join(ROOT, "design.md")

## The capsule sizes, and who asks for each.
##
## Steam's four plus itch's one. They are here as a written-down list rather
## than a loop over ratios because every one of them is a place a real store
## crops and scales differently, and a size arriving without anybody deciding
## to add one is a picture nobody looked at.
CAPSULES = [
    ("header", 460, 215, "Steam header - the one in search results"),
    ("small", 616, 353, "Steam small capsule - lists and shelves"),
    ("main", 1232, 706, "Steam main capsule - the top of the page"),
    ("vertical", 374, 448, "Steam vertical capsule - featured rows"),
    ("cover", 630, 500, "itch.io cover"),
]

## Which shot fills which capsule. The wave, because a capsule has to say
## what kind of game this is before anybody reads a word.
CAPSULE_SHOT = "wave.png"

## The five, in the order a page should show them.
SCREENSHOTS = [
    ("01-day", "noon.png", "The farm at noon"),
    ("02-switch", "switch-14.png", "The reality switch, half way over"),
    ("03-night", "switch-27.png", "The same tiles, after dark"),
    ("04-wave", "wave.png", "A wave mid-fight"),
    ("05-tech", "tech.png", "What the days pay for"),
]

## How many rows at the top of the screen are HUD, at 1x.
HUD_ROWS = 24

## How the GIF plays: milliseconds a frame, and how long it holds at each end.
GIF_MS = 70
GIF_HOLD_MS = 900


def run(command):
    done = subprocess.run(command, cwd=ROOT, capture_output=True, text=True,
                          timeout=900)
    return done.returncode, (done.stdout or "") + (done.stderr or "")


def capture():
    """Every picture the set needs, out of the real game."""
    if os.path.isdir(SHOTS):
        shutil.rmtree(SHOTS)
    code, out = run([sys.executable, "tools/shot.py", "store", "--switch"])
    if code != 0:
        return "the switch strip would not capture:\n%s" % out[-800:]
    code, out = run([sys.executable, "tools/shot.py", "store",
                     "noon", "wave", "tech"])
    if code != 0:
        return "the screenshots would not capture:\n%s" % out[-800:]
    return ""


def logo_on(image, band_height):
    """The wordmark, centred on the band, as big as it will go."""
    from PIL import Image
    logo = Image.open(LOGO).convert("RGBA")
    room = int(image.width * 0.82)
    scale = max(1, min(room // logo.width,
                       max(1, int(band_height * 0.8) // logo.height)))
    logo = logo.resize((logo.width * scale, logo.height * scale),
                       Image.NEAREST)
    at = ((image.width - logo.width) // 2,
          image.height - band_height
          + (band_height - logo.height) // 2)
    image.alpha_composite(logo, at)
    return image


def capsule(source, width, height):
    """One capsule: the game, scaled whole, with its name under it."""
    from PIL import Image
    shot = Image.open(source).convert("RGBA")

    # **Whole numbers only.** A store page showing a smoothed pixel game is
    # a promise the build does not keep.
    #
    # **The smallest scale that covers the target**, which decides how
    # much of the farm ends up in the picture. The first version pushed
    # the scale as high as it would go before cropping, and the header
    # capsule came back as a close-up of four tiles and a hat - which
    # says nothing about what kind of game this is, and that is the one
    # job a header capsule has.
    scale = 1
    while shot.width * scale < width or shot.height * scale < height:
        scale += 1
    big = shot.resize((shot.width * scale, shot.height * scale), Image.NEAREST)
    left = (big.width - width) // 2

    # **Start below the HUD bar.** A third down was the rule and it left a
    # sliver of the night HUD's health bar clipped across the top edge of
    # the header capsule, which reads as a mistake rather than as a game.
    # There is no HUD-free capture mode and there does not need to be: the
    # top rows are the only chrome a crop this shape can catch.
    top = max(HUD_ROWS * scale, (big.height - height) // 3)
    top = min(top, big.height - height)
    out = big.crop((left, top, left + width, top + height))

    band = max(int(height * 0.38), 48)
    ink = palette.rgb("ink")
    shade = Image.new("RGBA", (width, band), ink + (232,))
    out.alpha_composite(shade, (0, height - band))
    return logo_on(out, band)


def gif(frames, path):
    """The switch, looping, with a beat at each end."""
    from PIL import Image
    if not frames:
        return "no switch frames to make a GIF out of"
    scale = 2
    pictures = []
    for one in frames:
        im = Image.open(one).convert("RGB")
        pictures.append(im.resize((im.width * scale, im.height * scale),
                                  Image.NEAREST))
    # **A beat at each end**, so a looping GIF reads as day-then-night rather
    # than as a light flickering.
    times = [GIF_MS] * len(pictures)
    times[0] = GIF_HOLD_MS
    times[-1] = GIF_HOLD_MS
    pictures[0].save(path, save_all=True, append_images=pictures[1:],
                     duration=times, loop=0, optimize=True)
    return ""


def pitch_lines():
    """The design document's section 20, as the lines it is made of."""
    text = io.open(DESIGN, encoding="utf-8").read()
    if "# 20. Elevator Pitch" not in text:
        return []
    after = text.split("# 20. Elevator Pitch", 1)[1]
    out = []
    for line in after.splitlines():
        if line.startswith("#"):
            break
        line = line.strip()
        if line.startswith(">"):
            line = line[1:].strip().replace("**", "")
            if line:
                out.append(line)
    return out


def copy_is_honest():
    """Every line of the design document's pitch is in the Portuguese copy.

    **The one thing about a store page that can quietly stop being true.**
    The pitch is the game's own description of itself and it lives in
    `design.md`; a page that drifted from it would be a page describing a
    game somebody decided not to make."""
    if not os.path.exists(COPY):
        return ["docs/STORE.md is missing, so there is no copy"]
    text = io.open(COPY, encoding="utf-8").read()
    bad = []
    lines = pitch_lines()
    if not lines:
        bad.append("design.md has no section 20 to take a pitch from")
    for line in lines:
        if line not in text:
            bad.append("the pitch line %r is not in docs/STORE.md" % line[:48])
    for wanted in ["## English", "## Portugues"]:
        if wanted not in text:
            bad.append("docs/STORE.md has no %r section" % wanted)
    return bad


def main():
    args = sys.argv[1:]
    print("")
    print("HARVEST THE NIGHT - store assets")
    print("")

    bad = copy_is_honest()
    for line in bad:
        print("  FAIL  " + line)
    if bad:
        print("FAIL  the copy and the design document disagree")
        return 1
    print("  copy       docs/STORE.md says what design.md says")

    if "--check" in args:
        missing = [p for p in [LOGO, COPY] if not os.path.exists(p)]
        for one in missing:
            print("  FAIL  %s is missing" % os.path.relpath(one, ROOT))
        if missing:
            return 1
        print("")
        print("CHECKED  the parts that need no capture")
        return 0

    # **`--keep` is for composing, not for making a set.** Capturing is a
    # minute and a half and laying out a capsule takes a dozen tries.
    if "--keep" in args and os.path.isdir(SHOTS):
        print("  kept       the pictures already captured (--keep)")
    else:
        trouble = capture()
        if trouble:
            print("  FAIL  " + trouble)
            return 1
    print("  captured   %d pictures into %s"
          % (len(os.listdir(SHOTS)), os.path.relpath(SHOTS, ROOT)))

    if os.path.isdir(OUT):
        shutil.rmtree(OUT)
    os.makedirs(OUT)

    for name, source, caption in SCREENSHOTS:
        where = os.path.join(SHOTS, source)
        if not os.path.exists(where):
            print("  FAIL  %s was not captured" % source)
            return 1
        shutil.copyfile(where, os.path.join(OUT, "screenshot-%s.png" % name))
        print("  shot       %-12s %s" % (name, caption))

    for name, width, height, why in CAPSULES:
        image = capsule(os.path.join(SHOTS, CAPSULE_SHOT), width, height)
        image.convert("RGB").save(
            os.path.join(OUT, "capsule-%s.png" % name))
        print("  capsule    %-12s %4dx%-4d  %s" % (name, width, height, why))

    frames = sorted(os.path.join(SHOTS, f) for f in os.listdir(SHOTS)
                    if f.startswith("switch-") and f.endswith(".png"))
    trouble = gif(frames, os.path.join(OUT, "the-switch.gif"))
    if trouble:
        print("  FAIL  " + trouble)
        return 1
    size = os.path.getsize(os.path.join(OUT, "the-switch.gif"))
    print("  gif        the-switch   %d frames, %.2f MB"
          % (len(frames), size / 1048576.0))

    shutil.copyfile(COPY, os.path.join(OUT, "STORE.md"))
    print("  copy       STORE.md     English and Portuguese")

    print("")
    print("MADE  %s - %d files"
          % (os.path.relpath(OUT, ROOT), len(os.listdir(OUT))))
    return 0


if __name__ == "__main__":
    sys.exit(main())
