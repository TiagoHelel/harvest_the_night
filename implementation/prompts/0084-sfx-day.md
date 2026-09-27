# 0084 - The sounds of the day

- **Phase:** 6 - Sound and juice
- **Status:** todo
- **Depends on:** 0083
- **Likely files:** tools/gen_sfx.py, assets/sfx/

## Goal

Chop, mine, till, plant, water, the fishing splash and the bite, the craft, the sale - generated, not licensed.

## Requirements

- `tools/gen_sfx.py` synthesises every effect to WAV and is deterministic
- Every day verb has a sound and a small random pitch so repetition does not grate
- Cozy, soft, short: the day is the calm half
- The bite is the most attention-grabbing sound of the day, because it is the only one with a window

## Done when

- [ ] Chopping a tree for a full minute does not become annoying - go and check
- [ ] Regenerating produces byte-identical files
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
