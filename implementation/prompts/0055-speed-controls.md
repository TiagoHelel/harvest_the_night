# 0055 - Double speed and skipping the night

- **Phase:** 3 - The full night
- **Status:** done
- **Depends on:** 0002, 0027
- **Likely files:** src/ui/night_hud.gd, src/core/sim.gd

## Goal

The semi-idle promise: if the defence is clearly going to hold, let the player say so and move on.

## Requirements

- 1x, 2x and 4x, implemented as ticks per frame - never as a changed tick rate
- Skip to the end simulates the rest of the night as fast as it can and shows the result
- A skipped night and a watched night give an identical outcome from the same state - this is the test of the whole tick design
- Speed is remembered across nights
- Skipping is refused while the house is under a lever's worth of hit points, because that night is worth watching

## Done when

- [ ] Watched and skipped nights from one seed produce the same hash
- [ ] 4x does not drop frames on a full board
- [ ] `headless_check` runs a night both ways and compares
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
