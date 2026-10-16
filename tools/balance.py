# -*- coding: utf-8 -*-
"""Sweep the levers that matter over the year, and report survival.

    python tools/balance.py [seeds] [lever name] [--with=lever=value ...] [--days=N]
                                                   sweep the levers, `balanced`
    python tools/balance.py year [seeds]           the year now, every policy
    python tools/balance.py days                   the day's money

**It edits `game_data.gd`, runs the autoplayer, and puts the file back.** There
is no other way to sweep a `const` in GDScript, and making every lever
runtime-settable to suit a test would be changing the game to suit the
instrument. The file is restored in a `finally`, and the sweep refuses to start
if git says it is already dirty, so an interrupted run cannot leave a lever
moved without anyone noticing.

## The year (task 0277)

**It reads only the autoplayer's `RUN` lines** (0276): a run each, its losses,
boss repeats, money and essence a season, and the dates of the nights it lost.
A year is minutes a run, so a configuration plays **`balanced` on `seeds`
seeds** (four unless said), **one process a seed** in parallel - the data does
not change inside a configuration. The baseline is played once and stands for
every lever's current value; each other value is a configuration of its own.

What it reports, per configuration:
- the nights lost before Winter 1 (day 43), a run's average - 0277's target
  is 2-4 - and a season's;
- the boss nights the boss lived through, a season's, counted apart from
  losses (0153), and the runs that hit the cap or ended the year;
- **survival per day**: of the runs that reached a date, the share that never
  lost its night;
- the wall time.

A lever whose values all give the same runs is **dead weight**, and said so.

**`--with=giant hp=500`** (any number of them) moves a lever for every
configuration, the baseline too: a sweep around a candidate point, with the
committed `game_data.gd` still the thing restored. **`--days=42`** stops each
run at that date - the sweep's question is the nights before Winter 1, and a
winter night is the dearest to play.

**`year`** plays the four policies on the game as it stands - the done-when's
table - and adds the days no run of any policy survived and the
dominant-strategy alarm a season.

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
import threading
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
DATA = os.path.join(ROOT, "src", "core", "game_data.gd")
GODOT = os.environ.get(
    "GODOT",
    "C:/Users/PC GAMER DA FAMILIA/Documents/Godot/"
    "Godot_v4.7.2-stable_win64_console.exe")

# **The levers this sweep turns, re-chosen for 1.0** (task 0277). Each is
# (name, a regex matching exactly one line, the values to try besides the
# current one); the first group keeps what is before the number and the
# second what is after it, and **the number is `\d+`, never today's value**,
# so a lever still matches after it has moved. A regex that matches none or
# more than one line is reported and skipped, never guessed at.
#
# What they are for: the season's sizes and the Full Moon's percent are the
# night's weight; the Giant's hit points and armour the first boss; the house
# tier what a player leans on; the defeat's share what one bad night costs
# the next; essence and the night's money what a night pays; the breaker's
# bite what spring's towers lose between nights. **Not the night's length**:
# 0277's sweep found the nights' records written to 240 seconds, and
# `validate()` refuses anything outside 230-240 - it moves with them or not
# at all. Nor the Full Moon under 130, for the same reason (Winter 7).
LEVERS = [
    ("spring size",
     r'(\t\t"size": \[380, )\d+(\],\s+# LEVER)',
     [2000, 3600]),
    ("summer size",
     r'(\t\t"size": \[1800, )\d+(\],\s+# LEVER)',
     [4000, 6000]),
    ("autumn size",
     r'(\t\t"size": \[5200, )\d+(\],\s+# LEVER)',
     [7000]),
    ("full moon",
     r'(const FULL_MOON_HORDE_PERCENT := )\d+(\s+# LEVER)',
     [130]),
    # The Giant's own lines, not its range comments (task 0277): the
    # Harvester's hit points and armour carry the same ranges since then.
    ("giant hp",
     r'(&"giant": \{\n(?:\t\t#[^\n]*\n)*\t\t"hp": )\d+(,)',
     [700]),
    ("giant armour",
     r'(# A heap of its own, the most one cell holds\.\n\t\t"bones": \d+,[^\n]*\n\t\t"armour": )\d+(,)',
     [6]),
    ("breaker bite",
     r'(# house\.\n\t\t"structure_damage_percent": )\d+(,)',
     [200]),
    ("defeat loss",
     r'(const DEFEAT_LOSS_PERCENT := )\d+(\s+# LEVER)',
     [10]),
    ("house tier",
     r'("hp_bonus": )\d+(,\s+# LEVER: hit points, 20-80)',
     [80]),
    ("essence",
     r'(\t"tech_points": )\d+(,\s+# LEVER)',
     [2]),
    ("night money",
     r'(\t"base_money": )\d+(,\s+# LEVER)',
     [30]),
]

## How many seeds a configuration plays unless told: 0277's "on 4 seeds".
SWEEP_SEEDS = 4
## And the year check's: "at least 8 seeds".
YEAR_SEEDS = 8
POLICIES = ["balanced", "economy", "towers", "walls"]
WINTER_1 = 43
YEAR = 56

BALANCE_MD = os.path.join(ROOT, "implementation", "BALANCE.md")
DAYS_BEGIN = "<!-- tools/balance.py days writes from here to its end mark -->"
DAYS_END = "<!-- tools/balance.py days: end -->"
SEASONS = ["spring", "summer", "autumn", "winter"]
STRATEGIES = [("crops", "Crops"), ("fishing", "Fishing"),
              ("mining", "The cliff and the woods"), ("animals", "Animals"),
              ("artisan", "Artisan goods")]
RUN = re.compile(r"^RUN (.*)$")


def read():
    return io.open(DATA, encoding="utf-8").read()


def write(text):
    io.open(DATA, "w", encoding="utf-8", newline="\n").write(text)


def clean_tree():
    out = subprocess.run(["git", "status", "--porcelain", "--", DATA],
                         cwd=ROOT, capture_output=True, text=True)
    return not out.stdout.strip()


def parse_run(line):
    """A `RUN` line as a dict - the season lists and `lost` as lists of ints."""
    hit = RUN.match(line.strip())
    if not hit:
        return None
    out = {}
    for pair in hit.group(1).split():
        key, _, value = pair.partition("=")
        if key in ("losses", "repeats", "money", "essence", "lost", "boss_left",
                   "built", "boss_built", "stock", "food", "ammo", "low"):
            out[key] = [int(v) for v in value.split(",") if re.match(r"^-?\d+$", v)]
        elif re.match(r"^-?\d+$", value):
            out[key] = int(value)
        else:
            out[key] = value
    return out


class Run(object):
    """**One year in its own process**, read as it goes: `ready` is set once
    it prints `PLAYING` - every table loaded, so `game_data.gd` may be
    written again - and `row()` waits for its `RUN` line."""

    def __init__(self, policy, seed, days=0):
        self.policy, self.seed = policy, seed
        self.out = []
        self.ready = threading.Event()
        self.proc = subprocess.Popen(
            [GODOT, "--headless", "--path", ROOT,
             "--script", "res://src/tools/autoplay_run.gd", "++",
             "--year", "--policy=%s" % policy, "--seeds=%d" % seed]
            + (["--nights=%d" % days] if days > 0 else []),
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
            encoding="utf-8", errors="replace")
        self.reader = threading.Thread(target=self._read)
        self.reader.daemon = True
        self.reader.start()

    def _read(self):
        for line in self.proc.stdout:
            self.out.append(line)
            if line.startswith("PLAYING"):
                self.ready.set()
        self.proc.wait()
        self.ready.set()

    def done(self):
        return not self.reader.is_alive()

    def row(self):
        self.reader.join()
        for line in self.out:
            row = parse_run(line)
            if row:
                return row
        if self.invalid():
            return None
        sys.stderr.write("no RUN line from %s seed %d:\n%s\n"
                         % (self.policy, self.seed, "".join(self.out)[-600:]))
        return None

    def invalid(self):
        """The first reason the tables did not validate, or "": a lever moved
        outside what the rest of the data allows, which is a finding, not a
        crash (0277: the Full Moon at 120% leaves night 49 short of the fill
        line)."""
        text = "".join(self.out)
        if "the tables do not validate" not in text:
            return ""
        after = text.split("the tables do not validate:", 1)[1].strip().splitlines()
        return after[0].strip() if after else "?"


def seeds_of(n):
    return [9000 + i * 7 for i in range(n)]


def play(policies, seeds, jobs):
    """Every policy on every seed, `jobs` processes at a time, on the data as
    it is. -> [RUN dicts]."""
    work = [(p, s) for p in policies for s in seeds_of(seeds)]
    running, rows = [], []
    for policy, seed in work:
        while len([r for r in running if not r.done()]) >= jobs:
            time.sleep(0.5)
        running.append(Run(policy, seed))
    for run in running:
        row = run.row()
        if row:
            rows.append(row)
    return rows


def survival(rows):
    """Of the runs that reached each date, the share that never lost it."""
    out = []
    for day in range(1, YEAR + 1):
        reached = [r for r in rows if r.get("days", 0) >= day]
        if not reached:
            out.append(None)
            continue
        kept = sum(1 for r in reached if day not in r.get("lost", []))
        out.append(kept / float(len(reached)))
    return out


def before_winter(row):
    return sum(1 for d in row.get("lost", []) if d < WINTER_1)


def summary(rows):
    n = float(max(len(rows), 1))
    return {
        "before": sum(before_winter(r) for r in rows) / n,
        "lost": [sum(r["losses"][i] for r in rows) / n for i in range(4)],
        "repeats": [sum(r["repeats"][i] for r in rows) / n for i in range(4)],
        "capped": sum(r["capped"] for r in rows),
        "over": sum(r["over"] for r in rows),
        "runs": len(rows),
        "survival": survival(rows),
        "shape": tuple(sorted(tuple(r.get("lost", [])) + (r["days"],) for r in rows)),
    }


def survival_lines(rates, indent="      "):
    out = []
    for i, season in enumerate(SEASONS):
        cells = rates[i * 14:(i + 1) * 14]
        out.append("%s%-7s %s" % (indent, season, " ".join(
            "  -" if c is None else "%3.0f" % (c * 100) for c in cells)))
    return out


def describe(name, value, s, wall):
    return ("  %-13s %-5s  lost before day 43: %4.1f   a season: %s   boss nights "
            "lived through: %s   capped %d/%d  year ended %d/%d  %4.0f s"
            % (name, value, s["before"],
               " ".join("%4.1f" % x for x in s["lost"]),
               " ".join("%3.1f" % x for x in s["repeats"]),
               s["capped"], s["runs"], s["over"], s["runs"], wall))


def lock_or_refuse():
    if not clean_tree():
        print("game_data.gd has uncommitted changes: commit or stash first,")
        print("or an interrupted sweep will leave a lever moved.")
        return None
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
        return None
    return lock


def moved(text, name, value):
    """`text` with the lever called `name` at `value`, or None when its regex
    does not match exactly one line."""
    for lever, pattern, _values in LEVERS:
        if lever == name:
            if len(re.findall(pattern, text)) != 1:
                return None
            return re.sub(pattern, r"\g<1>%d\g<2>" % value, text)
    return None


def sweep(seeds, only, jobs, base_moves=(), days=0):
    """**The configurations overlap** (task 0277): each one's processes are
    started on its own text of `game_data.gd`, and the next is written only
    once all of them have printed `PLAYING` - so `jobs // seeds`
    configurations play at once, each on the data it was given."""
    lock = lock_or_refuse()
    if not lock:
        return 1
    original = read()
    base_text = original
    for name, value in base_moves:
        base_text = moved(base_text, name, value)
        if base_text is None:
            print("  --with lever '%s' does not match exactly one line" % name)
            os.remove(lock)
            return 1
    configs = [("baseline", None, None, base_text)]
    for name, pattern, values in LEVERS:
        if only and name != only:
            continue
        found = len(re.findall(pattern, base_text))
        if found != 1:
            print("  lever '%s' matched %d lines, not one - skipped" % (name, found))
            continue
        hit = re.search(pattern, base_text)
        current = int(hit.group(0)[len(hit.group(1)):len(hit.group(0)) - len(hit.group(2))])
        for value in values:
            if value != current:
                configs.append((name, value, current, moved(base_text, name, value)))
    print("")
    print("  balanced, %d seeds a configuration, %d configurations, %d processes%s%s"
          % (seeds, len(configs), jobs,
             ", with %s" % ", ".join("%s %d" % m for m in base_moves) if base_moves else "",
             ", to day %d" % days if days else ""))
    print("")
    started_all = time.time()
    playing = []
    told = set()

    def as_they_finish():
        # Each configuration's line as soon as its runs are in, so a sweep of
        # hours can be read while it plays.
        for name, value, current, started, runs in playing:
            if (name, value) not in told and all(r.done() for r in runs):
                told.add((name, value))
                rows = [r for r in (run.row() for run in runs) if r]
                wall = max(r["ms"] for r in rows) / 1000.0 if rows else 0.0
                if not rows and runs[0].invalid():
                    print("  done  %-13s %-5s  DOES NOT VALIDATE: %s"
                          % (name, value, runs[0].invalid()))
                else:
                    print("  done" + describe(name, "" if value is None else value,
                                              summary(rows), wall)[1:])
                sys.stdout.flush()

    try:
        for name, value, current, text in configs:
            while len([r for c in playing for r in c[4] if not r.done()]) + seeds > jobs:
                as_they_finish()
                time.sleep(0.5)
            write(text)
            runs = [Run("balanced", s, days) for s in seeds_of(seeds)]
            for run in runs:
                run.ready.wait()
            playing.append((name, value, current, time.time(), runs))
    finally:
        write(original)
        os.remove(lock)
    while len(told) < len(playing):
        as_they_finish()
        time.sleep(0.5)
    print("")
    results = {}
    for name, value, current, started, runs in playing:
        rows = [r for r in (run.row() for run in runs) if r]
        wall = max(r["ms"] for r in rows) / 1000.0 if rows else 0.0
        bad = runs[0].invalid() if not rows else ""
        results[(name, value)] = (summary(rows), wall, current, bad)
    base, base_wall, _, _ = results[("baseline", None)]
    print(describe("baseline", "", base, base_wall))
    for line in survival_lines(base["survival"]):
        print(line)
    for name, pattern, values in LEVERS:
        if only and name != only:
            continue
        shapes = {}
        for value in values:
            if (name, value) not in results:
                continue
            s, wall, current, bad = results[(name, value)]
            if bad:
                print("  %-13s %-5s  DOES NOT VALIDATE: %s" % (name, value, bad))
                continue
            shapes[value] = s["shape"]
            shapes[current] = base["shape"]
            print(describe(name, value, s, wall))
            for line in survival_lines(s["survival"]):
                print(line)
        if shapes and len(set(shapes.values())) == 1:
            print("  DEAD WEIGHT: '%s' changed nothing across %s" % (name, sorted(shapes)))
    print("")
    print("  the sweep took %.0f s" % (time.time() - started_all))
    return 0


def survival_report(rows):
    """Under the year's table: each policy's nights lost before Winter 1 and
    its survival per day, and the days no run of any policy held."""
    print("")
    print("  survival per day, %: of the runs that reached the date, the share that held it")
    every = []
    for p in POLICIES:
        mine = [r for r in rows if r["policy"] == p]
        if not mine:
            continue
        rates = survival(mine)
        every.append(rates)
        print("    %-9s lost before day 43: %.1f a run" % (p, summary(mine)["before"]))
        for line in survival_lines(rates):
            print(line)
    dead = [d + 1 for d in range(YEAR)
            if every and all(col[d] is not None and col[d] == 0 for col in every)]
    print("")
    print("  days no run of any policy held: %s" % (dead if dead else "none"))


def year(seeds, jobs):
    """The year as it stands, every policy: `tools/autoplay.py --year`, which
    prints the table, the alarms and `survival_report`."""
    import autoplay
    return autoplay.year(seeds, jobs)


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
    lock = lock_or_refuse()
    if not lock:
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
    if not os.path.exists(GODOT):
        print("no godot at %s - set GODOT" % GODOT)
        return 1
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    jobs = max(min((os.cpu_count() or 4) - 4, 8), 1)
    for arg in sys.argv[1:]:
        if arg.startswith("--jobs="):
            jobs = max(int(arg.split("=", 1)[1]), 1)
    if args and args[0] == "days":
        return days()
    if args and args[0] == "year":
        seeds = int(args[1]) if len(args) > 1 else YEAR_SEEDS
        return year(seeds, jobs)
    base_moves = []
    days_to = 0
    for arg in sys.argv[1:]:
        if arg.startswith("--with="):
            name, _, value = arg.split("=", 1)[1].rpartition("=")
            base_moves.append((name, int(value)))
        if arg.startswith("--days="):
            days_to = int(arg.split("=", 1)[1])
    seeds = int(args[0]) if args else SWEEP_SEEDS
    only = args[1] if len(args) > 1 else ""
    return sweep(seeds, only, jobs, base_moves, days_to)


if __name__ == "__main__":
    sys.exit(main())
