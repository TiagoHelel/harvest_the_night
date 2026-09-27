# 0014 - Sprites generated from ASCII maps

- **Phase:** 1 - The first playable build
- **Status:** done
- **Depends on:** 0001
- **Likely files:** tools/gen_sprites.py, sprites/

## Goal

Art that a script owns. One palette, one generator, one command - so the set stays consistent and a colour change is one edit rather than forty.

## Requirements

- `tools/gen_sprites.py` turns ASCII maps plus a named palette into PNGs under `sprites/`
- 16x16 for tiles and props, 16x24 for actors, drawn on a transparent background
- One palette table shared by every sprite, with the day and night ramps named
- Running it twice produces byte-identical files
- Hand-authored PNGs are not allowed: the map is the source

## Done when

- [ ] `python tools/gen_sprites.py` regenerates the whole set
- [ ] Editing one character in a map changes exactly one pixel
- [ ] The generated sheet imports with nearest-neighbour filtering and no mipmaps
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
