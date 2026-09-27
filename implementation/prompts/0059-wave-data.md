# 0059 - Waves as data

- **Phase:** 4 - Ten nights and progression
- **Status:** done
- **Depends on:** 0027, 0050, 0051, 0052
- **Likely files:** src/core/waves.gd, src/core/game_data.gd

## Goal

Before authoring ten nights, make a night a table. Composition, timing and spawn points become numbers a designer edits, not code.

## Requirements

- A night is a list of waves; a wave is a list of (enemy, count, spawn point, delay)
- Wave gaps and the delay before the first wave are per night
- Spawn points may differ per wave, so a night can come from two sides
- A night definition is validated at load: an unknown enemy id fails loudly
- Total enemy count and total reward per night are computable without running it

## Done when

- [ ] Editing a wave table changes the night with no code edit
- [ ] `validate()` catches a typo in an enemy id
- [ ] A summary of all ten nights can be printed headlessly
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
