"""Animated playback of the approved-walk renderer captures.

    python implementation/fhd-player/pilots/2026-10-06/walk-approved-integration/playback.py

Reads the sheets capture.gd wrote from the real 1920x1080 renderer (rows in
PlayerArt.HEADINGS order: south, north, west, east, south-east, south-west,
north-east, north-west; nine columns, the ninth being phase 1 again) and plays
the eight phases at the game's frame times - walking 0.1 s, running 0.07 s -
all eight directions side by side, plus the stop/start strip. Review media
only: nothing here is a sprite source and no game file is read or written.
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[5]
SHOTS = ROOT / "implementation/shots/walk-approved-1080"
CROP = 240
PHASES = 8


def cells(sheet):
    with Image.open(sheet) as image:
        image = image.convert("RGB")
    return [[image.crop((c * CROP, r * CROP, (c + 1) * CROP, (r + 1) * CROP))
             for c in range(image.width // CROP)] for r in range(image.height // CROP)]


def save(frames, name, milliseconds):
    frames = [f.quantize(colors=256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE) for f in frames]
    frames[0].save(SHOTS / name, save_all=True, append_images=frames[1:], duration=milliseconds, loop=0)
    print("wrote", (SHOTS / name).relative_to(ROOT).as_posix(), len(frames), "frames")


def main():
    for light in ("day", "night"):
        for motion, milliseconds in (("walk", 100), ("run", 70)):
            rows = cells(SHOTS / ("farmer_%s_%s.png" % (motion, light)))
            frames = []
            for column in range(PHASES):
                frame = Image.new("RGB", (CROP * len(rows), CROP))
                for index, row in enumerate(rows):
                    frame.paste(row[column], (index * CROP, 0))
                frames.append(frame)
            save(frames, "playback_%s_%s.gif" % (motion, light), milliseconds)
        strip = cells(SHOTS / ("farmer_stop_start_%s.png" % light))[0]
        save(strip, "playback_stop_start_%s.gif" % light, 100)


if __name__ == "__main__":
    main()
