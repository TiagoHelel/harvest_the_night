# 0271 - Spring's fourteen nights

- **Phase:** 15 - Fifty-six nights and balance
- **Status:** todo
- **Depends on:** 0270, 0157
- **Likely files:** src/core/game_data.gd (`KEY_NIGHTS`, spring's `SEASON_NIGHTS`), src/tools/play_nights.gd, tools/play_nights.py, src/tools/headless_v1.gd

## Goal

Spring is the season that teaches: the walker, the runner, the tank and the breaker one at a time, all from the east, a Full Moon on day 7 and the Giant on day 14. Today's ten nights are the raw material, but they were balanced for two sides and a ten-night run, so they are rewritten rather than pasted.

## Requirements

- First the instrument, moved here from 0270: `tools/play_nights.py` forwards its arguments (today it passes none) and `python tools/play_nights.py <from> <to>` plays that range of dates with the scripted build, buying only what each date's season has unlocked (0234's `unlock_season`, money and materials) from a purse that starts where a run would be (what the earlier dates paid plus the income). 0272-0274 author with it
- Every spring night comes from the east only (0157's east region; 0270 already deleted the allowance today's ten had). Today's night 2, 'the same again from two sides', becomes a lesson one side can teach
- The plan's rhythm: days 1-6 grow gently, day 7 is a Full Moon of the kinds already met, days 8-13 grow again with the season's novelty - the breaker, 'Primavera (fim)' - and day 14 is the Full Moon with the Giant (0153's row) in company. A starting map: today's 1-6 to days 1-6, today's 7 (breakers) to day 8, today's 8-9 spread over 9-13, today's 10 to day 14 - change it if the numbers say so
- One new thing a night at most, and the night after an introduction is where it bites (0060's rule): the walker on 1, the runner and the tank in days 2-6, the breaker in 8-13. The introductions, day 7 and day 14 are `KEY_NIGHTS`; the other days come from spring's template
- Day 1 stays the tutorial night: a normal night 1 (the calm night only follows a fallen boss), winnable with what the tutorial (0141) gives; the tutorial asserts of 0041/0141 stay green
- Every night fits the night length (0137) with room for the last wave to be fought before dawn, **and fills it** (moved here by 0148): its last wave is sent no earlier than `NIGHT_TICKS - DAWN_MARGIN_TICKS - NIGHT_FILL_TICKS`, a new `# LEVER` in `src/core/game_data.gd` (60 s, 30-120) in `digest()`'s `time` row, and `tools/nights.py` prints each night's last send against that line. 0148 measured today's ten sending everything by 36-84 s of a 240 s night: every night it played was over, everything dead, about a minute in, and none of a thousand autoplayed nights reached dawn, so the plan's 'holding on until sunrise is worth as much as killing everything' (4.5) and its three to five minutes of waves never happen. Spread the waves - a later last wave, gaps that leave quiet stretches between them - rather than shortening `NIGHT_TICKS` below the plan's three minutes; day 1 too, still winnable with the tutorial's tower
- Notes in the voice of the authored ten, English, one line each - they are what `tools/nights.py` prints
- Author against `python tools/nights.py 1 14` (count, hit points and reward climb, peaking on 7 and 14) and `python tools/play_nights.py 1 14` at its three incomes
- DATA moves on purpose; SIM moves if day 1 changed, because the determinism scenario fights it - both numbers in `implementation/PROGRESS.md`

## Done when

- [ ] `_task_0271_spring_nights` in `src/tools/headless_v1.gd`: days 1-14 send only the walker, runner, tank, breaker and the Giant, only from the east; each kind is first sent on its authored introduction day; day 7 is the largest of days 1-7 and day 14 the largest of spring in hit points; the Giant is on day 14 and nowhere else; every day 1-14 sends its last wave after the fill line (`NIGHT_FILL_TICKS`) and before the dawn margin
- [ ] `python tools/play_nights.py 1 14` output is in the journal: night 1 holds at the lowest income, and every night that falls is named with what the curve does there; `python tools/play_nights.py 15 20` runs on 0270's summer draft and buys nothing summer has not unlocked
- [ ] Spring's table from `python tools/nights.py 1 14` is in the journal beside the old ten nights' numbers
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
