# 0102 - A performance budget

- **Phase:** 8 - Ship the MVP
- **Status:** done
- **Depends on:** 0005, 0060
- **Likely files:** tools/perf.py, src/tools/perf_check.gd

## Goal

A number, checked automatically, instead of a feeling about whether it runs well.

## Requirements

- A budget in milliseconds per frame for the worst case: night 10, everything built, lights and particles on
- A headless benchmark that reports tick cost, path cost and entity count
- Wired into `verify.py`, failing when the budget is exceeded
- A baseline file, moved deliberately the way the hash is
- The report names the most expensive system, so a regression points at itself

## Done when

- [ ] The worst case is inside the budget on this machine
- [ ] Adding a deliberately slow loop makes verify fail and name it
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
