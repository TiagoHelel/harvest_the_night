# 0006 - The phase machine: day, preparation, night, result

- **Phase:** 0 - Foundation
- **Status:** todo
- **Depends on:** 0002, 0003
- **Likely files:** src/core/phases.gd, src/core/sim.gd

## Goal

The loop the whole game is: DAY to PREPARATION to NIGHT to RESULT and back to DAY, owned by the rules rather than by a screen.

## Requirements

- An enum in core plus `state.phase`, `state.day` and `state.night`
- Transitions are functions on the state, not signals: `Phases.begin_night(state)` and friends
- DAY and NIGHT both advance by the same `Sim.tick`; only what ticks inside them differs
- PREPARATION is the build step between pressing the night button and the first zombie: the clock does not run and nothing attacks
- RESULT computes the payout and is the only place the day counter moves

## Done when

- [ ] A headless run walks DAY, PREPARATION, NIGHT, RESULT, DAY with no UI loaded
- [ ] The day counter increments exactly once per cycle
- [ ] Crops do not grow during NIGHT and zombies do not spawn during DAY
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
