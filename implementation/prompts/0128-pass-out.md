# 0128 - Passing out at 02:00

- **Phase:** 10 - Sleep is the night
- **Status:** todo
- **Depends on:** 0127
- **Likely files:** src/core/sim.gd, src/core/phases.gd, src/core/house.gd, src/core/game_data.gd, src/core/events.gd, src/ui/title_screen.gd, src/ui/log_panel.gd, src/tools/autoplay.gd, assets/locale/strings.csv, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd

## Goal

The day finally ends. A farmer still awake at 02:00 collapses where he stands and the night begins anyway, with only a thirty-second build step: staying up late is allowed, and it costs preparation, not the run.

## Requirements

- In `Sim._tick_day`, on the tick `day_tick` reaches `DAY_TICKS` (02:00), `Phases.pass_out(state)`: whatever he was doing stops (his action, a fishing cast), `house_visit.asleep` and a new `house_visit.passed_out` are set, and `begin_preparation` runs - indoors or out. A panel that stops the clock also stops 02:00 from arriving, as today
- `PASS_OUT_PREPARATION_TICKS := 30 * SECONDS` (`# LEVER`, 15-60 seconds worth): after a pass-out the build step ends itself after this many ticks, through 0118's `Phases.start_waves`; an ordinary bedtime keeps today's `PREPARATION_TICKS` until 0136 removes it (the build step's `phase_tick` is the counter; no new key). `validate()` checks it is positive and below `Sim.MOST_TICKS_IN_A_NIGHT`, and it joins the `time` row of `digest()`
- The clock clamps at 02:00, and `overtime_percent` now runs 0-100 from dusk to 02:00 and never past it
- A `passed_out` event: a new `Events.KINDS` entry, a severity in `log_panel.gd` and a `LOG_PASSED_OUT` line in both languages, so the log says why the build step is short; add its sample to `_task_0090_log` (headless_check), which fails on a kind without one. The fade from where he fell is the transition's; the collapse itself is A001's (0129 registers it, 0143 integrates it)
- Anything that spends a whole `DAY_TICKS` by day now passes out into a night. `Autoplay._a_day` spends exactly that and then calls the road into the build step, which would find it already there: make it stop short of 02:00 and go to bed (0142 rewrites the loop properly). Check the long day advances in the suites too - `_task_0002_tick_and_rng`'s 10000 ticks, `_task_0005_guards`' 20000-tick replay, `_task_0030_fishing`'s idle `DAY_TICKS`, `_task_0038_idle`, `_mine_for_a_day` - and either keep them inside the day or accept the night on purpose; report the suite times
- Rewrite `_task_0039_clock`: 'the night never starts itself' becomes 'at 02:00 he passes out and the night starts itself'. The stubborn-player block keeps its point - ignoring the clock costs nothing beyond the short build step (house, money, wood and the planted crop are what they were at 02:00)
- The title backdrop (`title_screen.gd`) stops writing the sleep intent at dusk: it starts its clock shortly before 02:00 and lets the pass-out bring the night. Update `_case_0091_title`, which compares `backdrop_tick()` with `DUSK_AT_TICK` (~5439)
- SIM moves on purpose: `house_visit` gains `passed_out` (hashed like every state key), and the determinism scenario's second day (about 12700 ticks after `begin_day`) now runs past 02:00 into a pass-out night. Record both numbers. DATA moves (a new lever in `digest()`)

## Done when

- [ ] `_task_0128_pass_out` in `headless_v1.gd` (write `day_tick` near the end rather than playing the day): still DAY at `DAY_TICKS - 1`; PREPARATION with `asleep` and `passed_out` at `DAY_TICKS`; NIGHT after exactly `PASS_OUT_PREPARATION_TICKS`; a farmer indoors passes out too; going to bed at 01:59 is an ordinary night
- [ ] The rewritten `_task_0039_clock`, `_task_0090_log` and `_case_0091_title` pass, and `python tools/autoplay.py` still plays its nights
- [ ] `python tools/shot.py 0128 --title` opened: the backdrop farm still reaches the night
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
