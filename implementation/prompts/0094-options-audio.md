# 0094 - Options: audio

- **Phase:** 7 - Shell and product
- **Status:** done
- **Depends on:** 0083, 0092
- **Likely files:** src/ui/options_audio.gd

## Goal

Master, music, effects and ambience, with a test sound on each.

## Requirements

- Four sliders, each writing to its bus through Settings
- A test sound on release, on the bus being adjusted
- A mute toggle that is separate from a zero slider
- Values persist and apply on boot

## Done when

- [ ] Each slider affects only its own bus
- [ ] Muting and unmuting restores the previous levels
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
