# -*- coding: utf-8 -*-
"""A number instead of a feeling about whether it runs well.

    python tools/perf.py             measure, compare, fail on a regression
    python tools/perf.py --accept    move the baseline, printing both numbers
    python tools/perf.py --report    the table, and nothing compared

Runs `src/tools/perf_check.gd` on the worst case the game has - night ten,
forty towers, every plot sown, the field as full of zombies as it gets - and
compares what comes back against `tools/perf_baseline.txt`.

## A budget and a baseline are two different questions

The **budget** is the hard ceiling: a tick must take less than a tick, with
room for everything else on the machine. It is a property of the design and
it does not move.

The **baseline** is what this game costs today. It moves, deliberately, the
way the determinism hash does - `--accept` prints the old and the new number
so the journal can record both. A change that makes the night twice as
expensive is still inside the budget and still something somebody should have
decided rather than discovered.

## The report names the most expensive system

Every system is timed on its own, so a regression points at itself: the table
is sorted and the worst one is called out by name. Without that, "the tick
got slower" is a sentence somebody has to go and investigate.

## What this cannot measure

Drawing. A headless run has the dummy renderer and nothing is rasterised, so
the lamps and the sparks are timed on the **thinking** they do per frame and
not on the pixels they put down. The pixels are the debug overlay's number,
on a machine with a screen.
"""
import io
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GODOT = os.environ.get("GODOT", os.path.join(
    os.path.expanduser("~"), "Documents", "Godot",
    "Godot_v4.7.2-stable_win64_console.exe"))

BASELINE = os.path.join(ROOT, "tools", "perf_baseline.txt")
SCRIPT = "res://src/tools/perf_check.gd"

## The hard ceiling, in microseconds, for the two whole-tick numbers.
##
## A tick is 33,333us at 30Hz and the game may have **a quarter of it**. The
## other three quarters are the drawing, the operating system, the browser
## and whatever else the player has open - and a game that needs all of its
## own tick is a game with nothing left for the machine it runs on.
TICK_BUDGET_US = 8333

## And for a path rebuild, which is not per tick but happens on every wall a
## player puts down. A whole tick's worth: it is allowed to be the most
## expensive thing in the game as long as it is not every frame.
PATH_BUDGET_US = 33333

## How much a measurement may grow before it counts as a regression.
##
## **Forty per cent, because this is a wall clock on a desktop.** Measured
## rather than guessed: the same build run three times in a row moved
## `night_enemies` 212 -> 214 -> 246, which is sixteen per cent of noise on
## an idle machine and more on a busy one. A threshold tighter than the
## noise is a check people learn to re-run until it passes, which is worse
## than no check; forty is about two and a half times the noise, and a real
## regression is bigger than that - a four-thousand-iteration loop added to
## `Towers.tick` moved it seventeen per cent and was correctly ignored,
## forty thousand moved it a hundred and eighty-two and was not.
TOLERANCE = 0.40

## Below this, a percentage is meaningless - a 2us system growing to 4us is
## not a regression, it is the clock.
FLOOR_US = 30


def run():
    """{name: microseconds}, {name: count} from a fresh measurement."""
    done = subprocess.run(
        [GODOT, "--headless", "--path", ROOT, "--script", SCRIPT],
        capture_output=True, text=True, timeout=600)
    out = (done.stdout or "") + (done.stderr or "")
    timings = {}
    counts = {}
    for line in out.splitlines():
        hit = re.match(r"^PERF (\S+)\s+(\d+)$", line.strip())
        if hit:
            timings[hit.group(1)] = int(hit.group(2))
            continue
        hit = re.match(r"^COUNT (\S+)\s+(\d+)$", line.strip())
        if hit:
            counts[hit.group(1)] = int(hit.group(2))
    if not timings:
        print(out[-1500:])
    return timings, counts


def read_baseline():
    if not os.path.exists(BASELINE):
        return {}
    out = {}
    with io.open(BASELINE, encoding="utf-8") as f:
        for line in f:
            bits = line.split()
            if len(bits) == 2 and bits[1].isdigit():
                out[bits[0]] = int(bits[1])
    return out


def write_baseline(timings):
    with io.open(BASELINE, "w", encoding="utf-8", newline="\n") as f:
        f.write("# What this game costs today, in microseconds.\n")
        f.write("# Moved with: python tools/perf.py --accept\n")
        for name in sorted(timings):
            f.write("%s %d\n" % (name, timings[name]))


