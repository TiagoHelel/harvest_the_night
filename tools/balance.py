# -*- coding: utf-8 -*-
"""Sweep the levers that matter and report the win rate per night.

    python tools/balance.py [runs-per-configuration] [lever name]
    python tools/balance.py days

**It edits `game_data.gd`, runs the autoplayer, and puts the file back.** There
is no other way to sweep a `const` in GDScript, and making every lever
runtime-settable to suit a test would be changing the game to suit the
instrument. The file is restored in a `finally`, and the sweep refuses to start
if git says it is already dirty, so an interrupted run cannot leave a lever
moved without anyone noticing.

What it reports, per configuration: how far each policy got, and from that the
**win rate per night** - the share of runs still alive at the end of night N.
Task 0068's done-when is that no night sits at 100% or 0% across every policy,
which is the difference between a difficulty curve and a wall.

The written report is `implementation/BALANCE.md`.

**`days`** (task 0194) is the day's money instead of the night's survival.
It plays a well-worked day of each way of earning - the crops, the pond, the
cliff and the woods, the animals and the machines - in a spring and a summer
(`src/tools/day_economy.gd`), beside the day `Economy` computes for every
season and the season's band in `GameData.DAY_TARGETS`. It rewrites its own
block of BALANCE.md, between `DAYS_BEGIN` and `DAYS_END`, and nothing else.
It moves no lever, and it keeps the same guard as the sweep: it refuses a
dirty `game_data.gd` and puts the file back in a `finally`.
"""
import io
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DATA = os.path.join(ROOT, "src", "core", "game_data.gd")
GODOT = os.environ.get(
    "GODOT",
    "C:/Users/PC GAMER DA FAMILIA/Documents/Godot/"
    "Godot_v4.7.2-stable_win64_console.exe")

# The levers this sweep turns. Each is (name, a regex matching exactly one
# line, the values to try). The first three were chosen from what the
# autoplayer measured rather than from taste: the back half of the run fails
# on throughput, so the guns' damage and the house's hit points are the two
# dials pointed straight at it, and the purse decides whether a player can
# answer a bad night with another tower.
#
# `wave gap` is in the list for the opposite reason. Task 0059 moved the gap
# between waves onto each night's own record, and nothing has read the global
# since. It is here to have that said in measurements rather than only in a
# grep - a lever that cannot move the game is the clearest kind of dead
# weight, and this sweep exists partly to name it.
LEVERS = [
    ("gun damage",
     r'(\t\t"damage": )6(,\s+# LEVER: per shot)',
     [4, 6, 9]),
    ("house hp",
     r'(const HOUSE_HP := )100(\s+# LEVER)',
     [80, 100, 140]),
    ("money a night",
     r'(\t"money_per_night": )15(,\s+# LEVER)',
     [10, 15, 25]),
    # Added once the first pass named power as the binding constraint: the
    # farm makes four energy a tick, a gun tower draws one and a crossbow
    # three, and every defence after those two puts the **whole farm** below
    # full speed - including the towers already standing. The fifth tower
    # makes the first four worse, which is a trap rather than a decision.
    ("base energy",
     r'(const BASE_ENERGY := )4(\s+# LEVER)',
     [4, 6, 8]),
    ("brownout floor",
     r'(const UNPOWERED_PERCENT := )\d+(\s+# LEVER)',
     [25, 50]),
    # Night one is the other outlier, and it is arithmetic rather than taste:
    # a walker crosses the gun tower's five tiles in 5 * 20 = 100 ticks, the
    # tower deals 6 a second, and 100 ticks is 3.3 seconds of 6 - which is
    # 20, exactly one walker's hit points. So one tower kills one walker per
    # wave however many are in it, nine of twelve reach the house, and the
    # "tutorial night" ends with the house on ten of a hundred. Slowing the
    # walker lengthens the only window the tower has.
    ("walker speed",
     r'(		"ticks_per_tile": )20(,\s+# LEVER: ticks, 12-30)',
     [20, 26, 30]),
    ("wave gap",
     r'(const WAVE_GAP_TICKS := )15( \* SECONDS\s+# LEVER)',
     [8, 30]),
]

NIGHTS = 10

