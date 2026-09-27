# 0038 - Production runs while you are elsewhere

- **Phase:** 2 - The full day
- **Status:** done
- **Depends on:** 0037, 0029
- **Likely files:** src/core/sim.gd

## Goal

The feeling the design document asks for: 'I built a machine and now I want to find out whether it works'.

## Requirements

- Crops, presses, generators and queues all advance on the same tick regardless of camera or player position
- No system may depend on being on screen - find and remove any that does
- Returning to a building shows what happened while away, not a silent jump
- A day spent entirely fishing still produces from everything else

## Done when

- [ ] A scripted day where the player never leaves the pond still finishes the crafting queue
- [ ] The tick cost of a fully built farm stays inside the budget
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
