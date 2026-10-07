# -*- coding: utf-8 -*-
"""Backlog part 7: the calendar and the seasons.

Part 6 made the night something the farmer sleeps through and the guardian
defends until dawn. This phase hangs those nights on a year: four seasons of
fourteen days, Full Moons on 7 and 14, a boss that holds the season until it
falls, a calm night after it, a forecast at dusk, a new side of attack every
season, and a farm that changes colour with them. It comes before the day
economy (part 8) because crops, fish and the stall key off the season, and
before the content (parts 9-11) because the fifty-six nights are written into
the calendar this phase builds.
"""

P11 = "11 - Calendar and seasons"

TASKS = [
    # ========================================== phase 11 - calendar and seasons
    dict(id=149, phase=P11, title="The calendar: four seasons of fourteen days",
         slug="calendar", deps=[148],
         files="src/core/calendar.gd (new), src/core/game_data.gd, "
               "src/ui/day_hud.gd, src/ui/names.gd, "
               "assets/locale/strings.csv, src/tools/headless_v1.gd, "
               "src/tools/input_v1.gd, src/tools/input_check.gd",
         goal="The farm learns what day of the year it is. Every rule of this "
              "phase hangs off one small set of pure helpers, and the player "
              "sees 'SPRING 3' beside the clock - before a single rule reads "
              "it.",
         req=["`src/core/calendar.gd` (`class_name Calendar`, node-free, "
              "static): `date(state)` - the calendar day, which is "
              "`state[\"day\"]` until 0153 adds the boss hold, and the one "
              "place that knows it - plus pure `year_of(date)`, "
              "`season_of(date)` (0-3), `day_of_season(date)` (1-14) and "
              "`year_days()`. Each pure helper takes an optional season "
              "length, so a test can prove a seven-day season without "
              "editing the lever",
              "`GameData.SEASON_DAYS := 14  # LEVER: days a season, 7-28` and "
              "`SEASONS: Array` of the ids `spring`, `summer`, `autumn`, "
              "`winter` (names, not a lever); `validate()` gains "
              "`check_calendar` (four seasons, a season of at least two "
              "days), and both go into `digest()` (0112's coverage assert)",
              "No new State key and no rule reads the calendar yet: day 1 is "
              "Spring 1 of Year 1, day 14 Spring 14, day 15 Summer 1, day 56 "
              "Winter 14, day 57 Spring 1 of Year 2",
              "The day HUD shows the date beside 0126's HH:MM clock: "
              "`SPRING 3`, and `SPRING 3  YEAR 2` from the second year on. "
              "It takes the place of the day count in the clock line "
              "(`DAY %d` in `DHUD_DAY` / `DHUD_DAY_FIRST`, as 0126 and 0140 "
              "left them): one number for the day, not two. Rewrite in place "
              "the input_check cases that read `DAY 1` "
              "(`_case_0021_day_hud`, `_case_0039_clock`) and drop any row "
              "nothing reads any more. Season names go through `Names.KEYS` "
              "(`spring` -> `SEASON_SPRING`, ...) so `tools/i18n_check.py` "
              "sees literal keys",
              "`assets/locale/strings.csv` rows, both languages: "
              "`SEASON_SPRING` SPRING / PRIMAVERA, `SEASON_SUMMER` SUMMER / "
              "VERÃO, `SEASON_AUTUMN` AUTUMN / OUTONO, `SEASON_WINTER` WINTER "
              "/ INVERNO, `DHUD_DATE` `%s %d` / `%s %d`, `DHUD_DATE_YEAR` "
              "`%s %d  YEAR %d` / `%s %d  ANO %d`; the width is the label's "
              "real width, measured",
              "The night HUD keeps its night number for now: `night` is not "
              "the date until 0151, and 0158 names the date there",
              "Hashes: SIM must not move. DATA moves once, because the "
              "calendar levers enter `digest()` - both numbers in the "
              "journal"],
         dod=["`_task_0149_calendar` in `src/tools/headless_v1.gd` asserts "
              "the five mappings above, a seven-day season through the "
              "optional argument, `year_days() == 56`, and that a state's "
              "hash is the same before and after asking every helper",
              "`_case_0149_date` in `src/tools/input_v1.gd` reads `SPRING 3` "
              "on day 3 and `SUMMER 1` on day 15 from the day HUD, in English "
              "and in Portuguese (`PRIMAVERA 3`, `VERÃO 1`)",
              "`python tools/shot.py 0149 noon dusk --fhd` and the same with "
              "`--pt_BR`, opened: the date sits by the clock and nothing "
              "overlaps"]),

    dict(id=150, phase=P11, title="Nights looked up by the calendar",
         slug="calendar-lookup", deps=[149],
         files="src/core/waves.gd, src/core/endless.gd, src/core/run.gd, "
               "src/core/tech.gd, src/core/rewards.gd, "
               "src/core/game_data.gd, src/tools/headless_check.gd, "
               "src/tools/headless_v1.gd",
         goal="Before the night number changes meaning, every question about "
              "which night is which goes through one lookup, and nothing in "
              "the rules asks `MVP_NIGHTS` any more. A port: the same ten "
              "nights, the same Endless past them, the same hashes.",
         req=["Split the lookup in two in `src/core/waves.gd`: "
              "`Waves.plain_night(night, seed)` is the record as written - "
              "the authored row for days `1..Waves.authored_count()` "
              "(today's ten, `NIGHTS.size()`), `Endless.night(seed, day)` "
              "after them, defined for every day of every year - and "
              "`Waves.night_of(night, seed)` is the record the night "
              "actually fights: `plain_night` plus the calendar's rules. "
              "There are none yet; 0152-0154 add theirs there and nowhere "
              "else. With no rule, `night_of` hands back the authored row "
              "itself, not a copy",
              "Every pure question keeps going through `night_of` (`table`, "
              "`size_of`, `kinds_of`, `spawns_of`, `reward_of`, `summary_of`, "
              "`delay_before`, `tonight`); tests of the authored curve and of "
              "the endless curve (`_task_0059`, `_task_0060`, and "
              "`_task_0070`'s 'it grows', 'deals out every body it promised' "
              "and 'both sides') read `plain_night`, so the Full Moon, boss "
              "and calm rules of 0152-0154 do not fight them. No new record "
              "format: 0270 owns that",
              "Core readers of `MVP_NIGHTS` ask a named question instead: "
              "`Endless.is_generated`, `step_of` and `_size` use "
              "`Waves.authored_count()`, and `_size`'s base is the last "
              "authored night's plain size (through `plain_night`, not "
              "`Waves.size_of`), so a calendar rule on that date never moves "
              "the whole curve; `Run.is_over`, `is_final_night` "
              "and `go_endless` use a new `Run.final_night()` (the last "
              "authored night in this task; 0151 makes it the year's last "
              "day, 0160 the winter boss); `Tech.total_available()` and "
              "`least_available()` count `Run.final_night()` nights",
              "`Rewards._lines` and `_money_from` scale with "
              "`state[\"night\"]`, which becomes the calendar day in 0151: "
              "read it through one helper (e.g. `Rewards.night_step(state)`) "
              "so 0219 and 0278 retune a 56-night year in one place; nights "
              "1-10 pay exactly what they pay today",
              "`check_nights`' `nights.size() != MVP_NIGHTS` rule becomes: at "
              "least one authored night and no more than "
              "`Calendar.year_days()`",
              "The other test reads of `MVP_NIGHTS` that only mean 'the "
              "authored nights' become `Waves.authored_count()` as a plain "
              "rename: `_task_0003_game_data` ('ten nights'), "
              "`_a_full_farm` (for `_task_0038_idle`), `_task_0058_giant` "
              "and `_task_0068_balance`. `MVP_NIGHTS` then survives only for "
              "`_task_0066_run_end` and input_check's `_case_0070_endless` "
              "(both about the run's end, which 0151 changes), the tools "
              "(`autoplay.gd`, `nights.gd`, `play_nights.gd`, "
              "`perf_check.gd`) and its line in `digest()`; its comment says "
              "0151 deletes it",
              "Rewrite `_task_0059`, `_task_0060`, `_task_0061`, `_task_0062` "
              "and `_task_0070` in `src/tools/headless_check.gd` over the "
              "lookup and the named questions: `_ten_of` becomes one copy "
              "per authored night, 'the Giant on night ten' becomes 'on the "
              "last authored night', the endless asserts compare "
              "`plain_night` with `Endless.night` and read 'past the "
              "authored nights'. Keep what each asserted and its run time",
              "Hashes: SIM and DATA both stay where they are. If either "
              "moves, find out why before going on"],
         dod=["`grep -rn MVP_NIGHTS src/core` finds only its declaration and "
              "the `digest()` line",
              "The five rewritten groups pass, and the journal has one line "
              "per group on what changed in it",
              "`python tools/nights.py 20` prints the same twenty lines as "
              "before the change (diff the two outputs; the result goes in "
              "the journal)",
              "`_task_0150_lookup` in `src/tools/headless_v1.gd`: every day "
              "1-112 resolves to a non-empty record for seeds 0 and 424242; "
              "`night_of(1)` is the same object as `GameData.NIGHTS[0]` "
              "(`is_same`); `Tech.least_available()` is `tech_points` x "
              "`Run.final_night()`, and `Run.final_night()` equals "
              "`Waves.authored_count()` - the one line 0151 changes to "
              "`Calendar.year_days()`"]),

    dict(id=151, phase=P11, title="The night is the calendar day",
         slug="night-is-calendar", deps=[150],
         files="src/core/phases.gd, src/core/run.gd, src/core/state.gd, "
               "src/core/tech.gd, src/core/endless.gd, src/app/save.gd, "
               "src/core/game_data.gd, "
               "src/app/playtest.gd, src/tools/nights.gd, tools/nights.py, "
               "tools/verify.py, src/tools/headless_check.gd, "
               "src/tools/input_check.gd, src/tools/headless_v1.gd, "
               "src/tools/autoplay.gd, src/tools/play_nights.gd, "
               "src/tools/perf_check.gd, tools/goldens/",
         goal="The meaning change. The night fought at the end of a day is "
              "that day's night in the calendar, so difficulty follows the "
              "calendar, a lost night is never fought again, and the year has "
              "fifty-six of them.",
         req=["`Phases.begin_night` sets `night = Calendar.date(state)` "
              "instead of `nights_won + 1`; `enter_result` still moves `day` "
              "every time and `nights_won` only on a win - a count now, not "
              "an index. Fix every reader that means 'the next night is "
              "nights_won + 1': `src/app/playtest.gd` (~l.221), the "
              "`perf_check.gd` and `play_nights.gd` fixtures, and test "
              "fixtures that set `nights_won` to pick a night "
              "(`_a_run_at_night`, `_task_0070_endless`'s 'night 25 is "
              "playable'), which now set `day`",
              "`Run.final_night()` becomes `Calendar.year_days()` (update "
              "`_task_0150_lookup`'s line that pins it to "
              "`Waves.authored_count()`). `Run.is_over` is 'the year's last "
              "night has been won', read from a stable fact "
              "(`Tech.already_paid(state, Run.final_night())` or "
              "equivalent), never from a count of wins, and `go_endless` "
              "opens on that same fact (0160 reworks the door). "
              "`Tech.total_available()` now counts a year (56 x 4 = 224 at "
              "best) and the whole tree costs 45, so `_task_0063_tech_tree`'s "
              "'the tree costs more than the best run earns' fails: give "
              "`total_available`/`least_available` an optional night count "
              "and keep that assert on the first `Waves.authored_count()` "
              "nights, commented that 0220 re-prices the tree against the "
              "year",
              "`State.VERSION` 5 with `Save.migrations()[4]`: `day` is kept "
              "and becomes the date (no v4 save ever held a day back); a "
              "night in progress keeps its `night` until it ends and the "
              "calendar takes over at the next `begin_night`; `nights_paid` "
              "keeps its entries unchanged (an old night number is below the "
              "date, a date the calendar has left behind, so none can pay "
              "twice) and gains nothing - padding it with lost dates would "
              "make `already_paid(56)` lie to `Run.is_over`; `endless` "
              "becomes false (the year carries the run on; 0160 offers it "
              "again) except on an endless save already past `year_days()`, "
              "which stays endless so it is not 'over' on load (0291 settles "
              "those shapes). Saves can be written in any phase (the pause "
              "menu's save and quit): handle all four",
              "Test the step on a real v4 save: if `tools/goldens/run-v4.sav` "
              "does not exist, make it from the MVP commit `bea89a88` in a "
              "`git worktree` outside the repository (`--import`, "
              "`src/tools/make_goldens.gd` with `GODOT` set, copy back only "
              "the v4 goldens, remove the worktree); after the bump write "
              "`run-v5*.sav` from this build. Never name a key `moon_phase` "
              "(the newer golden's dropped key)",
              "Delete `MVP_NIGHTS` everywhere (code, tools, tests, "
              "`digest()`): after 0150 it is left in `_task_0066`, "
              "input_check's `_case_0070_endless`, `autoplay.gd`, "
              "`nights.gd`, `play_nights.gd` and `perf_check.gd`. The "
              "autoplayer's and `play_nights`' night counts become explicit "
              "arguments (default: the first ten calendar nights, so "
              "`implementation/BALANCE.md` keeps its meaning)",
              "Rewrite `_task_0065` (a lost night is not fought again: losing "
              "day 3's night leads to night 4 on day 4, and `nights_won` "
              "holds), `_task_0066` (not over mid-year, not ended by a "
              "loss, over once the year's last night is won - by a fixture "
              "on that date, not by playing 56 nights - then carrying on and "
              "the profile) and `_case_0070_endless` (the ending offers "
              "PLAY ON after a fixture wins date 56, and the next night is "
              "57). The in-suite played run is at most three nights",
              "The whole-year assertion moves to a tool: "
              "`python tools/nights.py --check` resolves every date "
              "1..`year_days()` for seeds 0 and 424242 and exits 1 on an "
              "empty record or any `check_nights` error; `tools/verify.py` "
              "runs it as a gate (through `check_script()` on "
              "`src/tools/nights.gd` with `verify.GODOT` - `tools/nights.py` "
              "has its own hard-coded `GODOT` default). If a generated "
              "night breaks 0137's "
              "night-length rule, fix the generator's pacing (an `ENDLESS` "
              "lever, DATA moving on purpose), not the check",
              "Hashes: SIM moves (the version is in the state) and DATA moves "
              "(`MVP_NIGHTS` leaves the digest), both on purpose - both "
              "numbers in the journal. The night HUD keeps printing "
              "`NIGHT %d`, now the date's number; naming the date there "
              "(`SPRING 3`) moved to 0158, whose captures show it"],
         dod=["`_task_0065`, `_task_0066`, `_task_0063_tech_tree` and "
              "`_case_0070_endless` rewritten as above and passing; "
              "`grep -rn MVP_NIGHTS src` and `grep -n MVP_NIGHTS tools/*.py` "
              "find nothing (the prompts in `tools/backlog/` may still name "
              "it)",
              "`python tools/nights.py --check` passes and prints 56 nights; "
              "a deliberately broken record makes it exit 1 (tried, "
              "reverted, said so in the journal)",
              "`_task_0151_migration` in `src/tools/headless_v1.gd` steps a "
              "v4 state in DAY, PREPARATION, NIGHT and RESULT up to v5, "
              "brings each to its next night through 0118's road and the "
              "sleep intent (never by playing a day out) and asserts the "
              "night number, the paid list and that no date pays twice; an "
              "endless v4 state past day 56 stays endless and a non-endless "
              "one there is not over either; every golden (v1, v4, v5) "
              "loads and plays"]),

    dict(id=152, phase=P11, title="Full Moon nights", slug="full-moon",
         deps=[151],
         files="src/core/calendar.gd, src/core/waves.gd, src/core/rewards.gd, "
               "src/core/game_data.gd, tools/palette.py, "
               "src/ui/palette_data.gd (generated), src/ui/world_view.gd, "
               "src/ui/day_hud.gd, src/ui/result_screen.gd, "
               "assets/locale/strings.csv, src/tools/shot.gd, "
               "src/tools/headless_v1.gd, src/tools/input_v1.gd",
         goal="Days 7 and 14 of every season are Full Moon nights: a bigger "
              "horde, double the pay, and a night you can see further into. "
              "The player sees one coming days ahead.",
         req=["`FULL_MOON_DAYS: Array = [7, 14]  # LEVER: days of the "
              "season`, `FULL_MOON_HORDE_PERCENT := 150  # LEVER: percent of "
              "the night's count, 120-200` and `FULL_MOON_REWARD_PERCENT := "
              "200  # LEVER: percent of the night's pay, 150-300`; "
              "`check_calendar` refuses a Full Moon day outside the season "
              "and a percent under 100; all go into `digest()`",
              "`Calendar.is_full_moon(date)` and `days_to_full_moon(date)` "
              "(0 on the night itself), pure",
              "In `Waves.night_of`, over `plain_night`: a Full Moon date's "
              "record has each non-boss wave's count scaled by "
              "`FULL_MOON_HORDE_PERCENT` (integer arithmetic, never below "
              "the plain count), boss rows untouched, and carries "
              "`\"full_moon\": true` - the flag 0158's forecast reads. "
              "Authored and generated nights alike, and no RNG. A scaled "
              "record must still fit 0137's night length (`python "
              "tools/nights.py --check` resolves Full Moons too): if one does "
              "not, the Full Moon record tightens its own pacing (its gaps "
              "first), never the check",
              "`Waves.tonight()` is asked every frame by the night HUD: cache "
              "a record a rule changed the way generated ones are cached "
              "(`wave.tonight`), and only then, so night 1 stays the "
              "authored row and nothing new enters its state",
              "`Rewards`: a won Full Moon night pays "
              "`FULL_MOON_REWARD_PERCENT` of its money and materials, "
              "itemised as its own line for the morning report. Essence is "
              "not doubled here (0219 reads this helper for that) and moon "
              "stones are 0221's",
              "View only, a brighter night ramp: a `full_moon` entry in "
              "`tools/palette.py` `RAMPS` with the five fields `night` has "
              "(tint, lift, saturation, warm_keep, warm_edge), which "
              "`python tools/gen_sprites.py` writes into `PaletteData` as "
              "`FULL_MOON_TINT`, `_LIFT`, `_SATURATION`, ... (never edit "
              "`palette_data.gd`); `WorldView._night_ramp()` (static today) "
              "picks them when tonight is a Full Moon, and it still reads as "
              "night",
              "The day HUD's date line gains `FULL MOON IN 4 DAYS` / `FULL "
              "MOON TONIGHT` (plan section 9) through `I18n.plural`: "
              "`DHUD_FULL_MOON_IN.one`/`.other` (FULL MOON IN %d DAY(S) / LUA "
              "CHEIA EM %d DIA(S)), `DHUD_FULL_MOON_TONIGHT` (FULL MOON "
              "TONIGHT / LUA CHEIA HOJE), and the morning report's "
              "`RES_FULL_MOON` (FULL MOON BONUS / BÔNUS DE LUA CHEIA - no "
              "'double', since the percent is a lever)",
              "`_task_0060`'s 'every curve climbs' and `_task_0070`'s 'it "
              "grows' keep reading `plain_night` (0150); if anything else in "
              "the suites assumed day 7 or 14 is a plain night, point it at "
              "the plain record",
              "Hashes: DATA moves (new levers). SIM should not, because the "
              "determinism night is day 1 - if it moves, explain it"],
         dod=["`_task_0152_full_moon` in `src/tools/headless_v1.gd`: days 7, "
              "14, 21 and 56 are Full Moons and 6, 8 and 15 are not; a Full "
              "Moon record sends the lever's percent of its plain record per "
              "wave with the boss count unchanged; a won Full Moon night's "
              "money and materials are the lever's percent of what the same "
              "state would be paid with the flag off (same kills), with the "
              "difference on its own line; `Waves.tonight` hands back the "
              "same record over 100 ticks; `python tools/nights.py --check` "
              "still passes",
              "`_case_0152_moon_line` in `src/tools/input_v1.gd` reads the "
              "line on day 3 (`FULL MOON IN 4 DAYS`), day 6 (`... IN 1 DAY`) "
              "and day 7 (`FULL MOON TONIGHT`), in both languages",
              "A new shot scenario `full_moon` (the `wave` scene on day 7): "
              "`python tools/shot.py 0152 wave full_moon --fhd`, opened side "
              "by side - brighter, and still night"]),

    dict(id=153, phase=P11, title="Boss nights repeat until the boss falls",
         slug="boss-nights", deps=[151, 137],
         files="src/core/waves.gd, src/core/phases.gd, src/core/calendar.gd, "
               "src/core/rewards.gd, src/core/sim.gd, src/core/game_data.gd, "
               "src/ui/result_screen.gd, src/ui/night_hud.gd, "
               "assets/locale/strings.csv, src/tools/perf_check.gd, "
               "src/tools/headless_check.gd, src/tools/headless_v1.gd, "
               "src/tools/shot.gd",
         goal="Day 14 of every season is the season's boss night, and the "
              "season does not end until that boss is down. A boss alive at "
              "dawn walks off with the rest and is back the next night - "
              "without the loss penalty, and without the farm losing a day of "
              "crops and animals.",
         req=["`SEASON_BOSSES: Array = [&\"giant\", &\"giant\", &\"giant\", "
              "&\"giant\"]` (one per season; 0253-0255 put in the Harvester, "
              "the Scarecrow King and the Winter Lord); `check_calendar` "
              "requires each to be an `is_boss` enemy; in `digest()`",
              "`Calendar.is_boss_night(date)` is the season's last day. In "
              "`Waves.night_of`: a boss date's record gets one row of the "
              "season's boss, third from last like "
              "`Endless._put_the_giants_in`, from spawn 0 (the east, open in "
              "every season - 0157); every other date loses its `is_boss` "
              "rows (today's night 10 loses its Giant; Endless's "
              "every-fifth-night Giants stop reaching the calendar, and the "
              "`giant_every` levers stay for 0279 to decide)",
              "`Waves.boss_fell(state)`: every `is_boss` body in tonight's "
              "record was killed (from `killed_by_kind`). `Waves.tick` "
              "raises `boss_arrived` from `is_boss`, not from `&\"giant\"`",
              "0137's interim goes (dawn waiting while `Combat.boss_here`, "
              "the night HUD's dawn countdown holding at 0:00, and the "
              "`_task_0137_dawn` assert of it, rewritten in place in "
              "`headless_v1` as the escape below). At dawn (`dawn_at`) on a "
              "boss night, boss alive and house standing: a third outcome, "
              "escaped, through `Rewards.settle` and `Phases.enter_result` - "
              "the boss and the survivors walk off as on any dawn, no "
              "`_loss`, no night pay or technology, `nights_won` unchanged. "
              "The house falling is a loss as on any night. The season holds "
              "whenever the boss did not fall, however the night ended",
              "The hold is a counter, not a frozen `day`: `day` still moves "
              "every night (the stall restocks on it, the report and stats "
              "count it, every day system runs) and a new Phases key "
              "`days_held` grows by one; `Calendar.date(state)` becomes "
              "`day - days_held`, so the date stays on 14 and tonight is the "
              "boss again. A new top-level int only: reconcile fills 0 for "
              "old saves, no version bump",
              "`nights_paid` is keyed by the date, so a repeated boss night "
              "pays its technology once, when the boss falls",
              "The morning report says it: `RES_BOSS_ESCAPED` (%s GOT AWAY - "
              "IT COMES BACK TONIGHT / %s FUGIU - VOLTA HOJE À NOITE), the "
              "boss named through `Names.of`",
              "Whatever assumed the Giant on night 10 looks for the boss on "
              "Spring 14: `_task_0058_giant` (`Waves.table(...)` of the last "
              "night), the 'one new thing a night' asserts of "
              "`_task_0059`/`_task_0060` and `_task_0070_endless`'s Giant "
              "counts if any still read `night_of` rather than "
              "`plain_night`, and `perf_check.gd`'s worst case (0275 later "
              "makes it the winter boss night)",
              "Hashes: SIM moves on purpose (a new key, the boss rows); DATA "
              "moves (a new table) - both in the journal"],
         dod=["`_task_0153_boss_nights` in `src/tools/headless_v1.gd`: for "
              "dates 1-112 and two seeds, `is_boss` rows appear only on "
              "dates 14, 28, 42, 56, 70, 84, 98 and 112, once each, with the "
              "season's boss; `python tools/nights.py --check` still passes "
              "with the boss rows in",
              "The same group, from Spring 14 fixtures started through "
              "0118's `NightRoad` (its park, with dawn brought close rather "
              "than played out): boss "
              "alive at dawn -> no stock taken, `nights_won` unchanged, `day` "
              "+1, the date still 14, the stall restocked, tonight's record "
              "the boss night again; boss killed -> the next date is 15; "
              "house down with the boss alive -> the loss and the hold; house "
              "down after the boss fell -> the loss and no hold",
              "`boss_arrived` is raised for the Giant through `is_boss`, and "
              "`src/core/waves.gd` no longer names `&\"giant\"`",
              "A `boss_escaped` shot scenario: `python tools/shot.py 0153 "
              "boss_escaped --fhd`, opened - the morning report names the "
              "boss and says it comes back"]),

    dict(id=154, phase=P11, title="The calm night after a boss",
         slug="calm-night", deps=[153],
         files="src/core/calendar.gd, src/core/waves.gd, src/core/rewards.gd, "
               "src/core/game_data.gd, src/ui/day_hud.gd, "
               "src/ui/result_screen.gd, src/tools/nights.gd, "
               "assets/locale/strings.csv, src/tools/shot.gd, "
               "src/tools/headless_v1.gd, src/tools/input_v1.gd",
         goal="After a boss falls the horde regroups: the first night of the "
              "next season sends nothing, the farmer sleeps through it, and "
              "something is waiting on the porch in the morning. Spring 1 of "
              "Year 1 is still the tutorial's night 1.",
         req=["`Calendar.is_calm(date)`: the first day of a season, except "
              "the first day of the game. With 0153's hold the calendar "
              "reaches a new season only once its boss has fallen, so this is "
              "a pure function of the date and the forecast cannot be wrong "
              "about it - in every year, Spring 1 of Year 2 included",
              "`Waves.night_of` returns a calm record for those dates: "
              "`{note, opening_ticks: 0, waves: [], calm: true}`. "
              "`check_nights` refuses an empty wave list unless the record "
              "says calm; `Waves.summary_of` and `tools/nights.py --check` "
              "print and accept it as calm",
              "The night still happens and takes no special road: the build "
              "step opens as on any night (decision #4: the only time "
              "defences go down), START - or 0128's 30 s after passing out - "
              "starts a night with nothing in it, and `Waves.begin`'s empty "
              "table wins it on the first tick",
              "A calm night pays only the gift: `CALM_NIGHT_GIFT: Dictionary "
              "= {WOOD: 20, STONE: 20, FOOD: 10}  # LEVER: units each, "
              "0-60` - no night money, materials or technology, since "
              "nothing was defended; `nights_paid` still records the date; "
              "`validate()` allows only known resources and never money or "
              "`tech`; in `digest()`",
              "The day HUD's date line says `CALM NIGHT` on a calm date "
              "(`DHUD_CALM_TONIGHT`: CALM NIGHT / NOITE CALMA); the morning "
              "report says `RES_CALM_NIGHT` (A CALM NIGHT - THE HORDE "
              "REGROUPED / NOITE CALMA - A HORDA SE REAGRUPOU) and `RES_GIFT` "
              "(A GIFT ON THE PORCH / UM PRESENTE NA VARANDA); 0158's "
              "forecast reads the record's flag",
              "Anything in the suites or tools that reads dates 15, 29, 43 "
              "or 57 through `night_of` and expects a fight (a size, a kind, "
              "a side) reads `plain_night` instead, or skips calm dates; "
              "0137's night-length sample and `tools/nights.py` accept a "
              "calm record",
              "Hashes: SIM should not move (day 1 is not calm); DATA moves "
              "(the gift lever)"],
         dod=["`_task_0154_calm` in `src/tools/headless_v1.gd`: dates 15, 29, "
              "43 and 57 are calm and 1, 14 and 16 are not; a calm night ends "
              "won on its first tick after START with no entity spawned; it "
              "pays exactly `CALM_NIGHT_GIFT` and no technology",
              "`_case_0154_calm` in `src/tools/input_v1.gd`: to bed on Summer "
              "1, START, and the morning report shows the calm and the gift - "
              "once by keyboard, once by pad",
              "A `calm_morning` shot scenario: `python tools/shot.py 0154 "
              "calm_morning --fhd` and `--pt_BR`, opened"]),

    # Added 0153: this task asserts 0153's boss hold beside the ordinary
    # loss, so the hold must exist first.
    dict(id=155, phase=P11, title="Losing a night when the calendar moves on",
         slug="losing-calendar", deps=[151, 153], dresses=["A014"],
         files="src/core/rewards.gd, src/core/farming.gd, "
               "src/core/pathing.gd, src/core/phases.gd, src/core/run.gd, "
               "src/core/game_data.gd, src/ui/world_view.gd, "
               "src/ui/placeholder_art.gd, src/ui/result_screen.gd, "
               "assets/locale/strings.csv, src/tools/shot.gd, "
               "src/tools/headless_v1.gd",
         goal="Losing costs what the plan says and nothing more: the calendar "
              "moves on, the horde takes a quarter of the stock, tramples the "
              "crops it walked through, and what it broke stays broken. Only a "
              "boss night comes back.",
         req=["The calendar moving on after a loss is 0151's rule; assert it "
              "here beside 0153's exception: an ordinary lost night is never "
              "fought again, a lost boss night is",
              "Stock loss stays `Rewards._loss` (`DEFEAT_LOSS_PERCENT`, money "
              "and technology kept by the `DEFEAT_KEEPS_*` levers): no "
              "change, an assert",
              "Trampling, new and deterministic: when the house falls, every "
              "plot on the horde's routes loses its crop. The routes are "
              "cells, never randomness - from each spawn region tonight used "
              "(`Waves.spawns_of`), follow the flow field "
              "(`Pathing.step_from`) from every spawn cell to the house, add "
              "every cell an enemy stands on when the house falls, widen by "
              "`TRAMPLE_REACH := 0  # LEVER: tiles either side of a route, "
              "0-2` (in `digest()`; `validate()` refuses one outside 0-2), "
              "and walk the cells sorted",
              "A trampled plot (`plots`, RUN_DATA) stays tilled, loses its "
              "crop and growth, and keeps a `trampled` marker naming the crop "
              "for the view until something is planted there; `Farming` "
              "treats it as empty tilled ground. No migration: a missing "
              "marker means nothing was trampled",
              "Destroyed defences stay destroyed (the rubble is swept, "
              "nothing refunded): an assert, not a change",
              "The morning report lists it: `RES_TRAMPLED.one`/`.other` (%d "
              "CROP TRAMPLED / %d CROPS TRAMPLED; %d PLANTA PISOTEADA / %d "
              "PLANTAS PISOTEADAS)",
              "Find and remove what still says the same night comes back "
              "(doc comments in `phases.gd` and `run.gd`, any tutorial or "
              "report text); 0153's boss hold is the only repeat left. "
              "`_task_0065` is 0151's and is not touched here",
              "The trampled crop is drawn through 0120's placeholder road "
              "(`src/ui/placeholder_art.gd`: the crop's first stage frame, "
              "flattened and darkened in code) until A014 is integrated by "
              "0197",
              "Hashes: SIM moves only if the determinism night is lost (it is "
              "not); DATA moves (the lever)"],
         dod=["`_task_0155_losing` in `src/tools/headless_v1.gd`: a lost "
              "night on day 5 leads to night 6 and a lost Spring 14 with the "
              "boss alive to Spring 14 again; a quarter of each stock is "
              "taken as before; on a farm planted across and beside the east "
              "route, every plot on the route cells (worked out in the test "
              "the same way) is trampled and none off them; a won night "
              "tramples nothing; a wall destroyed that night is still gone "
              "the next morning",
              "Two copies of the same state lose the same night and trample "
              "the same cells",
              "A `trampled` shot scenario (the morning after a loss, by the "
              "field): `python tools/shot.py 0155 trampled --fhd`, opened - "
              "trampled plots read as damaged, the rest as untouched"]),

    dict(id=156, phase=P11, title="The 1.0 farm map", slug="farm-map-v1",
         deps=[151],
         files="src/core/game_data.gd (FARM_MAP, MAP_LEGEND, checks), "
               "src/core/farm.gd, src/core/interact.gd, src/core/pathing.gd, "
               "src/app/save.gd, src/core/state.gd, "
               "src/ui/world_view.gd, src/ui/placeholder_art.gd, "
               "tools/goldens/, src/tools/shot.gd, src/tools/headless_v1.gd",
         goal="Every change the 1.0 farm needs on its map, made once so a save "
              "migrates once: ground for the new attack sides, the new ore, "
              "the big hardwood stumps, ponds with names, and room kept for "
              "the coop, the barn and the shipping bin.",
         req=["Spawn ground for the sides 0157 opens: a clear band of "
              "walkable cells near the north, west and south edges, away from "
              "the farmstead and about as far from the house by path as the "
              "east band (measure with `Pathing.distance`; the numbers go in "
              "the journal), with nothing on it that regrows",
              "Nodes under their final ids, so 0176 and 0177 change data "
              "only: copper, coal and gold nodes (e.g. `copper_ore`, "
              "`coal_seam`, `gold_ore`; gold deeper in the rock face) and "
              "2x2 hardwood stumps (`hardwood_stump`, one thing over four "
              "cells with an `anchor`, as a building's footprint is kept); "
              "new `MAP_LEGEND` characters. Until those tasks give them "
              "`GATHERING` rows they are inert, impassable obstacles with no "
              "verb: check that `Interact`, `Pathing._through`, `Farm` and "
              "`Save._widen` accept an occupant with no table row",
              "Ponds by name: one anchor cell per water body in a `PONDS` "
              "table (the north-west pond, the forest pond, the south-east "
              "lake) and `Farm.pond_of(state, cell)` by flood fill over the "
              "state's own terrain, cheap enough to ask once per cast, so "
              "0179 keys species by pond; no occupants",
              "Room kept clear in a `MAP_SITES` table: the coop and the barn "
              "near the workshop and the animals (room for footprints up to "
              "7x4; 0183 decides the real ones) and the shipping bin by the "
              "porch (0189)",
              "`check_map`, `check_livestock` and `validate()` stay clean; "
              "`check_reachable` (which walks only `GATHERING` ids today) "
              "also covers the new node ids that have no row yet, so each "
              "can be stood beside; a new check that every spawn band cell is "
              "walkable map ground. `PONDS` and `MAP_SITES` go into "
              "`digest()`",
              "`State.VERSION` + 1 (6 after 0151's 5) with a step in "
              "`Save.migrations()` in the style of `_expand_farm_v1..3`: the "
              "new nodes, stumps and cleared bands laid onto a save only "
              "where its cell is empty map ground - never over a plot, a "
              "building, the house or anything the player placed; map trees "
              "and rocks leave the bands and sites only if they are "
              "untouched map props; path caches reset and `grid_version` "
              "bumped. Write `run-v6*.sav` after the bump (0151's "
              "`run-v5*.sav` is this step's input)",
              "The new nodes and the stump are drawn through 0120's "
              "placeholder road (tinted `ore`, `seam` and `stump` frames, the "
              "stump scaled over its 2x2) until A021 is integrated by 0204",
              "Hashes: SIM and DATA both move (the map is in `digest()` and "
              "in the state) - both numbers in the journal"],
         dod=["`_task_0156_map_v1` in `src/tools/headless_v1.gd`: "
              "`GameData.validate()` is clean; every spawn band cell is "
              "walkable and `Pathing.reachable` on a new farm; each new node "
              "id is on the map; `Farm.pond_of` names three ponds and "
              "nothing on land",
              "The v5 golden steps up to v6 with every plot and every "
              "player-placed occupant where it was, the new nodes only on "
              "cells that were empty, and plays 600 ticks; every golden "
              "loads",
              "New shot scenarios standing at the north band, the new ore "
              "and a stump: `python tools/shot.py 0156 <them> --fhd`, "
              "opened"]),

    dict(id=157, phase=P11, title="A new side every season",
         slug="attack-sides", deps=[156, 115],
         files="src/core/game_data.gd (SPAWNS, SPAWN_SIDES, "
               "SIDES_BY_SEASON, check_nights), src/core/calendar.gd, "
               "src/core/endless.gd, src/core/enemies.gd, "
               "src/ui/build_mode.gd, src/ui/world_view.gd, "
               "src/tools/headless_check.gd, src/tools/headless_v1.gd, "
               "src/tools/shot.gd",
         goal="The farm is surrounded one side at a time: spring comes from "
              "the east, summer adds the south-east, autumn the north, and in "
              "winter they come from everywhere.",
         req=["`SPAWNS` gains regions on 0156's ground - 2 north, 3 west, 4 "
              "south - each a line of border cells like the east one; a "
              "parallel `SPAWN_SIDES: Array` names them `east`, "
              "`south_east`, `north`, `west`, `south` (the forecast's "
              "words); indices 0 and 1 do not move",
              "`SIDES_BY_SEASON: Array  # LEVER`: spring `[0]`, summer "
              "`[0, 1]`, autumn `[0, 1, 2]`, winter all five; "
              "`Calendar.open_sides(date)`; validated (every index a real "
              "region, each season a superset of the one before); both new "
              "tables in `digest()`",
              "Generated nights deal their sides from the date's open sides "
              "only: `Endless._lay_out` alternates through them instead of "
              "through every region. 0153's boss row already comes from the "
              "east. Rewrite in place `_task_0070_endless`'s 'both sides, "
              "always' (nights 11, 13, 20, 25, 33 against `SPAWNS.size()`) "
              "as 'every side open on that date'",
              "`check_nights` gains the rule that a record names only sides "
              "open in its season; it knows a record's date from its index "
              "(`validate()` passes `NIGHTS`, 0151's `nights.py --check` the "
              "resolved year). Today's ten break it in spring (nights "
              "2-10 use the south-east): exempt them with an explicit, "
              "commented allowance that 0271 deletes when it remaps them, "
              "and record the deviation in the journal",
              "Every new region has walkable, reachable cells on a new farm "
              "(`Enemies.spawn_cells`), and 0115's rule holds for each: "
              "building over a region never silently loses a wave member",
              "The flow field is swept from the house, so more regions should "
              "add no sweep: measure with `python tools/perf.py` "
              "(path_refresh inside `PATH_BUDGET_US` and the 40% tolerance) "
              "and put the numbers in the journal",
              "The build step's route preview (`Pathing.route_if_blocked`, "
              "`WorldView.show_route`) shows a route from every side open "
              "tonight",
              "Hashes: DATA moves (new tables). SIM should not - day 1 comes "
              "from the east as before - and if it does, explain it"],
         dod=["`_task_0157_sides` in `src/tools/headless_v1.gd`: the open "
              "sides of Spring 1, Summer 1, Autumn 1 and Winter 1 are the "
              "table's; for dates 11-56 and two seeds every generated wave "
              "comes from an open side; every region has spawn cells on a "
              "fresh farm",
              "0115's guarantee holds for regions 2-4, whichever fix 0115 "
              "chose: each region built over as far as the rules allow, a "
              "small hand-made record of a few walkers from it accounts for "
              "every member (killed, alive or waiting) and ends in bounded "
              "ticks - a few seconds for the three",
              "A `winter_build` shot scenario: `python tools/shot.py 0157 "
              "winter_build --fhd`, opened - a route from each of the five "
              "sides"]),

    dict(id=158, phase=P11, title="The forecast", slug="forecast",
         deps=[151, 152, 153, 154, 157], dresses=["A010", "A011"],
         files="src/core/forecast.gd (new), src/ui/forecast_panel.gd (new), "
               "src/ui/day_hud.gd, src/ui/night_hud.gd, src/ui/names.gd, "
               "assets/locale/strings.csv, src/tools/shot.gd, "
               "src/tools/headless_v1.gd, src/tools/input_v1.gd",
         goal="At dusk the farmer learns what is coming: from which sides, "
              "how many and of what kind, and whether it is a Full Moon, a "
              "boss or a calm night. The forecast is never wrong, because it "
              "is the night.",
         req=["`src/core/forecast.gd` (`class_name Forecast`): "
              "`Forecast.of(seed, date)` returns `{date, season, "
              "day_of_season, full_moon, boss, calm, sides, waves, kinds, "
              "count, event}`, pure, built only from `Waves.night_of(date, "
              "seed)` - the record the night will fight, flags included - "
              "and `Calendar`; `Forecast.tonight(state)` asks it for "
              "`Calendar.date(state)`",
              "Never the run's stream: it reads `state[\"seed\"]`, never "
              "`state[\"rng\"]`, and anything random in it comes from a "
              "fresh `(seed, date)` stream like `Endless._stream_for`",
              "`event` is an empty slot (`&\"\"`) that 0256 fills from "
              "`(seed, date)`; the panel draws nothing for it until then",
              "`src/ui/forecast_panel.gd`: shown in the day HUD from 18:00 "
              "(0126's dusk, `Phases.is_dusk`) and on the night HUD in the "
              "build step, hidden at noon and once the waves start. It shows "
              "the date, the season and moon marks, the sides in words, the "
              "waves, and one head and count per kind; a calm night says so "
              "and nothing else",
              "Strings in both languages, widths measured: `FCAST_TITLE` "
              "(TONIGHT / ESTA NOITE), `FCAST_FROM` (from the %s / pelo %s), "
              "`SIDE_EAST`, `SIDE_SOUTH_EAST`, `SIDE_NORTH`, `SIDE_WEST`, "
              "`SIDE_SOUTH` (EAST / LESTE, SOUTH-EAST / SUDESTE, NORTH / "
              "NORTE, WEST / OESTE, SOUTH / SUL), `FCAST_EVERY_SIDE` (from "
              "every side / por todos os lados), `FCAST_WAVES.one`/`.other` "
              "(%d WAVE / %d WAVES; %d ONDA / %d ONDAS), "
              "`FCAST_FULL_MOON` (FULL MOON / LUA CHEIA), `FCAST_BOSS` (%s IS "
              "COMING / %s ESTÁ VINDO), `FCAST_CALM` (A CALM NIGHT / NOITE "
              "CALMA). 0157's side ids get literal `Names.KEYS` entries "
              "(`east` -> `SIDE_EAST`, ...) so the panel names a side with "
              "`Names.of` and `tools/i18n_check.py` sees the keys; kinds "
              "through `Names.of` and the plural enemy keys",
              "Stand-ins through 0120's placeholder road until A010 is "
              "integrated by 0161 and A011 by 0162: each enemy's first walk "
              "frame cropped into a 16x16 head box, and code-drawn moon, "
              "boss and season marks at 16x16 and 10x10",
              "No new input path: the panel is information, and showing it "
              "all day is an option of 0292's",
              "Moved here from 0151: the night HUD's top strip (0139) names "
              "the date beside its night label with 0149's helper and "
              "`DHUD_DATE`/`DHUD_DATE_YEAR` (`SPRING 3`), through the waves "
              "too, so the plan's 'season, night and wave' is on screen",
              "Pure functions and view only: SIM and DATA must not move"],
         dod=["`_task_0158_forecast` in `src/tools/headless_v1.gd`: for a "
              "plain, a Full Moon and a calm date, the forecast's kinds, "
              "count and sides equal what the night sends (count "
              "`Enemies.spawn` through a parked run that only steps until "
              "every wave is out, keeping the group to a few seconds), and a "
              "boss date names the season's boss; 1000 calls to "
              "`Forecast.tonight` leave `state[\"rng\"]` and the state hash "
              "unchanged",
              "`_case_0158_panel` in `src/tools/input_v1.gd`: hidden at noon, "
              "shown at 18:00 and in the build step, hidden once START is "
              "pressed",
              "`forecast_dusk` and `forecast_build` shot scenarios: "
              "`python tools/shot.py 0158 forecast_dusk forecast_build "
              "--fhd` and with `--pt_BR`, opened - every line fits, the "
              "night HUD names the date, and the heads read as the enemies"]),

    dict(id=159, phase=P11, title="Seasons on screen", slug="seasons-on-screen",
         deps=[149], dresses=["A012", "A013"],
         files="src/ui/season_view.gd (new), "
               "src/ui/season_remap.gdshader (new), "
               "src/ui/ambient_motion.gdshader, tools/palette.py, "
               "tools/gen_sprites.py, src/ui/palette_data.gd (generated), "
               "src/ui/world_view.gd, src/ui/particles.gd, "
               "src/ui/placeholder_art.gd, src/tools/shot.gd, "
               "src/tools/input_v1.gd, src/tools/headless_v1.gd",
         goal="The same farm through the year: today's green in spring, "
              "warmer in summer, ochre and rust in autumn, snow in winter - "
              "all of it in the view, with not one rule touched.",
         req=["A palette remap shader (`src/ui/season_remap.gdshader`) on the "
              "terrain, edge and prop layers: each season maps the grass and "
              "foliage palette entries onto other palette entries (spring is "
              "today's art, summer warmer, autumn ochre and rust). The tables "
              "live in `tools/palette.py` and reach `PaletteData` through "
              "`python tools/gen_sprites.py` (its `palette_gd()` writes only "
              "`COLOURS` and `RAMPS` today: extend it); a uniform switches "
              "the season, and the terrain - drawn once - is never redrawn "
              "for it. A CanvasItem has one material and the trees already "
              "carry `ambient_motion.gdshader` for the wind: put the remap "
              "inside that shader (or a shared include) for them",
              "Winter stand-in until A012 and A013 are integrated by 0163 "
              "and 0164: the remap turns grass and foliage to the palette's "
              "pale colours (`bone`, `bone_dark`, `moon`, `stone_light`). "
              "No new `COLOURS` entry: the raster importer maps sources onto "
              "that palette, so a new colour could change imported art. "
              "Register the winter paths the seasonal lookup asks for "
              "(`terrain/<name>_winter`, `props/tree_<season>`, the caps) in "
              "0120's registry under A012 and A013, resolving to the base "
              "frame, so `python tools/placeholders.py` lists both packs "
              "until 0163 and 0164 delete the entries",
              "Hooks so those leaves only add frames: a seasonal lookup (e.g. "
              "`SeasonView.frame_for(name, season)`) returns "
              "`<name>_<season>` when the art lookup of 0120 has it and the "
              "base name otherwise; a seasonal terrain atlas, when one "
              "exists, is swapped onto the terrain `TileMapLayer`'s tile "
              "set; the remap leaves alone a raster frame that already "
              "carries its season, and still remaps a registered stand-in",
              "Snowfall in winter in `src/ui/particles.gd`, honouring "
              "`a11y/particle_density` and the `video/max_particles` cap",
              "Snow on roofs by a code mask: in winter the top rows of the "
              "house's, the stations' and the stall's opaque roof pixels draw "
              "in `bone`/`moon` (the occupant sprites in `world_view.gd`; "
              "`house_view.gd` is the interior and has no roof). No new art: "
              "if the shots fail, say so in the journal and propose a pack "
              "rather than drawing one",
              "The season comes from `Calendar.season_of(Calendar.date"
              "(state))` and changes on the morning of a season's first "
              "day, behind 0138's wake-up, never mid-frame",
              "New shot scenarios `season_summer`, `season_autumn`, "
              "`season_winter` and `season_winter_night`: a date in each "
              "season, framed like `noon`",
              "View only: nothing in `src/core/` changes, and SIM and DATA "
              "must not move"],
         dod=["`_case_0159_seasons` in `src/tools/input_v1.gd`: the remap's "
              "season and the snowfall follow the date (off in spring, on in "
              "winter), and the terrain layer is not redrawn when the season "
              "changes",
              "`python tools/gen_sprites.py --check` (or a "
              "`_task_0159_palette` group in `src/tools/headless_v1.gd`) "
              "checks that every grass or foliage colour used by `terrain/` "
              "and the trees has a mapping in every season: it passes, and a "
              "scratch table missing one mapping makes it fail (tried, "
              "reverted, said so in the journal)",
              "`python tools/shot.py 0159 noon season_summer season_autumn "
              "season_winter season_winter_night --fhd`, opened against "
              "`docs/reference-sheet.png`: each season reads at a glance and "
              "the night ramp still works over it"]),

    # Added 0154: carrying on must land on Year 2's calm Spring 1, and this
    # task's group asserts it.
    dict(id=160, phase=P11, title="The end of the year", slug="year-end",
         deps=[153, 151, 154],
         files="src/core/run.gd, src/ui/result_screen.gd, "
               "src/ui/credits_roll.gd (new), src/ui/main.gd, "
               "assets/locale/strings.csv, src/tools/shot.gd, "
               "src/tools/headless_check.gd, src/tools/input_check.gd, "
               "src/tools/headless_v1.gd, src/tools/input_v1.gd",
         goal="When the winter boss - for now the Giant - falls on Winter 14, "
              "the year is over: an ending, the credits, and the choice to "
              "carry on into a Year 2 that does not end.",
         req=["`Run.is_over` is 'the year's last boss has fallen and the run "
              "is not endless': with 0153's hold the date passes "
              "`Calendar.year_days()` only then. A lost or escaped Winter 14 "
              "is not an ending; a Winter 14 lost after its boss fell is",
              "The morning report's ending branch (0138's screen, today's "
              "`_build_the_ending`): `YOU SURVIVED A YEAR` with what "
              "`Run.summary` already holds (days lived, nights won, bosses "
              "down, killed, structures lost, the build that won), then two "
              "choices",
              "Carry on: `Run.go_endless` (only once the year is beaten); the "
              "farmer wakes on Year 2 Spring 1 - 0154's calm night - and the "
              "nights keep coming through the lookup from today's Endless "
              "until 0279 makes later years heavier",
              "A new farm: the run is recorded (`Run.record`: `runs_won` "
              "counts the year; `best_night` keeps its meaning, any change "
              "to it is 0291's) and a new run starts, as "
              "`_record_and_restart` does today",
              "A credits roll before the choices (`src/ui/credits_roll.gd`): "
              "lines from `CRED_*` strings, skippable with confirm or cancel "
              "on keyboard, mouse and pad",
              "Strings in both languages replace the MVP's: `RES_NEW_FARM` (A "
              "NEW FARM / UMA FAZENDA NOVA), `RES_PLAY_ON` (CARRY ON INTO "
              "YEAR %d / SEGUIR PARA O ANO %d), `RES_RUN_LINE` without 'the "
              "Giant', `END_TITLE` (YOU SURVIVED A YEAR / VOCÊ SOBREVIVEU UM "
              "ANO); remove the rows nothing reads any more",
              "Keep the node names `ContinueButton` and `PlayOnButton`, and "
              "rewrite in place what reads the old ending as 0151 left it: "
              "input_check's `_case_0070_endless` (the credits now come "
              "first), `_task_0066_run_end`'s over/carry-on asserts and "
              "`_task_0070_endless`'s `go_endless` refusals, against the new "
              "`Run.is_over`",
              "Hashes: SIM must not move (the determinism run never reaches "
              "Winter 14) and DATA does not"],
         dod=["`_task_0160_year_end` in `src/tools/headless_v1.gd`, from a "
              "Winter 14 fixture (date 56, started through 0118's road, "
              "never by playing the year): boss down -> `Run.is_over` and the "
              "result says so; boss escaped -> not over, the date still 56; "
              "carried on -> not over, and the next night is date 57, Year 2 "
              "Spring 1, calm; `Run.record` counts the year in `runs_won`",
              "`_case_0160_ending` in `src/tools/input_v1.gd`: the ending "
              "shows, the credits skip by keyboard and by pad, CARRY ON "
              "returns to the farm on Year 2 Spring 1, and A NEW FARM starts "
              "day 1 of a new run",
              "A `year_end` shot scenario: `python tools/shot.py 0160 "
              "year_end --fhd` and with `--pt_BR`, opened - nothing "
              "overflows"]),

    # ------------------------------------------------- art integration leaves
    dict(id=161, phase=P11, title="Art: seasons and moons",
         slug="art-calendar-icons", deps=[158], art=["A010"],
         files="assets/art_source/ui/, assets/art_source/manifest.json, "
               "assets/art_source/ownership.json, tools/check_ui_art.py, "
               "src/ui/raster_art.gd (generated), "
               "src/ui/placeholder_art.gd, src/ui/forecast_panel.gd",
         goal="The approved season, moon, boss-night and calm-night icons "
              "take the place of the forecast's code-drawn marks.",
         req=["`python tools/task.py next` only offers this task once "
              "`python implementation/backlog/assets.py status A010` says "
              "`approved`. Check it again first; if it does not, stop and "
              "change nothing (the task stays todo and waits). This task "
              "never draws, generates or substitutes art.",
              "Use only the folder named in the pack's "
              "`CLAUDE-A010-PROMPT.txt` handoff; check every file against "
              "its `contract.json` sha256 before promoting; never resample, "
              "regenerate, or cut from previews or GIFs.",
              "Promote through the raster pipeline: versioned sources under "
              "`assets/art_source/ui/`, manifest entries with "
              "prompt/approval provenance, "
              "`assets/art_source/ownership.json`, then "
              "`python tools/import_art.py`; extend the hard-coded family "
              "lists the art checks use (`tools/check_ui_art.py`, "
              "`ArtPlacement` if needed).",
              "Runtime names: `ui/icon_<id>` 16x16 pivot (8,8) and "
              "`ui/hud_<id>` 10x10 pivot (5,5) for `spring`, `summer`, "
              "`autumn`, `winter`, `full_moon`, `boss_night` and "
              "`calm_night`, both cut from one source crop like the resource "
              "icons, binary alpha, no text. `tools/check_ui_art.py` is "
              "hard-coded to the fifteen resource icons of task 0018: give "
              "it a calendar family with the same clipping and size rules",
              "Replace 0158's code-drawn marks in the forecast panel by "
              "deleting their entries from `src/ui/placeholder_art.gd`; "
              "`python tools/placeholders.py` no longer lists A010",
              "Set the pack to integrated: "
              "`python implementation/backlog/assets.py set A010 "
              "integrated`."],
         dod=["`python tools/check_ui_art.py` and "
              "`python tools/show_art.py --ui --check` pass, and "
              "`python tools/import_art.py --check` passes",
              "FHD (1920x1080) captures by day and by night of the icons in "
              "the real game - `python tools/shot.py 0161 forecast_dusk "
              "forecast_build --fhd` - in `implementation/shots/0161/`, "
              "opened and looked at",
              "The sim and data hashes are unchanged (art never moves them)"]),

    dict(id=162, phase=P11, title="Art: forecast heads",
         slug="art-forecast-heads", deps=[158], art=["A011"],
         files="assets/art_source/ui/, assets/art_source/manifest.json, "
               "assets/art_source/ownership.json, tools/check_ui_art.py, "
               "src/ui/raster_art.gd (generated), "
               "src/ui/placeholder_art.gd, src/ui/forecast_panel.gd",
         goal="The forecast names what is coming with the enemies' own faces: "
              "the approved heads of the walker, runner, tank, breaker and "
              "Giant replace the cropped walk frames.",
         req=["`python tools/task.py next` only offers this task once "
              "`python implementation/backlog/assets.py status A011` says "
              "`approved`. Check it again first; if it does not, stop and "
              "change nothing (the task stays todo and waits). This task "
              "never draws, generates or substitutes art.",
              "Use only the folder named in the pack's "
              "`CLAUDE-A011-PROMPT.txt` handoff; check every file against "
              "its `contract.json` sha256 before promoting; never resample, "
              "regenerate, or cut from previews or GIFs.",
              "Promote through the raster pipeline: versioned sources under "
              "`assets/art_source/ui/`, manifest entries with "
              "prompt/approval provenance, "
              "`assets/art_source/ownership.json`, then "
              "`python tools/import_art.py`; extend the hard-coded family "
              "lists the art checks use (`tools/check_ui_art.py`, "
              "`ArtPlacement` if needed).",
              "Runtime names: `ui/head_<kind>` 16x16, pivot (8,8), for "
              "`walker`, `runner`, `tank`, `breaker` and `giant`, binary "
              "alpha, matching each enemy's sprite. `tools/check_ui_art.py` "
              "gains a heads family that requires a head for each of these "
              "five; later enemies bring theirs in their own packs and add "
              "themselves to the list",
              "Replace 0158's cropped walk-frame heads by deleting their "
              "entries from `src/ui/placeholder_art.gd`; the panel asks for "
              "`ui/head_<kind>` and nothing else changes; "
              "`python tools/placeholders.py` no longer lists A011",
              "Set the pack to integrated: "
              "`python implementation/backlog/assets.py set A011 "
              "integrated`."],
         dod=["`python tools/check_ui_art.py` and "
              "`python tools/show_art.py --ui --check` pass, and "
              "`python tools/import_art.py --check` passes",
              "FHD (1920x1080) captures by day and by night of the heads in "
              "the real game - `python tools/shot.py 0162 forecast_dusk "
              "forecast_build --fhd`, with the scenarios moved to a date "
              "whose forecast lists all five kinds (Spring 14 does while it "
              "is Endless-generated with the Giant's row; check it on the "
              "day) - in `implementation/shots/0162/`, opened and looked at",
              "The sim and data hashes are unchanged (art never moves them)"]),

    dict(id=163, phase=P11, title="Art: winter ground",
         slug="art-winter-ground", deps=[159], art=["A012"],
         files="assets/art_source/terrain/, assets/art_source/crops/, "
               "assets/art_source/manifest.json, "
               "assets/art_source/ownership.json, "
               "tools/check_terrain_art.py, tools/check_crop_art.py, "
               "tools/gen_sprites.py, src/ui/world_view.gd, "
               "src/ui/season_view.gd, src/ui/placeholder_art.gd",
         goal="Winter gets real snow on the ground: the approved snowy grass, "
              "path, soil, tilled ground, edges and shores replace the "
              "remapped stand-in of 0159.",
         req=["`python tools/task.py next` only offers this task once "
              "`python implementation/backlog/assets.py status A012` says "
              "`approved`. Check it again first; if it does not, stop and "
              "change nothing (the task stays todo and waits). This task "
              "never draws, generates or substitutes art.",
              "Use only the folder named in the pack's "
              "`CLAUDE-A012-PROMPT.txt` handoff; check every file against "
              "its `contract.json` sha256 before promoting; never resample, "
              "regenerate, or cut from previews or GIFs.",
              "Promote through the raster pipeline: versioned sources under "
              "`assets/art_source/terrain/` (and `crops/` for the tilled "
              "tiles), manifest entries with prompt/approval provenance, "
              "`assets/art_source/ownership.json`, then "
              "`python tools/import_art.py`; extend the hard-coded family "
              "lists the art checks use (`tools/check_terrain_art.py`, "
              "`tools/check_crop_art.py`, `ArtPlacement` if needed).",
              "Runtime names: `terrain/<name>_winter` for `grass`, "
              "`grass_b`-`grass_d`, `path` and `soil`, the winter "
              "`edge_*`/`shore_*` sides and corners, and "
              "`crops/tilled_winter` / `tilled_wet_winter` - 16x16, opaque, "
              "seamless, the same set as today's (the wet tile still at "
              "least 20 RGB darker, `check_crop_art.py`). The 256x80 atlas "
              "is ASCII-owned and built by `tools/gen_sprites.py` from the "
              "raster recipes (and asserted against it): build the winter "
              "atlas there the way the handoff says (new rows or a second "
              "atlas) and let 0159's hook swap it in",
              "Winter's ground stops going through 0159's remap (the remap "
              "stays for anything this pack does not cover); delete the "
              "stand-in entries from `src/ui/placeholder_art.gd`, so "
              "`python tools/placeholders.py` no longer lists A012",
              "Set the pack to integrated: "
              "`python implementation/backlog/assets.py set A012 "
              "integrated`."],
         dod=["`python tools/check_terrain_art.py`, "
              "`python tools/check_crop_art.py` and "
              "`python tools/show_art.py --check` pass, and "
              "`python tools/import_art.py --check` passes",
              "FHD (1920x1080) captures by day and by night in the real game "
              "- `python tools/shot.py 0163 season_winter "
              "season_winter_night --fhd` - in `implementation/shots/0163/`, "
              "opened and looked at: no seam, edge or shore breaks the snow",
              "The sim and data hashes are unchanged (art never moves them)"]),

    # Added 0156: the snow caps go on every node on the map, 0156's new ore
    # and stumps included.
    dict(id=164, phase=P11, title="Art: trees through the seasons",
         slug="art-seasonal-trees", deps=[159, 156], art=["A013"],
         files="assets/art_source/props/, assets/art_source/manifest.json, "
               "assets/art_source/ownership.json, tools/check_prop_art.py, "
               "src/ui/world_view.gd, src/ui/season_view.gd, "
               "src/ui/placeholder_art.gd",
         goal="Blossom in spring, colour in autumn, bare branches under snow "
              "in winter: the approved seasonal trees and snow caps replace "
              "the remapped stand-ins of 0159.",
         req=["`python tools/task.py next` only offers this task once "
              "`python implementation/backlog/assets.py status A013` says "
              "`approved`. Check it again first; if it does not, stop and "
              "change nothing (the task stays todo and waits). This task "
              "never draws, generates or substitutes art.",
              "Use only the folder named in the pack's "
              "`CLAUDE-A013-PROMPT.txt` handoff; check every file against "
              "its `contract.json` sha256 before promoting; never resample, "
              "regenerate, or cut from previews or GIFs.",
              "Promote through the raster pipeline: versioned sources under "
              "`assets/art_source/props/`, manifest entries with "
              "prompt/approval provenance, "
              "`assets/art_source/ownership.json`, then "
              "`python tools/import_art.py`; extend the hard-coded family "
              "lists the art checks use (`tools/check_prop_art.py`, "
              "`ArtPlacement` if needed).",
              "Runtime names: `props/tree_spring`, `tree_autumn` and "
              "`tree_winter`, and the same for `tree_b` - 40x48, pivot "
              "(20,44), sharing canvas, pivot, scale and palette with the "
              "base tree (`variant_of` rules); summer is today's tree. The "
              "tree wind motion (`tree_wind_showcase.gd`) still applies",
              "Generic 16x16 snow caps drawn over each stump, rock, seam and "
              "ore node in winter, and over 0156's new nodes and stumps (one "
              "per 2x2 cell); the caps are an overlay in the view, never a "
              "change to the occupant. 0159's lookup finds the seasonal "
              "frames, and the remap leaves them alone",
              "Delete the stand-in entries from "
              "`src/ui/placeholder_art.gd`; `python tools/placeholders.py` "
              "no longer lists A013",
              "Set the pack to integrated: "
              "`python implementation/backlog/assets.py set A013 "
              "integrated`."],
         dod=["`python tools/check_prop_art.py` and "
              "`python tools/show_art.py --check` pass, and "
              "`python tools/import_art.py --check` passes",
              "FHD (1920x1080) captures by day and by night in the real game "
              "- `python tools/shot.py 0164 noon season_autumn "
              "season_winter season_winter_night --fhd` - in "
              "`implementation/shots/0164/`, opened and looked at: the "
              "trees change with the season and every cap sits on its node",
              "The sim and data hashes are unchanged (art never moves them)"]),
]
