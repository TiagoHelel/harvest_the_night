# 0091 - The title screen

- **Phase:** 7 - Shell and product
- **Status:** todo
- **Depends on:** 0081, 0006
- **Likely files:** src/ui/title_screen.gd, scenes/Title.tscn

## Goal

The game currently boots into a farm. Make it boot into a game.

## Requirements

- The farm at dusk behind the title, with the night creeping in - the premise, in one image
- The logo, generated with the same tools as everything else
- Continue, New run, Statistics, Options, Quit
- Continue is absent, not greyed, when there is no save
- Any key or click moves past the ident into the menu

## Done when

- [ ] Booting lands here and not in a run
- [ ] The screen says what kind of game this is before a word is read
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
