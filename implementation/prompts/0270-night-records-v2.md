# 0270 - Fifty-six nights as data

- **Phase:** 15 - Fifty-six nights and balance
- **Status:** done
- **Depends on:** 0151, 0152, 0153, 0154, 0256, 0257, 0234
- **Likely files:** src/core/game_data.gd, src/core/waves.gd, src/core/endless.gd, src/core/almanac.gd (new), src/core/weather.gd, src/tools/nights.gd, tools/nights.py, src/tools/headless_check.gd, src/tools/headless_v1.gd

## Goal

The year stops being ten written nights plus a curve and becomes tables a designer can read: a template per season, hand-written key nights (every introduction, every Full Moon) and a seeded generator for the nights in between. Nothing downstream of `Waves.night_of` can tell which is which, so the season tasks after this one edit data (0271 also gives `play_nights` a day range).

## Requirements

- A night is still `{note, opening_ticks, gap_ticks, waves}` with waves `[kind, count, spawn, delay?]`, so `Waves`, `Enemies`, `Rewards`, the forecast (0158) and the HUD need no new case. Two new tables in `src/core/game_data.gd`: `SEASON_NIGHTS` (per season: the sides it deals from - indices open for that season in 0157's `SIDES_BY_SEASON`, never a second copy of that table - each with the day it joins, so a season brings a new side in gently; the kinds of its mix with a weight and the day each joins; a size in hit points - the honest measure 0060 used, `play_nights.gd`'s `_hit_points_of` - at the season's second and thirteenth day; waves and gap from/to; every number a `# LEVER` with a range) and `KEY_NIGHTS` (day of the year 1-56 -> a record)
- Key nights are each kind's introduction and the Full Moons on days 7 and 14 of every season. No record names a boss: 0153's rule in `Waves.night_of` adds the `SEASON_BOSSES` row on day 14 (0253-0255 put theirs there), so a day-14 key night writes only the boss's company. Draft content so all 56 resolve: today's nights 1-9 as spring's days 1-9 and today's 10, without its Giant row, as day 14, their south-east rows moved to the east; delete 0157's commented allowance for today's ten, which nothing needs now (0271 has nothing left to remove). Day 1 stays byte-identical. Summer to winter get drafts that send spring's kinds only; 0271-0274 author them for real
- Days 15, 29 and 43 are 0154's calm dates (`Calendar.is_calm`): `night_of` already returns the calm record for them, so they carry no key night and the generator never makes one
- A node-free generator - `src/core/almanac.gd` with `Almanac.night(seed, day)`, or the home 0150/0158 already gave the calendar lookup (extend it, never a second one) - fills every other day from its season's template with a fresh stream from `(seed, day)` (the `Endless._stream_for` pattern), never `state["rng"]`. The seed orders the waves and picks among the open sides; it never changes the totals per kind (the `Endless` contract)
- `Waves.plain_night(day, seed)` (0150) is where the year comes from - the key night first, else the generator - and `night_of` keeps 0152-0154's rules on top of it, unchanged. `Waves.tonight` keeps caching generated records on `state.wave.tonight`, so no new State key and `remaining()` stays free per frame. `GameData.NIGHTS` retires here (its rows are spring's draft) and `Waves.authored_count()` with it: grep `src/` and `tools/` for both and move every reader. Past day 56 the lookup keeps serving `Endless.night` until 0279 (if its base or step must read something new, the journal says what day 57 sends before and after); `perf_check.gd`'s worst case stays on Spring 14 (0153) until 0275
- Decide in one place whether 0152's Full Moon percent scales an authored Full Moon record or is already written into it - one, never both, and the forecast's count equals what is sent. A key night may pin or forbid an event with an optional `event` field, read by 0256's `Weather` chooser for that `(seed, day)`; a pin still obeys `check_night_events` and `Weather`'s own rules (no Blood Moon before autumn, on a boss night or - 0257's decision - on a Full Moon; nothing on Spring 1 or a calm date)
- `GameData.check_nights(templates, key_nights)` takes its tables as arguments, as it takes `nights` today, so a test can hand it a broken copy. It refuses: a boss in any template or key night (the boss row is 0153's); an unknown kind in a template; a side not open in that season (0157); a size that falls or a gap that grows across a season (0060's curve rules); a key-night day outside 1-56 or on a calm date; a Full Moon day without a key night; a schedule that outlasts the night (0137); an unknown `event`. The per-record rules are one function: `validate()` runs it on seed 0's year only, so loading stays cheap, and 0151's `python tools/nights.py --check` gate runs it on every date for its two seeds
- `GameData.digest()` lists `SEASON_NIGHTS` and `KEY_NIGHTS` and drops `NIGHTS` (0112's coverage assert passes). DATA moves on purpose; SIM should not, day 1 being identical - if it moves, the journal says why. What 0150-0153 left of `_task_0058_giant`, `_task_0059_wave_data`, `_task_0060_ten_nights` and `_task_0070_endless` in `src/tools/headless_check.gd` that reads `GameData.NIGHTS` rows reads the year through `Waves.plain_night` instead, keeping what each asserted
- `python tools/nights.py` prints the year by default: a block per season, each day's kinds, sides, count, hit points, reward and event, with key, Full Moon, boss and calm days marked, then first-seen per kind and the size bars. Its positional arguments change from today's `[count] [seed]` to `[from] [to] [seed]` (`python tools/nights.py 15 28 3` prints a range); `--check` stays; the docstrings of `nights.gd` and `nights.py` say so

## Done when

- [ ] `_task_0270_year_records` in `src/tools/headless_v1.gd`: for seeds 0-4 every day 1-56 is a key night, a generated record or a calm date; generated records pass the per-record rules an authored one does; two seeds send the same totals per kind on every day; generating day 30 leaves `state["rng"]` untouched; no kind is sent before the day its key night or template introduces it; day 1's record equals the old night 1
- [ ] The same group hands `check_nights` doctored copies - a boss in a key night, an unknown kind in a template's mix, a spring night from the south-east, a key night on day 15 - and each is refused
- [ ] For days 1-56 and two seeds, 0158's forecast counts equal `Waves.size_of`/`kinds_of` for the same day
- [ ] The year from `python tools/nights.py` is in the journal: count, hit points and reward per day, by season
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
