# 0021 - The day HUD

- **Phase:** 1 - The first playable build
- **Status:** todo
- **Depends on:** 0007, 0006
- **Likely files:** src/ui/day_hud.gd

## Goal

The bar across the top of the reference sheet: what day it is, what you have, and the button that starts the night.

## Requirements

- Day counter, money, and the resources that matter, laid out like section 14 of the design document
- A resource that changes flashes briefly so a gain is visible without watching the number
- The night button sits bottom right and says what it will do
- The HUD reads state and holds none of its own
- It survives a window resize at every supported integer scale

## Done when

- [ ] Gathering wood updates the HUD the same tick
- [ ] The night button is reachable by keyboard as well as mouse
- [ ] `input_check` presses it
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
