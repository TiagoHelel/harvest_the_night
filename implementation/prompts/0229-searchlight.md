# 0229 - The searchlight

- **Phase:** 13 - Weapons of the night
- **Status:** todo
- **Depends on:** 0196, 0132, 0226
- **Likely files:** src/core/light.gd (new), src/core/game_data.gd, src/core/towers.gd, src/core/ability.gd, src/core/combat.gd, src/ui/lighting.gd, src/ui/names.gd, src/ui/describe.gd, assets/locale/strings.csv, src/tools/headless_check.gd, src/tools/headless_v1.gd

## Goal

A powered lamp that lights the ground around it and lets the towers in its light see a tile further - and the moment light becomes a rule that the wraith and the fog will read (plan section 5).

## Art

What this task puts on screen will be dressed by Codex art pack(s) A041
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- Id `searchlight`: a `DEFENCES` row with no `reload_ticks` (it does not shoot) and no `damage` (so no `Sfx.TOWER_SOUNDS` entry), an `energy_draw`, a `light_tiles` LEVER (3-6), a cost in iron and copper (0176) and `season` winter (0193's field). Breakers hunt it like anything built. `check_defences` refuses a light with `light_tiles` of zero; a new constant (the porch radius, the reach bonus) goes into `GameData.digest()`
- Light is a core rule in one place (e.g. `src/core/light.gd`): `Light.is_lit(state, cell)` is true on searchlight cells, in the flare's area while it burns (`Ability.flare_at`), on the cells of burning enemies (`Combat.is_burning`) and on the porch (a LEVER radius round the house door). 0252 and 0256 read it; `lighting.gd` may draw from it, never the other way round
- Searchlight cells are cached against `grid_version`, like `Towers._towers` (new state keys: SIM moves; a Dictionary cache goes in `State.TABLES` or `RUN_DATA`); the flare and the fires are asked fresh. `Light` is asked, never ticked - if it grows a `tick`, it goes in `PerfNames` and `perf_check`
- A tower standing in light reaches +1 (LEVER): `Towers.reach_of` learns the tower's cell (or `_acquire` passes it) - move every caller: `_acquire` (0218's bucketed version), `acquire_for`, the old asserts that call `reach_of` in `headless_check.gd`, and any range drawing the view gained (0131's cursor)
- Needs power, degraded never dead like the rest of `Power`: on a short farm the light shrinks (e.g. by a tile) instead of going out; decide and assert
- `TOWER_LEVELS` 1-2 for `searchlight` (a wider light), refused past its last row by 0226's fix to `Building.why_not_upgrade`
- `Names.KEYS` `DEF_SEARCHLIGHT`, a `Describe.defence` line, strings in both languages; drawn through the placeholder road (32x48 per level and state, a `light_xy` point) with the beam in code, until A041 is integrated by 0240
- SIM and DATA: record both

## Done when

- [ ] `_task_0229_light` in `src/tools/headless_v1.gd` asserts the lit cells of each source (a searchlight, the flare, a burning zombie, the porch), a gun tower in light acquiring one tile further than one in the dark, a short farm shrinking the light, and the cache rebuilding when a searchlight goes up or comes down
- [ ] The Deliverables table of `implementation/backlog/packs/A041-searchlight.md` states the final geometry this task settled
- [ ] `python tools/shot.py 0229` captures of a lit and an unlit tower line at night, opened and looked at
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
