# -*- coding: utf-8 -*-
"""Play the nights many times over and report.

    python tools/autoplay.py
    python tools/autoplay.py 4 --nights=1  # one full day and night per policy
    python tools/autoplay.py --year [seeds] [--jobs=N]
    python tools/autoplay.py --economy [seeds] [--jobs=N]

A reader, not a check: `verify.py` is what fails. This is for looking at the
curve while tuning it, which task 0060 does a great deal of.

## A year (task 0276)

`--year` plays every date of the year, `seeds` seeds of each of the four
policies (eight unless said). A year is long - minutes a run - so the runs
are **split across processes**, one a policy and a seed, `--jobs` of them at
a time (the machine's cores less a few unless said): the data does not
change inside a run set, so a run is the same in any process. Each prints
its `RUN` line (`src/tools/autoplay_run.gd`); this reads them back and
prints the per-policy table - nights lost and boss nights played again, a
season each - the dominant-strategy alarm a season, and how long it took.
Since task 0277 it also prints each policy's survival per day (the share of
the runs that reached a date that held it) and the days no run of any policy
held, from `tools/balance.py`, whose `RUN` parser it uses.

## The economy across a year (task 0278)

`--economy` plays the same year and adds, from the same `RUN` lines:
- **what each boss cost**: the worth of the line it fell to, less the line
  that faced the season's first night, over that season's best focused day
  (`src/tools/year_economy.gd` prints those days, and the rest of 0278's
  tables, from the rules alone);
- **what winter lived off**, run by run: the stock, food and ammunition each
  run entered Winter 1 (day 43) with, the least food and ammunition it held
  on a winter morning, its winter losses and whether the Lord fell.
"""
import concurrent.futures
import os
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
GODOT = os.environ.get(
    "GODOT",
    "C:/Users/PC GAMER DA FAMILIA/Documents/Godot/"
    "Godot_v4.7.2-stable_win64_console.exe")

SCRIPT = "res://src/tools/autoplay_run.gd"
POLICIES = ["balanced", "economy", "towers", "walls"]
SEASONS = ["spring", "summer", "autumn", "winter"]
YEAR_SEEDS = 8


def godot(args, timeout=None):
    done = subprocess.run(
        [GODOT, "--headless", "--path", ROOT, "--script", SCRIPT, "++"] + args,
        capture_output=True, text=True, timeout=timeout)
    return done.returncode, done.stdout or ""


def parse_run(line):
    """A `RUN` line as a dict. The parser is `tools/balance.py`'s since task
    0277, which reads nothing else."""
    import balance
    return balance.parse_run(line)


def one_year(policy, seed):
    """One run in its own process: its `RUN` line, parsed, or None."""
    code, out = godot(["--year", "--policy=%s" % policy, "--seeds=%d" % seed])
    for line in out.splitlines():
        row = parse_run(line)
        if row:
            return row
    sys.stderr.write("no RUN line from %s seed %d (exit %d):\n%s\n"
                     % (policy, seed, code, out[-800:]))
    return None


def year(seeds, jobs, economy=False):
    import balance
    # A sweep has a lever moved while it holds the lock (`tools/balance.py`).
    if os.path.exists(os.path.join(ROOT, ".balance-lock")):
        print("a sweep holds .balance-lock and has a lever moved - wait for it")
        return 1
    first = [9000 + i * 7 for i in range(seeds)]
    work = [(p, s) for p in POLICIES for s in first]
    print("")
    print("HARVEST THE NIGHT - a year, %d seeds of each policy, %d processes"
          % (seeds, jobs))
    print("")
    started = time.time()
    rows = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as pool:
        for row in pool.map(lambda w: one_year(*w), work):
            if row:
                rows.append(row)
                print("  " + " ".join("%s=%s" % (k, ",".join(map(str, v))
                                                  if isinstance(v, list) else v)
                                      for k, v in row.items()))
    wall = time.time() - started
    table(rows, seeds)
    alarms(rows, seeds)
    balance.survival_report(rows)
    if economy:
        economy_report(rows)
    runs_ms = [r["ms"] for r in rows]
    print("")
    print("  %d runs in %.0f s wall, %d processes; a run took %.0f-%.0f s (%.0f s on average)"
          % (len(rows), wall, jobs, min(runs_ms) / 1000.0, max(runs_ms) / 1000.0,
             sum(runs_ms) / 1000.0 / max(len(runs_ms), 1)))
    return 0 if len(rows) == len(work) else 1


def focused_days():
    """Each season's best focused day, off `year_economy.gd`'s first table."""
    done = subprocess.run(
        [GODOT, "--headless", "--path", ROOT, "--script", "res://src/tools/year_economy.gd"],
        capture_output=True, text=True)
    days = {}
    for line in (done.stdout or "").splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) > 6 and cells[0] in SEASONS and cells[6].startswith("$"):
            days[cells[0]] = int(cells[6].lstrip("$"))
    return days


