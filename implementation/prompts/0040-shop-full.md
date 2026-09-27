# 0040 - The shop grows

- **Phase:** 2 - The full day
- **Status:** todo
- **Depends on:** 0020, 0028
- **Likely files:** src/core/shop.gd, src/ui/shop_panel.gd

## Goal

Somewhere for money to go: all three seeds, materials when you are short, and the first upgrades.

## Requirements

- Seeds for all three crops, and materials at a markup over their sale price
- Buying materials is always worse than gathering them, so money cannot replace playing
- A small daily stock that refreshes, so the shop cannot be drained into an exploit
- Prices in game_data, every one a lever
- Buy and sell are two tabs, not two shops

## Done when

- [ ] Buy-then-sell on the same item loses money at every price
- [ ] Stock refreshes once per day and not once per visit
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
