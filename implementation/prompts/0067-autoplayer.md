# 0067 - The autoplayer

- **Phase:** 4 - Ten nights and progression
- **Status:** done
- **Depends on:** 0059, 0055
- **Likely files:** src/tools/autoplayer.gd

## Goal

A robot that plays the ten nights, so balance is measured over hundreds of runs instead of guessed at over three.

## Requirements

- A scripted day policy - gather, craft, build - and a night that runs itself
- Several policies: all towers, all walls, economy first, balanced
- Runs headless, seeded, and reports per night: survived, house hit points left, resources spent
- It is a measuring instrument, not an AI: simple and readable beats clever
- A dominant strategy detector: flag when one policy wins every night by a wide margin

## Done when

- [ ] 100 seeded runs finish in under two minutes
- [ ] The report names which night kills each policy
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
