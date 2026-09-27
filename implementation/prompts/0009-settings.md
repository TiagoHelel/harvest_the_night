# 0009 - Settings singleton

- **Phase:** 0 - Foundation
- **Status:** todo
- **Depends on:** 0001
- **Likely files:** src/core/settings.gd, project.godot

## Goal

One place that owns every user setting and writes it to `user://settings.cfg`, so the options menus later only read and write it.

## Requirements

- `Settings` autoload with typed getters grouped as video, audio, gameplay and controls
- Atomic save: temp file then rename, so a crash mid-write cannot corrupt the config
- A `version` field and a migration hook for when keys change
- Defaults in one dictionary; an unknown key on load is dropped with a warning and never crashes
- `signal changed(key)` so panels react instead of polling

## Done when

- [ ] Change a value, quit, relaunch: it survived
- [ ] Delete the file: the game boots on defaults with no error
- [ ] Corrupt the file by hand: the game boots on defaults and says so in the log
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
