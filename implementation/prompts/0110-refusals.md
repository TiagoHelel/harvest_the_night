# 0110 - Refusals in two languages

- **Phase:** 7 - Shell and product
- **Status:** done
- **Depends on:** 0097
- **Likely files:** src/core/building.gd, src/core/sim.gd, src/core/tech.gd

## Goal

The last English sentences in `src/core/`: the lines that say why a thing cannot be built, bought or skipped.

## Requirements

- `why_not_*` returns a key and its arguments rather than a sentence
- The words live in `assets/locale/strings.csv` like every other line
- The ids in a refusal - what is short, what is needed - are named by `Names.of` rather than printed raw
- `tools/i18n_check.py` covers them, widths and all

## Done when

- [ ] `grep` finds no player-facing sentence left in `src/core/`
- [ ] Every refusal reads in Portuguese, and the checker proves it fits
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
