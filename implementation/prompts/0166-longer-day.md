# 0166 - A day of eight to ten minutes

- **Phase:** 12 - The day that pays
- **Status:** todo
- **Depends on:** 0165
- **Likely files:** src/core/game_data.gd, src/core/phases.gd, src/tools/autoplay.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd, tools/balance.py, implementation/BALANCE.md

## Goal

The day becomes eight to ten real minutes, so the 80x65 farm has time in it: crossing it already takes 28 seconds, and the plan's spring day (its appendix) does not fit in four minutes.

## Requirements

- `DAY_TICKS` spans 0126's 1200 game minutes (06:00-02:00) at a whole number of ticks per minute, which 0126's `validate()` rule demands: 12-15 a minute is 14400-18000 ticks, 8-10 real minutes (`# LEVER`). Recommended 14 (16800 ticks, 9 min 20 s) - nine minutes flat is 13.5 a minute and is refused. 0126 already derives `DUSK_AT_TICK` from `DUSK_MINUTE`: check it still lands on 18:00
- Re-express every per-tick producer against the longer day, with the arithmetic in the journal: `RECIPES` ticks (a kit still takes about a walk across the farm), `LIVESTOCK.every_ticks`, `GATHERING.regrow_ticks` (a node still gives about twice a day), the `FISHING` bite range, the generator's `fuel_every_ticks` and the `DAILY_STOCK` sizes. Nothing may double its daily output by accident
- Nothing in core or ui may hard-code a tick count for an hour of the clock: the bedtime reminders (0140) and pass-out (0128) read 0126's helpers, and so will 0190's stall hours - grep for `SECONDS` multiples compared with `day_tick`
- Re-time the suites: no headless group or input case may advance a whole day or a whole morning of ticks. Today's are `_task_0006_phases` and `_task_0021_night_intent` (to dusk), `_task_0030_fishing`, `_task_0031_iron` (`_mine_for_a_day`), `_task_0038_idle` (`_a_busy_day`), `_task_0039_clock`, `_task_0065_defeat`, `_task_0067_autoplay`, `_task_0068_balance`, `_case_0039_clock`, `_case_0091_title` and any v1 group that does (grep `DAY_TICKS`, `DUSK_AT_TICK`, `tick_at_minute`): give them a shorter road - a rigged `day_tick`, a direct morning call - and record each suite's time before and after
- `Autoplay._a_day` (as 0142 left it) spends the new day; 0142 already plays one day and one night per policy in `_task_0067`/`_task_0068`, so keep them inside the budget by an earlier policy bedtime in the suite or fewer policies there, never by shortening the lever. `tools/autoplay.py` and `tools/balance.py` still run
- A saved `day_tick` keeps its meaning (ticks since 06:00) and only reads earlier on the longer clock, and producer timers count down as before: no `State.VERSION` bump - say so in the journal
- DATA moves on purpose (time and producer levers). SIM moves on purpose too: the determinism scenario's kits, animals and clock run on the re-expressed levers. Record both, and add a BALANCE.md note on what one day yields now

## Done when

- [ ] `_task_0166_long_day` in `src/tools/headless_v1.gd`: `DAY_TICKS` maps onto 06:00-02:00, dusk reads 18:00, and each producer's yield per day (computed from the tables, not simulated) is inside the range the journal claims
- [ ] headless_check, input_check and both v1 suites finish at least 20 s under `SCRIPT_TIMEOUT_S`, with the times in the journal
- [ ] A short `tools/autoplay.py` run plays a full day and night, and the journal records the money that day made
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