BALANCE_MD = os.path.join(ROOT, "implementation", "BALANCE.md")
DAYS_BEGIN = "<!-- tools/balance.py days writes from here to its end mark -->"
DAYS_END = "<!-- tools/balance.py days: end -->"
SEASONS = ["spring", "summer", "autumn", "winter"]
STRATEGIES = [("crops", "Crops"), ("fishing", "Fishing"),
              ("mining", "The cliff and the woods"), ("animals", "Animals"),
              ("artisan", "Artisan goods")]


def read():
    return io.open(DATA, encoding="utf-8").read()


def write(text):
    io.open(DATA, "w", encoding="utf-8", newline="\n").write(text)


def clean_tree():
    out = subprocess.run(["git", "status", "--porcelain", "--", DATA],
                         cwd=ROOT, capture_output=True, text=True)
    return not out.stdout.strip()


def play(runs):
    """Run the autoplayer once. -> {policy: (won, [nights reached, ...])}."""
    done = subprocess.run(
        [GODOT, "--headless", "--path", ROOT,
         "--script", "res://src/tools/autoplay_run.gd", "++", str(runs)],
        capture_output=True, text=True)
    won = {}
    reached = {}
    name = None
    for line in (done.stdout or "").splitlines():
        # The summary table: "  towers       0  night 9 (3x)   9.0  ..."
        row = re.match(r"\s{2}(\w+)\s+(\d+)\s+(?:night \d|nothing)", line)
        if row:
            won[row.group(1)] = int(row.group(2))
            continue
        # The per-policy block: a name line, then its nights.
        got = re.match(r"\s{2}(\w+)\s{2,}\w[\w ,']*$", line)
        hit = re.search(r"nights: \[([0-9, ]+)\]", line)
        if hit and name:
            reached[name] = [int(n) for n in hit.group(1).split(",")]
            name = None
        elif got:
            name = got.group(1)
    return dict((k, (won.get(k, 0), v)) for k, v in reached.items())


def win_rates(result):
    """Share of all runs still alive at the end of each night, 1..10.

    A run that reached night N and stopped there died on N, so it is alive at
    the end of nights 1..N-1. The exception is the tenth: a run that reached
    ten may have beaten it, and the autoplayer's own `won` column is the only
    thing that knows which.
    """
    reached = [n for _won, runs in result.values() for n in runs]
    if not reached:
        return []
    total = float(len(reached))
    out = [sum(1 for n in reached if n > night) / total
           for night in range(1, NIGHTS)]
    out.append(sum(w for w, _runs in result.values()) / total)
    return out


def play_days():
    """Play the days once. -> {(season, strategy): (computed, played, low, high)},
    -1 where a strategy has no means that season or was not played."""
    done = subprocess.run(
        [GODOT, "--headless", "--path", ROOT,
         "--script", "res://src/tools/day_economy.gd"],
        capture_output=True, text=True)
    rows = {}
    for line in (done.stdout or "").splitlines():
        row = re.match(r"DAY (\w+) (\w+) computed (-?\d+) simulated (-?\d+) "
                       r"target (\d+)-(\d+)$", line.strip())
        if row:
            rows[(row.group(1), row.group(2))] = tuple(
                int(row.group(i)) for i in range(3, 7))
    return rows


def days_block(rows):
    """The BALANCE.md block: money a well-worked day, by season and strategy,
    computed and - in spring and summer - played, against the season's band."""
    out = [DAYS_BEGIN, "",
           "| Season | Band | %s | Most |" % " | ".join(n for _k, n in STRATEGIES),
           "|---|---|%s---|" % ("---|" * len(STRATEGIES))]
    for season in SEASONS:
        cells = []
        best = None
        band = None
        for key, _name in STRATEGIES:
            computed, played, low, high = rows.get((season, key), (-1, -1, 0, 0))
            band = (low, high)
            if computed < 0:
                cells.append("-")
                continue
            if best is None or computed > best[1]:
                best = (key, computed)
            cell = "$%d" % computed
            if played >= 0:
                cell += " (played $%d)" % played
            if not low <= computed <= high or (played >= 0 and not low <= played <= high):
                cell += " **outside**"
            cells.append(cell)
        out.append("| %s | $%d-%d | %s | %s |" % (
            season, band[0], band[1], " | ".join(cells),
            dict(STRATEGIES)[best[0]].lower() if best else "-"))
    out += ["", "Computed: `Economy.day`. Played: `src/tools/day_economy.gd`, the "
            "crops over their season, the machines until their batches come "
            "round together, the pond over three days and the animals over "
            "four, by the day. A dash: the season has no means for it.", "",
            DAYS_END]
    return "\n".join(out)


