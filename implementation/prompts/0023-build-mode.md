# 0023 - Build mode

- **Phase:** 1 - The first playable build
- **Status:** done
- **Depends on:** 0008, 0019, 0022
- **Likely files:** src/ui/build_mode.gd, src/core/building.gd

## Goal

Placing things on the farm: pick a structure, see where it can go, pay for it, put it there.

## Requirements

- A build palette of what the player owns or can afford
- A ghost under the cursor, green where it fits and red where it does not, with the reason on hover
- Cost is checked and taken on placement, through the ledger
- Right click sells the structure under the cursor back for a fraction, and the fraction is a lever
- Build mode works in DAY and PREPARATION, and in NIGHT only for what 0053 later allows

## Done when

- [ ] A structure cannot be placed on water, rock or another structure
- [ ] Placing and selling in a loop neither creates nor destroys resources beyond the sell fraction
- [ ] `input_check` places one and sells it
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
