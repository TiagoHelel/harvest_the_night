# 0036 - The inventory

- **Phase:** 2 - The full day
- **Status:** done
- **Depends on:** 0007
- **Likely files:** src/core/inventory.gd, src/ui/inventory_panel.gd

## Goal

Somewhere to see everything at once, which the HUD cannot do once there are twelve resources.

## Requirements

- A panel listing every resource with its amount and its sale price
- Grouped the way the reference sheet groups them
- Opens and closes on one key without pausing the day
- It is a view of the ledger, not a second store of truth

## Done when

- [ ] Every resource in game_data appears without being listed twice
- [ ] Adding a resource to game_data makes it appear with no UI edit
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
