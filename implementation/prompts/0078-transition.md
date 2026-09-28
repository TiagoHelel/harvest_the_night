# 0078 - The reality transition

- **Phase:** 5 - Art and visual direction
- **Status:** done
- **Depends on:** 0076
- **Likely files:** src/ui/transition.gd

## Goal

The moment the game is named after. Two seconds that say: same farm, different world.

## Requirements

- The light drains from warm to cold across the whole farm at once
- Day actors leave and night structures wake during it
- It is skippable, and it never blocks the simulation
- It plays in both directions, and coming back to the farm in the morning is the reward half
- Length is a lever and a setting

## Done when

- [ ] It is the clip you would put first in a trailer - say in the journal whether it is yet
- [ ] Skipping it lands in exactly the same state as watching it
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
