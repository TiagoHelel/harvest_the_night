# 0178 - Sprinklers

- **Phase:** 12 - The day that pays
- **Status:** todo
- **Depends on:** 0176, 0165
- **Likely files:** src/core/game_data.gd, src/core/farming.gd, src/core/phases.gd, src/core/pathing.gd, src/core/building.gd, src/ui/names.gd, src/ui/particles.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

Sprinklers automate the chore: copper, iron and gold ones water the plots around them every morning, so a big field stops costing the whole morning.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A018
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- Three tiers (copper, iron, gold) as `BUILDINGS` entries or one id with levels - decide - with costs in their metal plus money, hp and a 1x1 size, built by day like every production building; recipes or a direct cost, with `check_recipes` and `check_buildings` still honest
- Each morning, after 0165's growth credit, every sprinkler marks the plots of its pattern watered for the new day (four neighbours, 3x3, 5x5 - `# LEVER`), in sorted cell order; they dry at night like any other plot
- **Never a wall.** `Pathing._through` makes anything without a `path_cost` impassable, so a row of sprinklers would fence the farm. Make them walkable for the flow field like a trap (a declared flag `_through` reads) and not prey - `is_prey` counts any `BUILDINGS` entry with no `path_cost` today, so it reads the same flag - and say whether the farmer walks over them
- A cell with a sprinkler is not a plot: tilling and planting skip it, and a sprinkler cannot go on a planted plot
- The spray is code particles (view only); the body draws through the placeholder road until A018 is integrated by 0201
- `BLD_*`/`REC_*` names and strings in both languages. DATA moves; SIM moves if the state's shape changes (a new station in `selected_recipe`) or the scenario places one - say which

## Done when

- [ ] `_task_0178_sprinklers` in `src/tools/headless_v1.gd`: a copper sprinkler waters its four neighbours on a morning and they grow the next; the flow field crosses its cell at ground cost; a breaker does not hunt it
- [ ] `_case_0178_sprinkler` in `src/tools/input_v1.gd`: place one by day from the build list
- [ ] A new `sprinklers` scenario: `python tools/shot.py 0178 sprinklers --fhd` shows the three tiers spraying; opened and looked at
- [ ] the Deliverables table of `implementation/backlog/packs/A018-sprinklers.md` states the final geometry this task settled
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
