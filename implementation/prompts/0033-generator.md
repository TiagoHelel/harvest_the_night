# 0033 - The generator and energy

- **Phase:** 2 - The full day
- **Status:** todo
- **Depends on:** 0031, 0019
- **Likely files:** src/core/power.gd

## Goal

Energy, the resource on the reference sheet that gates the advanced structures and makes placement matter.

## Requirements

- A generator burns a fuel over ticks and produces energy
- Energy is a rate, not a stockpile: structures draw it while they run
- A structure with no power runs at a reduced rate rather than switching off - degraded, not dead
- The HUD shows supply against draw
- Generator output, fuel burn and each structure's draw are levers

## Done when

- [ ] Building one structure too many visibly slows everything rather than stopping it
- [ ] Running out of fuel mid-night degrades the defence and the night still resolves
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
