# 0073 - The player sprite

- **Phase:** 5 - Art and visual direction
- **Status:** done
- **Depends on:** 0071, 0015
- **Likely files:** tools/cut_sheet.py, sprites/actors/, src/ui/player_view.gd

## Goal

Somebody worth watching walk around: four directions, walking, and the work verbs - cut from the sheet the owner drew rather than generated from an ASCII map.

## Requirements

- **The art already exists**: `docs/sprites_sem_fundo.png`, 1536x1024 RGBA, with idle, walk, chop, mine, hoe, water, fish, plant, carry and a row of reactions
- **Decide the size first, and write the answer in the journal.** The sheet is a painted image, not pixel art: 82,714 distinct colours and no blocky native resolution, with frames about 100x170. The game is 480x270 on 16px tiles, where a character is 16x24. Those cannot both be true. The three ways out are (a) downscale to 16x24 and lose the drawing, (b) render the player larger than a tile - 32x48 over the 16px grid, which is what Stardew does - or (c) raise the whole game to 32px tiles and 960x540. (b) is the cheapest and changes no other art
- A cutting tool in `tools/`, not by hand: the frames are not on a clean grid and have a soft glow between them, so the cut is code with the offsets as data and is re-runnable when the sheet is redrawn
- The glow keyed out, so a frame has hard alpha and no halo over the grass
- Every verb the game has maps to a row: chop, mine, till, plant, water, fish, craft, and idle and walk in four facings
- The animation is driven by the core state's action, not by the view guessing
- Frame counts and speeds are data
- A shadow, because without one the character floats

## Done when

- [ ] Every verb in the game has an animation and none plays the wrong one
- [ ] Walking diagonally picks a facing and stays with it
- [ ] Re-running the cutting tool on the same sheet produces byte-identical PNGs
- [ ] The chosen size is stated in the journal with the reason
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
