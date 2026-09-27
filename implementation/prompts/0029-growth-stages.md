# 0029 - Growth stages and watering

- **Phase:** 2 - The full day
- **Status:** todo
- **Depends on:** 0028
- **Likely files:** src/core/farming.gd

## Goal

A field you can read at a glance, and one small daily chore that rewards coming back.

## Requirements

- Four visible stages per crop, driven by the growth ticks already in data
- Watering a tile speeds growth by a lever percentage until the next night
- Unwatered is slower, never fatal - this is a cozy game, not a punishment
- Water comes from the pond and the well, with a range or a carry limit that is a lever
- Watering the whole field is one held input, not forty clicks

## Done when

- [ ] A watered and an unwatered tile planted together finish a measurable distance apart
- [ ] Holding the water input across a row waters the row once each
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
