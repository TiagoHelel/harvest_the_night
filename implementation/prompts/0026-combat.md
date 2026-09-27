# 0026 - The tower kills the zombie

- **Phase:** 1 - The first playable build
- **Status:** todo
- **Depends on:** 0024, 0025
- **Likely files:** src/core/combat.gd

## Goal

Close the fight: projectiles land, damage is dealt, zombies die and drop what the night pays.

## Requirements

- Damage resolution in one place, so every later tower and enemy goes through it
- Overkill is not wasted on a second target; a dead target stops being shot at the same tick
- Death removes the entity cleanly with no dangling reference in the state
- Hit, death and the projectile are visible - a kill should read at a glance
- Entity ids are stable and ordered so the hash cannot depend on spawn order

## Done when

- [ ] A tower clears a lane of ten zombies with the expected number of shots
- [ ] `headless_check` runs a scripted fight and asserts the survivor count
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
