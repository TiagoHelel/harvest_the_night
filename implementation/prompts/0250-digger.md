# 0250 - The digger

- **Phase:** 14 - Enemies and bosses
- **Status:** todo
- **Depends on:** 0218, 0234
- **Likely files:** src/core/pathing.gd, src/core/enemies.gd, src/core/towers.gd, src/core/game_data.gd, src/ui/world_view.gd, src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/perf_check.gd, tools/perf_baseline.txt, src/tools/shot.gd, src/tools/headless_v1.gd

## Goal

The enemy that makes a fence a different thing from a wall: it tunnels under fences and barricades and comes up on the other side. Only a real wall stops it.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A049
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- `ENEMIES.digger` with `# LEVER`s (hp, `ticks_per_tile` slower than the runner's 9 so `check_enemies` holds, damage, reward, armour) and a `burrows` flag; inside `_task_0051_tank`'s non-boss bounds
- A burrow field through 0218's named-field registry, built on first request by a digger, so a night without one never builds it: a barrier flagged `burrowable` costs only the ground under it (`Pathing._through` and `_entry_costs`), everything else as in the flow field
- `check_defences` makes every barrier (`path_cost` > 0) declare `burrowable`: fence and barricade yes, wall no (0231's hardwood wall is the wall's `TOWER_LEVELS` row and inherits it); 0231's sandbag barrier, 0230's electric fence and anything else with a `path_cost` decided and written in the journal
- On a `burrowable` barrier's cell it is underground: in `Enemies._walk` it passes instead of `_gnaw`ing, `Towers._acquire` (0218's bucketed version) cannot target it and the barrier loses nothing; on open ground it surfaces, and walls and the house are gnawed and bitten as a walker does (`_gnaw`, `_bite`)
- The tie-breaks of `Grid.STEPS` and 0049's rule hold: a digger never alternates between two cells for 20 ticks
- A digger case in `src/tools/perf_check.gd` (its own `PERF` line, fifty walls and fences, the burrow field built): its path rebuild stays inside `PATH_BUDGET_US` (33333 us) in `python tools/perf.py --report`, the baseline accepted with the reason in the journal
- Names.KEYS `digger`, `ENEMY_DIGGER`/`ENEMY_DIGGER.other` (digger/diggers, escavador/escavadores); `DESC_BURROWS` ('digs under fences' / 'cava por baixo das cercas'); `Sfx.ENEMY_SOUNDS.digger` borrows `sfx/groan_breaker` until 0284
- On screen through 0120's placeholder road: a tinted stand-in, a code-drawn mound while underground and its forecast head, until A049 is integrated by 0263
- Hashes: DATA moves; SIM should not (no digger in the determinism night, so no field is built)

## Done when

- [ ] `_task_0250_digger` in `src/tools/headless_v1.gd`: a digger reaches the house through a ring of fences without a fence losing a hit point, a ring of walls makes it gnaw, and a tower cannot target it while it is under a fence
- [ ] The same group asserts the burrow field is never built on a night without a digger
- [ ] `python tools/shot.py 0250 digger` (a new scenario) opened and looked at: the mound reads as under the fence
- [ ] the Deliverables table of `implementation/backlog/packs/A049-digger.md` states the final geometry this task settled
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