def write_days(block):
    text = io.open(BALANCE_MD, encoding="utf-8").read()
    if DAYS_BEGIN in text and DAYS_END in text:
        start = text.index(DAYS_BEGIN)
        end = text.index(DAYS_END) + len(DAYS_END)
        text = text[:start] + block + text[end:]
    else:
        text = text.rstrip("\n") + "\n\n" + block + "\n"
    io.open(BALANCE_MD, "w", encoding="utf-8", newline="\n").write(text)


def days():
    if not os.path.exists(GODOT):
        print("no godot at %s - set GODOT" % GODOT)
        return 1
    if not clean_tree():
        print("game_data.gd has uncommitted changes: commit or stash first,")
        print("or an interrupted sweep will leave a lever moved.")
        return 1
    lock = os.path.join(ROOT, ".balance-lock")
    try:
        os.close(os.open(lock, os.O_CREAT | os.O_EXCL | os.O_WRONLY))
    except OSError:
        print("another sweep holds %s - wait for it, or delete the file if"
              % lock)
        print("you are sure nothing is running.")
        return 1
    original = read()
    try:
        rows = play_days()
    finally:
        write(original)
        os.remove(lock)
    if not rows:
        print("the day sweep printed nothing - run it by hand to see why:")
        print("  godot --headless --path . --script res://src/tools/day_economy.gd")
        return 1
    block = days_block(rows)
    write_days(block)
    print(block)
    return 0


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "days":
        return days()
    runs = int(sys.argv[1]) if len(sys.argv) > 1 else 8
    only = sys.argv[2] if len(sys.argv) > 2 else ""
    if not os.path.exists(GODOT):
        print("no godot at %s - set GODOT" % GODOT)
        return 1
    if not clean_tree():
        print("game_data.gd has uncommitted changes: commit or stash first,")
        print("or an interrupted sweep will leave a lever moved.")
        return 1

    # **One sweep at a time.** Two of these running together both rewrite
    # `game_data.gd` and neither notices, so the second one measures whatever
    # the first happened to have written that second. It happened, the numbers
    # looked plausible, and the only reason it was caught was a process list.
    lock = os.path.join(ROOT, ".balance-lock")
    try:
        os.close(os.open(lock, os.O_CREAT | os.O_EXCL | os.O_WRONLY))
    except OSError:
        print("another sweep holds %s - wait for it, or delete the file if"
              % lock)
        print("you are sure nothing is running.")
        return 1

    original = read()
    rows = []
    try:
        for name, pattern, values in LEVERS:
            if only and name != only:
                continue
            if not re.search(pattern, original):
                print("  lever '%s' did not match its line - skipped" % name)
                continue
            for value in values:
                write(re.sub(pattern, r"\g<1>%d\g<2>" % value, original))
                result = play(runs)
                rows.append((name, value, result, win_rates(result)))
                far = ", ".join("%s %d" % (k, max(v))
                                for k, (_w, v) in sorted(result.items()))
                print("  %-14s = %-4s  furthest night: %s" % (name, value, far))
    finally:
        write(original)
        os.remove(lock)

    print("")
    print("  lever          value   win rate %% per night, 1..%d" % NIGHTS)
    shapes = {}
    for name, value, _result, rates in rows:
        print("  %-14s %-6s %s"
              % (name, value, " ".join("%3.0f" % (r * 100) for r in rates)))
        shapes.setdefault(name, []).append(tuple(rates))

    print("")
    dead = [n for n, seen in shapes.items() if len(set(seen)) == 1]
    for name in sorted(dead):
        print("  DEAD WEIGHT: '%s' changed nothing across its whole range"
              % name)
    if not dead:
        print("  every lever moved the curve")
    return 0


if __name__ == "__main__":
    sys.exit(main())
