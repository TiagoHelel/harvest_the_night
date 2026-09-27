# 0046 - Fences and walls

- **Phase:** 3 - The full night
- **Status:** todo
- **Depends on:** 0023
- **Likely files:** src/core/building.gd, src/core/pathing.gd

## Goal

The other half of a tower defence: making the zombies walk where you want them to.

## Requirements

- A fence is cheap wood with low hit points; a wall is stone and slow to break
- Walls change the flow field, and the field is rebuilt when one is placed or destroyed
- A wall cannot fully seal the house: if every path is blocked, zombies attack the nearest wall instead of standing still
- Placing shows the path the zombies will take afterwards
- Hit points and cost are levers

## Done when

- [ ] Walling a lane visibly reroutes the next wave
- [ ] Sealing the farm completely makes them break in rather than freeze
- [ ] The field rebuild cost stays inside the budget with fifty walls
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
