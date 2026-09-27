# 0076 - Night lighting

- **Phase:** 5 - Art and visual direction
- **Status:** todo
- **Depends on:** 0071, 0022
- **Likely files:** src/ui/lighting.gd

## Goal

The half of the reference sheet that sells the whole idea: the same farm, lit by the moon and by what is burning.

## Requirements

- A CanvasModulate for the night ramp and real 2D lights on top
- Lit: house windows, braziers, tower muzzle flashes, fires, the mortar's blast
- Light is cosmetic: it never changes a rule or the hash
- A quality setting, because lights are what will cost frames
- The moon gives a soft global fill so the farm is never unreadable

## Done when

- [ ] The night screenshot sits next to the reference sheet and holds up
- [ ] Turning lighting off changes nothing about the outcome of a night
- [ ] Frame time on a full board stays inside the budget with lights on
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
