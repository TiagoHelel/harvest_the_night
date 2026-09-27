# 0066 - Night 10 and the end of the run

- **Phase:** 4 - Ten nights and progression
- **Status:** done
- **Depends on:** 0060, 0058
- **Likely files:** src/core/phases.gd, src/ui/result_screen.gd

## Goal

**The MVP is complete here.** Beating the Giant ends the run with a summary that answers the design document's question.

## Requirements

- A run summary: days played, resources gathered, zombies killed, structures lost, the build that won
- The run is recorded to the profile and a new one can be started
- An option to continue past night 10 into 0070's endless mode
- It is a real ending, with a screen worth reaching

## Done when

- [ ] A full run from day 1 to the Giant can be played in one sitting
- [ ] The journal answers, honestly: after surviving the first night, did you want to go back to the farm and improve? That is the success criterion of the entire MVP
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
