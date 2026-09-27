# 0088 - Juice: shake, hit stop, damage numbers

- **Phase:** 6 - Sound and juice
- **Status:** todo
- **Depends on:** 0026, 0077
- **Likely files:** src/ui/juice.gd

## Goal

Make a kill feel like a kill. Small, cheap, and entirely in the view layer.

## Requirements

- Screen shake scaled to the event, with a cap and a setting to disable it
- A few frames of hit stop on a big hit, implemented without touching the tick rate
- Floating damage numbers, colour-coded by damage type, batched when many land at once
- A flash on a hit entity and a squash on death
- None of it is in core and none of it touches the hash

## Done when

- [ ] Hit stop does not desynchronise the simulation - prove it with the hash
- [ ] Everything here can be turned off and the game still reads
- [ ] A crowded wave does not spawn a thousand number labels
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
