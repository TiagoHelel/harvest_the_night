# 0015 - The player walks and interacts

- **Phase:** 1 - The first playable build
- **Status:** todo
- **Depends on:** 0013
- **Likely files:** src/core/player.gd, src/ui/player_view.gd

## Goal

Somebody to be on the farm: eight-way movement on the grid and one interact key that does the right thing for whatever is in front of you.

## Requirements

- Position and facing live in core and move on the tick, not on the frame
- Movement is blocked by water, rock and occupied tiles
- One `interact` action; the target is the tile being faced, with the tile under the player as a fallback
- An `interactable` registry so later tasks add a verb without touching the player
- A highlight on the targeted tile so the player can see what they will hit

## Done when

- [ ] Walking into the pond stops the player rather than teleporting them
- [ ] The same input sequence from the same seed ends at the same cell
- [ ] `input_check` drives a walk and an interact
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
