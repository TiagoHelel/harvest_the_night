# 0098 - Accessibility

- **Phase:** 7 - Shell and product
- **Status:** done
- **Depends on:** 0093, 0097
- **Likely files:** src/app/a11y.gd, src/ui/options_a11y.gd

## Goal

The cheap things that decide whether a lot of people can play it at all.

## Requirements

- Screen shake, flashing and particle density each separately reducible
- A larger UI scale and a high-contrast HUD option
- Colour-blind safe damage types: shape and icon, never colour alone
- Hold-to-act as an alternative to repeated pressing
- A slower game speed option that scales the tick budget, not the rules

## Done when

- [ ] Every damage type is identifiable in greyscale
- [ ] The slow speed option does not change the determinism hash
- [ ] The game is playable start to finish with shake and flashing off
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
