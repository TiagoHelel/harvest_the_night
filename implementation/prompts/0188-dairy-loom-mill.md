# 0188 - The dairy, the loom and the mill

- **Phase:** 12 - The day that pays
- **Status:** todo
- **Depends on:** 0187, 0185
- **Likely files:** src/core/game_data.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd

## Goal

The dairy, the loom and the mill: milk into cheese and butter, wool into cloth and sandbags, wheat into flour and beet into sugar.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A031, A032
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- Dairy, loom and mill as `BUILDINGS` built by day; recipes (`ticks` or `days`, `# LEVER`s): cheese and butter from milk; cloth from wool and sandbags from cloth plus a filler you choose; flour from wheat and sugar from beet
- `CHEESE`, `BUTTER`, `CLOTH`, `SANDBAG`, `FLOUR` and `SUGAR` with prices, groups, names and strings in both languages, and `BLD_*`/`REC_*` rows for the machines and every recipe; every value passes `check_chain`. If 0187's jelly should take sugar, add it now
- Sandbags are a material here: their night use is 0231's. Bread is 0192's (the kitchen, from flour)
- Settle the art: the five machines' footprints, states (idle, active, hurt, and wreck if 0187 said so) and light/smoke points into A031; the eleven goods into A032 (bread included)
- Stand-ins through the placeholder road until A031 (0213) and A032 (0214) are integrated
- DATA moves; SIM moves on purpose (six resources in `held`/`gained`, three stations in `selected_recipe`) - record both

## Done when

- [ ] `_task_0188_mills` in `src/tools/headless_v1.gd`: every new recipe runs and `check_chain` holds for each
- [ ] A new `machines` scenario: `python tools/shot.py 0188 machines --fhd` shows the five machines idle and working; opened and looked at
- [ ] the Deliverables tables of `implementation/backlog/packs/A031-machines.md` and `A032-artisan-goods.md` state the final geometry and item list this task settled
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
