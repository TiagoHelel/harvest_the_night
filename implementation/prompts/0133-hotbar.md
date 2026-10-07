# 0133 - The hotbar of defences

- **Phase:** 10 - Sleep is the night
- **Status:** todo
- **Depends on:** 0132
- **Likely files:** src/ui/hotbar.gd (new), src/ui/build_mode.gd, src/ui/night_hud.gd, src/ui/day_hud.gd, src/ui/tooltip.gd, src/ui/guardian_view.gd, src/ui/placeholder_art.gd, project.godot, src/app/input_actions.gd, assets/locale/strings.csv, src/tools/input_v1.gd

## Goal

The night's shop window: a hotbar of every defence with its price, picked with a number key, a click or a bumper instead of a text list, so what the day earned is visible as walls and towers.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A005
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- In PREPARATION and NIGHT a hotbar along the bottom replaces BuildMode's text palette: one slot per id of `Building.catalogue(state)`, in that order, with its icon and price - the kit count when a kit is held, else `Building.cost_of`, greyed with what is short when `Building.affordable` says no, and the barricade's `left_tonight`. By day `B` keeps the text list of buildings
- Built from the catalogue, not a list: phase 13's six new defences appear with no edit here, and more slots than fit page or scroll
- Selection goes through `Building.select`, the road the palette rows use today: a click on a slot; `slot_1`..`slot_8` (add `slot_7` and `slot_8` - slots 1-6 are the seed keys by day (`DayHud.SEED_ACTIONS`) and mean hotbar slots at night, when the seed strip ignores them; `ACT_SLOT_*` stop saying 'SEED' in both languages); and `hotbar_prev`/`hotbar_next` on two pad buttons 0121's layout left free (the bumpers if they are) and a key pair, wrapping. New actions go into `project.godot` and `InputActions.ACTIONS` with `ACT_*` strings, rebindable, with the clash check passing. `cancel` clears the selection and the cursor goes back to inspecting
- Each slot's tooltip shows name, cost, HP, range and damage read from `GameData` (never copied) through `tooltip.gd`
- Icons through the placeholder road - the structure's own sprite scaled down is enough - until A005 is integrated by 0147
- The porch guardian (0131) plays its point state when a defence goes down, spotted by the view the way `sfx.gd` and `particles.gd` compare this frame's occupants with the last - no new `Events` kind, which would move SIM
- View only: neither hash moves. The night HUD's bottom-right controls stay clickable (0139 settles the final layout)

## Done when

- [ ] `_case_0133_hotbar` in `input_v1.gd`: `slot_2` selects the second defence, clicking a slot selects it, a bumper cycles and wraps, a placement at the cursor uses the selection, an unaffordable slot shows its shortfall, `slot_2` at night leaves the selected seed alone, and the guardian is in its point state after the placement
- [ ] `python tools/shot.py 0133 wave refused` and `--fhd` captures opened, also with `--pt_BR`: prices legible, nothing overlapping the night HUD
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
