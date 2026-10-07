# 0149 - The calendar: four seasons of fourteen days

- **Phase:** 11 - Calendar and seasons
- **Status:** todo
- **Depends on:** 0148
- **Likely files:** src/core/calendar.gd (new), src/core/game_data.gd, src/ui/day_hud.gd, src/ui/names.gd, assets/locale/strings.csv, src/tools/headless_v1.gd, src/tools/input_v1.gd, src/tools/input_check.gd

## Goal

The farm learns what day of the year it is. Every rule of this phase hangs off one small set of pure helpers, and the player sees 'SPRING 3' beside the clock - before a single rule reads it.

## Requirements

- `src/core/calendar.gd` (`class_name Calendar`, node-free, static): `date(state)` - the calendar day, which is `state["day"]` until 0153 adds the boss hold, and the one place that knows it - plus pure `year_of(date)`, `season_of(date)` (0-3), `day_of_season(date)` (1-14) and `year_days()`. Each pure helper takes an optional season length, so a test can prove a seven-day season without editing the lever
- `GameData.SEASON_DAYS := 14  # LEVER: days a season, 7-28` and `SEASONS: Array` of the ids `spring`, `summer`, `autumn`, `winter` (names, not a lever); `validate()` gains `check_calendar` (four seasons, a season of at least two days), and both go into `digest()` (0112's coverage assert)
- No new State key and no rule reads the calendar yet: day 1 is Spring 1 of Year 1, day 14 Spring 14, day 15 Summer 1, day 56 Winter 14, day 57 Spring 1 of Year 2
- The day HUD shows the date beside 0126's HH:MM clock: `SPRING 3`, and `SPRING 3  YEAR 2` from the second year on. It takes the place of the day count in the clock line (`DAY %d` in `DHUD_DAY` / `DHUD_DAY_FIRST`, as 0126 and 0140 left them): one number for the day, not two. Rewrite in place the input_check cases that read `DAY 1` (`_case_0021_day_hud`, `_case_0039_clock`) and drop any row nothing reads any more. Season names go through `Names.KEYS` (`spring` -> `SEASON_SPRING`, ...) so `tools/i18n_check.py` sees literal keys
- `assets/locale/strings.csv` rows, both languages: `SEASON_SPRING` SPRING / PRIMAVERA, `SEASON_SUMMER` SUMMER / VERÃO, `SEASON_AUTUMN` AUTUMN / OUTONO, `SEASON_WINTER` WINTER / INVERNO, `DHUD_DATE` `%s %d` / `%s %d`, `DHUD_DATE_YEAR` `%s %d  YEAR %d` / `%s %d  ANO %d`; the width is the label's real width, measured
- The night HUD keeps its night number for now: `night` is not the date until 0151, and 0158 names the date there
- Hashes: SIM must not move. DATA moves once, because the calendar levers enter `digest()` - both numbers in the journal

## Done when

- [ ] `_task_0149_calendar` in `src/tools/headless_v1.gd` asserts the five mappings above, a seven-day season through the optional argument, `year_days() == 56`, and that a state's hash is the same before and after asking every helper
- [ ] `_case_0149_date` in `src/tools/input_v1.gd` reads `SPRING 3` on day 3 and `SUMMER 1` on day 15 from the day HUD, in English and in Portuguese (`PRIMAVERA 3`, `VERÃO 1`)
- [ ] `python tools/shot.py 0149 noon dusk --fhd` and the same with `--pt_BR`, opened: the date sits by the clock and nothing overlaps
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
