# 0132 - Defences go down only at night

- **Phase:** 10 - Sleep is the night
- **Status:** todo
- **Depends on:** 0131, 0119
- **Likely files:** src/core/building.gd, src/core/game_data.gd, src/core/phases.gd, src/core/tutorial.gd, src/core/sim.gd, src/ui/build_mode.gd, assets/locale/strings.csv, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd

## Goal

The plan's decision 4: defences are placed, upgraded and sold only at night, by cursor, and production buildings only by day. The day earns and the night spends.

## Requirements

- `Building.allowed_in_phase`: a `DEFENCES` id only in PREPARATION and NIGHT, a `BUILDINGS` id only in DAY. `why_not` answers `WHY_ONLY_AT_NIGHT` for a defence by day (the string exists) and `WHY_NOT_AT_NIGHT` for a building after dark; `why_not_upgrade` and `sell` follow the same rule; `catalogue()` keeps following `allowed_in_phase`. The plan (4.3) lets upgrades go on during the waves, so `why_not_upgrade`'s `WHY_MID_NIGHT` refusal goes: rewrite `_task_0064_tower_levels` (~11931), and delete the `WHY_MID_NIGHT` row if nothing reads it any more (`tools/i18n_check.py` fails on an unused key)
- `placeable_at_night` goes: drop it from the barricade and drop the `check_defences` rule that tied it to a lifetime and a nightly limit. The barricade keeps `lifetime_ticks` and `per_night_limit` as its own identity (cheap, temporary, limited). Section 13's bug must not come back in the build step, which has no clock after 0136: a barricade placed in PREPARATION counts against tonight's limit (`Building.forget_tonight` moves from `begin_night` to `begin_preparation`) and its lifetime starts with the waves, not when it went down
- At night upgrade and sell go through the cursor: BuildMode's `upgrade` and `remove` write `build_upgrade` and `build_sell` at the cursor cell, and the cursor shows its upgrade and sell states (0131's registry)
- By day `B` lists only production buildings; at night the palette lists only defences (0133 turns it into the hotbar)
- The tutorial's `build` step moves to the night: it follows `night` in `TUTORIAL`, `Tutorial.tick` also runs on its beat in `_tick_preparation`, and `TUT_BUILD` says it happens at night, in both languages. 0141 writes the rest of the night's steps
- Rewrite `_task_0047_barricades` ('only the barricade goes down at night' becomes 'every defence goes down at night and none by day; buildings only by day'), `_task_0022_reality`'s 'built by day' wording and `_task_0041_tutorial`'s build step; any input_check case still placing a defence by day moves to the build step (0119 should already have moved them)
- Production buildings the other way round (found by 0119): `play_nights.gd` buys generators inside its build step, interleaved with its towers as their draw climbs. It must put them up by day once a `BUILDINGS` id is refused in PREPARATION - plan the generators from the shopping list before `begin_preparation`. `SuiteKit.built_last_night()` (0119) is how a fixture gets defences standing on a day farm without playing a night
- A rule change: if SIM moves, record both numbers and why (0119 moved the determinism scenario's placements into PREPARATION, so it may not). DATA moves (the barricade and the tutorial)

## Done when

- [ ] `_task_0132_night_build` in `headless_v1.gd`: for every `DEFENCES` id, `can_place` is false by day with the night refusal and true in PREPARATION and NIGHT on a clear cell; the reverse for every `BUILDINGS` id; upgrade and sell follow, and a tower upgrades mid-wave; the barricade still expires and still has its nightly limit, and one placed in PREPARATION counts against that limit and still stands for `lifetime_ticks` after the waves begin
- [ ] `python tools/shot.py 0132 refused` and a day build-mode capture opened: by day the list holds buildings only, at night defences only
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
