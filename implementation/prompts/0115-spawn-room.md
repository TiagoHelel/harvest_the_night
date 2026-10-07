# 0115 - Spawn ground that cannot be built shut

- **Phase:** 9 - v1.0 groundwork
- **Status:** todo
- **Depends on:** 0112
- **Likely files:** src/core/waves.gd, src/core/enemies.gd, src/core/building.gd, src/core/state.gd, assets/locale/strings.csv, src/tools/headless_v1.gd

## Goal

The plan suspects that fencing every cell of a spawn line makes that side's zombies vanish: `Enemies.spawn` returns 0 when no cell is free and `Waves.tick` counts the member as sent anyway. About seventeen fences would win a night. Prove it, and if it is real, no wave member is ever lost without a trace.

## Requirements

- Reproduce first, headless: in PREPARATION, `Building.place` a fence on every cell of `GameData.SPAWNS[0]` (ten cells on x=68), run night 1 to its end and compare `Waves.size_of(1, seed)` with `state["killed"]` plus `Entities.count`. Write the numbers in the journal whether or not the suspicion holds
- If it holds, pick one fix and say why: `Building.why_not` refuses the last free cells of a spawn region (a new `WHY_*` key, en and pt_BR rows in `assets/locale/strings.csv`, shown by the red ghost); or a member with nowhere to stand waits in `Waves.tick` without counting as sent; or it falls back deterministically to another cell or region
- Whatever is chosen draws from the run RNG only when it places somebody, exactly as `Enemies.spawn` does now
- No softlock: a member that never finds a cell must not hold the night open for ever. 0137's dawn will end nights, but this task cannot lean on it
- A save written with a region already sealed behaves by the same rule. A new state key gets a default in `initial()` and reconcile, with no `State.VERSION` bump: inside `wave` (already in `State.TABLES`) if it can live there, and a new nested Dictionary is listed in `State.TABLES` or `State.RUN_DATA`
- Check `SPAWNS[1]` (seven cells) and a part-blocked region too: spawning still picks only among free reachable cells, and `Enemies.spawn_cells` stays the one place that answers where one can stand (0157 adds regions on this rule)
- Hashes: the determinism scenario seals no region, so the rule alone changes nothing there - but `State.hash_of` hashes every key, so a new state key moves SIM by itself. If it moves, it is on purpose: accept it and write both numbers and why. A refusal key moves nothing; DATA does not move

## Done when

- [ ] `_task_0115_spawn_room` in `headless_v1`: with the east line built over as far as the rules now allow, night 1 run to its end accounts for every member - killed plus alive plus still waiting equals `Waves.size_of(1, seed)`
- [ ] The same night ends within a bounded number of ticks in the assert, whichever fix was chosen
- [ ] If a refusal was added, it reads in both languages and `python tools/i18n_check.py` passes
- [ ] The journal says whether the suspicion was real, with the before numbers
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
