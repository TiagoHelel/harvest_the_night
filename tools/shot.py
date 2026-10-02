# -*- coding: utf-8 -*-
"""Take the screenshots, so a visual change can be looked at.

    python tools/shot.py 0082              the whole set
    python tools/shot.py 0082 wave tech    two of them
    python tools/shot.py --list            what there is

Writes `implementation/shots/<id>/<name>.png` at the game's own 480x270.
The scenarios themselves live in `src/tools/shot.gd`; this is the wrapper
that supplies the two flags which make the pictures repeatable, and it is
`tools/verify.py`'s sibling rather than a second way of doing the same job.

## It is not headless, and it cannot be

Task 0082 asked for headless. Godot's `--headless` selects the **dummy**
rendering backend: `Viewport.get_texture().get_image()` returns null out of
`servers/rendering/dummy/storage/texture_storage.h`, and
`RenderingServer.frame_post_draw` never fires at all, so a script that waits
for it hangs rather than failing. Both were measured before this was written,
and the second one is worse than the first - a check that hangs is a check
nobody can put in a suite.

So this opens a real window and puts it four thousand pixels off the left of
the screen, where nothing has to be looked at or clicked, and closes it when
the last picture is written. That is the part of "headless" the task wanted:
one command, no interaction.

## --fixed-fps is what makes two runs match

The simulation is already reproducible - a seed and a script, through
`Sim.advance`. The **view** is not: a flickering lamp, a pulsing warning and a
walking farmer all advance on `delta`, which is real seconds. `--fixed-fps`
hands every frame the same delta whatever the machine is doing, which turns
the view into the same kind of thing the simulation already is.
"""
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))

import verify                                       # noqa: E402

## Frames a second the view is told it is running at. Sixty rather than the
## simulation's thirty, because the view is what this flag is for and a
## smaller delta puts less of an animation between one frame and the next.
FIXED_FPS = 60

## Far enough left that it is off any monitor anybody has. Minimising would be
## tidier and does not work: some drivers stop presenting a minimised window
## and the picture comes back blank.
WINDOW_AT = "-4000,-4000"


def main():
    args = sys.argv[1:]
    if not verify.GODOT:
        print("no Godot found - set GODOT or put it on the path")
        return 1

    command = [verify.GODOT, "--path", verify.PROJECT_PATH,
               "--fixed-fps", str(FIXED_FPS),
               "--position", WINDOW_AT,
               "--script", "res://src/tools/shot.gd", "--"]
    command += args if args else ["latest"]

    code, out = verify.run(command, timeout=600)
    for line in out.splitlines():
        if line.startswith("Godot Engine") or "OpenGL API" in line:
            continue
        if line.strip():
            print(line)
    return code


if __name__ == "__main__":
    sys.exit(main())
