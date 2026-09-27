# 0004 - Headless check harness

- **Phase:** 0 - Foundation
- **Status:** todo
- **Depends on:** 0002
- **Likely files:** src/tools/headless_check.gd

## Goal

The gate that every later rule hangs its test on: run the game's rules with no window, assert, and exit non-zero when one breaks.

## Requirements

- Runs as `godot --headless --path . --script res://src/tools/headless_check.gd`
- A tiny `expect(condition, message)` helper; the failure prints the message and the values, not just `false`
- Prints `N asserts, M failed` on the last line and exits 1 if M > 0
- First asserts cover the tick loop, the RNG stream and `GameData.validate()`
- No dependency on anything in `src/ui/`

## Done when

- [ ] It finishes in under 10 seconds
- [ ] Breaking a rule on purpose makes it exit 1 and name the assert
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
