# 0022 - Switching reality

- **Phase:** 1 - The first playable build
- **Status:** todo
- **Depends on:** 0006, 0021
- **Likely files:** src/ui/world_view.gd, src/core/phases.gd

## Goal

The same farm, a different world. Press the button and the day farm becomes the night map: same tiles, same buildings, new rules and a new light.

## Requirements

- The switch is a phase transition, not a scene change: the grid object is the same object
- Day and night tint, and a short transition between them
- Day-only actors leave and night-only actors arrive as part of the transition
- The player recognises the farm instantly: nothing moves, only the light and what is on it
- Switching is allowed from DAY only, and lands in PREPARATION

## Done when

- [ ] A building placed by day is in the same cell by night
- [ ] Switching twice returns to a day that is identical except for the day counter
- [ ] The transition is skippable and the game does not wait on it
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
