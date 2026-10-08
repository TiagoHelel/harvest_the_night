# 0118 - One road into the waves

- **Phase:** 9 - v1.0 groundwork
- **Status:** done
- **Depends on:** 0112
- **Likely files:** src/core/phases.gd, src/core/sim.gd, src/tools/night_road.gd (new), src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd, src/tools/shot.gd, src/tools/autoplay.gd, src/tools/determinism.gd, src/tools/make_goldens.gd, src/tools/perf_check.gd, src/tools/play_nights.gd, src/tools/art_showcase.gd, src/tools/capture_dawn.gd

## Goal

About sixty-five places in the tests and tools start a night the same way: `begin_preparation`, then wait out `PREPARATION_TICKS`. Phase 10 changes how the build step ends twice (0136's START, 0137's dawn). Put the road into the waves in one place first, so those tasks change it once.

## Requirements

- A refactor: both hashes stay where they are and no test changes what it asserts
- One core entry starts the waves: `Phases.start_waves(state)`, PREPARATION to NIGHT, refusing any other phase with `push_error` like the other transitions; `Sim._tick_preparation`'s timer calls it. 0136's START intent and 0128's 30 s pass-out step will be its other callers
- Nothing in `src/tools/` or `src/ui/` calls `Phases.begin_night` directly any more (`art_showcase.gd` and `capture_dawn.gd` do today); `_task_0006_phases`' refused-transition check (`not Phases.begin_night(guard)`, ~l.2089) asks `start_waves` instead, or stays as an allowed exception
- A shared tool/test helper, e.g. `src/tools/night_road.gd` (`class_name NightRoad`, static): into the build step (`begin_preparation`); through it (the rest of the build step, `PREPARATION_TICKS - phase_tick`: on a fresh one exactly today's `Sim.advance(state, GameData.PREPARATION_TICKS)`, so the ticks are identical); both together; the night runner (step until the phase leaves NIGHT, with a cap - autoplay's 40000 loop); and the park (today's `_park_the_waves`)
- The park is where 0137 will also hold back dawn: say so in its doc comment, and add no state key for it now (any new key moves SIM)
- Route every site through it: `headless_check`'s `_scheduled_night`, `_fresh_night`, `_night_falls`, `_a_run_at_night`, `_to_the_next_night`, `_armed_prep`, `_defended_night` and the inline ones; the 19 lines in `input_check`; anything 0113-0117 put in the v1 suites; `shot.gd` (its `PREPARATION_TICKS + 1` too), `autoplay.gd`, `make_goldens.gd`, `perf_check.gd`, `play_nights.gd`. `determinism.gd` folds the state into SIM every `SAMPLE_EVERY` ticks through `_advance_sampling`: its build step must keep folding at the same ticks (the road tells it how many ticks are left, or takes the stepper), or SIM moves
- Leave the asserts whose subject is the timer itself (`_task_0006_phases`, 'then the night begins' after `PREPARATION_TICKS - 1`), each with a comment that 0136 rewrites it
- A brand-new `class_name` is invisible to `--script` runs until `--import` refreshes the cache: run verify, not the scripts by hand

## Done when

- [ ] `_task_0118_road` in `headless_v1` reads the code lines (comments skipped) of `src/tools/*.gd` and `src/ui/*.gd`: `PREPARATION_TICKS` appears only in the road and in an allow-list of timer asserts named in the assert, and `Phases.begin_night(` nowhere outside `src/core/` but its allowed exceptions (the assert's own needles excluded)
- [ ] `Phases.start_waves` from DAY or NIGHT returns false and changes nothing - asserted
- [ ] `python tools/autoplay.py` prints the same table as before the refactor, and `python tools/perf.py` stays within tolerance
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
