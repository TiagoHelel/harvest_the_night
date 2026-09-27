# 0068 - A balance sweep over the ten nights

- **Phase:** 4 - Ten nights and progression
- **Status:** todo
- **Depends on:** 0067
- **Likely files:** tools/balance.py, implementation/BALANCE.md

## Goal

Use the autoplayer: find the nights that are trivial, the ones that are impossible, and the levers that are doing nothing.

## Requirements

- Sweep the important levers across a range and record the win rate per night
- A written report with the curve, the outliers and a recommendation per lever
- Apply the recommendations and re-run
- A lever that changes nothing across its whole range is reported as dead weight
- The determinism hash will move: record both numbers

## Done when

- [ ] No night has a win rate of 100% or 0% across every policy
- [ ] The report is in the repository and the applied changes are in game_data
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
