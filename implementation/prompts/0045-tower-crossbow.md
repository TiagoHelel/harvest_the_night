# 0045 - The auto-crossbow

- **Phase:** 3 - The full night
- **Status:** todo
- **Depends on:** 0042
- **Likely files:** src/core/game_data.gd

## Goal

The reference sheet's last tower: cheap, fast, low damage each, and it hits everything in a line.

## Requirements

- A bolt that pierces, losing a lever's fraction of its damage per target
- It fires along a line the player can see while placing it
- Cheap in iron, hungry for energy - the reason to build the generator
- Strong against the runner, weak against the tank, by construction

## Done when

- [ ] A line of five zombies takes the falloff the lever claims
- [ ] It is clearly the wrong answer against a tank and clearly the right one against a rush
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
