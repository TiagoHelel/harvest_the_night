# 0039 - The day clock and dusk

- **Phase:** 2 - The full day
- **Status:** todo
- **Depends on:** 0006, 0021
- **Likely files:** src/core/phases.gd, src/ui/day_hud.gd

## Goal

Time passing, without taking away the design document's promise that the player switches reality when they want to.

## Requirements

- A day is a lever's worth of ticks and the HUD shows it as a clock or a sun
- The light warms and then cools across the day
- At dusk the night button starts asking to be pressed; it does not press itself
- Past dusk the day keeps running, with a gentle nudge rather than a penalty
- Time does not pass in menus

## Done when

- [ ] A player who ignores the clock entirely is not punished for it
- [ ] The clock stops in the shop panel and resumes on close
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
