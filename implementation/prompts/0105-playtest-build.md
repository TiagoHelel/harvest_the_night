# 0105 - A playtest build

- **Phase:** 8 - Ship the MVP
- **Status:** done
- **Depends on:** 0100, 0103
- **Likely files:** tools/playtest.py

## Goal

A build to put in front of someone, with the instrumentation to learn something from it.

## Requirements

- A build flag that turns on local session logging: nights reached, time per day, what was built, where the run ended
- The log is a local file the player can read and send, never an upload
- A one-page note for the tester: what to try, what to ignore, what to report
- An in-game feedback key that timestamps a note into the log
- It is obvious it is a playtest build

- **Carried over from task 0101**: watch a first-time player through
  day one and night one and write down where they stopped. 0101 built
  the seven lines and measured which four a player clears without
  reading; the three that have to be read - the stall, putting a
  defence down, and sending for the night - are what to watch.

## Done when
- [ ] The journal names where the first-time player hesitated on day
      one, because that is the finding task 0101 could not make

- [ ] A session produces a readable log
- [ ] `tools/playtest.py` summarises a folder of logs into the questions that matter
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
