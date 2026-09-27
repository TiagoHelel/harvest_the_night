# 0027 - Three waves, a result screen, and back to the farm

- **Phase:** 1 - The first playable build
- **Status:** todo
- **Depends on:** 0026, 0021
- **Likely files:** src/core/waves.gd, src/ui/result_screen.gd

## Goal

**The MVP checkpoint.** Three waves of basic zombies, a night that ends, a payout, and a day 2 that is better than day 1. If this is not fun, nothing after it will be.

## Requirements

- Three waves with a gap between them, all from data
- The night ends when the last zombie of the last wave is gone, or when the house falls
- A result screen showing what survived, what was killed and what it paid
- Surviving pays money and resources; losing costs part of the stock, and both numbers are levers
- Confirming the result returns to DAY with the day counter moved on

## Done when

- [ ] A human can play: gather, craft, build, fight, get paid, repeat - without the console open
- [ ] The whole first cycle takes about three minutes
- [ ] `headless_check` plays all three waves and asserts the payout
- [ ] Say in the journal whether it was fun, honestly, because that is the question this whole phase exists to answer
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
