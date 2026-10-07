# 0169 - An inventory for many things

- **Phase:** 12 - The day that pays
- **Status:** todo
- **Depends on:** 0168
- **Likely files:** src/ui/inventory_panel.gd, src/core/inventory.gd, src/core/game_data.gd, src/ui/day_hud.gd, src/ui/names.gd, src/app/input_actions.gd, project.godot, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

Task 0036's inventory was a list for fifteen things and 1.0 has about seventy. Groups become pages a player flips with a key, a click or the pad, and the HUD's six numbers become a choice.

## Requirements

- `RESOURCE_GROUPS` grows to the categories of plan section 8 (materials, crops, seeds, fish, animal goods, artisan goods, ammunition, night leftovers, the farm). A group may be declared before its members exist; an empty group is not drawn
- `inventory_panel.gd` shows one group per page with tabs (keyboard, mouse and pad through `InputActions`: a new page action goes into `InputActions.ACTIONS` and `project.godot` with a pad binding and its `ACT_*` row, or reuse an existing one - say which), amount and sale price per row, and fits 480x270 with seventy items in all; `ROW_HEIGHT` decides how many rows a page holds. Each tab is named by a literal key (`INV_GROUP_*` rows, en and pt_BR, looked up through a literal table so `tools/i18n_check.py` sees them). `_case_0036_inventory` expects every resource's `inv_<id>` row on screen at once and `_task_0036_inventory` the reference sheet's groups: rewrite both in place for pages
- `DayHud.SHOWN` stays six numbers in two rows; which six is a decision written in the journal (wood, stone, iron and food, plus the two that matter most in 1.0). The bar never grows
- **From here on a resource is not done until it is complete**: `GameData.validate()` (an extended `check_groups` or a new check) refuses a `RESOURCES` id with no `SELL_PRICE` (money, energy and tech excepted) or no group (nothing new may fall into `GROUP_OTHER`), and headless asserts each id has a `Names.KEYS` entry and an `ITEM_*` row in both languages. Every later task that adds a resource adds all four
- An item with no `ui/icon_<id>` draws a placeholder through the placeholder road (0120), so no row is ever blank
- View only: SIM unchanged; DATA moves for the groups table

## Done when

- [ ] `_task_0169_inventory` in `src/tools/headless_v1.gd`: the new check fails by name on a rigged table with an unpriced and with an ungrouped resource; every real resource has a price, a group, a `Names.KEYS` entry and an `ITEM_*` row in both languages
- [ ] `_case_0169_inventory` in `src/tools/input_v1.gd`: open the inventory, flip every page with the keyboard, the mouse and a synthetic pad event, close it
- [ ] A new `inventory_full` scenario (every item held): `python tools/shot.py 0169 inventory_full --fhd` shows each page with no labels on top of each other; opened and looked at
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
