# 0024 - The shooting tower

- **Phase:** 1 - The first playable build
- **Status:** todo
- **Depends on:** 0023
- **Likely files:** src/core/towers.gd

## Goal

The first thing that fights for you: cheap, single target, medium range, fires by itself.

## Requirements

- Range, rate of fire, damage and cost are levers
- Targeting is deterministic: nearest to the house, ties broken by entity id, never by iteration order
- It fires on the tick, and reload is counted in ticks
- A projectile with travel time, not an instant hit - the night should be watchable
- It does nothing at all during DAY

## Done when

- [ ] Two runs from the same seed fire at the same targets on the same ticks
- [ ] A tower with nothing in range costs no measurable time per tick
- [ ] Halving the rate of fire lever halves the shots in a fixed number of ticks
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
