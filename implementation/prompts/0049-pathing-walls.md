# 0049 - Zombies path around walls

- **Phase:** 3 - The full night
- **Status:** done
- **Depends on:** 0025, 0046
- **Likely files:** src/core/pathing.gd

## Goal

Make the flow field earn its keep: cost, not just blocked, so zombies prefer the open lane and break through when they must.

## Requirements

- Path cost per terrain and per structure, so a wall is expensive rather than impossible
- A zombie whose cheapest path is still expensive attacks the structure instead of walking around the world
- Recompute is incremental or cached: it must not cost a frame when a wall falls mid-wave
- Deterministic tie-breaking everywhere in the field
- No zombie ever oscillates between two cells

## Done when

- [ ] A hundred zombies and a maze stay inside the tick budget
- [ ] The same seed and the same maze give the same arrival order
- [ ] A headless test asserts no zombie is in the same pair of cells for 20 ticks
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
