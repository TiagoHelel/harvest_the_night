# -*- coding: utf-8 -*-
"""Print the nights without running one, or check the whole year.

    python tools/nights.py [how many nights] [seed]
    python tools/nights.py --check

Without `--check`, a reader: this is for looking at the curve while tuning
it, which task 0060 does a great deal of. With it, every date of the year
for seeds 0 and 424242 must resolve and pass `check_nights`, or it exits 1;
`tools/verify.py` runs that as a gate (task 0151).
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