def economy_report(rows):
    """**The economy across a year** (task 0278), off the `RUN` lines: what
    each boss cost in focused days, and what each run lived off in winter."""
    days = focused_days()
    print("")
    print("  THE ECONOMY ACROSS A YEAR - what each boss cost, in the season's best focused day (%s)"
          % ", ".join("%s $%d" % (s, days.get(s, 0)) for s in SEASONS))
    print("  policy     season   line at its start   line its boss fell to   built for it   focused days   runs")
    for p in POLICIES:
        mine = [r for r in rows if r["policy"] == p and len(r.get("built", [])) == 4]
        for i, season in enumerate(SEASONS):
            fell = [r for r in mine if r["built"][i] >= 0 and r["boss_built"][i] >= 0]
            if not fell:
                continue
            start = sum(r["built"][i] for r in fell) / float(len(fell))
            end = sum(r["boss_built"][i] for r in fell) / float(len(fell))
            cost = end - start
            print("  %-10s %-7s  %17.0f   %21.0f   %12.0f   %12.1f   %d"
                  % (p, season, start, end, cost, cost / max(days.get(season, 1), 1), len(fell)))
    print("")
    print("  WINTER - what each run entered Winter 1 with, and the least it held on a winter morning")
    print("  policy     seed    stock    food   ammo   least food   least ammo   winter lost   Lord down")
    for p in POLICIES:
        for r in sorted([r for r in rows if r["policy"] == p and len(r.get("stock", [])) == 4],
                        key=lambda r: r["seed"]):
            if r["stock"][3] < 0:
                continue
            low = r.get("low", [-1, -1])
            print("  %-10s %5d %8d %7d %6d %12d %12d %13d   %s"
                  % (p, r["seed"], r["stock"][3], r["food"][3], r["ammo"][3], low[0], low[1],
                     r["losses"][3], "yes" if r["over"] else "no"))


def table(rows, seeds):
    print("")
    print("  policy     lost: spring summer autumn winter   repeats: sp su au wi"
          "   over  capped   money at winter  essence  walked/run")
    for p in POLICIES:
        mine = [r for r in rows if r["policy"] == p]
        if not mine:
            continue
        n = float(len(mine))
        lost = [sum(r["losses"][i] for r in mine) / n for i in range(4)]
        rep = [sum(r["repeats"][i] for r in mine) / n for i in range(4)]
        over = sum(r["over"] for r in mine)
        capped = sum(r["capped"] for r in mine)
        money = [r["money"][3] for r in mine if r["money"][3] >= 0]
        essence = [r["essence"][3] for r in mine if r["essence"][3] >= 0]
        print("  %-10s       %5.1f %6.1f %6.1f %6.1f        %4.1f %4.1f %4.1f %4.1f"
              "   %d/%d    %d/%d  %10s  %7s  %10.0f"
              % (p, lost[0], lost[1], lost[2], lost[3],
                 rep[0], rep[1], rep[2], rep[3], over, len(mine), capped, len(mine),
                 "%.0f" % (sum(money) / len(money)) if money else "-",
                 "%.0f" % (sum(essence) / len(essence)) if essence else "-",
                 sum(r["walked"] for r in mine) / n))
    print("")
    print("  (lost: nights lost a season, a run's average; repeats: boss nights"
          " the boss lived through, each fought again unless it hit the cap; over: runs that ended the year with the Winter Lord down)")


def alarms(rows, seeds):
    """**The dominant-strategy alarm, a season** - the runs of each policy
    that got through the season without losing a night, and the same rule as
    the ten nights': one policy that does where the others do not, or does
    twice as often as the next, is a season with one answer."""
    print("")
    for i, season in enumerate(SEASONS):
        clean = {}
        for p in POLICIES:
            mine = [r for r in rows if r["policy"] == p]
            clean[p] = sum(1 for r in mine if r["losses"][i] == 0
                           and r["money"][i] >= 0)
        ranked = sorted(POLICIES, key=lambda p: -clean[p])
        best, second = ranked[0], ranked[1]
        reached = sum(1 for r in rows if r["money"][i] >= 0)
        if reached == 0:
            print("  %-7s not reached: every run stopped before it" % season)
        elif clean[best] <= 0:
            print("  %-7s ALARM: no policy got through it without a loss" % season)
        elif clean[second] <= 0:
            print("  %-7s ALARM: '%s' is the only policy that gets through it "
                  "clean (%d of %d)" % (season, best, clean[best], seeds))
        elif clean[best] >= clean[second] * 2 and clean[best] >= seeds / 2.0:
            print("  %-7s ALARM: '%s' gets through it clean %d times where the "
                  "next gets %d - a dominant strategy"
                  % (season, best, clean[best], clean[second]))
        else:
            print("  %-7s no dominant strategy: clean runs %s"
                  % (season, ", ".join("%s %d" % (p, clean[p]) for p in ranked)))


def main():
    if not os.path.exists(GODOT):
        print("no godot at %s - set GODOT" % GODOT)
        return 1
    args = sys.argv[1:]
    if "--year" in args or "--economy" in args:
        seeds = YEAR_SEEDS
        jobs = max(min((os.cpu_count() or 4) - 4, 8), 1)
        for arg in args:
            if arg.isdigit():
                seeds = max(int(arg), 1)
            if arg.startswith("--jobs="):
                jobs = max(int(arg.split("=", 1)[1]), 1)
        return year(seeds, jobs, economy="--economy" in args)
    code, out = godot(args)
    for line in out.splitlines():
        # The engine's own banner is not part of the answer.
        if line.startswith("Godot Engine") or line.startswith("Settings:"):
            continue
        print(line)
    return code


if __name__ == "__main__":
    sys.exit(main())
