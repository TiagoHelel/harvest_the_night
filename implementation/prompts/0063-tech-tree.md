# 0063 - The tech tree

- **Phase:** 4 - Ten nights and progression
- **Status:** done
- **Depends on:** 0062
- **Likely files:** src/core/tech.gd, src/ui/tech_screen.gd

## Goal

Somewhere to spend the points, small enough to read on one screen and real enough to change how a night goes.

## Requirements

- Around twelve nodes, no more: the design document forbids a giant tree in the MVP
- Three branches: production, defence, survival
- Prerequisites are data; a node shows what it needs and what it gives
- It opens from the day HUD and never during a wave
- Spending is confirmed and is not refundable - or is, for a fee, and the fee is a lever

## Done when

- [ ] Every node is reachable inside ten nights, but not all of them
- [ ] The choice between branches is real: say in the journal which one you would take and why
- [ ] `input_check` buys a node
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
