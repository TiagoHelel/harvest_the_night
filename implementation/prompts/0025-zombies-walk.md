# 0025 - Zombies walk to the house

- **Phase:** 1 - The first playable build
- **Status:** done
- **Depends on:** 0022, 0008
- **Likely files:** src/core/enemies.gd, src/core/pathing.gd

## Goal

Something to shoot at. Zombies come in from the edges and head for the farmhouse, and the house has hit points.

## Requirements

- A flow field computed once from the house over the walkable grid, not A* per zombie - it is cheap, it is deterministic and it will hold a hundred of them
- The field is recomputed only when the grid changes
- Spawn points are edge cells in data; spawn order and timing come from the seeded RNG
- Reaching the house deals damage and removes the zombie
- House hit points are a lever and hitting zero ends the night

## Done when

- [ ] Fifty zombies pathing costs under a millisecond a tick
- [ ] Two runs from one seed produce the same zombie positions at tick 1000
- [ ] A zombie with no path at all stands still rather than crashing
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
