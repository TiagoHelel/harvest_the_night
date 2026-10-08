# 0136 - The build step waits for START

- **Phase:** 10 - Sleep is the night
- **Status:** done
- **Depends on:** 0118, 0132, 0128
- **Likely files:** src/core/sim.gd, src/core/phases.gd, src/core/game_data.gd, src/core/player.gd, src/ui/night_hud.gd, project.godot, src/app/input_actions.gd, assets/locale/strings.csv, src/tools/night_road.gd, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

The build step has no clock. The night waits while the player builds and starts when they press START - except after a pass-out, when the horde is already at the gate and gives thirty seconds.

## Requirements

- `Sim._tick_preparation` no longer starts the night by itself: a new edge intent `start_waves` (consumed by the tick, ignored outside PREPARATION) calls 0118's `Phases.start_waves`; after a pass-out the night also starts by itself at `PASS_OUT_PREPARATION_TICKS` (0128), and that timer is the only one left
- `PREPARATION_TICKS` leaves `game_data.gd` and `digest()`; the day clock stays stopped through the build step
- A START button on the night HUD (`StartButton`, `NHUD_START` 'START' / 'COMEÇAR') and a `start_waves` action in `project.godot` and `InputActions.ACTIONS`, with a pad button (0121) and a default key that is not the GO TO BED key, so a double press cannot skip the build step; `ACT_START` in both languages. After a pass-out the button counts down (`NHUD_START_IN`)
- The pad (found by 0121, reshuffled by 0133): every named button already carries an action - A interact (and the cursor's confirm at night), B cancel, X inventory, Y build, LB hotbar_prev, RB hotbar_next, LT upgrade, RT ability, L3 tech, R3 remove, Start pause, Back night - and the right stick is 0130's camera; `run` and `place` have no pad button. Give `start_waves` a button by taking one from an action 0121 left reachable another way (it named speed, skip_night, stats and log as focus-only), or move `tech` off L3 to make room; not Back, which is the GO TO BED key and would let a double press skip the build step. Update `_task_0121_pad`'s exceptions to match
- 0118's road (the `NightRoad` helper, or whatever 0118 named it) now writes `start_waves` instead of advancing `PREPARATION_TICKS`, so autoplay, determinism, shot, perf_check, play_nights and make_goldens change nowhere else. A loop that waits the build step out without naming the constant would now spin for ever - `shot.gd`'s trailer (~322, `while ... == Phases.PREPARATION`) is one: route it through the road too
- Rewrite `_task_0006_phases` ('preparation ends itself' becomes 'preparation waits for START') and every assert 0118 left on the timer with a comment pointing here; input cases that waited out the build step use the road. 0118's `_task_0118_road` text scan allowed `PREPARATION_TICKS` in the road: it now allows it nowhere. Check 0128's `_task_0128_pass_out` ordinary-bedtime half still holds
- SIM moves on purpose (`intent` gains `start_waves`, and the determinism scenario's build step is one tick instead of 600): record both numbers. DATA moves (`PREPARATION_TICKS` leaves `digest()`)

## Done when

- [ ] `_task_0136_start` in `headless_v1.gd`: two minutes of ticks in PREPARATION (past the old 20 s and the 30 s pass-out timer) stay in PREPARATION; `start_waves` begins the night on the next tick; `start_waves` by day or at night changes nothing; after a pass-out the night begins at exactly `PASS_OUT_PREPARATION_TICKS`, or sooner on START
- [ ] `_case_0136_start` in `input_v1.gd`: clicking `StartButton` and pressing the START key each begin the waves
- [ ] A capture of the build step with START on screen, opened
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
