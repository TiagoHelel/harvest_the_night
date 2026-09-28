# 0104 - Saves survive an update

- **Phase:** 8 - Ship the MVP
- **Status:** done
- **Depends on:** 0010, 0062
- **Likely files:** src/app/save.gd

## Goal

Adding a lever or a tech node must not delete somebody's run.

## Requirements

- A save version and a migration per bump, applied in order
- A missing key takes the default; an unknown key is dropped with a warning
- Golden saves in the repository, one per version, loaded by `verify.py`
- A save that cannot be migrated says so, keeps the file, and offers a new run

## Done when

- [ ] Every golden save loads and plays
- [ ] Adding a resource to game_data does not break a save that predates it
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
