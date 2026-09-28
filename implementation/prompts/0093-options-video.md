# 0093 - Options: video

- **Phase:** 7 - Shell and product
- **Status:** done
- **Depends on:** 0009, 0092
- **Likely files:** src/ui/options_video.gd

## Goal

Resolution, window mode and scaling, done properly for a pixel art game.

## Requirements

- A resolution list built from the monitor, marking the integer multiples of 480x270
- Windowed, borderless and exclusive fullscreen
- Integer scaling on by default, with a toggle and a warning about what turning it off does
- VSync and an FPS cap
- Applied immediately with a revert countdown, so a bad mode cannot strand the player

## Done when

- [ ] Every listed mode applies and survives a restart
- [ ] Picking an impossible mode reverts on its own within ten seconds
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
