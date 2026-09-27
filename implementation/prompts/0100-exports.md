# 0100 - Exports: Windows and Web

- **Phase:** 7 - Shell and product
- **Status:** todo
- **Depends on:** 0005, 0092
- **Likely files:** export_presets.cfg, tools/release.py

## Goal

Two builds anyone can run, from one command, with the Web one small enough that a stranger will wait for it.

## Requirements

- `python tools/release.py` builds both and writes them into `build/`
- The Web build excludes `implementation/`, `tools/`, `docs/` and previous builds from the pack - check, because this is where that goes wrong
- A wire-size budget for the Web build, gzipped, and the build fails when it is exceeded
- The Web build takes focus and audio correctly on first click
- The version and the build date are baked in and shown on the title screen

## Done when

- [ ] Both builds run a full night on a machine without Godot installed
- [ ] The Web build is inside its budget and the number is printed
- [ ] The two builds produce the same determinism hash
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
