# -*- coding: utf-8 -*-
"""Backlog part 11: fifty-six nights and the balance of a year.

By here every enemy, boss, weapon and event exists, and the nights are still
the MVP's ten plus a curve. This phase writes the year as data, authors each
season's key nights, moves the benchmark to the worst night 1.0 can produce,
teaches the autoplayer the whole loop and balances the year with it - in that
order, so the sweeps run on final content and on the final cost profile.
"""

P15 = "15 - Fifty-six nights and balance"

TASKS = [
    # ================================== phase 15 - fifty-six nights and balance
    dict(id=270, phase=P15, title="Fifty-six nights as data",
         slug="night-records-v2", deps=[151, 152, 153, 154, 256, 257, 234],
         files="src/core/game_data.gd, src/core/waves.gd, src/core/endless.gd, "
               "src/core/almanac.gd (new), src/core/weather.gd, "
               "src/tools/nights.gd, tools/nights.py, "
               "src/tools/headless_check.gd, src/tools/headless_v1.gd",
         goal="The year stops being ten written nights plus a curve and becomes "
              "tables a designer can read: a template per season, hand-written "
              "key nights (every introduction, every Full Moon) and a seeded "
              "generator for the nights in between. Nothing downstream of "
              "`Waves.night_of` can tell which is which, so the season tasks "
              "after this one edit data (0271 also gives `play_nights` a day "
              "range).",
         req=["A night is still `{note, opening_ticks, gap_ticks, waves}` with "
              "waves `[kind, count, spawn, delay?]`, so `Waves`, `Enemies`, "
              "`Rewards`, the forecast (0158) and the HUD need no new case. Two "
              "new tables in `src/core/game_data.gd`: `SEASON_NIGHTS` (per "
              "season: the sides it deals from - indices open for that season "
              "in 0157's `SIDES_BY_SEASON`, never a second copy of that table "
              "- each with the day it joins, so a season brings a new side in "
              "gently; the kinds of its mix with a weight and the day each "
              "joins; a size in hit points - the honest measure 0060 used, "
              "`play_nights.gd`'s `_hit_points_of` - at the season's second "
              "and thirteenth day; waves and gap from/to; every number a "
              "`# LEVER` with a range) and `KEY_NIGHTS` (day of the year 1-56 "
              "-> a record)",
              "Key nights are each kind's introduction and the Full Moons on "
              "days 7 and 14 of every season. No record names a boss: 0153's "
              "rule in `Waves.night_of` adds the `SEASON_BOSSES` row on day 14 "
              "(0253-0255 put theirs there), so a day-14 key night writes only "
              "the boss's company. Draft content so all 56 resolve: today's "
              "nights 1-9 as spring's days 1-9 and today's 10, without its "
              "Giant row, as day 14, their south-east rows moved to the east; "
              "delete 0157's commented allowance for today's ten, which "
              "nothing needs now (0271 has nothing left to remove). Day 1 "
              "stays byte-identical. Summer to winter get drafts that send "
              "spring's kinds only; 0271-0274 author them for real",
              "Days 15, 29 and 43 are 0154's calm dates (`Calendar.is_calm`): "
              "`night_of` already returns the calm record for them, so they "
              "carry no key night and the generator never makes one",
              "A node-free generator - `src/core/almanac.gd` with "
              "`Almanac.night(seed, day)`, or the home 0150/0158 already gave "
              "the calendar lookup (extend it, never a second one) - fills every "
              "other day from its season's template with a fresh stream from "
              "`(seed, day)` (the `Endless._stream_for` pattern), never "
              "`state[\"rng\"]`. The seed orders the waves and picks among the "
              "open sides; it never changes the totals per kind (the `Endless` "
              "contract)",
              "`Waves.plain_night(day, seed)` (0150) is where the year comes "
              "from - the key night first, else the generator - and "
              "`night_of` keeps 0152-0154's rules on top of it, unchanged. "
              "`Waves.tonight` keeps caching generated records on "
              "`state.wave.tonight`, so no new State key and `remaining()` "
              "stays free per frame. `GameData.NIGHTS` retires here (its rows "
              "are spring's draft) and `Waves.authored_count()` with it: grep "
              "`src/` and `tools/` for both and move every reader. Past day 56 "
              "the lookup keeps serving `Endless.night` until 0279 (if its "
              "base or step must read something new, the journal says what "
              "day 57 sends before and after); `perf_check.gd`'s worst case "
              "stays on Spring 14 (0153) until 0275",
              "Decide in one place whether 0152's Full Moon percent scales an "
              "authored Full Moon record or is already written into it - one, "
              "never both, and the forecast's count equals what is sent. A key "
              "night may pin or forbid an event with an optional `event` "
              "field, read by 0256's `Weather` chooser for that `(seed, day)`; "
              "a pin still obeys `check_night_events` (no Blood Moon before "
              "autumn or on a boss night, nothing on Spring 1 or a calm date)",
              "`GameData.check_nights(templates, key_nights)` takes its tables "
              "as arguments, as it takes `nights` today, so a test can hand it "
              "a broken copy. It refuses: a boss in any template or key night "
              "(the boss row is 0153's); an unknown kind in a template; a side "
              "not open in that season (0157); a size that falls or a gap "
              "that grows across a season (0060's curve rules); a key-night "
              "day outside 1-56 or on a calm date; a Full Moon day without a "
              "key night; a schedule that outlasts the night (0137); an "
              "unknown `event`. The per-record rules are one function: "
              "`validate()` runs it on seed 0's year only, so loading stays "
              "cheap, and 0151's `python tools/nights.py --check` gate runs it "
              "on every date for its two seeds",
              "`GameData.digest()` lists `SEASON_NIGHTS` and `KEY_NIGHTS` and "
              "drops `NIGHTS` (0112's coverage assert passes). DATA moves on "
              "purpose; SIM should not, day 1 being identical - if it moves, "
              "the journal says why. What 0150-0153 left of "
              "`_task_0058_giant`, `_task_0059_wave_data`, "
              "`_task_0060_ten_nights` and `_task_0070_endless` in "
              "`src/tools/headless_check.gd` that reads `GameData.NIGHTS` rows "
              "reads the year through `Waves.plain_night` instead, keeping "
              "what each asserted",
              "`python tools/nights.py` prints the year by default: a block per "
              "season, each day's kinds, sides, count, hit points, reward and "
              "event, with key, Full Moon, boss and calm days marked, then "
              "first-seen per kind and the size bars. Its positional arguments "
              "change from today's `[count] [seed]` to `[from] [to] [seed]` "
              "(`python tools/nights.py 15 28 3` prints a range); `--check` "
              "stays; the docstrings of `nights.gd` and `nights.py` say so"],
         dod=["`_task_0270_year_records` in `src/tools/headless_v1.gd`: for "
              "seeds 0-4 every day 1-56 is a key night, a generated record or a "
              "calm date; generated records pass the per-record rules an "
              "authored one does; two seeds send the same totals per kind on "
              "every day; generating day 30 leaves `state[\"rng\"]` untouched; "
              "no kind is sent before the day its key night or template "
              "introduces it; day 1's record equals the old night 1",
              "The same group hands `check_nights` doctored copies - a boss in "
              "a key night, an unknown kind in a template's mix, a spring "
              "night from the south-east, a key night on day 15 - and each is "
              "refused",
              "For days 1-56 and two seeds, 0158's forecast counts equal "
              "`Waves.size_of`/`kinds_of` for the same day",
              "The year from `python tools/nights.py` is in the journal: count, "
              "hit points and reward per day, by season"]),

    dict(id=271, phase=P15, title="Spring's fourteen nights", slug="spring-nights",
         deps=[270, 157],
         files="src/core/game_data.gd (`KEY_NIGHTS`, spring's `SEASON_NIGHTS`), "
               "src/tools/play_nights.gd, tools/play_nights.py, "
               "src/tools/headless_v1.gd",
         goal="Spring is the season that teaches: the walker, the runner, the "
              "tank and the breaker one at a time, all from the east, a Full Moon "
              "on day 7 and the Giant on day 14. Today's ten nights are the raw "
              "material, but they were balanced for two sides and a ten-night "
              "run, so they are rewritten rather than pasted.",
         req=["First the instrument, moved here from 0270: "
              "`tools/play_nights.py` forwards its arguments (today it passes "
              "none) and `python tools/play_nights.py <from> <to>` plays that "
              "range of dates with the scripted build, buying only what each "
              "date's season has unlocked (0234's `unlock_season`, money and "
              "materials) from a purse that starts where a run would be (what "
              "the earlier dates paid plus the income). 0272-0274 author with "
              "it",
              "Every spring night comes from the east only (0157's east "
              "region; 0270 already deleted the allowance today's ten had). "
              "Today's night 2, 'the same again from two sides', becomes a "
              "lesson one side can teach",
              "The plan's rhythm: days 1-6 grow gently, day 7 is a Full Moon of "
              "the kinds already met, days 8-13 grow again with the season's "
              "novelty - the breaker, 'Primavera (fim)' - and day 14 is the Full "
              "Moon with the Giant (0153's row) in company. A starting map: "
              "today's 1-6 to "
              "days 1-6, today's 7 (breakers) to day 8, today's 8-9 spread over "
              "9-13, today's 10 to day 14 - change it if the numbers say so",
              "One new thing a night at most, and the night after an "
              "introduction is where it bites (0060's rule): the walker on 1, "
              "the runner and the tank in days 2-6, the breaker in 8-13. The "
              "introductions, day 7 and day 14 are `KEY_NIGHTS`; the other days "
              "come from spring's template",
              "Day 1 stays the tutorial night: a normal night 1 (the calm night "
              "only follows a fallen boss), winnable with what the tutorial "
              "(0141) gives; the tutorial asserts of 0041/0141 stay green",
              "Every night fits the night length (0137) with room for the last "
              "wave to be fought before dawn, **and fills it** (moved here by "
              "0148): its last wave is sent no earlier than `NIGHT_TICKS - "
              "DAWN_MARGIN_TICKS - NIGHT_FILL_TICKS`, a new `# LEVER` in "
              "`src/core/game_data.gd` (60 s, 30-120) in `digest()`'s `time` "
              "row, and `tools/nights.py` prints each night's last send against "
              "that line. 0148 measured today's ten sending everything by 36-84 "
              "s of a 240 s night: every night it played was over, everything "
              "dead, about a minute in, and none of a thousand autoplayed nights "
              "reached dawn, so the plan's 'holding on until sunrise is worth as "
              "much as killing everything' (4.5) and its three to five minutes "
              "of waves never happen. Spread the waves - a later last wave, gaps "
              "that leave quiet stretches between them - rather than shortening "
              "`NIGHT_TICKS` below the plan's three minutes; day 1 too, still "
              "winnable with the tutorial's tower",
              "Notes in the voice of the authored ten, English, one line each - "
              "they are what `tools/nights.py` prints",
              "Author against `python tools/nights.py 1 14` (count, hit points "
              "and reward climb, peaking on 7 and 14) and `python "
              "tools/play_nights.py 1 14` at its three incomes",
              "DATA moves on purpose; SIM moves if day 1 changed, because the "
              "determinism scenario fights it - both numbers in "
              "`implementation/PROGRESS.md`"],
         dod=["`_task_0271_spring_nights` in `src/tools/headless_v1.gd`: days "
              "1-14 send only the walker, runner, tank, breaker and the Giant, "
              "only from the east; each kind is first sent on its authored "
              "introduction day; day 7 is the largest of days 1-7 and day 14 the "
              "largest of spring in hit points; the Giant is on day 14 and "
              "nowhere else; every day 1-14 sends its last wave after the fill "
              "line (`NIGHT_FILL_TICKS`) and before the dawn margin",
              "`python tools/play_nights.py 1 14` output is in the journal: "
              "night 1 holds at the lowest income, and every night that falls "
              "is named with what the curve does there; `python "
              "tools/play_nights.py 15 20` runs on 0270's summer draft and "
              "buys nothing summer has not unlocked",
              "Spring's table from `python tools/nights.py 1 14` is in the "
              "journal beside the old ten nights' numbers"]),

    dict(id=272, phase=P15, title="Summer's fourteen nights",
         slug="summer-nights", deps=[270, 247, 248, 253, 259, 271],
         files="src/core/game_data.gd (`KEY_NIGHTS`, summer's `SEASON_NIGHTS`), "
               "src/tools/headless_v1.gd",
         goal="Summer opens the second side and brings the first enemies that "
              "change what a spring defence is worth: the spitter shoots towers "
              "from range, the rats come in numbers that mines and fire love, "
              "and on day 28 the Harvester charges straight through the walls.",
         req=["Days 16-28 fight; day 15 is 0154's calm night after the Giant. "
              "The east and the south-east are open (0157), and the first "
              "south-east night is a small one, so the new side is learned "
              "before it is tested",
              "Summer's first fight starts below spring's Full Moons and above "
              "spring's day 6, so the year still climbs; spring's four kinds "
              "stay in the mix at summer's share",
              "The spitter and the rat swarm are introduced on different nights "
              "- one in days 16-20, the other in days 22-27 - never together; "
              "the Full Moon on day 21 sends what is already known; the night "
              "after each introduction bites",
              "Day 28 is the Full Moon with the Harvester in company, so it "
              "cannot be focused alone: the Harvester is the row 0153's rule "
              "adds from `SEASON_BOSSES` (0253 put it there), and this task "
              "writes its company",
              "Read 0259's `implementation/MATCHUPS.md` first: every night's "
              "mix has an answer in what summer's arsenal (0234) has unlocked "
              "by that day - the flamethrower, the decoy, the beehive and the "
              "bait arrive this season - and the journal says which weapon "
              "each new enemy is meant to teach",
              "Rats are many bodies: print the peak entity count of the largest "
              "rat night and compare it with what the swarm scenario of "
              "0218/0248 in `perf_check.gd` measured; the year's worst case is "
              "0275's",
              "Author against `python tools/nights.py 15 28` and `python "
              "tools/play_nights.py 15 28` (0271's range), starting from "
              "spring's final numbers; notes in the authored voice; every "
              "night fits and fills the night (0137, 0271's "
              "`NIGHT_FILL_TICKS`); DATA moves on purpose, SIM "
              "only if a day the determinism scenario fights changed"],
         dod=["`_task_0272_summer_nights` in `src/tools/headless_v1.gd`: days "
              "16-28 send only kinds introduced by that day, only from the east "
              "and the south-east; the spitter and the rats are first sent on "
              "their introduction days, on different nights; the Harvester is "
              "on day 28 and nowhere else; days 21 and 28 are the largest of "
              "their halves in hit points",
              "`python tools/nights.py 15 28` and `python tools/play_nights.py "
              "15 28` output in the journal, with the matchup line for each new "
              "enemy and the peak rat count"]),

    dict(id=273, phase=P15, title="Autumn's fourteen nights",
         slug="autumn-nights", deps=[270, 249, 250, 254, 259, 272],
         files="src/core/game_data.gd (`KEY_NIGHTS`, autumn's `SEASON_NIGHTS`), "
               "src/tools/headless_v1.gd",
         goal="Autumn opens the north and brings the two enemies that ignore "
              "the shape of a maze: the crow flies over it to eat the crops, the "
              "digger goes under the fences and barricades. The Scarecrow King "
              "calls his flocks on day 42, and the Blood Moon can rise from now "
              "on.",
         req=["Days 30-42 fight; day 29 is 0154's calm night after the "
              "Harvester. The east, the south-east and the north are open "
              "(0157); the first north night is a small one",
              "The crow and the digger are introduced on different nights - one "
              "in days 30-34, the other in days 36-41 - never together; the Full "
              "Moon on day 35 sends what is already known; the night after each "
              "introduction bites",
              "Crows eat what is in the ground, and autumn's fields are full "
              "(wheat, pumpkin, grape, beet): crow nights are the ones where the "
              "farm's layout matters, so their first one is gentle",
              "Day 42 is the Full Moon with the Scarecrow King in company - "
              "0153's row from `SEASON_BOSSES`, which 0254 set; this task "
              "writes the company. The crows he summons come from his rule, "
              "not from rows, so the forecast's count leaves them out by "
              "design (0254): day 42's note says he calls crows, and the "
              "journal gives the peak count of crows alive on day 42 in "
              "`play_nights`",
              "The Blood Moon (0257) may roll from autumn: list which autumn "
              "days roll it for seeds 0-4 in `tools/nights.py`, and pin `event` "
              "off on an introduction night it would drown (0270's field)",
              "Read 0259's `implementation/MATCHUPS.md`: every night has an "
              "answer in what autumn's arsenal (0234) has unlocked by that day "
              "- the mortar, "
              "the pumpkin catapult and the garlic braid - and the journal says "
              "which weapon each new enemy is meant to teach",
              "The template keeps climbing from summer's final numbers "
              "(`python tools/play_nights.py 29 42`); notes in the authored "
              "voice; every night fits and fills the night (0137, 0271's "
              "`NIGHT_FILL_TICKS`); DATA moves on "
              "purpose, SIM only if a day the determinism scenario fights "
              "changed"],
         dod=["`_task_0273_autumn_nights` in `src/tools/headless_v1.gd`: days "
              "30-42 send only kinds introduced by that day, only from the "
              "east, south-east and north; the crow and the digger are first "
              "sent on their introduction days, on different nights; the "
              "Scarecrow King is on day 42 and nowhere else; days 35 and 42 are "
              "the largest of their halves in hit points",
              "`python tools/nights.py 29 42` and `python tools/play_nights.py "
              "29 42` output in the journal, with the Blood Moon days for seeds "
              "0-4 and the matchup line for each new enemy"]),

    dict(id=274, phase=P15, title="Winter's fourteen nights",
         slug="winter-nights", deps=[270, 251, 252, 255, 259, 273],
         files="src/core/game_data.gd (`KEY_NIGHTS`, winter's `SEASON_NIGHTS`), "
               "src/tools/headless_v1.gd",
         goal="Winter is the exam: every side open, the frost zombie that slows "
              "the towers it dies beside, the wraith that cannot be shot outside "
              "the light, and the Winter Lord on day 56. Nothing grows, so these "
              "nights are fought with what autumn put away.",
         req=["Days 44-56 fight; day 43 is 0154's calm night after the "
              "Scarecrow King. Every side is open (0157), but the sides new to "
              "winter join over several nights through the side join days of "
              "winter's template (0270) and key nights - never on an "
              "introduction night",
              "The frost zombie and the wraith are introduced on different "
              "nights, never together; the Full Moon on day 49 sends what is "
              "already known; the night after each introduction bites",
              "The first wraith night is small and answerable with the light a "
              "farm has without a searchlight - the porch, the flare, burning "
              "cells (0229's light rule) - because it is the night that teaches "
              "the searchlight",
              "Day 56 is the Full Moon with the Winter Lord in company - "
              "0153's row from `SEASON_BOSSES`, which 0255 set; this task "
              "writes the company - and the largest night of Year 1; 0160's "
              "ending hook fires when he falls",
              "Nothing grows outdoors in winter (the plan; the rule is 0171), "
              "so the money for these nights was made in autumn: prefer a climb "
              "in variety - sides, kinds, events - over a climb in bodies",
              "Read 0259's `implementation/MATCHUPS.md`: every night has an "
              "answer in what winter's arsenal (0234) has unlocked by that day "
              "(`python tools/play_nights.py 43 56`) - the "
              "searchlight and the electric fence - and the journal says which "
              "weapon each new enemy is meant to teach",
              "Notes in the authored voice; every night fits and fills the night "
              "(0137, 0271's `NIGHT_FILL_TICKS`); DATA moves on purpose, SIM "
              "only if a day the determinism scenario fights changed",
              "With all four seasons authored, `GameData.check_nights` refuses a "
              "night whose last wave is sent before 0271's fill line "
              "(`NIGHT_FILL_TICKS`), for every date `python tools/nights.py "
              "--check` resolves: 0148 found a night that is over in a minute "
              "leaves dawn nothing to do"],
         dod=["`_task_0274_winter_nights` in `src/tools/headless_v1.gd`: days "
              "44-56 send only kinds introduced by that day; the frost zombie "
              "and the wraith are first sent on their introduction days, on "
              "different nights; the Winter Lord is on day 56 and nowhere else; "
              "day 56 is the largest night of days 1-56 in hit points; a copy "
              "of a night with its last wave moved before 0271's fill line is "
              "refused by `check_nights`",
              "`python tools/nights.py 43 56` and `python tools/play_nights.py "
              "43 56` output in the journal, with the matchup line for each new "
              "enemy and the night each side first opens",
              "`python tools/nights.py` for the whole year, after all four "
              "seasons, is in the journal: the year's curve in one table"]),

    dict(id=275, phase=P15, title="The worst night of the year, within budget",
         slug="perf-year", deps=[274, 234, 248, 233],
         files="src/tools/perf_check.gd, src/tools/perf_names.gd, "
               "tools/perf.py, tools/perf_baseline.txt, src/tools/headless_v1.gd",
         goal="The benchmark's worst case is still Spring 14, where 0153 moved "
              "the MVP's night ten. Move it "
              "to the heaviest night 1.0 can produce - Winter 14 with the Winter "
              "Lord, a rat swarm and every defence on the farm - and settle the "
              "cost profile before 0277 simulates thousands of nights on it.",
         req=["`_the_worst_case()` in `src/tools/perf_check.gd` sets the run to "
              "Winter 14 (day 56) the way the calendar reads it (0151), not "
              "through `nights_won`, and still stops at the busiest moment",
              "At least one of every `GameData.DEFENCES` entry - the plan's "
              "fourteen and whatever 0231 added - at the top `TOWER_LEVELS` "
              "level, powered and with ammunition, placed where the fight is "
              "through the build-step road of 0119; 0218's swarm scenario is "
              "folded in or kept as its own rows - say which",
              "Every lazily built path field in 0218's registry is built "
              "tonight, adding the kinds that force one if day 56 lacks them, so "
              "`path_refresh` is timed with all of them; the heaviest event day "
              "56 can roll is on - fog or rain, since 0257 keeps the Blood "
              "Moon off boss nights - by picking a seed `Weather` gives it, "
              "never an override in core",
              "`COUNT` lines for each defence family, each enemy kind, the boss "
              "and the fields built, so a reader can see the case is the case",
              "`PerfNames.NIGHT`/`DAY` already have to match `Sim.tick` "
              "(`_task_0102_budget`); every one of those names gets its branch "
              "in `perf_check._tick_one` (today an unmapped name only "
              "`push_error`s and still prints a row), and `_a_busy_day` "
              "becomes the 1.0 day: tilled grass, season crops, sprinklers, "
              "animals, every machine queued",
              "The budgets do not move: `TICK_BUDGET_US` 8333 and "
              "`PATH_BUDGET_US` 33333 in `tools/perf.py`. If the winter case "
              "breaks one, optimise here, hash-neutral, or block with the "
              "measured numbers - never raise a budget",
              "Print the wall time of one winter night simulated end to end as "
              "a `COUNT` (not budgeted), because 0277 multiplies it by "
              "thousands",
              "`python tools/perf.py --accept` moves the baseline; every row's "
              "old and new number goes in the journal, with why it grew. A "
              "benchmark and hash-neutral optimisations only: neither hash "
              "moves"],
         dod=["`python tools/perf.py` passes on the new baseline, with "
              "`night_tick` and `path_refresh` under their budgets on the winter "
              "case - both numbers, and the old ones, in the journal",
              "The `COUNT` lines show one of every `DEFENCES` entry, the Winter "
              "Lord, a rat swarm and every named path field built",
              "`_task_0275_perf_year` in `src/tools/headless_v1.gd` reads "
              "`perf_check.gd` and asserts every name in `PerfNames.NIGHT` and "
              "`DAY` has a branch in `_tick_one`, the way `_task_0102_budget` "
              "reads `sim.gd`"]),

    dict(id=276, phase=P15, title="The autoplayer plays a whole year",
         slug="autoplay-year",
         deps=[142, 194, 233, 234, 275, 166, 171, 180, 186, 191, 221],
         files="src/tools/autoplay.gd, src/tools/autoplay_run.gd, "
               "tools/autoplay.py, src/tools/play_nights.gd, "
               "src/tools/headless_check.gd, src/tools/headless_v1.gd",
         goal="0142 taught the robot to sleep; this teaches it the rest of 1.0, "
              "so balance can be measured over a whole year: crops by days and "
              "season, the fishing minigame, animals and machines, the bin and "
              "the peddler, cursor building and repairs, the powers, and "
              "carrying on through losses and boss repeats.",
         req=["Each policy in `Autoplay.POLICIES` gains a day plan (its earners "
              "in order: season crops, fishing, animals, machines, mining, "
              "chopping), a night plan (what to place, upgrade and repair by "
              "cursor in the build step and during the waves, when each power "
              "fires) and a bedtime. `towers`, `walls`, `economy` and "
              "`balanced` keep their character; `balanced` is declared the "
              "average player 0277 balances against",
              "Everything goes through the intent road a player uses: tilling "
              "and watering through the verbs, fish landed through the "
              "minigame's press intents (0180), products collected, goods into "
              "the shipping bin, seeds and animals from the peddler in his "
              "hours, tool and house tiers bought (0173, 0191), night loot "
              "picked up (0221); `build_cell`, `build_place`, `build_upgrade` "
              "and `ability_cell` (0135) with 0232's power API at night. "
              "Nothing is granted by writing `state`",
              "Walking is counted from here on (path length at "
              "`PLAYER_SPEED`), or the journal measures why not: on an 80x65 "
              "farm with an 8-10 minute day (0166), 'walking is free' is no "
              "longer close to a player",
              "`Autoplay.play(seed, policy, days)` follows the calendar, not a "
              "night count: calm nights, Full Moons, winter with nothing "
              "growing (0171), boss nights repeated until the boss falls - with "
              "a cap so a tool run always ends, reported when hit - and losses "
              "that move the calendar on. Per night: held or lost, house left, "
              "essence and money; per season: losses and boss repeats",
              "`autoplay_run.gd` prints one machine-readable `RUN` line per run "
              "(policy, seed, losses per season, boss repeats, money and "
              "essence at each season's start) beside today's lines, so "
              "`tools/balance.py` keeps working until 0277 moves its parser "
              "onto `RUN` (moved there from here); `python tools/autoplay.py "
              "--year [runs]` prints the per-policy table and the "
              "dominant-strategy alarm per season",
              "`play_nights.gd` plays the whole year by default with its "
              "scripted floor, following the boss repeat rule",
              "A year is long: print the wall time per run; if 8 seeds of 4 "
              "policies are impractical in one process, split the runs across "
              "processes (the data does not change inside a run set) and say "
              "how long it took",
              "`_task_0067_autoplay` and `_task_0068_balance` in "
              "`src/tools/headless_check.gd` follow the new policy fields and "
              "stay one day and one night; nothing in the suites plays a "
              "season. Tools only: neither hash moves"],
         dod=["`_task_0276_year_autoplay` in `src/tools/headless_v1.gd`, its "
              "time measured, printed and under 15 s (over it, the slice's "
              "day plan shrinks - bed as soon as it is done - and the cap "
              "does not move): from a prepared "
              "mid-summer state the `balanced` policy plays one day and one "
              "night twice on one seed with the same result; that day landed a "
              "fish through the minigame, shipped goods through the bin and "
              "collected an animal product; that night placed a defence by "
              "cursor in the build step and fired a power",
              "`python tools/autoplay.py --year 8` completes for all four "
              "policies; its table and wall time are in the journal",
              "`python tools/balance.py` with a short sweep still finishes on "
              "today's lines and leaves the git tree clean (its move onto "
              "`RUN` is 0277's)"]),

    dict(id=277, phase=P15, title="Balancing the year", slug="balance-year",
         deps=[271, 272, 273, 274, 276, 259],
         files="tools/balance.py, tools/autoplay.py, src/core/game_data.gd, "
               "implementation/BALANCE.md, implementation/PROGRESS.md, "
               "src/tools/headless_v1.gd",
         goal="The phase's own target: an average player reaches winter having "
              "lost two to four nights, and every boss falls. Measured with the "
              "year autoplayer, moved with levers, written down - the way 0068 "
              "did it for ten nights.",
         req=["The target as numbers: the `balanced` policy loses 2-4 nights "
              "before Winter 1 (day 43), averaged over at least 8 seeds, and "
              "every boss falls for it on every seed. A boss that walks off at "
              "dawn is a repeat, not a loss (0153), and is counted apart",
              "`tools/balance.py` moves onto 0276's `RUN` lines (its parser, "
              "moved here from 0276) and sweeps the year: `NIGHTS = 10` and "
              "the win-rate-per-night arithmetic become survival per day and "
              "losses per season; `LEVERS` is re-chosen for 1.0 (season sizes, "
              "the Full Moon percent, boss hit points, house tiers, the night "
              "length, essence and night money), each regex matching exactly "
              "one line",
              "Size the sweep before running it: a year run takes minutes "
              "(0276 printed it, 0275 the winter night), so levers x values x "
              "8 seeds x 4 policies is days of wall time. Sweep with the "
              "`balanced` policy on 4 seeds, run seeds as parallel processes, "
              "and keep the full `--year 8` for all four policies for the "
              "before and after tables; each sweep's wall time goes in "
              "BALANCE.md",
              "It keeps its safety: it refuses a dirty `game_data.gd`, holds "
              "the lock file and restores the file in a `finally`",
              "Start with the instrument, as 0068 found: before moving a lever, "
              "ask a losing run what it was doing; a fault in the autoplayer is "
              "fixed there and named in BALANCE.md, not tuned around",
              "No policy wins every night of the year by a wide margin (the "
              "dominant alarm, per season); no day sits at 0% survival across "
              "every policy; a lever that moves nothing across its range is "
              "reported as dead weight",
              "Re-run 0259's matchup tool after the levers move: every weapon "
              "is still the best buy somewhere and every enemy still needs a "
              "different answer",
              "Levers move in `src/core/game_data.gd` with their `# LEVER` "
              "ranges kept true and `GameData.validate()` passing. DATA moves "
              "on purpose; SIM moves too where the determinism scenario reads a "
              "moved lever - old and new numbers of both in PROGRESS.md",
              "A new top section of `implementation/BALANCE.md`, 'The year': "
              "losses by season and policy, boss repeats, the sweep tables, "
              "every applied change with its old and new value, and what is "
              "still off"],
         dod=["`python tools/autoplay.py --year 8` after the changes: "
              "`balanced` loses between 2 and 4 nights before day 43 on average "
              "and every boss falls on every seed - the table is in BALANCE.md",
              "The sweep's own output in BALANCE.md shows no day at 0% survival "
              "across every policy and the dominant alarm silent in every "
              "season",
              "The season groups of 0271-0274 still pass with the moved levers, "
              "or the journal says which asserted relation the data proved "
              "wrong and how it was rewritten",
              "`python tools/balance.py` reads only `RUN` lines, and a short "
              "sweep leaves `game_data.gd` restored, the git tree clean and no "
              "`.balance-lock` behind"]),

    dict(id=278, phase=P15, title="The economy across a year",
         slug="economy-seasons", deps=[277],
         files="src/core/game_data.gd, src/core/shop.gd, src/tools/autoplay.gd, "
               "src/tools/autoplay_run.gd, tools/autoplay.py, "
               "implementation/BALANCE.md, src/tools/headless_v1.gd",
         goal="The plan's rule of thumb, checked in every season and not only "
              "the first: a good day buys about one new defence, a boss costs "
              "five to seven focused days, and winter - when nothing grows - "
              "lives off what autumn put away.",
         req=["Measure first, with the year autoplayer: per season, what a "
              "focused day earns by earner (crops, fish, animals, machines, "
              "mining), the price of each of that season's new defences "
              "(0234's money and materials, at stall prices), and what was "
              "standing on the night each boss fell - `python tools/autoplay.py "
              "--economy` or an equivalent report",
              "A real day is the field and then a second earner (0196): the "
              "tour's field took two to two and a half game hours, and the "
              "rest of the day went to the pond and the cliff. Measure each "
              "season against that mixed day - the field, then the best "
              "earner for the hours left - beside the focused ones, and say "
              "in BALANCE.md which of the two the rule of thumb is held to",
              "The hens' clock (0196): a hen holds one egg and its clock "
              "waits until it is collected, 4h10m a lay, so the tour's second "
              "round, four hours after its first, found nothing. Report eggs "
              "a day at one, two and three visits, and keep `holds` at 1 only "
              "if the journal says why that is the pressure the plan wants "
              "and not a chore",
              "Rule of thumb: one well-worked day at the start of each season "
              "buys about one of that season's new defences - the ratio per "
              "season in BALANCE.md, each within 0.7-1.5 or the journal says "
              "why",
              "A boss costs 5-7 focused days: the value of the build that beat "
              "it, less what stood at the season's start, divided by that "
              "season's focused-day income",
              "Winter: nothing grows (0171), so the `balanced` policy enters day "
              "43 with autumn's stock, and its winter income (fish, mining, "
              "machines, animals) plus that stock pays for winter's defences "
              "and repairs to day 56 without running out of food or "
              "ammunition - reported per run",
              "Costs before prices: prefer moving defence costs, machine times "
              "and yields, starting from 0234's day-to-defence table in "
              "BALANCE.md; if prices must differ by season, one `# LEVER` "
              "table (a percent per resource group per season) read through "
              "`Shop.sell_price` (it takes only an id today: it gains the "
              "season, and every caller follows) and so by the bin, listed in "
              "`digest()`",
              "`GameData.check_stall` and `check_chain` already take the prices "
              "as an argument: `validate()` runs them at every season's prices, "
              "so markups stay above prices and every recipe still adds value "
              "in every season",
              "DATA moves on purpose, SIM too if the determinism scenario's shop "
              "visit reads a moved price - both in PROGRESS.md; re-check 0277's "
              "target after the changes"],
         dod=["BALANCE.md 'The economy across a year': per season the "
              "focused-day income by earner, the day-to-defence ratio, the days "
              "each boss cost, and winter's stock from day 43 to day 56, all "
              "measured",
              "`_task_0278_season_economy` in `src/tools/headless_v1.gd`: the "
              "stall and chain checks pass at every season's prices, and a "
              "doctored price that breaks the chain in one season only is "
              "refused",
              "0277's target still holds: the `--year 8` table after the "
              "changes is in the journal"]),

    dict(id=279, phase=P15, title="Year 2", slug="year-two", deps=[160, 277],
         files="src/core/game_data.gd, src/core/almanac.gd, src/core/endless.gd, "
               "src/core/waves.gd, src/core/run.gd, src/ui/result_screen.gd, "
               "assets/locale/strings.csv, src/tools/nights.gd, "
               "tools/nights.py, src/tools/perf_check.gd, tools/perf.py, "
               "src/tools/shot.gd, src/tools/headless_check.gd, "
               "src/tools/headless_v1.gd",
         goal="After the Winter Lord the farm carries on, and today that means "
              "the MVP's endless curve. Replace it with the calendar: Year 2 and "
              "every year after replay the four seasons from 0270's templates, "
              "heavier each year, with the bosses back on every day 14.",
         req=["Days past 56 resolve through 0270's generator (wherever it "
              "lives): the year and the season from 0149's `Calendar` "
              "helpers, the season's template scaled by a per-year growth "
              "`# LEVER` that is added, not compounded (the "
              "`ENDLESS.growth_percent` lesson), with the mix allowed to lean "
              "heavier each year. The plan wants Year 2 heavier 'a cada "
              "estação': the journal compares Year 2's spring with Year 1's "
              "winter, and a drop between them stands only with its reason "
              "written down",
              "Every season's day 14 sends its boss again (0153's row), with "
              "hit points scaled per year by a `# LEVER` through the `max_hp` "
              "road 0257's elites use, read by `Combat.full_hp` (0246); the "
              "boss-repeat rule (0153) and the calm night after a fallen boss "
              "(0154) hold every year, so Spring 1 of Year 2 is calm",
              "Later years have no introductions; the Full Moons on 7 and 14 "
              "stay - Year 1's records scaled, or generated with the Full Moon "
              "percent: decide one and assert it",
              "Sides and events keep to their season as in Year 1, so each "
              "season keeps its character; the Blood Moon comes earlier only if "
              "a lever says so",
              "Retire the MVP curve: `Endless` and the `ENDLESS` table, "
              "`giant_every` levers included (0153 left them to this task), "
              "leave `plain_night`, `check_nights` and `digest()` (a reader "
              "of `Endless._stream_for`, such as 0256's `Weather`, keeps the "
              "helper in its new home); `_task_0070_endless` in "
              "`src/tools/headless_check.gd` is "
              "rewritten over the later years or removed with the reason in "
              "the journal; 0160's carry-on lands in Year 2 of the calendar, "
              "and `Run`'s `endless` flag means 'past Year 1' or goes. A saved "
              "key that changes meaning gets a `State.VERSION` bump, a "
              "migration and a golden (never a key named `moon_phase`); "
              "otherwise no bump. `validate()` checks the new levers' ranges",
              "0160's ending screen shows once, after Year 1; a later Winter "
              "Lord ends his year with a line in the morning report "
              "(`result_screen.gd`): a new `RES_YEAR_SURVIVED` row "
              "(key,width,en,pt_BR: YEAR %d SURVIVED / ANO %d SOBREVIVIDO, "
              "width measured). The HUD's year is already 0149's: `SPRING 3` "
              "beside the clock and `YEAR 2` on the line under it until dusk "
              "(`DHUD_YEAR`); add a `year_two` scenario (a Year 2 day) to "
              "`src/tools/shot.gd` to see it",
              "`python tools/nights.py --years 3` prints Years 1-3 by season "
              "with sizes, bosses and events; generation stays a fresh "
              "`(seed, day)` stream",
              "The curve stays sane to Year 3: `perf_check.gd` takes a date "
              "(e.g. `--date=<n>`, forwarded by `tools/perf.py`, which "
              "compares and accepts nothing on such a run) and times 0275's "
              "case on Year 3's heaviest night; the `balanced` policy plays "
              "into Year 2 on one seed with `Autoplay.play(seed, policy, "
              "days)`",
              "Hashes: DATA moves (the new levers; `ENDLESS` leaves the "
              "digest). SIM should not - the determinism night is day 1 - "
              "unless a state key goes (e.g. `endless`), which moves it on "
              "purpose; both numbers in `implementation/PROGRESS.md`"],
         dod=["`_task_0279_year_two` in `src/tools/headless_v1.gd`: day 57 is "
              "Spring 1 of Year 2 and calm; a Giant spawned on day 70 has more "
              "`Combat.full_hp` than one spawned on day 14; on every day of "
              "the year but Spring 1 "
              "(Year 1's is the tutorial night), Year 2 sends at least Year "
              "1's hit points on the same day and Year 3 at least Year 2's; "
              "days 57-168 resolve for seeds 0-2 without touching "
              "`state[\"rng\"]`",
              "Year 3's heaviest night is inside `TICK_BUDGET_US` and "
              "`PATH_BUDGET_US` (`python tools/perf.py --date=<it>`) - the "
              "numbers in the journal",
              "The `python tools/nights.py --years 3` summary and where the "
              "`balanced` policy fell in Year 2 are in the journal",
              "`python tools/shot.py 0279 year_two --fhd` opened: the year "
              "label fits, in English and in Portuguese"]),

    dict(id=280, phase=P15, title="Checkpoint: do fifty-six nights tire?",
         slug="checkpoint-year", deps=[277, 278, 279, 159, 258],
         files="implementation/PROGRESS.md, implementation/shots/0280/, "
               "src/tools/shot.gd, src/tools/nights.gd, "
               "implementation/prompts/ (later prompts, if the answer needs it), "
               "tools/backlog/ (new tasks, if any)",
         goal="The plan's Phase 6 question, answered honestly: 'as 56 noites "
              "cansam?' A checkpoint like 0027, 0066 and 0148, not a feature - "
              "a 'yes' found here is worth more than every polish task after "
              "it.",
         req=["Play, not only measure: the year autoplayer for all four "
              "policies, `python tools/nights.py` for the year, and at least "
              "one night of each season and each boss night driven through the "
              "real game with the cursor, by mouse and by pad (a real pad if "
              "one is attached; say honestly if it was synthetic), and looked "
              "at",
              "Captures at 1920x1080 (`python tools/shot.py 0280 <scenarios> "
              "--fhd`): each season by day and at night mid-wave, a Full Moon, "
              "a fog or rain night, a Blood Moon, and the four bosses "
              "mid-fight. Reuse what exists - 0159's `season_*`, 0258's `fog`, "
              "`rain`, `blood_moon` and `full_moon`, 0246's `boss` and the "
              "boss scenarios of 0253-0255 - and add to `src/tools/shot.gd` "
              "only what is missing (a tool change, hashes untouched)",
              "Look for sameness with numbers, computed by a tool rather than "
              "by eye (a `--sameness` report in `src/tools/nights.gd`): per "
              "season, how many nights share a mix of kinds and sides; the "
              "longest run of nights that bring nothing new (no new enemy, "
              "side, weapon, event or boss); how often the forecast says the "
              "same thing two nights running",
              "Answer in the journal: do the fifty-six nights tire, where and "
              "why, with the stretches named by day - then what would fix it "
              "(more events, fewer generated nights, new key nights, shorter "
              "seasons) and what each fix costs",
              "Fixes that fit go into the later prompts (P16-P17), or into new "
              "tasks in `tools/backlog/part*.py` run through `python "
              "tools/gen_backlog.py` - each with a free id and added to "
              "0295's deps, so the playtest waits for it; anything that "
              "changes an owner decision (14 days a season, Normal only) is a "
              "recommendation to the owner in the journal, not an edit made "
              "here",
              "If the honest answer is that the year tires and the cure is "
              "bigger than prompt edits, mark this task blocked with the reason "
              "(`python tools/task.py blocked 0280 \"<why>\"`), so 0295 (the "
              "playtest of the year) waits for the owner",
              "No rule changes here: nothing in `src/core/` moves, and neither "
              "hash moves"],
         dod=["`implementation/shots/0280/` holds the FHD captures listed "
              "above, every one opened and looked at; the journal names what is "
              "wrong in any of them",
              "The journal has the year's autoplayer table, the sameness "
              "numbers and the longest stretch with nothing new, by day",
              "The journal answers 'do the fifty-six nights tire?' in plain "
              "words and lists every prompt edited and every task added because "
              "of it"]),
]
