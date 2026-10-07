# 0277 - Balancing the year

- **Phase:** 15 - Fifty-six nights and balance
- **Status:** todo
- **Depends on:** 0271, 0272, 0273, 0274, 0276, 0259
- **Likely files:** tools/balance.py, tools/autoplay.py, src/core/game_data.gd, implementation/BALANCE.md, implementation/PROGRESS.md, src/tools/headless_v1.gd

## Goal

The phase's own target: an average player reaches winter having lost two to four nights, and every boss falls. Measured with the year autoplayer, moved with levers, written down - the way 0068 did it for ten nights.

## Requirements

- The target as numbers: the `balanced` policy loses 2-4 nights before Winter 1 (day 43), averaged over at least 8 seeds, and every boss falls for it on every seed. A boss that walks off at dawn is a repeat, not a loss (0153), and is counted apart
- `tools/balance.py` moves onto 0276's `RUN` lines (its parser, moved here from 0276) and sweeps the year: `NIGHTS = 10` and the win-rate-per-night arithmetic become survival per day and losses per season; `LEVERS` is re-chosen for 1.0 (season sizes, the Full Moon percent, boss hit points, house tiers, the night length, essence and night money), each regex matching exactly one line
- Size the sweep before running it: a year run takes minutes (0276 printed it, 0275 the winter night), so levers x values x 8 seeds x 4 policies is days of wall time. Sweep with the `balanced` policy on 4 seeds, run seeds as parallel processes, and keep the full `--year 8` for all four policies for the before and after tables; each sweep's wall time goes in BALANCE.md
- It keeps its safety: it refuses a dirty `game_data.gd`, holds the lock file and restores the file in a `finally`
- Start with the instrument, as 0068 found: before moving a lever, ask a losing run what it was doing; a fault in the autoplayer is fixed there and named in BALANCE.md, not tuned around
- No policy wins every night of the year by a wide margin (the dominant alarm, per season); no day sits at 0% survival across every policy; a lever that moves nothing across its range is reported as dead weight
- Re-run 0259's matchup tool after the levers move: every weapon is still the best buy somewhere and every enemy still needs a different answer
- Levers move in `src/core/game_data.gd` with their `# LEVER` ranges kept true and `GameData.validate()` passing. DATA moves on purpose; SIM moves too where the determinism scenario reads a moved lever - old and new numbers of both in PROGRESS.md
- A new top section of `implementation/BALANCE.md`, 'The year': losses by season and policy, boss repeats, the sweep tables, every applied change with its old and new value, and what is still off

## Done when

- [ ] `python tools/autoplay.py --year 8` after the changes: `balanced` loses between 2 and 4 nights before day 43 on average and every boss falls on every seed - the table is in BALANCE.md
- [ ] The sweep's own output in BALANCE.md shows no day at 0% survival across every policy and the dominant alarm silent in every season
- [ ] The season groups of 0271-0274 still pass with the moved levers, or the journal says which asserted relation the data proved wrong and how it was rewritten
- [ ] `python tools/balance.py` reads only `RUN` lines, and a short sweep leaves `game_data.gd` restored, the git tree clean and no `.balance-lock` behind
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
