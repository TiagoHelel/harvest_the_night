# 0047 - Barricades

- **Phase:** 3 - The full night
- **Status:** done
- **Depends on:** 0046
- **Likely files:** src/core/game_data.gd

## Goal

The emergency answer: almost free, almost paper, and placeable while the night is running.

## Requirements

- Cheapest structure in the game, from the workshop's first recipe
- It may be placed during NIGHT, which no other structure may
- It has a short lifetime as well as hit points, so it cannot become a permanent wall
- A limit on how many may be placed per night, and it is a lever

## Done when

- [ ] Placing one mid-wave buys the measurable seconds the lever claims
- [ ] It expires on its own if it survives the night
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
