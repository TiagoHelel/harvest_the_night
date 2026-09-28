# 0101 - Onboarding in seven lines

- **Phase:** 8 - Ship the MVP
- **Status:** done
- **Depends on:** 0041, 0097
- **Likely files:** src/core/tutorial.gd

## Goal

A stranger reaches night 1 and understands the loop, with no more text than the design document allows.

## Requirements

- Seven lines, total, across the whole first day
- Each appears on the thing it describes
- The reality switch is explained by showing it, not by describing it
- Every line is translated
- Watch someone play it and write down where they stopped

## Done when

- [ ] A first-time player reaches the end of night 1 without being told anything out loud
- [ ] The journal names where they hesitated, because that is the finding
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
