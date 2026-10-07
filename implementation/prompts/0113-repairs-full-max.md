# 0113 - Repairs mend to the real maximum

- **Phase:** 9 - v1.0 groundwork
- **Status:** done
- **Depends on:** 0112
- **Likely files:** src/core/repair.gd, src/core/building.gd, src/core/game_data.gd, src/ui/world_view.gd, assets/locale/strings.csv, src/tools/headless_v1.gd, src/tools/headless_check.gd

## Goal

Mending stops at the wrong number: the house comes back only to 100 when 'stout timbers' made it 140, and an upgraded tower only to its level-one hit points. A repair should put back what the thing really has when it is whole.

## Requirements

- `Repair.damage_at`: the house is missing `Phases.house_full(state) - house_hp`, not `GameData.HOUSE_HP - house_hp`
- A structure's maximum is its levelled one - `Building.entry_at(state, cell)`, the base row with `TOWER_LEVELS` laid over it - not `Building.entry_of(id)`, in `damage_at` and in the cap inside `Repair.apply`
- `per_hp_hundredths` shares a structure's price over the same levelled maximum, so a full mend of a level-3 tower costs `REPAIR_PERCENT` of its build cost like any other; or the journal says why the base hit points stay the divisor. Either way the cost of one full repair is asserted
- 'a full larder' (`repair_percent` 60, note `TECHNOTE_A_FULL_LARDER` 'mending costs two fifths less') reaches structures through `Tech.bonus` but the house branch of `per_hp_hundredths` ignores it. Decide whether the house gets the discount, make the code, the `note` in `TECH_TREE` and both languages of `TECHNOTE_A_FULL_LARDER` agree, and assert the decision. The `note` is inside `TECH_TREE`, which `digest()` hashes: rewording it moves DATA on purpose (accept it and write both numbers); leaving it alone moves nothing
- View: `world_view.gd` `_wear_of` tints by the base-table hp while `_is_hurt` uses `WorldView.levelled_stat`; make the tint read the levelled maximum too (view only)
- Asserts go in `headless_v1`. `Interact` offers repair through `Repair.can_mend`, so the verb follows the fix by itself - check rather than assume. An old assert that pinned the base maximum or price (`_task_0034_cooking`, `_task_0053_repair`, `_task_0057_structures` call `Repair`) is rewritten in place in `headless_check` with a comment pointing at 0113
- Run `python tools/autoplay.py` before and after: the robot repairs everything it can, so its nights may change. SIM can only move if the determinism scenario repairs (it does not) - say which happened

## Done when

- [ ] `_task_0113_repairs` in `headless_v1`: with 'stout timbers' owned, food enough and the house at 90 of 140, `Repair.apply_all` on a house cell puts back exactly 50 and `needs_repair` is then false
- [ ] A level-3 gun tower (placed and upgraded twice in PREPARATION, where 0132 will still allow it; the upgrades need 'true sights' then 'oiled works' owned - or set the occupant's `level` to 3) at 60 of 120 is mended to 120; a level-1 tower still stops at its table hp (60)
- [ ] The house-discount decision is asserted with and without 'a full larder', and `python tools/i18n_check.py` passes
- [ ] The journal has the autoplay table before and after
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
