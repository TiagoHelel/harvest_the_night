# 0167 - Any grass can be tilled

- **Phase:** 12 - The day that pays
- **Status:** todo
- **Depends on:** 0165
- **Likely files:** src/core/farming.gd, src/core/interact.gd, src/core/game_data.gd, src/core/tutorial.gd, src/ui/world_view.gd, src/ui/placeholder_art.gd, src/tools/autoplay.gd, src/tools/determinism.gd, src/tools/make_goldens.gd, src/tools/perf_check.gd, src/tools/house_check.gd, src/tools/shot.gd, src/core/player.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd, implementation/backlog/packs/A014-crop-ground.md

## Goal

Any grass can be tilled, as in Stardew, so the 60 beds become the starter garden rather than the whole of farming - and ground becomes a choice between field and fortress (plan section 5: space has two uses).

## Art

What this task puts on screen will be dressed by Codex art pack(s) A014
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- `Interact._offered` sends GRASS as well as SOIL to `Farming.verb_at`, which offers `till` on bare grass and works on any plot whatever the ground under it. **The terrain byte never changes**: `world_view` draws terrain once, so tilled grass is a plot over grass, drawn by `_refresh_plots`
- Only bare grass and soil take the hoe; path, floor, water, rock and any occupied cell offer nothing. A lawn that offers `till` everywhere changes `Player.target`, whose fallback is the cell he stands on: standing on grass and facing nothing would till under his feet, and every press on open ground now does something. Decide (e.g. grass offers `till` only as the faced cell, never as the fallback), assert it, and grep the input cases that press interact on open grass
- Untended ground goes back: an empty tilled plot on grass left for `TILLED_GRASS_FADES_DAYS` mornings (`# LEVER`, 1-7) returns to grass in `Farming.morning`; soil beds never fade. The plot remembers the morning it was last worked (plots are `RUN_DATA`: read the new field with a default, reconcile never fills it)
- Path cost: decide whether tilled grass costs like SOIL in the flow field. Recommended: it keeps the grass cost, because a field that changed the route on every hoe stroke would call `Farm.touch` and rebuild every field (`path_refresh` ~7.9 ms). The journal says which and why
- Add `Farming.field_cells(state)` (soil beds plus tilled grass, index order) and move every user that means 'the field' off `Farm.cells_of(SOIL)`: `tutorial.gd` (three sites), `autoplay.gd`, `determinism.gd`, `make_goldens.gd`, `perf_check.gd`, `house_check.gd` and the headless/input helpers. With no grass tilled it returns exactly today's cells, so that alone moves no hash
- Edges of tilled grass: decide the scheme (N1/E2/S4/W8 masks like the barriers, or a plain border) and draw it through the placeholder road with today's `tilled`/`tilled_wet` sprites until A014 is integrated by 0197
- DATA moves (the lever goes into `digest()`, and `validate()` holds it to 1-7). SIM moves only if the scenario's soil plots change shape: write the new plot field only on tilled grass (soil beds never fade) and it stays - say which

## Done when

- [ ] `_task_0167_till_grass` in `src/tools/headless_v1.gd` (mornings by `Farming.morning`, never a day of ticks): the hoe on grass makes a plot and leaves the terrain byte alone; an empty tilled grass plot is gone after the fade mornings and a planted one is not; a path cell refuses the hoe
- [ ] `_case_0167_till_grass` in `src/tools/input_v1.gd`: the farmer walks onto open grass, holds interact, and a plot appears
- [ ] A new `till_grass` scenario: `python tools/shot.py 0167 till_grass --fhd` shows tilled grass beside the beds by day and by night; opened and looked at
- [ ] the Deliverables table of `implementation/backlog/packs/A014-crop-ground.md` states the final geometry this task settled (edge masks, canvas, pivot), and the pack's text names 0171, not 0170, as the owner of the withered crop
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
