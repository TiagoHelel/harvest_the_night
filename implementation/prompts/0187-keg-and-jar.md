# 0187 - Days in a barrel: the keg and the preserves jar

- **Phase:** 12 - The day that pays
- **Status:** done
- **Depends on:** 0184, 0168, 0149, 0186
- **Likely files:** src/core/crafting.gd, src/core/game_data.gd, src/core/phases.gd, src/ui/workshop_panel.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

The first artisan machines: a keg and a preserves jar that turn fruit into wine, juice, jelly and pickles over days - the road for a player who wants to farm money (plan section 3.5).

## Art

What this task puts on screen will be dressed by Codex art pack(s) A031, A032
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- A per-day recipe credit: a `RECIPES` entry may say `days` (`# LEVER`) instead of `ticks`; `Crafting` credits such a job one day each morning (from `Phases.begin_day`), not per tick, and the panel shows days left (a new string in both languages: `WORK_MAKING` prints seconds). `check_recipes` accepts exactly one of `ticks` and `days`
- Keg and preserves jar are `BUILDINGS` entries built by day (size, hp, cost as `# LEVER`s; 0188 writes the final sizes into A031). The keg makes wine from grapes and juice from other fruit; the jar makes jelly from fruit and pickles from vegetables - choose which crops
- `WINE`, `JUICE`, `JELLY` and `PICKLES` with prices, an artisan group, names and strings in both languages; every recipe passes `check_chain` with a margin worth the days
- Breakers already hunt every building with no `path_cost` (`Pathing.is_prey`), machines included: decide whether a machine at 0 HP takes 0186's wrecked-but-standing state (then 0188 adds `<id>_wreck` rows to A031) or turns to rubble like today's stations, and assert it
- Machines and goods draw through the placeholder road until A031 (0213) and A032 (0214) are integrated
- `Names.KEYS` with `BLD_*`/`REC_*` rows for the machines and every recipe, both languages. DATA moves; SIM moves on purpose (four resources in `held`/`gained`, two stations in `selected_recipe`) - record both

## Done when

- [ ] `_task_0187_keg` in `src/tools/headless_v1.gd` (mornings by `Phases.begin_day`): grapes in a keg are wine after the recipe's mornings and not one before; a day spent elsewhere still counts; every new recipe has a positive chain margin
- [ ] `_case_0187_keg` in `src/tools/input_v1.gd`: queue wine at a keg from its panel
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
