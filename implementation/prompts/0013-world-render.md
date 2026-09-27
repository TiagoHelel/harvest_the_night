# 0013 - The world renders

- **Phase:** 1 - The first playable build
- **Status:** todo
- **Depends on:** 0008
- **Likely files:** src/ui/world_view.gd, scenes/World.tscn

## Goal

Draw the grid the rules own, with a camera that shows the farm the way the reference sheet does.

## Requirements

- A TileMapLayer for terrain and a sorted layer for occupants and actors
- The camera is fixed vertically and pans only as far as the 40 tile width needs; no free zoom
- The view reads the core state and never writes to it
- Redraw is driven by a dirty flag, not rebuilt every frame
- Placeholder colour blocks are fine here - 0014 brings the sprites

## Done when

- [ ] The farm regions are all visible and recognisable on screen
- [ ] Panning to both edges shows no gap or repeated column
- [ ] Moving the camera does not move the determinism hash
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
