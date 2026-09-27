# 0018 - Wheat: till, plant, grow, harvest

- **Phase:** 1 - The first playable build
- **Status:** todo
- **Depends on:** 0015, 0007, 0006
- **Likely files:** src/core/farming.gd

## Goal

The crop cycle, which is the semi-idle heart of the day: do a thing, go away, come back to something better.

## Requirements

- Four verbs on a soil tile: till, plant, (wait), harvest
- Growth advances on the tick during DAY only, never during NIGHT
- Growth stages are data, so the sprite can follow them later
- A planted tile survives the night and keeps growing the next day
- Harvest yields wheat through the ledger and returns the tile to tilled soil

## Done when

- [ ] Planting, ending the day, surviving a night and returning shows growth unchanged over the night and resumed after it
- [ ] The growth lever changes the number of ticks and nothing else
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
