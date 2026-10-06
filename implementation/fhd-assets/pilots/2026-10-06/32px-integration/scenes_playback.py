"""Turn the motion frames scenes.gd wrote into GIFs, then drop the frames.

    python implementation/fhd-assets/pilots/2026-10-06/32px-integration/scenes_playback.py

Twelve frames 0.1 s apart from the running game, per scene about motion:
trees and animals swaying at the farmstead, the fire and lamp indoors at
dusk, a wave against the towers. Review media only - nothing here becomes a
sprite. The GIFs keep a 960x540 nearest-neighbour copy (one art pixel is
2x2) so they stay small; the full 1920x1080 stills sit beside them.
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[5]
SHOTS = ROOT / "implementation/shots/assets32-1080"


def main():
    scenes = sorted({p.name.split("_motion_")[0] for p in SHOTS.glob("*_motion_*.png")})
    for scene in scenes:
        paths = sorted(SHOTS.glob(scene + "_motion_*.png"))
        frames = []
        for path in paths:
            with Image.open(path) as image:
                half = image.convert("RGB").resize((960, 540), Image.Resampling.NEAREST)
            frames.append(half.quantize(colors=256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE))
        target = SHOTS / ("playback_%s.gif" % scene)
        frames[0].save(target, save_all=True, append_images=frames[1:], duration=100, loop=0)
        for path in paths:
            path.unlink()
        print("wrote", target.relative_to(ROOT).as_posix(), len(frames), "frames")


if __name__ == "__main__":
    main()
