# 0175 - The axe and the pickaxe by tier

- **Phase:** 12 - The day that pays
- **Status:** done
- **Depends on:** 0173
- **Likely files:** src/core/interact.gd, src/core/gathering.gd, src/core/game_data.gd, src/ui/main.gd, assets/locale/strings.csv, src/tools/headless_v1.gd

## Goal

The axe and the pickaxe save time by tier, and the hardest things on the farm - hardwood stumps and gold - want the iron ones.

## Requirements

- Fewer swings by tier: the tool's tier scales the swing in `Interact.ticks_for` or the `hits` `Gathering.strike` counts - pick one, keep it integer, and make it compose with 'sharp tools' (`gather_percent`) rather than replace it
- A `GATHERING` entry may name a `min_tier`; below it the cell still shows its verb but the work is refused with a reason in both languages ('needs an iron axe'), never a swing that silently does nothing - through the `Interact` reason road 0171 opened (a `Building.why_not`-shaped array that `Names.refusal` words), or open it here if 0171 has not landed
- The real gates arrive with their nodes - hardwood stumps (0177) want an iron axe, gold (0176) an iron pickaxe - so test the rule here with a rigged entry
- `validate()` checks `min_tier` against the `TOOLS` ladder; `check_iron` and `check_reachable` still pass
- DATA moves; SIM only if the scenario gathers with an upgraded tool

## Done when

- [x] `_task_0175_swings` in `src/tools/headless_v1.gd`: an iron axe fells a tree in fewer ticks than a basic one, by the percent the lever claims; a rigged `min_tier` node refuses a basic pickaxe and yields to an iron one
- [x] The refusal fits its control in both languages (`tools/i18n_check.py`)
- [x] `python tools/verify.py` prints PASS
- [x] the determinism hash is unchanged, or the change is deliberate and both
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
