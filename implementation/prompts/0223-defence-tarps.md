# 0223 - Defences sleep under tarps

- **Phase:** 13 - Weapons of the night
- **Status:** todo
- **Depends on:** 0196, 0132, 0120
- **Likely files:** src/ui/world_view.gd, src/ui/transition.gd, src/ui/placeholder_art.gd, src/tools/shot.gd, src/tools/headless_v1.gd, implementation/backlog/packs/A044-tarps.md

## Goal

By day the defences sleep under tarps and the farm looks like a farm; when the night comes the covers come off with the wake the transition already plays (plan section 5).

## Art

What this task puts on screen will be dressed by Codex art pack(s) A044
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- View only: no rule reads a tarp, and both hashes stay where they are
- In the DAY phase every defence of a tarp family is drawn covered; during the switch into the night the tarps come off with the wake pass in `transition.gd` (`WAKES` kept - the generator still wakes, without a tarp) and go back on when the day begins
- Decide which families get tarps and why: probably the towers and the other standing one-cell defences, not barriers, mines or traps (a covered wall is still a wall, a covered mine is a lie). Drive the unveil from one list in the view so a later defence joins by being listed; 0234 lists the families of 0224-0231, which leave the list alone
- A hurt or wrecked defence shows its state by day - through the tarp or instead of it, decide - so the morning never hides damage
- Drawn through the placeholder road of 0120: a code-drawn or tinted cover per footprint (32x48 towers, 16x32, 16x24) with two unveil frames, until A044 is integrated by 0243
- Write the chosen families and footprints into the Deliverables table of `implementation/backlog/packs/A044-tarps.md`; 0234 settles the final list

## Done when

- [ ] `_task_0223_tarps` in `src/tools/headless_v1.gd` asserts every id in the view's tarp list is a `DEFENCES` id and nothing in `src/core/` mentions a tarp
- [ ] `python tools/shot.py 0223` captures of the same towers by day (covered), at dusk and at night (uncovered), opened and looked at
- [ ] `python tools/verify.py` prints PASS
- [ ] the determinism hash is unchanged, or the change is deliberate and both
      the old and the new number are in the journal

## House rules

`src/core/` holds the game rules: node-free, deterministic, advanced only by
`Sim.tick()` at a fixed rate. No nodes, no unseeded randomness, no clock reads,
no iterating an unordered Dictionary without sorting the keys first. `src/ui/`
draws and reads input and owns no rules.

Every number a designer might want to turn lives in `src/core/game_data.gd`
with `# LEVER` on it. A new rule ships with an assert and a new input path with
a case, in the same pass - from task 0112 on in `src/tools/headless_v1.gd` and
`src/tools/input_v1.gd` once 0112 has made them (the older suites are full).

Code, identifiers, comments and player-facing strings are in English; every
new string is a row in `assets/locale/strings.csv` with its pt_BR text. Art
comes only from the Codex packs in `implementation/backlog/` through the raster
pipeline (`assets/art_source/`, `tools/import_art.py`): never hand-paint or
generate PNGs in a game task.

`docs/PLANO-DO-JOGO.md` is the source of truth for intent in 1.0 (its section
12 says what it changes in `design.md`); `docs/reference-sheet.png` and the
approved 32px farmer are the look. If this task contradicts either, follow the
task and say so in the journal.
