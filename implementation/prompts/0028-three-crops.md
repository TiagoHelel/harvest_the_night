# 0028 - Corn and carrot

- **Phase:** 2 - The full day
- **Status:** todo
- **Depends on:** 0018
- **Likely files:** src/core/farming.gd, src/core/game_data.gd

## Goal

Three crops with a real choice between them: fast and cheap, slow and valuable, and one that feeds the defence.

## Requirements

- Wheat, corn and carrot, differing in growth time, sale price and what they feed into
- A crop is a data entry; adding a fourth takes no code
- Seed cost and sale price are set so no crop strictly dominates - show the arithmetic in the journal
- Corn is the defence crop: it is what gunpowder and rations come from later
- The planting menu shows time to grow and price per tick of growth

## Done when

- [ ] A fourth crop is one dictionary entry - check it and say so
- [ ] No crop is the right answer at every money level
- [ ] `headless_check` asserts each crop's yield and timing
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
