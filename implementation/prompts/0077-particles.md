# 0077 - Particles

- **Phase:** 5 - Art and visual direction
- **Status:** todo
- **Depends on:** 0074, 0075
- **Likely files:** src/ui/particles.gd

## Goal

Fire, smoke, sparks, dust and the small amount of blood the design document allows - the difference between a hit and a hit that felt like one.

## Requirements

- Muzzle flash, impact spark, explosion, burning, smoke from the chimney and from wreckage, dust when something falls
- Pixel particles on the shared palette, not soft gradients
- A hard cap on live particles, and the cap is a setting
- Particles are view only: never in the state, never in the hash
- Blood is restrained, as section 18 asks

## Done when

- [ ] A busy wave stays inside the frame budget with particles on
- [ ] Turning them off does not change the outcome of a night
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
