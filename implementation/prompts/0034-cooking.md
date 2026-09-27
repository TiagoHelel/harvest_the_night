# 0034 - Cooking: food and meat

- **Phase:** 2 - The full day
- **Status:** done
- **Depends on:** 0030, 0028
- **Likely files:** src/core/crafting.gd

## Goal

The kitchen from the reference sheet: raw crops and fish become food, which is what repairs and heals during the night.

## Requirements

- Recipes turning crops, fish and meat into food
- Food is the night's repair and heal currency, per the design document's resource table
- Cooked food is worth more than its inputs sold separately, or the kitchen has no reason to exist
- Meat comes from the farm animals on the reference sheet; keep it to a passive trickle, not an animal husbandry system

## Done when

- [ ] A cooked dish sells for more than its inputs - state the margin
- [ ] Food spent on repair during a night is taken through the ledger
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
