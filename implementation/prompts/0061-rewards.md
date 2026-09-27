# 0061 - Night rewards

- **Phase:** 4 - Ten nights and progression
- **Status:** done
- **Depends on:** 0059, 0007
- **Likely files:** src/core/rewards.gd

## Goal

Section 12: surviving pays money, resources and technology, and the payout is the reason to go again.

## Requirements

- The payout is computed from the night's data, not hardcoded per night
- A bonus for structures that survived intact, so defending well pays more than barely holding
- The result screen itemises it the way the design document shows
- Rewards go through the ledger
- Every multiplier is a lever

## Done when

- [ ] The same night defended two ways pays differently, in the right direction
- [ ] The itemised numbers add up to what the ledger received
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
