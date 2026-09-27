# 0109 - The character reacts

- **Phase:** 5 - Art and visual direction
- **Status:** todo
- **Depends on:** 0073
- **Likely files:** src/core/player.gd, src/ui/player_view.gd

## Goal

The little bubbles on the owner's sheet - !, ?, a heart, a note, an idea, a star - used for the two or three moments the game already has and nothing more.

## Requirements

- The sheet's reaction row is cut with the rest of task 0073 and is available as named frames
- A reaction is a fact in the state with a lifetime, not a thing the view invents, so the autoplayer and a replay see the same ones
- Used only where the game already has a moment: a bite on the line, a crop coming ready nearby, a structure destroyed, the night arriving. Four at most
- Never during a wave except for damage - a farmer with a music note over their head while the house burns is the wrong game
- It is decoration: removing every reaction changes nothing about what is possible, and there is an assert for that

## Done when

- [ ] A reaction appears on the tick the thing happens and clears itself
- [ ] Turning them all off leaves the determinism hash unchanged
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
