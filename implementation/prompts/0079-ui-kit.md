# 0079 - Resource icons and the UI kit

- **Phase:** 5 - Art and visual direction
- **Status:** todo
- **Depends on:** 0071, 0021
- **Likely files:** tools/gen_sprites.py, sprites/ui/

## Goal

The bottom half of the reference sheet: an icon per resource, and the panels, frames and buttons they sit in.

## Requirements

- One 16x16 icon per resource, in the reference sheet's style
- Nine-slice panel, button in its four states, tab, slider, checkbox, tooltip frame
- Icons are told apart at native resolution without their labels
- The same kit serves the day HUD, the night HUD, the shop and the tech tree
- All generated, all regenerable

## Done when

- [ ] Every resource in game_data has an icon and no icon is orphaned
- [ ] The icon set laid out in a row is recognisable against the reference sheet
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
