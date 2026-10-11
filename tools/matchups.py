# -*- coding: utf-8 -*-
"""Every weapon has its night (task 0259).

    python tools/matchups.py               the whole grid, into implementation/MATCHUPS.md
    python tools/matchups.py --only=rat    one enemy's rows, printed, nothing written

Runs `src/tools/matchups.gd` headless: every defence on the same budget on top
of a fixed base line, against one group of every enemy and every boss with its
escort, on an ordinary night and under fog, rain and the Blood Moon. Seeded and
deterministic - two runs write the same report byte for byte - and never run
by `verify.py`, whose scripts get 120 seconds and a full grid takes minutes.

Prints the claims (`CLAIM`) and the run time; exits with the tool's own code.
"""
import io
import os
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GODOT = os.environ.get("GODOT", os.path.join(
    os.path.expanduser("~"), "Documents", "Godot",
    "Godot_v4.7.2-stable_win64_console.exe"))
SCRIPT = "res://src/tools/matchups.gd"
REPORT = os.path.join(ROOT, "implementation", "MATCHUPS.md")
TIMEOUT_S = 3600


def main():
    args = [a for a in sys.argv[1:] if a.startswith("--only=")]
    started = time.time()
    done = subprocess.run(
        [GODOT, "--headless", "--path", ROOT, "--script", SCRIPT, "--", *args],
        capture_output=True, timeout=TIMEOUT_S)
    out = done.stdout.decode("utf-8", "replace") + done.stderr.decode("utf-8", "replace")
    report = []
    inside = False
    for line in out.splitlines():
        if line == "BEGIN MATCHUPS":
            inside = True
            continue
        if line == "END MATCHUPS":
            inside = False
            continue
        if inside:
            report.append(line)
        elif line.startswith(("DEFENCES", "BUDGET", "CLAIM", "RUN", "FAIL")) \
                or (args and line.startswith("ROW")):
            print(line)
    if done.returncode != 0:
        print(out[-2000:])
        print("FAIL  matchups.gd exited %d" % done.returncode)
        return done.returncode
    if not args:
        if not report:
            print(out[-2000:])
            print("FAIL  no report between the markers")
            return 1
        with io.open(REPORT, "w", encoding="utf-8", newline="\n") as f:
            f.write("\n".join(report) + "\n")
        print("wrote %s (%d lines)" % (os.path.relpath(REPORT, ROOT), len(report)))
    print("in %.0f s" % (time.time() - started))
    return 0


if __name__ == "__main__":
    sys.exit(main())
