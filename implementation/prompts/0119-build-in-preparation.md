# 0119 - Tests and tools build in the build step

- **Phase:** 9 - v1.0 groundwork
- **Status:** todo
- **Depends on:** 0118
- **Likely files:** src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd, src/tools/autoplay.gd, src/tools/determinism.gd, src/tools/shot.gd, src/tools/make_goldens.gd, src/tools/perf_check.gd, src/tools/play_nights.gd, src/tools/tower_showcase.gd, src/tools/barrier_showcase.gd, src/tools/effect_showcase.gd, src/tools/enemy_showcase.gd, src/tools/giant_showcase.gd

## Goal

0132 will forbid defences by day. Before it does, move every defence the tests and tools put down into the build step, where they are allowed today, so that rule change is a rule change and not a hundred broken set-ups.

## Requirements

- Every set-up `Building.place` of a defence (an id in `GameData.DEFENCES`) happens in PREPARATION, after the road's 'into the build step' and before the waves: `_arm_the_farm`/`_defended_night` and the rest of `headless_check`'s ~62 place sites, `input_check`'s ~10, the v1 suites' groups from 0113-0118, `shot.gd`'s scenarios, `determinism.gd` `_set_the_farm_going`, `make_goldens.gd`, `perf_check.gd`, `play_nights.gd`. The same for every set-up `Building.upgrade` and `Building.sell` of a defence (~11 in `headless_check`): 0132 makes them follow the same rule
- The art gates verify runs place real defences after setting `phase` to DAY: `tower_showcase.gd`, `barrier_showcase.gd`, `effect_showcase.gd`, `enemy_showcase.gd`, `giant_showcase.gd`. They set PREPARATION around the placement, upgrade and sale instead, and their `show_art.py ... --check` rows still pass (`art_showcase.gd`'s stations are buildings and stay by day)
- Production buildings (`GameData.BUILDINGS`: press, generator, kitchen...) stay by day: decision #4 keeps them a day job
- `Autoplay`: `_a_day` still gathers, crafts, buys tech and puts up production buildings; a new build step between `begin_preparation` and the waves places, upgrades and repairs defences off the same plan cursor (`_wants`, `_room_for`, `_next_step`)
- `_task_0068_balance` asserts 'builds what its plan names first' straight after `_a_day`: rewrite it to look after the build step
- Leave the asserts whose subject is the day-placement rule itself - e.g. `_task_0022`'s 'built by day', `_task_0047`'s night barricade, the tutorial's day `build` step in `_task_0041` - with a comment at each pointing at 0132
- In `input_check`, a defence placed through the real build mode goes down after the night button; if build mode cannot open in PREPARATION, that is a bug to fix here and say so
- Only SIM may move, because the determinism scenario's towers and walls now go down in PREPARATION: accept it and write both numbers and why in the journal. DATA does not move

## Done when

- [ ] With a scratch edit to `Building.allowed_in_phase` and `why_not_upgrade` refusing every `DEFENCES` id by day (reverted before the end), a full `python tools/verify.py` fails only on the day-rule asserts this task leaves for 0132, in `headless_check` and `input_check` - listed in the journal; the v1 suites, the art showcases, autoplay and the tools pass
- [ ] `python tools/autoplay.py` runs, and the journal has the nights held per policy before and after
- [ ] `python tools/shot.py 0119` taken and opened: `wave` and `refused` still show their towers and walls
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
