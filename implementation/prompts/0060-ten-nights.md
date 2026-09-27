# 0060 - The ten nights, authored

- **Phase:** 4 - Ten nights and progression
- **Status:** todo
- **Depends on:** 0059, 0058
- **Likely files:** src/core/game_data.gd

## Goal

Section 10 of the design document, as a real difficulty curve: tutorial, more, the runner, the tank, the breaker, the boss.

## Requirements

- Ten nights following the design document exactly: 1 tutorial, 3 first runner, 5 first tank, 7 breakers, 8 large, 9 heavy mix, 10 the Giant
- Each night introduces at most one new thing, and night 2 of a new enemy is where it gets hard
- Enemy count and reward curve upward smoothly - plot it in the journal
- Night 1 is beatable with the tower the tutorial gives you and nothing else
- Night 10 is not beatable without upgrades from the tech tree

## What task 0051 found and left here

The mortar is not a better answer to a tank than a wall of crossbows, and no
tank lever makes it one. Against armour four a crossbow does one damage every
fifteen ticks and a mortar thirty-six every hundred and fifty, so four
crossbows are 0.267 a tick against one mortar's 0.240 - eleven percent apart -
and at 170 against 665 goods the crossbow is also the cheaper way to buy it.
0051 measured the tank at 120, 160 and 220 hit points: every value either
lets both towers win or leaves both on a knife edge.

If the tank is meant to be the reason the mortar exists, the lever is on the
**mortar** rather than on the tank - its `reload_ticks` (3 to 8 seconds,
currently 5) or its price. Changing either affects task 0050's measurement
that one mortar does not stop a rush of runners, so re-run that group.

## Done when

- [ ] All ten are playable start to finish
- [ ] The count and reward curves are in the journal as numbers
- [ ] A headless run plays all ten with a scripted build and reports which ones fell
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
