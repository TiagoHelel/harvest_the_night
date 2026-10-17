# 0298 - The seasons' second weeks

- **Phase:** 15 - Fifty-six nights and balance
- **Status:** done
- **Depends on:** 0280
- **Likely files:** src/core/game_data.gd, src/core/almanac.gd, src/tools/nights.gd, src/tools/headless_v1.gd, implementation/BALANCE.md

## Goal

0280 found where the year tires: each season's days 9-13 send the same kinds from the same sides five nights running, only bigger - twenty of the year's 56 nights - and the forecast says the same thing two nights running about twenty times a year, most of them there. Give every second week something to meet without breaking the rhythm the plan wants (days 8-13 grow again with the season's novelty) or the year 0277 balanced.

## Requirements

- Measure first: `python tools/nights.py --sameness` for seeds 0-3, before and after, in the journal
- One written key night in each season's second week (day 11 is free of every other rule: no Full Moon, no boss, no introduction): a pinch rather than a bigger copy - the season's heaviest kinds from one side, or its newest kind leading - at the made night's hit points for that day, so `check_nights`' rules (a size never falls, a gap never grows) hold as written
- The made nights of days 9-13 no longer share a mix: a template's `mix` may name a day a kind's weight changes (`[weight, the day it joins]` gains an optional third, `[weight, day, weight from day 9]`), read by `Almanac.mix_on`, checked by `check_nights`; Year 2's `_later` follows it
- Targets, asserted in `_task_0298_second_weeks` in `src/tools/headless_v1.gd`: no two nights of a season's days 9-13 share their mix of kinds and sides; the longest run of nights that bring nothing new is three at most; the forecast says the same thing two nights running at most once a season
- The year still holds: `python tools/autoplay.py --year 8` after the change keeps 0277's target (`towers` two to four nights lost before Winter 1) or the journal says why and the owner calls it; the table in the journal
- DATA moves on purpose (the key nights and the templates), SIM should not - the determinism night is day 1 - both in `implementation/PROGRESS.md`

## Done when

- [ ] `_task_0298_second_weeks` in `src/tools/headless_v1.gd` holds the three sameness targets for seeds 0-3
- [ ] `python tools/nights.py --sameness` before and after, and the `--year 8` table after, are in the journal
- [ ] `python tools/verify.py` prints PASS
- [ ] the determinism hash is unchanged, or the change is deliberate and both the old and the new number are in the journal
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
