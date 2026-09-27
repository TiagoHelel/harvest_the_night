# 0004 - Harden the headless check harness

- **Phase:** 0 - Foundation
- **Status:** done
- **Depends on:** 0002, 0003
- **Likely files:** src/tools/headless_check.gd, tools/verify.py

## Goal

Task 0002 shipped `headless_check.gd` with its own asserts, because the house rule is that a rule ships with its test. It has one bad failure mode: **a script error before the final `quit()` leaves the SceneTree running forever**, so a broken check hangs the backlog loop instead of failing it. Fix that, and finish the harness.

## Requirements

- A script error must end the run non-zero, not idle. Guard `_initialize()` so anything that escapes still prints and quits
- `verify.py` already bounds it with a timeout; keep that as the belt to this task's braces, and make the timeout message stay accurate
- Add the `GameData.validate()` asserts that task 0003 made possible
- Asserts stay grouped by the task that introduced them, one function each, so a failure names the design that moved
- No dependency on anything in `src/ui/`

## Done when

- [ ] Introducing a deliberate script error makes it exit non-zero within a second instead of hanging - test this, do not assume it
- [ ] It finishes in under 10 seconds
- [ ] It runs with no `.godot/` cache present
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
