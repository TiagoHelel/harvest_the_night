# 0172 - Crops that grow back

- **Phase:** 12 - The day that pays
- **Status:** todo
- **Depends on:** 0168
- **Likely files:** src/core/farming.gd, src/core/game_data.gd, src/ui/world_view.gd, src/ui/placeholder_art.gd, src/tools/shot.gd, src/tools/headless_v1.gd

## Goal

Strawberry, corn, pepper and grape grow back after picking, so planting them early in their season is a choice that pays all season long.

## Requirements

- `CROPS` gains `regrow_days` (`# LEVER`) for strawberry 4, corn 4, pepper 3 and grape 3 (plan section 3.1)
- `Farming._harvest` on a regrowing crop leaves the plant in a regrowing state, `regrow_days` short of ready, instead of an empty plot; watering and the morning credit work as for any crop, and the hoe clears it
- `Farming.stage()` reports a distinct regrowing stage the view draws as `<crop>_regrow`; until A015/A016/A017 are integrated by 0198/0199/0200 it is the stage-2 sprite tinted, through the placeholder road
- `value_per_day` and `check_crops` count regrowth: harvests in a season are one plus the whole regrowths left in it. Put the table in the journal so the four do not dominate the rest
- The season-change withering of 0171 takes regrowing plants too; if 0171 has landed, assert it
- The new plot field is read with a default (plots are `RUN_DATA`); if it changes what a saved `growth` means, bump `State.VERSION` and migrate
- DATA moves; SIM only if the scenario harvests a regrowing crop

## Done when

- [ ] `_task_0172_regrow` in `src/tools/headless_v1.gd` (mornings by `Phases.begin_day`): a strawberry harvested when ready is ready again `regrow_days` watered mornings later without replanting; a carrot leaves an empty plot
- [ ] A new `regrowing` scenario: `python tools/shot.py 0172 regrowing --fhd` shows a regrowing strawberry beside a ripe one; opened and looked at
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
