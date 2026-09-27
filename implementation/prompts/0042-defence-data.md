# 0042 - Data-driven defences

- **Phase:** 3 - The full night
- **Status:** todo
- **Depends on:** 0024
- **Likely files:** src/core/towers.gd, src/core/game_data.gd

## Goal

Before adding five more towers, make a tower a data entry, so the combat code stops growing a branch per structure.

## Requirements

- A structure declares: targeting, damage type, shape, rate, range, cost, energy draw, ammunition use
- The combat code reads the declaration instead of comparing ids
- The shooting tower is ported with no behaviour change at all
- Damage types: impact, fire, explosive - named in one place
- A new tower that deals 3 fire in a radius is one entry and no combat edit

## Done when

- [ ] The determinism hash is unchanged after the port - that is what makes it a port
- [ ] Adding a test tower takes a data entry only; delete it afterwards and say so
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
