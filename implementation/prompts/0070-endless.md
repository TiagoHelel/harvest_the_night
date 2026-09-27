# 0070 - Endless nights past ten

- **Phase:** 4 - Ten nights and progression
- **Status:** todo
- **Depends on:** 0066, 0059
- **Likely files:** src/core/endless.gd

## Goal

For the player who beat the Giant and wants to know how far the farm goes. Cheap to build, and it answers whether the loop holds past its authored content.

## Requirements

- Waves generated from a curve past night 10, seeded and reproducible
- The curve scales count and mix, never invents an enemy that does not exist
- A Giant every fifth night, scaling
- A best night reached, kept in the profile
- It is off the critical path: a menu option, not the default

## Done when

- [ ] Night 25 is generated and playable
- [ ] The same seed generates the same night 25 twice
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
