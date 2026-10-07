# 0248 - The rat swarm

- **Phase:** 14 - Enemies and bosses
- **Status:** todo
- **Depends on:** 0218, 0132
- **Likely files:** src/core/game_data.gd, src/core/waves.gd, src/core/enemies.gd, src/tools/perf_check.gd, tools/perf_baseline.txt, src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd

## Goal

A crowd of small fast bodies that a single-target tower wastes shots on and a mine or a flame cone eats. It is also the perf case the groundwork of 0218 was built for.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A047
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- `ENEMIES.rat` with `# LEVER`s: hp 2-6, `ticks_per_tile` 10-14, damage 1-2, reward 1, armour 0, `cluster` (rats per spawn, 4-10; `check_enemies` refuses a `cluster` below 1); a swarm must not out-earn a day - check the night's bounty against 0219's levers
- `check_enemies` wants every `ignores_structures` kind faster than the fastest kind that stops for walls (the runner, 9 ticks a tile): a rat that stops for walls at 9 or less would fail the runner, so keep it at 10-14 or make it go round like one - decide, and never weaken the check to pass
- Clusters: a wave record still counts bodies, so the forecast and `Waves.size_of` stay true; `Waves.tick` releases up to `cluster` per `SPAWN_INTERVAL_TICKS`, the first on a cell from the run RNG as today (`Enemies.spawn`) and the rest through `Entities.spawn` on that cell's walkable, reachable neighbours in `Enemies.NEIGHBOURS` order (four of them), then back round onto the same cells - bodies may share a cell, as they already can - with no extra draws
- Mines and fire are the answer by construction: a gun tower overkills a rat, a mine's splash and the flamethrower cone take many. Put the cost per rat killed for the gun tower, the crossbow, the mine and the flamethrower in the journal
- Perf through 0218's caches: 0218's swarm scenario in `src/tools/perf_check.gd` swaps its walker stand-ins for rats (a few hundred alive); its `swarm_tick`, `swarm_towers` and `swarm_enemies` lines stay inside `TICK_BUDGET_US` (8333 us); a moved baseline is accepted (`python tools/perf.py --accept`) only with the journal saying why
- Names.KEYS `rat`, `ENEMY_RAT`/`ENEMY_RAT.other` (rat/rats, rato/ratos), and `DESC_SWARMS` ('comes %d at a time' / 'chega %d de cada vez') in `Describe.enemy`; `Sfx.ENEMY_SOUNDS.rat` borrows `sfx/groan_runner` until 0284
- Drawn through 0120's placeholder road at the pack's small canvas (~24x16), forecast head included - placeholders until A047 is integrated by 0261
- Hashes: DATA moves; SIM should not (no rats in the determinism night) - if it does, find out why before accepting

## Done when

- [ ] `_task_0248_rats` in `src/tools/headless_v1.gd`: one wave member releases `cluster` rats on adjacent cells on one tick, the bodies sent match `Waves.size_of`, and a mine under the cluster kills more rats per unit of cost than a gun tower in the same lane
- [ ] `python tools/perf.py --report` prints the swarm lines with rats inside `TICK_BUDGET_US` and every other line inside its tolerance
- [ ] `python tools/shot.py 0248 rats` (a new scenario) opened and looked at: a cluster reads as a crowd, not a smear
- [ ] the Deliverables table of `implementation/backlog/packs/A047-rats.md` states the final geometry this task settled
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
