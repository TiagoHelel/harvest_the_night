# 0222 - Bone meal

- **Phase:** 13 - Weapons of the night
- **Status:** todo
- **Depends on:** 0221, 0165
- **Likely files:** src/core/game_data.gd, src/core/farming.gd, src/core/interact.gd, src/ui/day_hud.gd, src/ui/sfx.gd, src/ui/names.gd, src/ui/world_view.gd, assets/locale/strings.csv, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

Bones go back into the ground: ground into bone meal, they give a plot one day of growth for free, once - the night paying for the day.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A036
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- A recipe (e.g. `grind_bone_meal`, at the workshop or 0188's mill) turns bones into `bone_meal`, a new resource with a price, a group, `Names.KEYS` (`ITEM_BONE_MEAL`, its `REC_*`) and both languages; `check_chain` holds (bone meal is worth more than its bones)
- Fertilising: with bone meal selected in the day HUD's strip beside the seeds (keyboard, mouse and pad), interact on a tilled plot spends one and marks the plot `fertilised` - a new field on the plot in `state["plots"]` (RUN_DATA), read with a default so old saves' plots need no migration and no `State.VERSION` bump. If it is a new verb (e.g. `fertilise` in `Farming.verb_at`), it goes in `Interact.DAY_ONLY` and `DEFAULT_TICKS`, and `Sfx.VERB_SOUNDS` maps it to the nearest generated sound (`sfx/plant`) so `_task_0084_day_sounds` stays green until 0281 gives it its own
- The rule: at the next morning's growth credit (0165) a fertilised plot grows one extra day, once, and the mark clears. Decide and assert whether it must also have been watered; it never gets round a regrowth (0172) or winter (0171) rule
- A fertilised plot not yet planted keeps the mark until it is; harvesting clears it
- The soil marker is drawn through the placeholder road (a tinted tilled tile, dry and wet) until A036 is integrated by 0235
- SIM and DATA move on purpose: record both

## Done when

- [ ] `_task_0222_bone_meal` in `src/tools/headless_v1.gd` asserts two plots of one crop planted together, one of them fertilised, finish exactly one day apart, and a second morning grants nothing extra - driving 0165's morning credit directly rather than simulating whole days, which the 120 s suite budget cannot afford
- [ ] `_case_0222_fertilise` in `src/tools/input_v1.gd` selects bone meal and fertilises a plot with the keyboard
- [ ] The Deliverables table of `implementation/backlog/packs/A036-night-loot.md` states the final geometry this task settled (the pickups, the fertilised soil, the four icons)
- [ ] `python tools/shot.py 0222` captures of a fertilised plot dry and wet, opened and looked at
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
