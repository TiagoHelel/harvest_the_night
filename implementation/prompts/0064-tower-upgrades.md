# 0064 - Tower I, II, automatic

- **Phase:** 4 - Ten nights and progression
- **Status:** done
- **Depends on:** 0063, 0042
- **Likely files:** src/core/towers.gd, src/core/game_data.gd

## Goal

The upgrade chain the design document draws: a tower that grows with the run instead of being replaced by a different tower.

## Requirements

- Each tower has three levels, each an entry in data, not a subclass
- An upgrade costs resources on the spot and is gated by a tech node
- Level 3 changes behaviour, not only numbers - that is what earns the word 'automatic'
- The upgrade is visible on the sprite
- Upgrading in place keeps the tower's current hit points proportionally

## Done when

- [ ] Upgrading a tower mid-preparation works and costs what it says
- [ ] A level 3 tower is clearly better and clearly not free
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
