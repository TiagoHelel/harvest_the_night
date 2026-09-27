# 0012 - Debug overlay

- **Phase:** 0 - Foundation
- **Status:** done
- **Depends on:** 0005, 0006
- **Likely files:** src/ui/debug_overlay.gd

## Goal

The thing you actually want while tuning: what phase, what tick, what seed, how many entities and what the frame costs.

## Requirements

- Toggled by an input action, off by default, never in the release build path
- Shows phase, day, night, tick, seed, resource totals and live entity counts
- Shows ticks simulated per frame and the millisecond cost of the last tick batch
- Draws over everything and never steals mouse input

## Done when

- [ ] Toggling it does not move the determinism hash
- [ ] It shows the tick cost climbing when a hundred zombies are alive
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
