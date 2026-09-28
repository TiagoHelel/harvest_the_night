# 0103 - Crash and error reporting

- **Phase:** 8 - Ship the MVP
- **Status:** done
- **Depends on:** 0010
- **Likely files:** src/app/crash.gd

## Goal

When it breaks on someone else's machine, get enough to fix it without them.

## Requirements

- A handler that writes state, seed, tick, phase and the last log lines to `user://crash/`
- A dialogue offering the file's location rather than vanishing
- The run save is preserved, not overwritten by the crash
- No personal data in the report - say what is in it
- It never sends anything anywhere by itself

## Done when

- [ ] A deliberate crash produces a report with the seed and the tick
- [ ] The run is still loadable afterwards
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
