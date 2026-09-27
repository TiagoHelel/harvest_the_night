# 0011 - input_check harness

- **Phase:** 0 - Foundation
- **Status:** todo
- **Depends on:** 0005
- **Likely files:** src/tools/input_check.gd

## Goal

The other half of the gate: drive real clicks and keys through the real UI with no human, so a refactor that breaks placing a tower is caught the same minute.

## Requirements

- Runs headless against the real scenes, synthesising `InputEventMouseButton` and `InputEventKey`
- A helper to click a world cell and one to click a named control
- Prints `N cases, M failed` and exits non-zero on failure
- Each case leaves the game in a known state for the next one
- It is wired into `verify.py` from this task on

## Done when

- [ ] It drives at least one full interaction end to end
- [ ] It fails loudly when a control it names is missing, rather than silently passing
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
