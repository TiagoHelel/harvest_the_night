# 0030 - Fishing

- **Phase:** 2 - The full day
- **Status:** todo
- **Depends on:** 0015, 0007
- **Likely files:** src/core/fishing.gd

## Goal

The pond earns its place: the highest value per action on the farm, paid for with attention rather than resources.

## Requirements

- Cast from a shore or jetty tile facing water, on the interact action
- A bite after a seeded random delay inside a lever range, then a window to react
- Common and rare fish, with the rare chance a lever
- Missing the window loses nothing but the time
- Fish sell high and feed cooking later

## Done when

- [ ] The bite delay is drawn from the run RNG and replays identically
- [ ] Fishing with no reaction for a whole day yields nothing and crashes nothing
- [ ] `input_check` lands one fish
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
