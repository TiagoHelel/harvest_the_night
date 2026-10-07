# 0279 - Year 2

- **Phase:** 15 - Fifty-six nights and balance
- **Status:** todo
- **Depends on:** 0160, 0277
- **Likely files:** src/core/game_data.gd, src/core/almanac.gd, src/core/endless.gd, src/core/waves.gd, src/core/run.gd, src/ui/result_screen.gd, assets/locale/strings.csv, src/tools/nights.gd, tools/nights.py, src/tools/perf_check.gd, tools/perf.py, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd

## Goal

After the Winter Lord the farm carries on, and today that means the MVP's endless curve. Replace it with the calendar: Year 2 and every year after replay the four seasons from 0270's templates, heavier each year, with the bosses back on every day 14.

## Requirements

- Days past 56 resolve through 0270's generator (wherever it lives): the year and the season from 0149's `Calendar` helpers, the season's template scaled by a per-year growth `# LEVER` that is added, not compounded (the `ENDLESS.growth_percent` lesson), with the mix allowed to lean heavier each year. The plan wants Year 2 heavier 'a cada estação': the journal compares Year 2's spring with Year 1's winter, and a drop between them stands only with its reason written down
- Every season's day 14 sends its boss again (0153's row), with hit points scaled per year by a `# LEVER` through the `max_hp` road 0257's elites use, read by `Combat.full_hp` (0246); the boss-repeat rule (0153) and the calm night after a fallen boss (0154) hold every year, so Spring 1 of Year 2 is calm
- Later years have no introductions; the Full Moons on 7 and 14 stay - Year 1's records scaled, or generated with the Full Moon percent: decide one and assert it
- Sides and events keep to their season as in Year 1, so each season keeps its character; the Blood Moon comes earlier only if a lever says so
- Retire the MVP curve: `Endless` and the `ENDLESS` table, `giant_every` levers included (0153 left them to this task), leave `plain_night`, `check_nights` and `digest()` (a reader of `Endless._stream_for`, such as 0256's `Weather`, keeps the helper in its new home); `_task_0070_endless` in `src/tools/headless_check.gd` is rewritten over the later years or removed with the reason in the journal; 0160's carry-on lands in Year 2 of the calendar, and `Run`'s `endless` flag means 'past Year 1' or goes. A saved key that changes meaning gets a `State.VERSION` bump, a migration and a golden (never a key named `moon_phase`); otherwise no bump. `validate()` checks the new levers' ranges
- 0160's ending screen shows once, after Year 1; a later Winter Lord ends his year with a line in the morning report (`result_screen.gd`): a new `RES_YEAR_SURVIVED` row (key,width,en,pt_BR: YEAR %d SURVIVED / ANO %d SOBREVIVIDO, width measured). The HUD's 'SPRING 3  YEAR 2' is already 0149's `DHUD_DATE_YEAR`; add a `year_two` scenario (a Year 2 day) to `src/tools/shot.gd` to see it
- `python tools/nights.py --years 3` prints Years 1-3 by season with sizes, bosses and events; generation stays a fresh `(seed, day)` stream
- The curve stays sane to Year 3: `perf_check.gd` takes a date (e.g. `--date=<n>`, forwarded by `tools/perf.py`, which compares and accepts nothing on such a run) and times 0275's case on Year 3's heaviest night; the `balanced` policy plays into Year 2 on one seed with `Autoplay.play(seed, policy, days)`
- Hashes: DATA moves (the new levers; `ENDLESS` leaves the digest). SIM should not - the determinism night is day 1 - unless a state key goes (e.g. `endless`), which moves it on purpose; both numbers in `implementation/PROGRESS.md`

## Done when

- [ ] `_task_0279_year_two` in `src/tools/headless_v1.gd`: day 57 is Spring 1 of Year 2 and calm; a Giant spawned on day 70 has more `Combat.full_hp` than one spawned on day 14; on every day of the year but Spring 1 (Year 1's is the tutorial night), Year 2 sends at least Year 1's hit points on the same day and Year 3 at least Year 2's; days 57-168 resolve for seeds 0-2 without touching `state["rng"]`
- [ ] Year 3's heaviest night is inside `TICK_BUDGET_US` and `PATH_BUDGET_US` (`python tools/perf.py --date=<it>`) - the numbers in the journal
- [ ] The `python tools/nights.py --years 3` summary and where the `balanced` policy fell in Year 2 are in the journal
- [ ] `python tools/shot.py 0279 year_two --fhd` opened: the year label fits, in English and in Portuguese
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
