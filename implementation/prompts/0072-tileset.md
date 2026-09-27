# 0072 - The farm tileset

- **Phase:** 5 - Art and visual direction
- **Status:** todo
- **Depends on:** 0071, 0013
- **Likely files:** tools/gen_sprites.py, sprites/terrain/

## Goal

Grass, soil, water, rock, path, wooden floor and fence, with edges that meet each other properly.

## Requirements

- Autotiling for grass to soil, grass to water and path edges
- Water animates: two or three frames, slow
- Soil has a tilled and a watered variant
- Small scattered detail tiles so the field is not a flat colour
- All of it from the ASCII maps, all regenerable

## Done when

- [ ] No visible seam anywhere on the farm
- [ ] Regenerating produces byte-identical files
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
