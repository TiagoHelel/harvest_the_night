# 0225 - Zombie bait

- **Phase:** 13 - Weapons of the night
- **Status:** done
- **Depends on:** 0224, 0179
- **Likely files:** src/core/game_data.gd, src/core/pathing.gd, src/core/enemies.gd, src/core/building.gd, src/ui/names.gd, src/ui/describe.gd, assets/locale/strings.csv, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

Rotten fish made by day and thrown down at night: for a few seconds the whole crowd around it turns toward it - the pond paying into the night (plan section 3.2).

## Art

What this task puts on screen will be dressed by Codex art pack(s) A037
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- Id `zombie_bait`: a recipe at the kitchen (or the press) turns fish into a bait kit, through 0179's rule that a recipe taking `fish` accepts any species; the kit's inputs equal the `DEFENCES` cost, as `check_recipes` demands. 0179's fish group is understood by `Crafting`, not by `Resources.pay`: either the bait goes down from a kit only (the ledger road refused with a reason) or its `cost` names a real resource - decide. Its `season` (0193's field) is summer, as 0234's table says
- It reuses 0224's lure rule and lurable flags, with a wider `lure_tiles` LEVER (6-14). Decide how one lure field honours two reaches (each source seeded with its own head start, or the bait as a second registered field) and keep 'the nearer by the field wins'
- Walkable like a mine: a `walkable` flag on the `DEFENCES` row that `Pathing._through` (the ground's cost) and `Pathing.is_prey` (left out) both read, so nothing breaks through it and breakers do not hunt it. 0228's garlic braid uses the same flag - if 0228 landed first, reuse it. `check_defences` refuses a walkable row with a `path_cost`
- Consumed: it lasts `lifetime_ticks` (LEVER, 5-20 s) and goes when that runs out or when a LEVER number of zombies have reached it, whichever is first; it leaves no rubble
- A per-night limit LEVER like the barricade's, read through `Building.left_tonight` - which today adds the tree's `barricade_bonus` to every `per_night_limit`: make that the barricade's alone, or decide the bait shares it, and assert which
- `Names.KEYS` (`DEF_ZOMBIE_BAIT`, its `REC_*`), a `Describe.defence` line, strings in both languages; no `damage`, so no `Sfx.TOWER_SOUNDS` entry; drawn through the placeholder road (a 16x16 fish on the ground and its icon) until A037 is integrated by 0236
- DATA moves (a row and a recipe); SIM moves only if a state key is added or the determinism scenario meets a bait - record which

## Done when

- [ ] `_task_0225_bait` in `src/tools/headless_v1.gd` asserts a crowd beyond any decoy's reach turns toward the bait, the bait goes at its lifetime or its arrival count, and the crowd is back on its road the same tick
- [ ] `_case_0225_bait` in `src/tools/input_v1.gd` makes a bait by day and places it with the cursor at night
- [ ] The Deliverables table of `implementation/backlog/packs/A037-decoy.md` states the final geometry this task settled (decoy states and sway frames, the bait on the ground, its icon)
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
