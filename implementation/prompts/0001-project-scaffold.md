# 0001 - Godot project scaffold

- **Phase:** 0 - Foundation
- **Status:** done
- **Depends on:** nothing
- **Likely files:** project.godot, scenes/Main.tscn, src/ui/main.gd, .gitignore

## Goal

The repository holds a design document and a reference image and nothing else. Turn it into a Godot 4.7 project that opens, boots and exports, with the directory layout every later task assumes.

## Requirements

- Godot 4.7 project at the repository root, renderer `gl_compatibility` so the Web export works
- Base viewport 480x270 at 16px tiles, stretch mode `viewport` with integer scaling: this is a pixel art game and half pixels are a bug, not a look
- Directories: `src/core/`, `src/ui/`, `src/tools/`, `scenes/`, `sprites/`, `assets/`, with a one-line README in each saying what belongs there
- `scenes/Main.tscn` boots to a plain screen showing the game name and the build version from `src/core/build_info.gd`
- `.gitignore` for Godot 4 (`.godot/`, `build/`, `*.tmp`, exports)
- `export_presets.cfg` with a Windows desktop and a Web preset, both writing into `build/`
- `git init` and one commit if this is not a repository yet

## Done when

- [ ] Opening the project in the editor produces no error or warning
- [ ] `godot --headless --path . --import` exits 0
- [ ] Both exports produce a file in `build/`
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
