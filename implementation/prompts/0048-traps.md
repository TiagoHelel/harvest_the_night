# 0048 - Mines and traps

- **Phase:** 3 - The full night
- **Status:** todo
- **Depends on:** 0042
- **Likely files:** src/core/towers.gd, src/core/game_data.gd

## Goal

The reference sheet's mine: no targeting, no upkeep, high damage, and then it is gone.

## Requirements

- Triggers on an enemy entering its cell, not on a timer
- High damage in a small radius, then it removes itself
- It is invisible to the player as a firing thing: no range circle, no target line
- A limited number armed per night, replenished by crafting
- Damage, radius and cost are levers

## Done when

- [ ] A mine under the choke point kills what the levers say it kills
- [ ] Two mines in adjacent cells do not chain into a fifty damage cascade - or they do, deliberately, and the journal says so
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
