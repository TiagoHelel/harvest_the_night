# 0003 - game_data.gd, the one file of levers

- **Phase:** 0 - Foundation
- **Status:** todo
- **Depends on:** 0001
- **Likely files:** src/core/game_data.gd

## Goal

Every number a designer would want to turn, in one file, before there are numbers scattered across ten.

## Requirements

- Sections: time, crops, gathering, prices, recipes, buildings, towers, enemies, waves, rewards
- `# LEVER` on every balance dial, with the unit and a sane range in the comment
- Data only: no branching, no node references, no logic
- Ids are `StringName` constants, never bare strings at the call site
- A `validate()` that cross-checks every id a recipe, wave or building refers to

## Done when

- [ ] Changing the wheat growth lever changes growth and nothing else
- [ ] `headless_check` calls `validate()` and it passes
- [ ] A recipe pointing at a resource that does not exist fails `validate()` with the offending id in the message
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
