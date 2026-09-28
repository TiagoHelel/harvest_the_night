# 0069 - Run statistics

- **Phase:** 4 - Ten nights and progression
- **Status:** done
- **Depends on:** 0066, 0010
- **Likely files:** src/core/stats.gd, src/ui/stats_screen.gd

## Goal

What the player did, kept across runs, because a number going up is its own reason to play another night.

## Requirements

- Per run and lifetime: nights survived, zombies killed by type, resources gathered, structures built and lost, best night reached
- Recorded in core on the tick, read by the screen
- It survives a crash: written with the profile, not at the end of a run
- Reachable from the main menu

## Done when

- [ ] Killing ten zombies increments by exactly ten
- [ ] Quitting mid-run and returning keeps the run's numbers
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
