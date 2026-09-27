# 0035 - Gunpowder and ammunition

- **Phase:** 2 - The full day
- **Status:** todo
- **Depends on:** 0032, 0033
- **Likely files:** src/core/crafting.gd, src/core/towers.gd

## Goal

Towers that consume something. The clearest possible version of 'what you made today decides what tonight can do'.

## Requirements

- Gunpowder from corn and oil; incendiary rounds from oil and wood
- A tower draws from a shared ammunition pool at a rate that is a lever
- Out of ammunition means a much slower basic shot, never a silent dead tower
- The night HUD shows the pool draining
- Ammunition left over carries into the next night

## Done when

- [ ] A night fought with no gunpowder is survivable but clearly worse
- [ ] The pool drains at the rate the levers claim over a scripted night
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
