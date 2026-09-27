# 0054 - The player's ability

- **Phase:** 3 - The full night
- **Status:** todo
- **Depends on:** 0027
- **Likely files:** src/core/ability.gd, src/ui/night_hud.gd

## Goal

One button that lets the player change a night they are losing, without turning the game into an action game.

## Requirements

- One ability with a cooldown in ticks: a flare that slows and damages everything in an area
- The cooldown is long enough that using it is a decision
- It is resolved on the tick like everything else and is in the determinism hash
- It reads clearly on screen: the player should see it working
- Damage, radius, slow and cooldown are levers

## Done when

- [ ] It turns one losing wave per night, not every wave
- [ ] Two uses in the same second are impossible
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