def worst(timings, prefix):
    """The most expensive system under a prefix, as (name, us)."""
    rows = [(v, k) for k, v in timings.items()
            if k.startswith(prefix) and not k.endswith("_tick")]
    if not rows:
        return ("", 0)
    rows.sort(reverse=True)
    return (rows[0][1], rows[0][0])


def table(timings, counts, old):
    print("  %-22s %9s %9s" % ("", "now", "baseline"))
    for name in sorted(timings):
        was = old.get(name)
        mark = ""
        if was is not None and was >= FLOOR_US:
            grew = (timings[name] - was) / float(was)
            if grew > TOLERANCE:
                mark = "  GREW %+.0f%%" % (grew * 100.0)
        print("  %-22s %9d %9s%s"
              % (name, timings[name],
                 "-" if was is None else str(was), mark))
    print("")
    print("  the farm: %s" % ", ".join(
        "%d %s" % (counts[k], k) for k in sorted(counts)))


def main():
    args = sys.argv[1:]
    print("")
    print("HARVEST THE NIGHT - performance")
    print("")

    timings, counts = run()
    if not timings:
        print("FAIL  the benchmark printed no measurements")
        return 1
    old = read_baseline()

    if "--report" in args:
        table(timings, counts, old)
        return 0

    if "--accept" in args:
        moved = []
        for name in sorted(timings):
            if old.get(name) != timings[name]:
                moved.append("%s %s -> %d"
                             % (name, old.get(name, "-"), timings[name]))
        write_baseline(timings)
        table(timings, counts, old)
        print("")
        for line in moved:
            print("  baseline moved: %s" % line)
        print("  write the ones that matter in implementation/PROGRESS.md.")
        return 0

    table(timings, counts, old)

    # **The swarm's tick is held to the same budget** (task 0218): a few
    # hundred bodies more is what the night is about to be asked for. And
    # the rebuild with four decoys standing to the path's (task 0224).
    bad = []
    for name, budget in [("night_tick", TICK_BUDGET_US),
                         ("day_tick", TICK_BUDGET_US),
                         ("swarm_tick", TICK_BUDGET_US),
                         ("path_refresh", PATH_BUDGET_US),
                         ("lure_refresh", PATH_BUDGET_US)]:
        if timings.get(name, 0) > budget:
            bad.append("%s is %dus and the budget is %d"
                       % (name, timings[name], budget))

    # **Sorted by how much it grew, and a whole tick last.** `night_tick`
    # goes up whenever a system under it does, so naming it first names the
    # symptom - the point of timing the systems separately is that the
    # failure says which one.
    grew = []
    for name in sorted(timings):
        was = old.get(name)
        if was is None or was < FLOOR_US:
            continue
        if timings[name] > was * (1.0 + TOLERANCE):
            grew.append((name.endswith("_tick"),
                         -(timings[name] - was) / float(was), name, was))
    grew.sort()
    grown = ["%s went from %dus to %d" % (n, w, timings[n])
             for _t, _by, n, w in grew]

    print("")
    for prefix, when in [("night_", "a night"), ("day_", "a day")]:
        name, cost = worst(timings, prefix)
        print("  the most expensive thing in %s is %s, at %dus"
              % (when, name, cost))

    if bad or grown:
        print("")
        for line in bad + grown:
            print("  " + line)
        if grown and not bad:
            print("  if that is on purpose: python tools/perf.py --accept")
        # **The last line names the culprit**, because that is the line
        # `verify.py` repeats and the one somebody reads first.
        blame = (bad + grown)[0]
        more = len(bad) + len(grown) - 1
        print("FAIL  %s%s" % (blame, "" if more < 1 else
                             " (and %d more)" % more))
        return 1

    print("")
    print("OK    a night tick is %dus of the %d it may have (%.0f%%), "
          "a swarm's %dus, a path rebuild %dus of %d (%dus with decoys)"
          % (timings.get("night_tick", 0), TICK_BUDGET_US,
             timings.get("night_tick", 0) * 100.0 / TICK_BUDGET_US,
             timings.get("swarm_tick", 0),
             timings.get("path_refresh", 0), PATH_BUDGET_US,
             timings.get("lure_refresh", 0)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
