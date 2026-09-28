# 0071 - The two palettes

- **Phase:** 5 - Art and visual direction
- **Status:** done
- **Depends on:** 0014, 0022
- **Likely files:** tools/gen_sprites.py, src/ui/palette.gd

## Goal

Section 18: warm and cozy by day, blue and purple by night, from one set of sprites. The reference sheet is the target.

## Requirements

- One base palette, around 32 colours, sampled from `docs/reference-sheet.png`
- A day ramp and a night ramp, applied as a shader or a modulate, never as a second set of PNGs
- The night ramp keeps the farm recognisable: same shapes, different light
- Fire, lamps and the moon are the only warm things at night
- Both ramps are data and can be tuned without regenerating sprites

## Done when

- [ ] Switching reality changes nothing but the light, and the farm is instantly recognisable - the whole point of the design document
- [ ] A screenshot of each sits next to the reference sheet and holds up
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
