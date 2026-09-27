# 0065 - Losing a night costs you

- **Phase:** 4 - Ten nights and progression
- **Status:** todo
- **Depends on:** 0061
- **Likely files:** src/core/rewards.gd, src/ui/result_screen.gd

## Goal

Section 3 of the loop diagram: defeat takes part of the stock. It has to hurt enough to matter and little enough to continue.

## Requirements

- A lever's fraction of resources lost, with money and technology untouched
- Structures destroyed in the night stay destroyed
- The night can be retried; the day in between is not skipped
- The result screen says exactly what was lost
- Losing never ends the run in the MVP - it costs a day

## Done when

- [ ] Losing twice in a row leaves a farm that can still recover
- [ ] The itemised loss matches what the ledger actually lost
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
