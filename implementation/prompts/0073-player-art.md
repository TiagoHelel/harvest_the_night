# 0073 - The player sprite

- **Phase:** 5 - Art and visual direction
- **Status:** todo
- **Depends on:** 0071, 0015
- **Likely files:** tools/gen_sprites.py, sprites/actors/

## Goal

Somebody worth watching walk around: four directions, walking, and the work verbs.

## Requirements

- Four facings, idle and walk, plus chop, mine, water, fish and craft
- 16x24, on the same palette as everything else
- A shadow, because without one the character floats
- The animation is driven by the core state's action, not by the view guessing
- Frame counts and speeds are data

## Done when

- [ ] Every verb in the game has an animation and none plays the wrong one
- [ ] Walking diagonally picks a facing and stays with it
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
