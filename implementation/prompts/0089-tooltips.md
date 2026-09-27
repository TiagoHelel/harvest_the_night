# 0089 - Tooltips

- **Phase:** 6 - Sound and juice
- **Status:** todo
- **Depends on:** 0081
- **Likely files:** src/ui/tooltip.gd

## Goal

Every cost, stat and icon explains itself, so the game does not need a manual.

## Requirements

- A hover tooltip on resources, structures, recipes, tech nodes and enemies
- It shows the numbers from game_data, never a copy of them
- A short delay before it appears and none before it moves to the next
- It never leaves the screen edge
- Keyboard focus shows the same tooltip as hover

## Done when

- [ ] Every interactive element has one
- [ ] Changing a lever changes the tooltip with no other edit
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
