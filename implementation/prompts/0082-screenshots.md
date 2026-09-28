# 0082 - Screenshots, and actually looking at them

- **Phase:** 5 - Art and visual direction
- **Status:** done
- **Depends on:** 0005, 0078
- **Likely files:** src/tools/shot.gd, implementation/shots/

## Goal

A command that puts the game in a known state and takes the picture, so a visual change can be checked instead of hoped for.

## Requirements

- `shot.gd` takes named scenarios: farm at noon, farm at dusk, a wave mid-fight, the result screen, the tech tree
- It runs headless and writes PNGs under `implementation/shots/<id>/`
- The scenario is built from a seed and a scripted state, so two runs give the same picture
- The runner loop is updated to say: after a visual task, take the shots and look at them

## Done when

- [ ] One command produces the whole set
- [ ] The set is recognisably the game on the reference sheet
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
