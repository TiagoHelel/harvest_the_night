# 0044 - The mortar

- **Phase:** 3 - The full night
- **Status:** done
- **Depends on:** 0042
- **Likely files:** src/core/game_data.gd

## Goal

The long shot: slow, expensive, splash damage, and it cannot hit what is next to it.

## Requirements

- A minimum range as well as a maximum - this is what makes placement a decision
- A shell with real flight time that lands where the target was aimed, not where it ended up
- Splash with falloff from the centre
- It consumes gunpowder per shot
- Minimum range, flight time, radius and falloff are levers

## Done when

- [ ] A zombie that walks out of the blast between firing and landing survives - and that reads as fair
- [ ] Splash damage at the edge is the falloff the lever claims
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
