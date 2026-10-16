# -*- coding: utf-8 -*-
"""Print the year's nights without running one, or check the whole year.

    python tools/nights.py [from] [to] [seed]
    python tools/nights.py --years 3
    python tools/nights.py --check

Without `--check`, a reader (task 0270): days 1-56 for seed 0 by default, a
block per season - each day's kinds, sides, count, hit points, reward and
weather, its key, made, Full Moon, boss and calm marks - then the day each
kind is first sent and the days as bars of hit points.
`python tools/nights.py 15 28 3` prints Summer for seed 3, and a range past
day 56 prints the later years (task 0279). `--years 3` prints Years 1-3 and a
line a season of each: its size, its boss and its weather. With `--check`, the year's tables must
pass `check_nights` and every date of the year for seeds 0 and 424242 must
resolve and pass `check_record`, or it exits 1; `tools/verify.py` runs that
as a gate (task 0151).
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
         "--script", "res://src/tools/nights.gd",
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
