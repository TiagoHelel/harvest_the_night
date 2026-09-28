# 0087 - Ambience

- **Phase:** 6 - Sound and juice
- **Status:** done
- **Depends on:** 0084, 0085
- **Likely files:** src/app/ambience.gd

## Goal

The bed under everything: birds and water by day, wind and distant groaning by night.

## Requirements

- A day bed and a night bed, cross-fading with the transition
- Positional touches: the pond is louder near the pond
- It ducks under an important sound rather than fighting it
- It is on its own bus so it can be turned down alone

## Done when

- [ ] Standing still on the farm for a minute is pleasant, not empty
- [ ] The ambience never masks the house-damage sound
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
