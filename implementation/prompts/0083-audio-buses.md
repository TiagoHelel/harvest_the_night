# 0083 - Audio buses and a sound manager

- **Phase:** 6 - Sound and juice
- **Status:** todo
- **Depends on:** 0009
- **Likely files:** src/core/audio.gd, default_bus_layout.tres

## Goal

Master, SFX and Music buses plus a small `Audio.play(id)`, so the sound tasks after this only have to drop in files.

## Requirements

- Three buses in `default_bus_layout.tres`
- `Audio` autoload mapping a string id to a stream and a bus
- Volumes read from Settings on boot and on `changed`
- An unknown id warns once and stays silent
- A polyphony cap and a same-frame dedupe, so twenty towers firing on one tick cannot clip

## Done when

- [ ] `Audio.play('missing')` warns exactly once and does not crash
- [ ] Master at zero silences everything including music
- [ ] Twenty simultaneous shots produce one clean sound, not clipping
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
