# 0126 - The clock: 06:00 to 02:00

- **Phase:** 10 - Sleep is the night
- **Status:** todo
- **Depends on:** 0118
- **Likely files:** src/core/phases.gd, src/core/game_data.gd, src/ui/day_hud.gd, src/ui/world_view.gd, assets/locale/strings.csv, src/tools/headless_v1.gd

## Goal

The day gets an hour. Today's `DAY_TICKS` is mapped onto a clock that runs from 06:00 to 02:00, dusk falls at 18:00, and the light and the HUD read the hour, so every later task can speak in times of day.

## Requirements

- Clock levers in `game_data.gd`: `DAY_START_MINUTE := 6 * 60` (`# LEVER`, 05:00-08:00), `DAY_END_MINUTE := 26 * 60` (02:00 the next morning, `# LEVER`, 24:00-27:00) and `DUSK_MINUTE := 18 * 60` (`# LEVER`, 16:00-20:00). `DUSK_AT_TICK` becomes a constant derived from them, so none of its callers change
- Integer helpers in `Phases`: `clock_minute(state)` (minutes since midnight of the day that began: 360 at `day_tick` 0, 1560 at `DAY_TICKS`), `tick_at_minute(minute)` (the inverse, for tests and tools), and `is_dusk` reading the dusk minute. Outside DAY they answer for the moment the day ended. Until 0128 the clock keeps counting past 02:00 rather than clamping
- `GameData.validate()` (through a `check_clock(start, dusk, end, day_ticks)` that takes its numbers as arguments, like `check_tutorial(steps)`, so a test can feed it a bad clock; it replaces today's `DUSK_AT_TICK > DAY_TICKS` line): start < dusk < end, and `DAY_TICKS` is a whole number of ticks per game minute (6 today, 12-15 after 0166), so the clock never shows a minute twice or skips one
- `DHUD_DAY` (today `DAY %d   %d:%02d%s`, elapsed m:ss) shows the hour as 24-hour HH:MM in both languages (`assets/locale/strings.csv`), wrapping after midnight (01:30, never 25:30); keep `DHUD_DUSK` read or delete its row, so `tools/i18n_check.py` finds no unused key. 0140 gives the clock its final look
- `WorldView._daylight_now` and `_ramp_now` read the hour: dawn to noon, noon to dusk at 18:00, the dusk light deepening until 02:00. The night ramp does not change
- No rule changes: `day_percent` and `overtime_percent` keep their meaning (overtime now starts at 18:00), and the real length of the day is 0166's
- SIM must not move. DATA moves on purpose - dusk goes from 192 s to 144 s of the 240 s day (22:00 to 18:00 on the new clock) and the clock levers join the `time` row of `digest()`; write both numbers in PROGRESS

## Done when

- [ ] `_task_0126_clock` in `src/tools/headless_v1.gd` asserts 06:00 at tick 0, 16:00 at `DAY_TICKS / 2`, 18:00 at `DUSK_AT_TICK`, 02:00 at `DAY_TICKS`, `tick_at_minute(clock_minute(t)) == t` on minute boundaries, and that `check_clock` refuses a dusk after the end of the day and a day that is not a whole number of ticks per minute
- [ ] `python tools/shot.py 0126 noon dusk` opened: the HUD reads HH:MM and the evening light starts at 18:00, not later
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
