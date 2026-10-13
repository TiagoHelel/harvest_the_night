# -*- coding: utf-8 -*-
"""Play a range of nights with a scripted build and report which fell.

    python tools/play_nights.py [from] [to]

`python tools/play_nights.py 15 28` plays summer (task 0271); one argument
plays from day 1 to it, and none plays the whole year (task 0276), a boss
night fought again while its boss is not down. Each date is bought from a
purse that starts where a run would be, with only what its season has
unlocked.

A reader, not a check: `verify.py` is what fails. This is for looking at the
curve while tuning it - the instrument 0060 authored the ten with and
0271-0274 the seasons.
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
GODOT = os.environ.get(
    "GODOT",
    "C:/Users/PC GAMER DA FAMILIA/Documents/Godot/"
    "Godot_v4.7.2-stable_win64_console.exe")


def main():
    if not os.path.exists(GODOT):
        print("no godot at %s - set GODOT" % GODOT)
        return 1
    done = subprocess.run(
        [GODOT, "--headless", "--path", ROOT,
         "--script", "res://src/tools/play_nights.gd",
         "++"] + sys.argv[1:],
        capture_output=True, text=True)
    out = done.stdout or ""
    for line in out.splitlines():
        # The engine's own banner is not part of the answer.
        if line.startswith("Godot Engine") or line.startswith("Settings:"):
            continue
        print(line)
    return done.returncode


if __name__ == "__main__":
    sys.exit(main())
