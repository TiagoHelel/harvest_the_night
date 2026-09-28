# 0099 - An icon and a boot ident

- **Phase:** 7 - Shell and product
- **Status:** done
- **Depends on:** 0014, 0091
- **Likely files:** tools/gen_icon.py, assets/icon.png

## Goal

Something recognisable in a taskbar and on an itch page, and two seconds before the title that are not the Godot logo.

## Requirements

- An icon generated at every size a platform asks for, readable at 16x16
- It says farm and night in one image
- The boot splash is replaced; no default Godot branding anywhere
- A short ident, skippable on any input

## Done when

- [ ] The 16x16 icon is still recognisable
- [ ] No Godot logo appears anywhere in a release build
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
