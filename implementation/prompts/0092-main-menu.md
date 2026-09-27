# 0092 - The main menu and the router

- **Phase:** 7 - Shell and product
- **Status:** todo
- **Depends on:** 0091, 0010
- **Likely files:** src/core/app.gd, src/ui/main_menu.gd

## Goal

One router that owns which screen is up, so screens stop knowing about each other.

## Requirements

- An `App` autoload with `goto(state)` and a `state_changed` signal
- States: BOOT, TITLE, MENU, RUN, TECH, STATS, OPTIONS, SUMMARY
- A back stack, so Options returns to whoever opened it
- No `get_node('/root/...')` reaching across screens
- The run becomes one state rather than the root scene

## Done when

- [ ] Options from the title and from the pause menu both return correctly
- [ ] `input_check` still drives a full night after the refactor
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
