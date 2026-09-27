# 0043 - The flamethrower tower

- **Phase:** 3 - The full night
- **Status:** todo
- **Depends on:** 0042
- **Likely files:** src/core/game_data.gd

## Goal

The reference sheet's second tower: expensive, short range, continuous area damage, and it burns oil.

## Requirements

- A cone in front of it rather than a single target
- Damage over time that keeps burning after the zombie leaves the cone
- Burn does not stack into absurdity: refresh the duration, do not add a second instance
- It consumes oil while firing and is much weaker without it
- Cost, range, cone angle, damage and burn duration are levers

## Done when

- [ ] A crowd walking through the cone takes the damage the levers claim
- [ ] Two flamethrowers on one zombie do not double the burn
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
