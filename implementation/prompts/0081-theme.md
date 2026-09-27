# 0081 - The UI theme

- **Phase:** 5 - Art and visual direction
- **Status:** todo
- **Depends on:** 0079, 0080
- **Likely files:** assets/theme.tres, src/ui/

## Goal

One Theme resource every control uses, so a colour change is one edit and no screen is the odd one out.

## Requirements

- Every Control style in one Theme: no per-node style overrides anywhere
- Built from the palette and the UI kit, not from Godot's defaults
- Focus, hover and disabled states defined for everything interactive
- A UI scale factor that works at every integer window scale

## Done when

- [ ] `grep` finds no `add_theme_*_override` left in `src/ui/`
- [ ] Every screen looks like the same game
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
