# 0224 - The scarecrow decoy

- **Phase:** 13 - Weapons of the night
- **Status:** done
- **Depends on:** 0218, 0132
- **Likely files:** src/core/game_data.gd, src/core/pathing.gd, src/core/enemies.gd, src/ui/names.gd, src/ui/describe.gd, assets/locale/strings.csv, src/tools/perf_check.gd, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

A straw figure that pulls nearby zombies off their road and takes their blows while the towers work - the first defence that changes where the horde goes without walling it in.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A037
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- Id `decoy` (not `scarecrow`, which is the porch guardian, and no crop id). A `DEFENCES` row: a cost in straw (the resource 0184 and 0193 brought in) and wood, a high `hp` LEVER (100-250), a `lure_tiles` LEVER (3-8), no `reload_ticks` (it is not a tower) and no `path_cost`, so breakers already hunt it as prey. Its `season` (0193's field on `DEFENCES`) is summer, per the plan's table, so `check_seasonal_supply` judges it right; 0234 does the gating. No `damage` either, so no `Sfx.TOWER_SOUNDS` entry: `_task_0085_night_sounds` wants a sound exactly when a defence has `damage`
- The lure rule: a lure field registered in 0218's `Pathing` registry, swept from decoy cells and built only while a decoy stands. An enemy whose `ENEMIES` row says it can be lured (a new flag: walker and runner yes, bosses never; decide the tank and the breaker) and is within `lure_tiles` of a decoy by the lure field walks down that field instead of its own, and bites the decoy through `Enemies._gnaw` when it is the next cell
- When the decoy falls the lured go back to their own field the same tick. Two decoys: the nearer by the field wins, ties by `Grid.STEPS`
- `GameData.validate()`: a lure has `lure_tiles` > 0 and hit points (`check_defences`); no boss is lurable (`check_enemies`)
- Perf: a farm without decoys pays nothing for the lure field; with four decoys the rebuild stays inside `PATH_BUDGET_US`. Add decoys to perf_check's swarm scenario
- `Names.KEYS` `DEF_DECOY`, a `Describe.defence` line for the lure (a `DESC_*` key), strings in both languages; placed by cursor at night like every defence (0132)
- Drawn through the placeholder road (a code-drawn straw figure at 16x32, whole/hurt/wreck) until A037 is integrated by 0236; the hit sway is view only
- DATA moves (a new row and the lurable flags). SIM moves on purpose too if the lure field's storage keys are in a new game's state, because `State.hash_of` folds every key, cached fields included: record both numbers and why

## Done when

- [ ] `_task_0224_decoy` in `src/tools/headless_v1.gd` asserts a walker within `lure_tiles` walks to the decoy and bites it while one beyond walks on to the house, a runner is lured, the Giant is not, and the lured return to the road the tick the decoy falls
- [ ] `_case_0224_decoy` in `src/tools/input_v1.gd` places a decoy with the cursor at night
- [ ] `python tools/perf.py` passes with decoys in the swarm, and a `shot.gd` scenario of a lured crowd, captured with `python tools/shot.py 0224`, is opened and looked at
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
