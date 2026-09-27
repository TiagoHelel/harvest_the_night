# 0008 - The farm grid

- **Phase:** 0 - Foundation
- **Status:** done
- **Depends on:** 0002, 0003
- **Likely files:** src/core/grid.gd, src/core/farm.gd

## Goal

The farm is one grid and it is the entire world. Day and night are the same tiles with a different job, which is the whole idea of the game.

## Requirements

- 40x18 tiles at 16px: about 1.3 screens wide and just over one tall, which is what the design document asks for
- A tile carries terrain (grass, soil, water, rock, path, floor) and at most one occupant id
- Regions marked out in data, not hardcoded coordinates: house, field, pond, wood, rock face, build space, shop
- Water and rock are not buildable; the house tile is never buildable
- `buildable(state, cell)` and `occupant(state, cell)` are the only way anything asks

## Done when

- [ ] The same grid serves the day screen and the night screen with no second copy
- [ ] A headless test places and removes an occupant and the grid is byte-identical afterwards
- [ ] `python tools/verify.py` prints PASS
- [ ] the determinism hash is unchanged, or the change is deliberate and both
      the old and the new number are in the journal

## House rules

`src/core/` holds the game rules: node-free, deterministic, advanced only by
`Sim.tick()` at a fixed rate. No nodes, no unseeded randomness, no clock reads,
no iterating an unordered Dictionary without sorting the keys first. `src/ui/`
draws and reads input and owns no rules.

Every number a designer might want to turn lives in `src/core/game_data.gd`
with `# LEVER` on it. A new rule ships with an assert in
`src/tools/headless_check.gd` and a new input path with a case in
`src/tools/input_check.gd` - same pass, not later.

Code, identifiers, comments and every player-facing string are in English.
Art is generated from ASCII maps in `tools/gen_sprites.py`: do not hand-author
PNGs, edit the map and regenerate.

`design.md` is the source of truth for intent and `docs/reference-sheet.png`
for the look. If this task contradicts either, follow the task and say so in
the journal.
