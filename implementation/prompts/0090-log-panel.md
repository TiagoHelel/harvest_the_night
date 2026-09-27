# 0090 - The log panel

- **Phase:** 6 - Sound and juice
- **Status:** todo
- **Depends on:** 0081, 0061
- **Likely files:** src/ui/log_panel.gd

## Goal

A short running account of what just happened, because at 4x speed the player will miss things.

## Requirements

- The last few events: a wave arriving, a structure lost, a crop ready, a craft finished
- Colour-coded by severity, with the alarming ones held longer
- It fades when nothing is happening and never covers the farm
- Events are emitted by core as data and formatted by the view
- A key expands it into a scrollable history for the night

## Done when

- [ ] A night at 4x is followable from the log alone
- [ ] It holds a bounded number of entries and cannot grow without limit
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
