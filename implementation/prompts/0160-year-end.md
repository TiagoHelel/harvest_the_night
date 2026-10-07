# 0160 - The end of the year

- **Phase:** 11 - Calendar and seasons
- **Status:** todo
- **Depends on:** 0153, 0151, 0154
- **Likely files:** src/core/run.gd, src/ui/result_screen.gd, src/ui/credits_roll.gd (new), src/ui/main.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

When the winter boss - for now the Giant - falls on Winter 14, the year is over: an ending, the credits, and the choice to carry on into a Year 2 that does not end.

## Requirements

- `Run.is_over` is 'the year's last boss has fallen and the run is not endless': with 0153's hold the date passes `Calendar.year_days()` only then. A lost or escaped Winter 14 is not an ending; a Winter 14 lost after its boss fell is
- The morning report's ending branch (0138's screen, today's `_build_the_ending`): `YOU SURVIVED A YEAR` with what `Run.summary` already holds (days lived, nights won, bosses down, killed, structures lost, the build that won), then two choices
- Carry on: `Run.go_endless` (only once the year is beaten); the farmer wakes on Year 2 Spring 1 - 0154's calm night - and the nights keep coming through the lookup from today's Endless until 0279 makes later years heavier
- A new farm: the run is recorded (`Run.record`: `runs_won` counts the year; `best_night` keeps its meaning, any change to it is 0291's) and a new run starts, as `_record_and_restart` does today
- A credits roll before the choices (`src/ui/credits_roll.gd`): lines from `CRED_*` strings, skippable with confirm or cancel on keyboard, mouse and pad
- Strings in both languages replace the MVP's: `RES_NEW_FARM` (A NEW FARM / UMA FAZENDA NOVA), `RES_PLAY_ON` (CARRY ON INTO YEAR %d / SEGUIR PARA O ANO %d), `RES_RUN_LINE` without 'the Giant', `END_TITLE` (YOU SURVIVED A YEAR / VOCÊ SOBREVIVEU UM ANO); remove the rows nothing reads any more
- Keep the node names `ContinueButton` and `PlayOnButton`, and rewrite in place what reads the old ending as 0151 left it: input_check's `_case_0070_endless` (the credits now come first), `_task_0066_run_end`'s over/carry-on asserts and `_task_0070_endless`'s `go_endless` refusals, against the new `Run.is_over`
- Hashes: SIM must not move (the determinism run never reaches Winter 14) and DATA does not

## Done when

- [ ] `_task_0160_year_end` in `src/tools/headless_v1.gd`, from a Winter 14 fixture (date 56, started through 0118's road, never by playing the year): boss down -> `Run.is_over` and the result says so; boss escaped -> not over, the date still 56; carried on -> not over, and the next night is date 57, Year 2 Spring 1, calm; `Run.record` counts the year in `runs_won`
- [ ] `_case_0160_ending` in `src/tools/input_v1.gd`: the ending shows, the credits skip by keyboard and by pad, CARRY ON returns to the farm on Year 2 Spring 1, and A NEW FARM starts day 1 of a new run
- [ ] A `year_end` shot scenario: `python tools/shot.py 0160 year_end --fhd` and with `--pt_BR`, opened - nothing overflows
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
