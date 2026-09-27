# 0005 - verify.py and the determinism guard

- **Phase:** 0 - Foundation
- **Status:** todo
- **Depends on:** 0004
- **Likely files:** tools/verify.py, tools/determinism_hash.txt, src/tools/determinism.gd

## Goal

A bootstrap `tools/verify.py` already exists so that task 0001 had something to run. Finish it: write the determinism guard it is waiting for, and make the export check real.

## Requirements

- Read the bootstrap first - the check order and the SKIP behaviour are already there and are not up for redesign
- `determinism.gd` runs a fixed scripted scenario for a fixed number of ticks and prints one integer
- `--accept` records a moved hash and prints the old and the new number; `--fast` skips the exports
- The Godot executable comes from `$GODOT`, defaulting to `C:/Users/PC GAMER DA FAMILIA/Documents/Godot/Godot_v4.7.2-stable_win64_console.exe`
- Every row is timed and the total is printed

## Done when

- [ ] `python tools/verify.py` prints PASS on the scaffold, with SKIPs for what does not exist yet
- [ ] Deleting the hash file then `--accept` records a first baseline
- [ ] Changing a lever makes the hash move and the run FAIL until `--accept`
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
