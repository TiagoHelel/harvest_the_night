# 0052 - The breaker

- **Phase:** 3 - The full night
- **Status:** done
- **Depends on:** 0049, 0046
- **Likely files:** src/core/enemies.gd, src/core/game_data.gd

## Goal

The enemy that goes after what you built: it targets structures first and the house second.

## Requirements

- It picks the nearest structure on its path, not the house
- Extra damage against structures and little against the house
- It makes an undefended tower line a liability, which is the point
- Target selection is deterministic and ordered

## Done when

- [ ] A wave of breakers dismantles an unprotected tower line
- [ ] With the towers covered, they die before they reach one
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
