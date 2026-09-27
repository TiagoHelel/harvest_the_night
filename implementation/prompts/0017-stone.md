# 0017 - Rocks and stone

- **Phase:** 1 - The first playable build
- **Status:** done
- **Depends on:** 0016
- **Likely files:** src/core/gathering.gd

## Goal

The second resource, on the same machinery as wood, which is the test of whether that machinery was general enough.

## Requirements

- Rocks use the same gathering code with different data, not a second implementation
- Stone per rock and respawn delay are levers
- The rock face region respawns rocks; loose rocks on grass do not
- Adding stone takes a data entry and no new function

## Done when

- [ ] Adding a third gatherable would be a data entry only - say so in the journal after checking
- [ ] `headless_check` covers stone yield the same way as wood
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
