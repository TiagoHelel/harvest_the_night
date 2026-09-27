# 0007 - The resource ledger

- **Phase:** 0 - Foundation
- **Status:** done
- **Depends on:** 0003
- **Likely files:** src/core/resources.gd

## Goal

One place that owns how much of everything the player has, so no later system invents its own counter.

## Requirements

- `add(state, id, n)`, `spend(state, id, n) -> bool`, `can_afford(state, cost) -> bool` where cost is a Dictionary
- `spend` is all-or-nothing: a cost of two things with only one affordable changes neither
- Negative balances are impossible; an attempt is a hard error in debug and a clamped no-op in release
- A running total of everything ever gathered, for the stats screen later
- Resources are the ones on the reference sheet: wood, stone, iron, food, fish, oil, wheat, corn, meat, gunpowder, money, energy

## Done when

- [ ] Spending more than you have returns false and changes nothing
- [ ] An atomic multi-resource cost either takes all of it or none
- [ ] `headless_check` covers both
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
