# 0106 - The release checklist

- **Phase:** 8 - Ship the MVP
- **Status:** todo
- **Depends on:** 0105, 0099
- **Likely files:** implementation/RELEASE.md

## Goal

The list you run before publishing, written once, so nothing is remembered at the wrong moment.

## Requirements

- Every check with its command: verify, exports, save compatibility, the i18n checker, the perf budget, both builds smoke-tested
- Version bump, changelog, and a tag
- A known-issues section that is honest
- A rollback plan in one paragraph
- Run it once, end to end, and fix what it finds

- **Carried over from task 0103**: `python tools/verify.py` now takes 303
  seconds against its own `BUDGET_S = 300` and prints `(OVER BUDGET)`, which
  does not fail the run. Three rows are the whole of it: `script parse` at
  94s, `headless_check` at 92s and `input_check` at 72s. The parse row
  launches Godot once per script - 97 processes - and is the one that is
  overhead rather than work. Decide here whether the number moves, the suite
  gets faster, or the checklist runs the slow half separately. Raising the
  budget to meet the measurement without saying so is the one answer that is
  wrong.

## Done when

- [ ] Running the list top to bottom produces a publishable build
- [ ] The journal records what the first run of it found, because it will find something
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
