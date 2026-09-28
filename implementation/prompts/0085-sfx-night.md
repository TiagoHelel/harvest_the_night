# 0085 - The sounds of the night

- **Phase:** 6 - Sound and juice
- **Status:** done
- **Depends on:** 0083, 0026
- **Likely files:** tools/gen_sfx.py, assets/sfx/

## Goal

The other half: shots, the flamethrower, the mortar, impacts, the groan, the death, the wall breaking, the house being hit.

## Requirements

- Every tower and every enemy has its own sound
- The house taking damage is the most alarming sound in the game
- A distance falloff, so the far side of the farm is quieter
- The Giant is audible before it is visible
- The same generator as 0084

## Done when

- [ ] With eyes closed, a night's audio says roughly what is happening
- [ ] Fifty zombies do not turn into noise
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
