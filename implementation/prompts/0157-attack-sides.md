# 0157 - A new side every season

- **Phase:** 11 - Calendar and seasons
- **Status:** todo
- **Depends on:** 0156, 0115
- **Likely files:** src/core/game_data.gd (SPAWNS, SPAWN_SIDES, SIDES_BY_SEASON, check_nights), src/core/calendar.gd, src/core/endless.gd, src/core/enemies.gd, src/ui/build_mode.gd, src/ui/world_view.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/shot.gd

## Goal

The farm is surrounded one side at a time: spring comes from the east, summer adds the south-east, autumn the north, and in winter they come from everywhere.

## Requirements

- `SPAWNS` gains regions on 0156's ground - 2 north, 3 west, 4 south - each a line of border cells like the east one; a parallel `SPAWN_SIDES: Array` names them `east`, `south_east`, `north`, `west`, `south` (the forecast's words); indices 0 and 1 do not move
- `SIDES_BY_SEASON: Array  # LEVER`: spring `[0]`, summer `[0, 1]`, autumn `[0, 1, 2]`, winter all five; `Calendar.open_sides(date)`; validated (every index a real region, each season a superset of the one before); both new tables in `digest()`
- Generated nights deal their sides from the date's open sides only: `Endless._lay_out` alternates through them instead of through every region. 0153's boss row already comes from the east. Rewrite in place `_task_0070_endless`'s 'both sides, always' (nights 11, 13, 20, 25, 33 against `SPAWNS.size()`) as 'every side open on that date'
- `check_nights` gains the rule that a record names only sides open in its season; it knows a record's date from its index (`validate()` passes `NIGHTS`, 0151's `nights.py --check` the resolved year). Today's ten break it in spring (nights 2-10 use the south-east): exempt them with an explicit, commented allowance that 0271 deletes when it remaps them, and record the deviation in the journal
- Every new region has walkable, reachable cells on a new farm (`Enemies.spawn_cells`), and 0115's rule holds for each: building over a region never silently loses a wave member
- The flow field is swept from the house, so more regions should add no sweep: measure with `python tools/perf.py` (path_refresh inside `PATH_BUDGET_US` and the 40% tolerance) and put the numbers in the journal
- The build step's route preview (`Pathing.route_if_blocked`, `WorldView.show_route`) shows a route from every side open tonight
- Hashes: DATA moves (new tables). SIM should not - day 1 comes from the east as before - and if it does, explain it

## Done when

- [ ] `_task_0157_sides` in `src/tools/headless_v1.gd`: the open sides of Spring 1, Summer 1, Autumn 1 and Winter 1 are the table's; for dates 11-56 and two seeds every generated wave comes from an open side; every region has spawn cells on a fresh farm
- [ ] 0115's guarantee holds for regions 2-4, whichever fix 0115 chose: each region built over as far as the rules allow, a small hand-made record of a few walkers from it accounts for every member (killed, alive or waiting) and ends in bounded ticks - a few seconds for the three
- [ ] A `winter_build` shot scenario: `python tools/shot.py 0157 winter_build --fhd`, opened - a route from each of the five sides
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
