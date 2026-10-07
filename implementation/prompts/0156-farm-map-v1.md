# 0156 - The 1.0 farm map

- **Phase:** 11 - Calendar and seasons
- **Status:** todo
- **Depends on:** 0151
- **Likely files:** src/core/game_data.gd (FARM_MAP, MAP_LEGEND, checks), src/core/farm.gd, src/core/interact.gd, src/core/pathing.gd, src/app/save.gd, src/core/state.gd, src/ui/world_view.gd, src/ui/placeholder_art.gd, tools/goldens/, src/tools/shot.gd, src/tools/headless_v1.gd

## Goal

Every change the 1.0 farm needs on its map, made once so a save migrates once: ground for the new attack sides, the new ore, the big hardwood stumps, ponds with names, and room kept for the coop, the barn and the shipping bin.

## Requirements

- Spawn ground for the sides 0157 opens: a clear band of walkable cells near the north, west and south edges, away from the farmstead and about as far from the house by path as the east band (measure with `Pathing.distance`; the numbers go in the journal), with nothing on it that regrows
- Nodes under their final ids, so 0176 and 0177 change data only: copper, coal and gold nodes (e.g. `copper_ore`, `coal_seam`, `gold_ore`; gold deeper in the rock face) and 2x2 hardwood stumps (`hardwood_stump`, one thing over four cells with an `anchor`, as a building's footprint is kept); new `MAP_LEGEND` characters. Until those tasks give them `GATHERING` rows they are inert, impassable obstacles with no verb: check that `Interact`, `Pathing._through`, `Farm` and `Save._widen` accept an occupant with no table row
- Ponds by name: one anchor cell per water body in a `PONDS` table (the north-west pond, the forest pond, the south-east lake) and `Farm.pond_of(state, cell)` by flood fill over the state's own terrain, cheap enough to ask once per cast, so 0179 keys species by pond; no occupants
- Room kept clear in a `MAP_SITES` table: the coop and the barn near the workshop and the animals (room for footprints up to 7x4; 0183 decides the real ones) and the shipping bin by the porch (0189)
- `check_map`, `check_livestock` and `validate()` stay clean; `check_reachable` (which walks only `GATHERING` ids today) also covers the new node ids that have no row yet, so each can be stood beside; a new check that every spawn band cell is walkable map ground. `PONDS` and `MAP_SITES` go into `digest()`
- `State.VERSION` + 1 (6 after 0151's 5) with a step in `Save.migrations()` in the style of `_expand_farm_v1..3`: the new nodes, stumps and cleared bands laid onto a save only where its cell is empty map ground - never over a plot, a building, the house or anything the player placed; map trees and rocks leave the bands and sites only if they are untouched map props; path caches reset and `grid_version` bumped. Write `run-v6*.sav` after the bump (0151's `run-v5*.sav` is this step's input)
- The new nodes and the stump are drawn through 0120's placeholder road (tinted `ore`, `seam` and `stump` frames, the stump scaled over its 2x2) until A021 is integrated by 0204
- Hashes: SIM and DATA both move (the map is in `digest()` and in the state) - both numbers in the journal

## Done when

- [ ] `_task_0156_map_v1` in `src/tools/headless_v1.gd`: `GameData.validate()` is clean; every spawn band cell is walkable and `Pathing.reachable` on a new farm; each new node id is on the map; `Farm.pond_of` names three ponds and nothing on land
- [ ] The v5 golden steps up to v6 with every plot and every player-placed occupant where it was, the new nodes only on cells that were empty, and plays 600 ticks; every golden loads
- [ ] New shot scenarios standing at the north band, the new ore and a stump: `python tools/shot.py 0156 <them> --fhd`, opened
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
