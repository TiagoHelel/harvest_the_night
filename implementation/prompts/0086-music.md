# 0086 - Two pieces of music

- **Phase:** 6 - Sound and juice
- **Status:** done
- **Depends on:** 0083, 0022
- **Likely files:** tools/gen_music.py, assets/music/

## Goal

One warm loop for the farm, one cold one for the night, and a crossfade on the reality switch.

## Requirements

- Generated, looping cleanly, a couple of minutes each
- The two share a motif, so the night is recognisably the same farm
- A crossfade tied to the transition length
- An intensity layer that comes in on the last wave of a night
- Music is off in menus by default, and that is a setting

## Done when

- [ ] The loop point is inaudible
- [ ] The crossfade lands with the transition, not before or after it
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
