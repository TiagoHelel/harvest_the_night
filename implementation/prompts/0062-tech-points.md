# 0062 - Technology points

- **Phase:** 4 - Ten nights and progression
- **Status:** todo
- **Depends on:** 0061
- **Likely files:** src/core/tech.gd

## Goal

The currency of permanent improvement, and the thing that makes night 4 feel different from night 3.

## Requirements

- One point per night survived, plus bonus points for the conditions in data
- Points persist in the run save and are spent in the tech tree
- Points cannot be earned by replaying a night already survived
- The total available across ten nights is fixed and known - print it

## Done when

- [ ] Ten nights yield exactly the number of points the journal claims
- [ ] Replaying a survived night yields none
- [ ] Points survive a save and a reload
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
