# 0116 - The mortar and the flamethrower, empty and upgraded

- **Phase:** 9 - v1.0 groundwork
- **Status:** todo
- **Depends on:** 0112
- **Likely files:** src/core/towers.gd, src/core/ammo.gd, src/core/game_data.gd, src/tools/headless_v1.gd, src/tools/headless_check.gd

## Goal

Two towers may not do what their tables say. An empty mortar may lob a rock that hits nobody, and the flamethrower may ignore the tree's damage and range bonuses while burning two incendiary rounds a second. Reproduce each and fix only what is real.

## Requirements

- Mortar: `Towers._fire` makes an unarmed shot `SHAPE_SINGLE` but leaves it ballistic, and `_advance_projectiles` lands a ballistic shot with `_land_at(state, shot, cell)` and no target, so a single-shape landing hits nobody. Reproduce through `Towers.tick`: a mortar placed in PREPARATION, a walker standing in range beyond `min_range`, the gunpowder pool empty, ticks until the shell lands. The seams `land_for_test`/`land_at_for_test` always build an armed shot with the entry's shape, so they cannot show it; give one an `armed` argument if a seam helps
- If real, the empty shell deals `Ammo.weak_damage` to what it lands on - the walker on the aimed cell or the target it was fired at, decide - and never 0: out of ammunition is a worse shot, never a silent tower (0035)
- Flamethrower: `_burn_cone` reads `entry["damage"]` and `entry["range"]` raw while `_acquire` uses `reach_of`; with 'long barrels' it can pick a target one tile past its cone, spend a round and hit nothing. Use `Towers.damage_of(state, entry, armed)` and `reach_of(state, entry)`, and decide whether `tower_damage_percent` scales `burn_damage` too
- `ammo_every_ticks` (2 s on the flame tower) is read by nothing: `Ammo.spend` runs on every cone, twice a second (`reload_ticks` is `SECONDS / 2`). Charge one round per `ammo_every_ticks` of firing, the countdown on the occupant dictionary without `Farm.touch`, defaulting when an old save has no such key
- Mark `ammo_every_ticks` `# LEVER: ticks, 1-4 seconds worth`; `check_defences` refuses one on an entry without `ammo` or shorter than its `reload_ticks`
- New asserts go in `headless_v1`. An old assert that encoded a bug (`_task_0035_ammunition`, `_task_0043_flame`, `_task_0044_mortar` are where to look) is rewritten in place with a comment pointing at 0116
- Run `python tools/autoplay.py` before and after (its policies build mortars); SIM moves only if the determinism scenario touches these towers (it builds gun towers, which use no ammunition, and walls) - say which. DATA moves only if a table value changes; a `# LEVER` comment moves nothing

## Done when

- [ ] `_task_0116_ammo` in `headless_v1`: an unarmed mortar shell landing on a walker takes `Ammo.weak_damage` of the mortar's damage off it (40 -> 12 at `EMPTY_DAMAGE_PERCENT` 30)
- [ ] With 'long barrels' a flame tower's cone hits a walker at range + 1; with 'true sights' (`tower_damage_percent` 120) the cone deals `Towers.damage_of` - assert it on the level-3 flame row (damage 5 -> 6), because level one's 3 rounds back to 3 in integer arithmetic
- [ ] A flame tower firing for 10 s on a full pool spends 5 rounds (10 s / `ammo_every_ticks`), not 20
- [ ] The journal says which of the three suspicions were real, with the autoplay table before and after
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
