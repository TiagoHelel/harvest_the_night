# 0002 - Fixed-timestep deterministic simulation

- **Phase:** 0 - Foundation
- **Status:** todo
- **Depends on:** 0001
- **Likely files:** src/core/sim.gd, src/core/rng.gd, src/core/state.gd

## Goal

One tick function that advances the whole world at a fixed rate. Crop growth, tower fire, zombie walking, the headless tests, the double speed button and skipping a night all become the same code run a different number of times.

## Requirements

- `TICK_HZ = 30` in game_data; `Sim.tick(state)` advances exactly one tick and returns nothing
- The UI accumulates `delta` and calls `tick()` a whole number of times. A partial tick never happens, and a slow frame catches up with a cap so it cannot spiral
- `src/core/rng.gd`: a seeded PCG the state carries. `randi()` and `randf()` are banned in `src/core/`, and so is `Time.*`
- `state` is plain data - Dictionary and Array of primitives - so it can be deep-copied, hashed, saved and diffed
- `state.tick` is the only clock the rules ever read

## Done when

- [ ] 10000 ticks from one seed, run twice, hash identical
- [ ] Nothing under `src/core/` says `extends Node`
- [ ] `grep -rE 'randf|randi|Time\.' src/core/` finds only `rng.gd`
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
