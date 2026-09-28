# 0075 - Buildings and towers

- **Phase:** 5 - Art and visual direction
- **Status:** done
- **Depends on:** 0071, 0042
- **Likely files:** tools/gen_sprites.py, sprites/buildings/

## Goal

The house, the workshop, the press, the generator, the shop, and every tower at its three levels.

## Requirements

- Each tower reads as its function: the reference sheet's shapes are the brief
- Three visible levels per tower, recognisably the same tower
- Damaged and destroyed states for everything that can be hit
- Firing frames for the towers that fire
- The house is the landmark: the biggest, warmest thing on the farm, by day and by night

## Done when

- [ ] A level 1 and a level 3 tower are told apart instantly
- [ ] A damaged wall reads as damaged without a health bar
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
