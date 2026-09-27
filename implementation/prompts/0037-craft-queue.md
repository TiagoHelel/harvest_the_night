# 0037 - The workshop queue

- **Phase:** 2 - The full day
- **Status:** done
- **Depends on:** 0019, 0036
- **Likely files:** src/core/crafting.gd, src/ui/workshop_panel.gd

## Goal

Semi-idle in one feature: queue five things, walk away, come back to five things.

## Requirements

- A queue per production building with a length that is a lever
- Inputs are taken when an item starts, not when it is queued
- Cancelling a queued item that has not started refunds it in full
- The queue advances on the tick whether or not the player is looking
- The panel shows time remaining on the current item

## Done when

- [ ] Queue three barricades, walk to the pond and back, and three exist
- [ ] Cancelling the second of three leaves the first and the third intact
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
