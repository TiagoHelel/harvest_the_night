# 0275 - The worst night of the year, within budget

- **Phase:** 15 - Fifty-six nights and balance
- **Status:** todo
- **Depends on:** 0274, 0234, 0248, 0233
- **Likely files:** src/tools/perf_check.gd, src/tools/perf_names.gd, tools/perf.py, tools/perf_baseline.txt, src/tools/headless_v1.gd

## Goal

The benchmark's worst case is still Spring 14, where 0153 moved the MVP's night ten. Move it to the heaviest night 1.0 can produce - Winter 14 with the Winter Lord, a rat swarm and every defence on the farm - and settle the cost profile before 0277 simulates thousands of nights on it.

## Requirements

- `_the_worst_case()` in `src/tools/perf_check.gd` sets the run to Winter 14 (day 56) the way the calendar reads it (0151), not through `nights_won`, and still stops at the busiest moment
- At least one of every `GameData.DEFENCES` entry - the plan's fourteen and whatever 0231 added - at the top `TOWER_LEVELS` level, powered and with ammunition, placed where the fight is through the build-step road of 0119; 0218's swarm scenario is folded in or kept as its own rows - say which
- Every lazily built path field in 0218's registry is built tonight, adding the kinds that force one if day 56 lacks them, so `path_refresh` is timed with all of them; the heaviest event day 56 can roll is on - fog or rain, since 0257 keeps the Blood Moon off boss nights - by picking a seed `Weather` gives it, never an override in core
- `COUNT` lines for each defence family, each enemy kind, the boss and the fields built, so a reader can see the case is the case
- `PerfNames.NIGHT`/`DAY` already have to match `Sim.tick` (`_task_0102_budget`); every one of those names gets its branch in `perf_check._tick_one` (today an unmapped name only `push_error`s and still prints a row), and `_a_busy_day` becomes the 1.0 day: tilled grass, season crops, sprinklers, animals, every machine queued
- The budgets do not move: `TICK_BUDGET_US` 8333 and `PATH_BUDGET_US` 33333 in `tools/perf.py`. If the winter case breaks one, optimise here, hash-neutral, or block with the measured numbers - never raise a budget
- Print the wall time of one winter night simulated end to end as a `COUNT` (not budgeted), because 0277 multiplies it by thousands
- `python tools/perf.py --accept` moves the baseline; every row's old and new number goes in the journal, with why it grew. A benchmark and hash-neutral optimisations only: neither hash moves

## Done when

- [ ] `python tools/perf.py` passes on the new baseline, with `night_tick` and `path_refresh` under their budgets on the winter case - both numbers, and the old ones, in the journal
- [ ] The `COUNT` lines show one of every `DEFENCES` entry, the Winter Lord, a rat swarm and every named path field built
- [ ] `_task_0275_perf_year` in `src/tools/headless_v1.gd` reads `perf_check.gd` and asserts every name in `PerfNames.NIGHT` and `DAY` has a branch in `_tick_one`, the way `_task_0102_budget` reads `sim.gd`
- [ ] `python tools/verify.py` prints PASS
- [ ] the determinism hash is unchanged, or the change is deliberate and both
      the old and the new number are in the journal

## House rules

`src/core/` holds the game rules: node-free, deterministic, advanced only by
`Sim.tick()` at a fixed rate. No nodes, no unseeded randomness, no clock reads,
no iterating an unordered Dictionary without sorting the keys first. `src/ui/`
draws and reads input and owns no rules.

Every number a designer might want to turn lives in `src/core/game_data.gd`
with `# LEVER` on it. A new rule ships with an assert and a new input path with
a case, in the same pass - from task 0112 on in `src/tools/headless_v1.gd` and
`src/tools/input_v1.gd` once 0112 has made them (the older suites are full).

Code, identifiers, comments and player-facing strings are in English; every
new string is a row in `assets/locale/strings.csv` with its pt_BR text. Art
comes only from the Codex packs in `implementation/backlog/` through the raster
pipeline (`assets/art_source/`, `tools/import_art.py`): never hand-paint or
generate PNGs in a game task.

`docs/PLANO-DO-JOGO.md` is the source of truth for intent in 1.0 (its section
12 says what it changes in `design.md`); `docs/reference-sheet.png` and the
approved 32px farmer are the look. If this task contradicts either, follow the
task and say so in the journal.
