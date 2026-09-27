# 0074 - Zombie sprites

- **Phase:** 5 - Art and visual direction
- **Status:** todo
- **Depends on:** 0071, 0050, 0051, 0052
- **Likely files:** tools/gen_sprites.py, sprites/enemies/

## Goal

Four enemies that are told apart at a glance in a dark field at 480x270, which is the only test that matters.

## Requirements

- Basic, runner, tank and breaker, distinct in silhouette before colour
- Walk, attack and death for each
- The Giant, larger, with its telegraph as a distinct pose
- A rim light so they read against the night ramp
- Silhouette test: all five in black at 100% zoom must still be distinguishable

## Done when

- [ ] The silhouette test passes - put the image in the journal
- [ ] A screenshot of a mixed wave is readable at native resolution
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
