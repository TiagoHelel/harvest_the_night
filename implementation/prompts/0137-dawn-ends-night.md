# 0137 - The night ends at 06:00

- **Phase:** 10 - Sleep is the night
- **Status:** done
- **Depends on:** 0136
- **Likely files:** src/core/sim.gd, src/core/phases.gd, src/core/waves.gd, src/core/game_data.gd, src/core/events.gd, src/ui/night_hud.gd, src/ui/log_panel.gd, assets/locale/strings.csv, src/tools/determinism.gd, src/tools/night_road.gd, src/tools/nights.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, tools/nights.py

## Goal

The night has an end you know in advance: 06:00. A house still standing at dawn is a won night and whatever is left walks off into the light; killing everything sooner still wins.

## Requirements

- `NIGHT_TICKS := 240 * SECONDS` (`# LEVER`, 180-300 seconds worth: the plan's three to five real minutes) is the waves' length from `begin_night` to dawn, the same after a 21:00 bedtime and after a pass-out. `validate()`: below `Sim.MOST_TICKS_IN_A_NIGHT`
- `begin_night` writes the dawn tick into the state (e.g. `wave.dawn_at`, a TABLES field whose `initial()` is `NIGHT_TICKS`, so an old save gets a whole night) and `Phases.ticks_to_dawn(state)` reads it. The park of 0118's `NightRoad` (today's `_park_the_waves`) parks dawn too (`dawn_at` out of reach), so parked nights still never end
- In `Sim._tick_night`, after `Combat.tick`: still NIGHT and `night_tick >= dawn_at` -> `Rewards.settle(state, true)` and `Phases.enter_result(state, true)` with the survivors still on the farm; `begin_day`'s `Enemies.withdraw` and `EnemyRetreats` walk them off. A `dawn` event (a new `Events.KINDS` entry with a severity in `log_panel.gd` and a sample in `_task_0090_log`) with `LOG_DAWN` ('dawn - %d walked off', en and pt_BR). The house at 0 still loses and `_test_for_the_end` still wins early
- Interim until 0153: dawn does not end a night while a boss is on the farm (`Combat.boss_here`), so night 10 still ends only with the Giant or the house down, and the run can never end with the Giant standing
- `check_nights`: every night's schedule (the opening, each wave's members x `SPAWN_INTERVAL_TICKS`, the gaps) ends at least a margin `# LEVER` before `NIGHT_TICKS`; a headless assert samples the endless curve (nights 11-40, a few seeds) against the same rule, from the schedule functions and without playing a night; `tools/nights.py` (through `src/tools/nights.gd`) prints each night's schedule against the night
- The night HUD shows the time left to dawn as a countdown (`NHUD_DAWN`), never a wall clock - after a pass-out a 22:00-06:00 mapping would lie - holding at 0:00 while a boss keeps the night going. Skip and 1x/2x/4x simply run to dawn
- Owns `_task_0027_the_loop` ('ends by itself' becomes 'ends at dawn or when everything is dead'), `_task_0055_speed` (skip runs to dawn) and the `Sim.skip_night` in input_check's `_case_0082_shots` (~4461). `determinism.gd` stops calling `enter_result` directly and fights until the night ends itself: SIM moves on purpose (that, and `wave` gains `dawn_at`), record both numbers. DATA moves too: `NIGHT_TICKS` and the margin join the `time` row of `digest()`. A bounty only for kills is 0219's

## Done when

- [ ] `_task_0137_dawn` in `headless_v1.gd` (write a near `dawn_at` into the test's state rather than playing 240 s, so the group stays a few seconds): a night whose horde cannot reach the house ends at exactly `dawn_at` with `survived` true, and the survivors are gone after `begin_day`; killing everything ends it sooner; a house at 0 before dawn loses; `check_nights` refuses a schedule longer than the night
- [ ] `Sim.skip_night` from mid-night takes at most the ticks left to dawn and lands in RESULT
- [ ] `python tools/nights.py` shows all ten nights inside the night with their margins; the numbers are in the journal
- [ ] `python tools/shot.py 0137 wave` opened: the dawn countdown is on screen
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
