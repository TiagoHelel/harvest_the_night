# 0057 - Structures take damage and die

- **Phase:** 3 - The full night
- **Status:** done
- **Depends on:** 0046, 0052
- **Likely files:** src/core/combat.gd, src/core/building.gd

## Goal

Losing things. A structure that breaks should be a small disaster the player watched happen.

## Requirements

- Every structure has hit points and a visible damage state
- Destruction frees the cell, rebuilds the flow field and leaves rubble that clears by morning
- Damaged structures survive into the next day at their current hit points
- A repair cost that is cheaper than rebuilding, so repairing is the right move
- Nothing in the state dangles after a structure dies

## Done when

- [ ] Destroying a wall mid-wave reroutes the zombies the same tick
- [ ] A structure at 1 hit point is still working, and looks wounded
- [ ] A night of heavy losses leaves a morning that is still playable
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
