# 0056 - The night HUD

- **Phase:** 3 - The full night
- **Status:** todo
- **Depends on:** 0027
- **Likely files:** src/ui/night_hud.gd

## Goal

Section 14 of the design document: which night, which wave, how the house is doing, and the three buttons.

## Requirements

- Night number, wave counter, house hit point bar, ammunition and energy
- Repair, ability and speed as the three controls, exactly as the design document lays them out
- An incoming wave is announced before it arrives
- The house bar turning dangerous is impossible to miss
- It replaces the day HUD on the phase change, sharing no state

## Done when

- [ ] Every number on it is readable at 480x270 scaled up
- [ ] `input_check` presses all three controls
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
