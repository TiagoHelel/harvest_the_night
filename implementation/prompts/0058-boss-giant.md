# 0058 - The Giant

- **Phase:** 3 - The full night
- **Status:** todo
- **Depends on:** 0051, 0052, 0057
- **Likely files:** src/core/enemies.gd, src/core/game_data.gd

## Goal

The single boss of the MVP: the test of the build you made over nine nights.

## Requirements

- Very high hit points, slow, and it smashes structures on its way through
- It arrives with ordinary zombies, so the player cannot aim everything at it
- It forces concentrated damage: a defence of only cheap towers cannot kill it in time
- One readable telegraph before its heavy attack
- Beating it is the end of the MVP run

## Done when

- [ ] A well-built night 9 defence beats it with something to spare
- [ ] A defence of nothing but crossbows loses to it
- [ ] It never softlocks the night by becoming unreachable
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
