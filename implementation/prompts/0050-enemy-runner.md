# 0050 - The runner

- **Phase:** 3 - The full night
- **Status:** done
- **Depends on:** 0049
- **Likely files:** src/core/game_data.gd

## Goal

The first enemy that changes what you build: fast, fragile, and it arrives before the mortar can reload.

## Requirements

- Roughly twice the basic speed and half the hit points - state the real numbers
- It ignores structures and runs straight for the house
- It punishes a defence made only of slow, expensive towers
- Speed, hit points and reward are levers

## Done when

- [ ] A crossbow line stops a rush and a mortar alone does not
- [ ] It arrives first when mixed into a wave with basics
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
