# 0192 - Cooking with the new harvest

- **Phase:** 12 - The day that pays
- **Status:** todo
- **Depends on:** 0188, 0184
- **Likely files:** src/core/game_data.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/headless_v1.gd

## Goal

The kitchen cooks the new harvest - potato, egg, milk and bread - into the food that mends the house at night, and spring gets a meal without wheat.

## Requirements

- Kitchen recipes with potato, egg, milk and flour, and `BREAD` baked from flour (price, group, names and strings in both languages; a tinted icon until A032 is integrated by 0214), each recipe with a `Names.KEYS` entry and a `REC_*` row; the better recipes give `FOOD` in bigger batches (`# LEVER`s)
- A spring meal without wheat: potato and carrot into food, so the house can be mended in spring - today `cook_meal` needs wheat, an autumn crop
- Every recipe passes `check_chain`: cooked is always worth more than its inputs
- Keep the ids `cook_meal`, `cook_fish` and `cook_roast` (tests and saves name them) unless the journal says why one goes
- DATA moves; SIM moves on purpose (`BREAD` in `held`/`gained`, and the kitchen's default selection if a new recipe sorts first) - record both

## Done when

- [ ] `_task_0192_kitchen` in `src/tools/headless_v1.gd`: from spring stock alone (carrot, potato, fish) the kitchen makes food; bread needs flour; every kitchen recipe has a positive chain margin
- [ ] The journal lists every kitchen recipe with its margin
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
