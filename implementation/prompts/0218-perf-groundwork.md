# 0218 - Room for more fields and more bodies

- **Phase:** 13 - Weapons of the night
- **Status:** done
- **Depends on:** 0196
- **Likely files:** src/core/pathing.gd, src/core/entities.gd, src/core/towers.gd, src/tools/perf_check.gd, tools/perf.py, tools/perf_baseline.txt, src/tools/headless_v1.gd

## Goal

Nothing changes for the player. The decoy, the bait, the digger and the rat swarm are coming, and today every wall placed re-sweeps every path field and every tower scans every zombie; make room before adding to either, with the game playing exactly as it does now.

## Requirements

- A named-field registry in `Pathing`, in code (a const table and one accessor such as `Pathing.field(state, name)`): a field is registered with its seeds, its cost rule and the state keys it is stored under, and is built on first request for the current `grid_version`, never on a rebuild nobody asked for. Today's three (`flow`, `flow_open`, `flow_hunt` and their `*_cost` arrays, under `flow_version`) keep being built eagerly in `refresh` exactly as now, because those keys are folded into SIM. The registry is for 0224's lure field and 0250's digger field, which add their own storage keys (and move SIM) then
- `Entities.ids` stops sorting on every call, on the strength of an asserted invariant: ids are handed out ascending and never reused (`next_entity_id`), so the table's own order is already ascending - assert it after spawns, kills, `Enemies.withdraw` and a save round trip (if a loaded table does not keep the order, sort it once where the save is read, e.g. `State.reconcile`). No static cache shared between states
- A spatial bucket for `Towers._acquire`, built once per `Towers.tick` as a local (never stored in the state) from the entity cells, so a tower looks only at the buckets its reach touches. It must pick exactly what the full scan picks for every `TARGETING` mode, ties to the lowest id included; `acquire_for` keeps working for the tests
- Both hashes unchanged is the bar. `State.hash_of` folds every state key, caches included, so nothing here may add a key to a new game's state. If that proves impossible, prove play identical (kills, house HP and every entity cell at fixed ticks of one seeded night, before and after) and record both numbers in `implementation/PROGRESS.md`
- A swarm scenario in `src/tools/perf_check.gd`: a few hundred walkers (the rat swarm's stand-in until 0248) against the worst case's towers, with its own `PERF` lines (e.g. `swarm_tick`, `swarm_towers`, `swarm_enemies`) and a `COUNT` of bodies. `PerfNames` is unchanged: no system is added
- The swarm must sit inside `TICK_BUDGET_US` (8333 us), and `tools/perf.py` holds only `night_tick`, `day_tick` and `path_refresh` to a budget today: add `swarm_tick` to that list so the bar is enforced. If it does not fit, write down what it would take rather than shrinking the swarm
- Accept the new baseline with `python tools/perf.py --accept` and say in the journal why each number moved

## Done when

- [ ] `_task_0218_perf_ground` in `src/tools/headless_v1.gd` asserts the bucketed acquire equals the full scan over a seeded crowd for all four targeting modes, `Entities.ids` is ascending after spawns, kills and a save round trip, and a registered field is not built until it is asked for
- [ ] `python tools/perf.py --report` shows `night_towers` below its baseline at the start of this task (1028 us when this was written) on the old worst case, and `python tools/perf.py` passes with `swarm_tick` inside the tick budget
- [ ] The journal has the perf table before and after
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
