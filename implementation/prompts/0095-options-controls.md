# 0095 - Options: controls

- **Phase:** 7 - Shell and product
- **Status:** done
- **Depends on:** 0009, 0092
- **Likely files:** src/ui/options_controls.gd, src/app/input_actions.gd

## Goal

Named actions instead of hardcoded keys, and a screen to rebind them.

## Requirements

- Every key the game reads is a named action: move, interact, build, cancel, inventory, ability, speed, night, pause
- A rebind screen that detects a conflict and refuses it with the clash named
- Reset to defaults, per binding and for all
- Bindings persist through Settings
- Mouse bindings are included, not a special case

## Done when

- [ ] `grep` finds no raw keycode left in `src/ui/`
- [ ] A rebound key works immediately and after a restart
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
