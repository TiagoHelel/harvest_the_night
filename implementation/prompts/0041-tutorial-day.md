# 0041 - The first day teaches itself

- **Phase:** 2 - The full day
- **Status:** todo
- **Depends on:** 0039, 0040
- **Likely files:** src/core/tutorial.gd

## Goal

Day 1 should teach chop, plant, craft, build and the night button without a wall of text or a cage.

## Requirements

- Prompts appear on the thing they describe and disappear when it is done
- Nothing is locked: a player who already knows can ignore all of it
- Night 1 stays the tutorial night the design document asks for - a handful of basic zombies
- Seven lines of text at most in the whole first day
- A profile flag so it never shows twice

## Done when

- [ ] Someone who has not seen the game reaches the first night without being told anything out loud
- [ ] Skipping every prompt still leaves a winnable night 1
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
