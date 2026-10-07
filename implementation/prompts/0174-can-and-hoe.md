# 0174 - The can and the hoe by tier

- **Phase:** 12 - The day that pays
- **Status:** todo
- **Depends on:** 0173, 0167
- **Likely files:** src/core/farming.gd, src/core/player.gd, src/core/game_data.gd, src/ui/day_hud.gd, src/ui/world_view.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

The can and the hoe earn their tiers: one tile, then three, then five at a stroke, which turns watering a big field from a chore into a walk.

## Requirements

- The can's and the hoe's tiers carry an area (`# LEVER`: 1, 3 and 5 tiles, plan section 3.7): the faced tile and the ones beside it across the facing. Pick the shape, draw it, write it down
- `Farming._water` and `Player._do_instant` water every tile of the area that offers `water`, one unit of the can per tile, in a fixed order; a can short of water waters what it holds
- A better hoe tills the area through `Farming._till` in one action of the hoe's time, skipping cells 0167 refuses
- Decide whether the can's tier also raises its capacity (a per-tier `# LEVER` added in `Farming.can_capacity`), and fix the known bug: `day_hud.gd` prints the can against `GameData.WATER_CAN_CAPACITY` instead of `Farming.can_capacity(state)`, so 'full cans' never showed
- The highlight shows every cell the next press will touch (view only, `world_view.gd`)
- DATA moves; SIM moves only if the scenario uses an upgraded tool (it should not)

## Done when

- [ ] `_task_0174_area` in `src/tools/headless_v1.gd`: an iron can waters three dry plots in one press and spends three; a gold hoe (its tier written into the state - gold cannot be ordered before 0176) tills five grass cells and skips a path cell among them; the HUD's capacity equals `Farming.can_capacity` with 'full cans' bought
- [ ] `_case_0174_area` in `src/tools/input_v1.gd`: holding interact along a row with an iron can waters it in a third of the steps
- [ ] A new `can_area` scenario: `python tools/shot.py 0174 can_area --fhd` shows the area highlight; opened and looked at
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
