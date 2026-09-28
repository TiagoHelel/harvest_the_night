# 0096 - The pause menu

- **Phase:** 7 - Shell and product
- **Status:** done
- **Depends on:** 0092, 0006
- **Likely files:** src/ui/pause_menu.gd

## Goal

Escape stops the world, and pausing mid-night is safe.

## Requirements

- Pause stops the tick accumulator: no ticks run and none are banked to run later
- Resume, Options, Save and quit, Abandon run
- Pausing mid-night and resuming produces an identical night
- Abandon asks twice and says what will be lost

## Done when

- [ ] A paused night resumed gives the same hash as an unpaused one
- [ ] Pausing for five minutes does not fast-forward on resume
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
