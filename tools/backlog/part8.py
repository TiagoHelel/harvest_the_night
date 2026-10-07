# -*- coding: utf-8 -*-
"""Backlog part 8: phase 12, the day that pays.

The plan's Phase 3 (`docs/PLANO-DO-JOGO.md` section 3). The night works with
the farmer asleep (0148) and the calendar turns (0149-0160); now the day earns
its half: crops by days in twelve kinds and three growing seasons, tools in
tiers, fish by pond and hour, barns, artisan machines, a shipping bin and a
peddler. It comes before the new weapons because the night spends what the
day makes, and it ends at a checkpoint (0196): is the day good on its own?
"""

P12 = "12 - The day that pays"


# The four bullets every art integration leaf shares, word for word, so the
# twenty-one leaves below cannot drift apart. Each leaf adds its own mapping.
def _gate(pack):
    return ("`python tools/task.py next` only offers this task once "
            "`python implementation/backlog/assets.py status %s` says "
            "`approved`. Check it again first; if it does not, stop and "
            "change nothing (the task stays todo and waits). This task never "
            "draws, generates or substitutes art." % pack)


def _handoff(pack):
    return ("Use only the folder named in the pack's `CLAUDE-%s-PROMPT.txt` "
            "handoff; check every file against its `contract.json` sha256 "
            "before promoting; never resample, regenerate, or cut from "
            "previews or GIFs." % pack)


def _promote(family, checks):
    return ("Promote through the raster pipeline: versioned sources under "
            "`assets/art_source/%s/`, manifest entries with prompt/approval "
            "provenance, `assets/art_source/ownership.json`, then "
            "`python tools/import_art.py`; extend the hard-coded family lists "
            "the art checks use (%s)." % (family, checks))


def _integrated(pack):
    return ("Set the pack to integrated: "
            "`python implementation/backlog/assets.py set %s integrated`."
            % pack)


def _art_dod(checks, task):
    return [checks + " pass",
            "`python tools/import_art.py --check` passes",
            "FHD (1920x1080) captures by day and by night of the art in the "
            "real game, opened and looked at, in `implementation/shots/%04d/`"
            % task,
            "the sim and data hashes are unchanged (art never moves them)"]


TASKS = [
    # ============================================ phase 12 - the day that pays
    dict(id=165, phase=P12, title="Crops grow by days", slug="crops-by-days",
         deps=[149, 151, 156],
         files="src/core/farming.gd, src/core/phases.gd, src/core/sim.gd, "
               "src/core/game_data.gd, src/app/save.gd, src/core/state.gd, "
               "src/ui/day_hud.gd, src/ui/describe.gd, "
               "assets/locale/strings.csv, src/tools/perf_names.gd, "
               "src/tools/perf_check.gd, tools/perf_baseline.txt, "
               "src/tools/make_goldens.gd, tools/goldens/, "
               "src/tools/headless_check.gd, src/tools/input_check.gd, "
               "src/tools/headless_v1.gd",
         goal="Crops grow by days, the way the plan and Stardew have it: each "
              "morning a plot that was watered the day before moves one day "
              "along. A field becomes something you plan a week around, not "
              "a minute.",
         req=["`CROPS` entries trade `growth_ticks` for `growth_days` "
              "(`# LEVER`, plan section 3.1: carrot 3, wheat 4, corn 8; the "
              "other nine crops are 0168's). `stages` stays 4 and "
              "`Farming.stage()` maps days onto it in integer arithmetic",
              "The credit: `Farming.dry_out()` (called by "
              "`Phases.begin_preparation`) first records which planted plots "
              "were watered, then dries them; `Phases.begin_day` calls a new "
              "`Farming.morning(state)` that adds one day to each recorded "
              "plot and raises `crop_ready`. One credit per morning, so a boss "
              "night that repeats (0153) still grows the field and a farmer "
              "who passed out (0128) is credited like one who went to bed",
              "Dry is not dead: an unwatered plot waits a day and loses "
              "nothing. `WATER_GROWTH_BONUS` and the `soak` bank go, nothing "
              "grows per tick any more: take `Farming.tick` out of "
              "`Sim._tick_day` and `Farming` out of `PerfNames.DAY` "
              "(`_task_0102_budget` compares the two), its arm out of "
              "`perf_check.gd`'s `_tick_one`, and the `day_farming` row out "
              "of `tools/perf_baseline.txt` (`python tools/perf.py --accept`)",
              "`value_per_day`, `harvests_per_day`, `seconds_to_grow` and "
              "`GameData._crop_offer`/`check_crops` work in days: harvests "
              "per season of 0149's season length, value per harvest as "
              "today; the seed strip (`DHUD_SEED_ROW`, `day_hud.gd`) and the "
              "tooltip (`DESC_GROWS_IN`, `describe.gd`) say days, in both "
              "languages",
              "A saved plot's `growth` changes units: `State.VERSION` 7 "
              "(after 0156's 6) with a step in `Save.migrations()` that turns "
              "tick growth into whole days (rounded down, a ready crop stays "
              "ready - the step carries the old `growth_ticks` per crop as "
              "literals, the table no longer has them) and drops `soak`, "
              "plus `run-v7*.sav` through `src/tools/make_goldens.gd`; every "
              "older golden still loads",
              "Rewrite `_task_0028_crops` and `_task_0029_watering` "
              "(headless_check) and `_case_0028_seeds`/`_case_0029_watering` "
              "(input_check) to the new rule, and every other reader of tick "
              "growth: `_task_0018_wheat`, `_task_0020_shop` and "
              "`_task_0039_clock` (growth paused by a panel, a crop ripe "
              "after a day), `_case_0040_shop`, `art_showcase.gd` (it calls "
              "`Farming.tick`), `effect_showcase.gd`, `house_check.gd`, the "
              "autoplayer's field plan - grep `growth`, `is_ready` and "
              "`Farming.tick` for the rest",
              "Tests credit mornings by calling `Farming.morning` or "
              "`Phases.begin_day`, never by advancing whole days of ticks - a "
              "day is about to become some sixteen thousand of them (0166)",
              "SIM moves on purpose (the determinism scenario plants crops) "
              "and DATA moves (the CROPS table); record both numbers"],
         dod=["`_task_0165_days` in `src/tools/headless_v1.gd`: a watered and "
              "an unwatered carrot planted together are a day apart after one "
              "morning; a carrot watered three days running is ready on the "
              "third morning; passing out credits the field like going to bed",
              "The migration turns a golden's half-grown plot into the "
              "matching whole days, asserted",
              "`python tools/shot.py 0165 noon --fhd` shows the field at "
              "several stages; opened and looked at"]),

    dict(id=166, phase=P12, title="A day of eight to ten minutes",
         slug="longer-day", deps=[165],
         files="src/core/game_data.gd, src/core/phases.gd, "
               "src/tools/autoplay.gd, src/tools/headless_check.gd, "
               "src/tools/input_check.gd, src/tools/headless_v1.gd, "
               "tools/balance.py, implementation/BALANCE.md",
         goal="The day becomes eight to ten real minutes, so the 80x65 farm "
              "has time in it: crossing it already takes 28 seconds, and the "
              "plan's spring day (its appendix) does not fit in four minutes.",
         req=["`DAY_TICKS` spans 0126's 1200 game minutes (06:00-02:00) at "
              "a whole number of ticks per minute, which 0126's `validate()` "
              "rule demands: 12-15 a minute is 14400-18000 ticks, 8-10 real "
              "minutes (`# LEVER`). Recommended 14 (16800 ticks, 9 min 20 s) "
              "- nine minutes flat is 13.5 a minute and is refused. 0126 "
              "already derives `DUSK_AT_TICK` from `DUSK_MINUTE`: check it "
              "still lands on 18:00",
              "Re-express every per-tick producer against the longer day, "
              "with the arithmetic in the journal: `RECIPES` ticks (a kit "
              "still takes about a walk across the farm), "
              "`LIVESTOCK.every_ticks`, `GATHERING.regrow_ticks` (a node "
              "still gives about twice a day), the `FISHING` bite range, the "
              "generator's `fuel_every_ticks` and the `DAILY_STOCK` sizes. "
              "Nothing may double its daily output by accident",
              "Nothing in core or ui may hard-code a tick count for an hour of "
              "the clock: the bedtime reminders (0140) and pass-out (0128) "
              "read 0126's helpers, and so will 0190's stall hours - grep for "
              "`SECONDS` multiples compared with `day_tick`",
              "Re-time the suites: no headless group or input case may "
              "advance a whole day or a whole morning of ticks. Today's are "
              "`_task_0006_phases` and `_task_0021_night_intent` (to dusk), "
              "`_task_0030_fishing`, `_task_0031_iron`, `_task_0038_idle`, "
              "`_task_0039_clock`, `_task_0067_autoplay`, "
              "`_task_0068_balance`, `_case_0039_clock` and any v1 group "
              "that does (grep `DAY_TICKS`, `DUSK_AT_TICK`): give them a "
              "shorter road - a rigged `day_tick`, a direct morning call - "
              "and record each suite's time before and after",
              "`Autoplay._a_day` (as 0142 left it) spends the new day; keep "
              "`_task_0067`/`_task_0068` inside the budget by playing fewer "
              "days in the suite, never by shortening the lever. "
              "`tools/autoplay.py` and `tools/balance.py` still run",
              "A saved `day_tick` keeps its meaning (ticks since 06:00) and "
              "only reads earlier on the longer clock, and producer timers "
              "count down as before: no `State.VERSION` bump - say so in the "
              "journal",
              "DATA moves on purpose (time and producer levers). SIM moves on "
              "purpose too: the determinism scenario's kits, animals and "
              "clock run on the re-expressed levers. Record both, and add a "
              "BALANCE.md note on what one day yields now"],
         dod=["`_task_0166_long_day` in `src/tools/headless_v1.gd`: "
              "`DAY_TICKS` maps onto 06:00-02:00, dusk reads 18:00, and each "
              "producer's yield per day (computed from the tables, not "
              "simulated) is inside the range the journal claims",
              "headless_check, input_check and both v1 suites finish at least "
              "20 s under `SCRIPT_TIMEOUT_S`, with the times in the journal",
              "A short `tools/autoplay.py` run plays a full day and night, and "
              "the journal records the money that day made"]),

    dict(id=167, phase=P12, title="Any grass can be tilled", slug="till-grass",
         deps=[165], dresses=["A014"],
         files="src/core/farming.gd, src/core/interact.gd, "
               "src/core/game_data.gd, src/core/tutorial.gd, "
               "src/ui/world_view.gd, src/ui/placeholder_art.gd, "
               "src/tools/autoplay.gd, src/tools/determinism.gd, "
               "src/tools/make_goldens.gd, src/tools/perf_check.gd, "
               "src/tools/house_check.gd, src/tools/shot.gd, "
               "src/tools/headless_v1.gd, src/tools/input_v1.gd",
         goal="Any grass can be tilled, as in Stardew, so the 60 beds become "
              "the starter garden rather than the whole of farming - and "
              "ground becomes a choice between field and fortress (plan "
              "section 5: space has two uses).",
         req=["`Interact._offered` sends GRASS as well as SOIL to "
              "`Farming.verb_at`, which offers `till` on bare grass and works "
              "on any plot whatever the ground under it. **The terrain byte "
              "never changes**: `world_view` draws terrain once, so tilled "
              "grass is a plot over grass, drawn by `_refresh_plots`",
              "Only bare grass and soil take the hoe; path, floor, water, rock "
              "and any occupied cell offer nothing",
              "Untended ground goes back: an empty tilled plot on grass left "
              "for `TILLED_GRASS_FADES_DAYS` mornings (`# LEVER`, 1-7) returns "
              "to grass in `Farming.morning`; soil beds never fade. The plot "
              "remembers the morning it was last worked (plots are "
              "`RUN_DATA`: read the new field with a default, reconcile never "
              "fills it)",
              "Path cost: decide whether tilled grass costs like SOIL in the "
              "flow field. Recommended: it keeps the grass cost, because a "
              "field that changed the route on every hoe stroke would call "
              "`Farm.touch` and rebuild every field (`path_refresh` ~7.9 ms). "
              "The journal says which and why",
              "Add `Farming.field_cells(state)` (soil beds plus tilled grass, "
              "index order) and move every user that means 'the field' off "
              "`Farm.cells_of(SOIL)`: `tutorial.gd` (three sites), "
              "`autoplay.gd`, `determinism.gd`, `make_goldens.gd`, "
              "`perf_check.gd`, `house_check.gd` and the headless/input "
              "helpers. With no grass tilled it returns exactly today's "
              "cells, so that alone moves no hash",
              "Edges of tilled grass: decide the scheme (N1/E2/S4/W8 masks "
              "like the barriers, or a plain border) and draw it through the "
              "placeholder road with today's `tilled`/`tilled_wet` sprites "
              "until A014 is integrated by 0197",
              "DATA moves (the lever goes into `digest()`). SIM moves only if "
              "the scenario's soil plots change shape: write the new plot "
              "field only on tilled grass (soil beds never fade) and it "
              "stays - say which"],
         dod=["`_task_0167_till_grass` in `src/tools/headless_v1.gd`: the hoe "
              "on grass makes a plot and leaves the terrain byte alone; an "
              "empty tilled grass plot is gone after the fade mornings and a "
              "planted one is not; a path cell refuses the hoe",
              "`_case_0167_till_grass` in `src/tools/input_v1.gd`: the farmer "
              "walks onto open grass, holds interact, and a plot appears",
              "A new `till_grass` scenario: `python tools/shot.py 0167 "
              "till_grass --fhd` shows tilled grass beside the beds by day "
              "and by night; opened and looked at",
              "the Deliverables table of "
              "`implementation/backlog/packs/A014-crop-ground.md` states the "
              "final geometry this task settled (edge masks, canvas, pivot)"]),

    dict(id=168, phase=P12, title="Nine new crops", slug="crop-data",
         deps=[165], dresses=["A015", "A016", "A017"],
         files="src/core/game_data.gd, src/ui/names.gd, "
               "assets/locale/strings.csv, src/ui/day_hud.gd, "
               "src/ui/placeholder_art.gd, src/tools/shot.gd, "
               "src/tools/headless_v1.gd",
         goal="The plan's twelve crops exist as data: potato, garlic, "
              "strawberry, pepper, sunflower, melon, pumpkin, grape and beet "
              "join carrot, corn and wheat, each with the role section 3.1 "
              "gives it.",
         req=["Data only: nine `CROPS` entries with `growth_days`, "
              "`seed_cost`, `yield` and `stages` from the plan's table "
              "(potato 5, garlic 4, strawberry 8, pepper 5, sunflower 7, "
              "melon 10, pumpkin 10, grape 8, beet 6 days), plus `RESOURCES`, "
              "`SELL_PRICE` and the existing `crops` group of "
              "`RESOURCE_GROUPS`, every number a `# LEVER`",
              "Seasons are 0170's and regrowth 0172's: add neither field here",
              "Ids are the plain crop names; the defences that share a crop "
              "word keep their own ids (`garlic_braid`, `catapult`, `decoy`)",
              "`Names.KEYS` and `ITEM_POTATO`..`ITEM_BEET` rows in "
              "`assets/locale/strings.csv` (key,width,en,pt_BR: batata, alho, "
              "morango, pimenta, girassol, melancia, abóbora, uva, beterraba); "
              "`tools/i18n_check.py` clean",
              "`check_crops` keeps 'no crop dominates on money, visits and "
              "seed cost at once' across all twelve: seed costs that rise "
              "with value per day are enough. Put the table in the journal; "
              "0170 may narrow the comparison to one season",
              "Twelve rows overflow the `DayHud` seed strip and its six "
              "`SEED_ACTIONS`. Until 0170 filters it by season, keep it "
              "legible (page it, or six rows around the selection - view "
              "only) and capture it",
              "Every new crop draws through the placeholder road: a tinted "
              "stand-in of an existing crop's four stages at the final canvas "
              "(the art contract's 16x16, pivot (8,14); sunflower and the "
              "grape trellis very tall at 16x32, pivot (8,30)) until "
              "A015/A016/A017 are integrated by 0198/0199/0200",
              "DATA moves (the tables). SIM moves on purpose: nine new keys "
              "in `held`/`gained`, which `State.hash_of` folds, and the "
              "determinism scenario sows `Farming.seeds()` in sorted order, "
              "so its field changes. Record both"],
         dod=["`_task_0168_crops` in `src/tools/headless_v1.gd`: all twelve "
              "validate, each has a price, a group and a name in both "
              "languages, and each reaches its ready stage in its plan days "
              "of watered mornings",
              "A new `twelve_crops` scenario: `python tools/shot.py 0168 "
              "twelve_crops --fhd` shows every crop at its four stages; "
              "opened and looked at",
              "the Deliverables tables of "
              "`implementation/backlog/packs/A015-spring-crops.md`, "
              "`A016-summer-crops.md` and `A017-autumn-crops.md` state the "
              "final geometry this task settled (canvas, pivot, stages, which "
              "crops are tall)"]),

    dict(id=169, phase=P12, title="An inventory for many things",
         slug="inventory", deps=[168],
         files="src/ui/inventory_panel.gd, src/core/inventory.gd, "
               "src/core/game_data.gd, src/ui/day_hud.gd, src/ui/names.gd, "
               "src/app/input_actions.gd, assets/locale/strings.csv, "
               "src/tools/shot.gd, src/tools/headless_v1.gd, "
               "src/tools/input_v1.gd",
         goal="Task 0036's inventory was a list for fifteen things and 1.0 "
              "has about seventy. Groups become pages a player flips with a "
              "key, a click or the pad, and the HUD's six numbers become a "
              "choice.",
         req=["`RESOURCE_GROUPS` grows to the categories of plan section 8 "
              "(materials, crops, seeds, fish, animal goods, artisan goods, "
              "ammunition, night leftovers, the farm). A group may be "
              "declared before its members exist; an empty group is not drawn",
              "`inventory_panel.gd` shows one group per page with tabs "
              "(keyboard, mouse and pad through `InputActions`), amount and "
              "sale price per row, and fits 480x270 with seventy items in "
              "all; `ROW_HEIGHT` decides how many rows a page holds. Each tab "
              "is named by a literal key (`INV_GROUP_*` rows, en and pt_BR, "
              "looked up through a literal table so `tools/i18n_check.py` "
              "sees them)",
              "`DayHud.SHOWN` stays six numbers in two rows; which six is a "
              "decision written in the journal (wood, stone, iron and food, "
              "plus the two that matter most in 1.0). The bar never grows",
              "**From here on a resource is not done until it is complete**: "
              "`GameData.validate()` (an extended `check_groups` or a new "
              "check) refuses a `RESOURCES` id with no `SELL_PRICE` (money, "
              "energy and tech excepted) or no group (nothing new may fall "
              "into `GROUP_OTHER`), and headless asserts each id has a "
              "`Names.KEYS` entry and an `ITEM_*` row in both languages. "
              "Every later task that adds a resource adds all four",
              "An item with no `ui/icon_<id>` draws a placeholder through the "
              "placeholder road (0120), so no row is ever blank",
              "View only: SIM unchanged; DATA moves for the groups table"],
         dod=["`_task_0169_inventory` in `src/tools/headless_v1.gd`: the "
              "new check fails by name on a rigged table with an unpriced and "
              "with an ungrouped resource; every real resource has a price, "
              "a group, a `Names.KEYS` entry and an `ITEM_*` row in both "
              "languages",
              "`_case_0169_inventory` in `src/tools/input_v1.gd`: open the "
              "inventory, flip every page with the keyboard, the mouse and a "
              "synthetic pad event, close it",
              "A new `inventory_full` scenario (every item held): `python "
              "tools/shot.py 0169 inventory_full --fhd` shows each page with "
              "no labels on top of each other; opened and looked at"]),

    dict(id=170, phase=P12, title="Crops keep to their seasons",
         slug="crop-seasons", deps=[168, 149],
         files="src/core/game_data.gd, src/core/farming.gd, src/core/shop.gd, "
               "src/ui/day_hud.gd, src/ui/shop_panel.gd, src/ui/names.gd, "
               "src/ui/placeholder_art.gd, assets/locale/strings.csv, "
               "src/tools/autoplay.gd, src/tools/determinism.gd, "
               "src/tools/make_goldens.gd, src/tools/perf_check.gd, "
               "src/tools/shot.gd, src/tools/headless_check.gd, "
               "src/tools/input_check.gd, src/tools/headless_v1.gd, "
               "src/tools/input_v1.gd",
         goal="Each crop keeps to its season, so spring, summer and autumn "
              "fields look and pay differently, and seeds are bought at the "
              "stall when their season comes round (plan sections 3.1 and "
              "3.6).",
         req=["`CROPS` gains `seasons` (`# LEVER`): carrot, potato, garlic, "
              "strawberry in spring; corn, pepper, sunflower, melon in "
              "summer; wheat, pumpkin, grape, beet in autumn. No crop lists "
              "winter. The season is "
              "`Calendar.season_of(Calendar.date(state))` (0149). What a "
              "change of season does to a planted field, winter included, "
              "is 0171's",
              "Seeds become items, as the plan's stall and the seed packets "
              "of A015-A017 expect: a `<crop>_seed` resource per crop with a "
              "price, the seeds group, a `Names.KEYS` entry and an "
              "`ITEM_<CROP>_SEED` row in both languages (0169's check wants "
              "all four). `Farming._plant` spends one packet of the selected "
              "crop instead of `seed_cost` in money (its own comment names it "
              "as the one function this changes); `selected_seed` still holds "
              "a crop id; `STARTING_RESOURCES` gives a few spring packets so "
              "day 1 still plants",
              "`seed_cost` stays the number `check_crops` balances on and is "
              "what a packet costs at the stall; the packet's sell-back stays "
              "below it so `check_stall`'s no-profit loop holds",
              "The stall stocks this season's seeds only (a seasonal stock "
              "table read by `Shop.restock`/`buyable`, in `digest()`); "
              "`check_stall` covers every season",
              "The seed strip lists this season's crops with the packets "
              "held, inside the six `SEED_ACTIONS`; an off-season crop cannot "
              "be selected. Packet icons draw through the placeholder road "
              "(the crop's icon, tinted) until A015/A016/A017 are integrated "
              "by 0198/0199/0200",
              "Move what plants with money: `_task_0018_wheat`, "
              "`_task_0028_crops`, `_case_0028_seeds`, the autoplayer (it "
              "buys packets), `determinism.gd`, `make_goldens.gd`, "
              "`perf_check.gd` and `shot.gd` (they sow on a fresh farm). "
              "Correct `TUT_PLANT`/`TUT_SELL` and any line that says seeds "
              "are paid at the furrow, in both languages",
              "SIM and DATA move on purpose (twelve packet resources in "
              "`held`/`gained`, the stall's seasonal stock in the state, the "
              "planting rule); record both"],
         dod=["`_task_0170_seasons` in `src/tools/headless_v1.gd`: a spring "
              "stall stocks only spring seeds and a summer one only "
              "summer's; planting spends one packet and no money; an "
              "off-season crop cannot be selected",
              "`_case_0170_seeds` in `src/tools/input_v1.gd`: buy potato "
              "packets at the stall, pick them on a slot key, plant one",
              "New `spring_field` and `summer_field` scenarios: `python "
              "tools/shot.py 0170 spring_field summer_field --fhd`; opened "
              "and looked at"]),

    dict(id=171, phase=P12, title="Winter: nothing grows outside",
         slug="winter-rules", deps=[170, 159],
         files="src/core/farming.gd, src/core/game_data.gd, "
               "src/ui/day_hud.gd, src/ui/world_view.gd, "
               "src/ui/placeholder_art.gd, assets/locale/strings.csv, "
               "src/tools/shot.gd, src/tools/headless_v1.gd",
         goal="When a season ends its crops wither, and in winter nothing "
              "grows outside - yet the day still matters: the pond, the "
              "quarry, the workshop and the barn carry it while the farm "
              "lives on autumn's stock.",
         req=["The change of season, moved here from 0170 so one task owns "
              "what a season boundary does to the field: on the first "
              "morning of a season `Farming.morning` withers every planted "
              "crop whose `seasons` does not list the new one (regrowing "
              "plants too, once 0172 has them). The plot keeps a `withered` "
              "marker, like 0155's `trampled`, that harvest or the hoe clears "
              "for nothing. No crop lists winter, so Winter 1 withers what "
              "autumn left in the ground: write that in the journal",
              "A withered crop draws through the placeholder road (the "
              "crop's stage-2 frame, greyed in code) until A014's withered "
              "crop is integrated by 0197",
              "`Farming.morning` credits no growth outdoors in a season named "
              "by `NO_GROWTH_SEASONS` (`# LEVER`, winter; in `digest()`), so "
              "a crop that is in the ground in winter anyway (a test, an old "
              "save) never grows",
              "Planting in winter is refused with a reason the highlight can "
              "show (a `WHY_*` key in both languages), never a silent "
              "nothing; tilling still works",
              "The seed strip says that nothing grows in winter instead of "
              "showing an empty list (a `DHUD_*` string in both languages)",
              "Assert the rest of a winter day still runs - a check, not a "
              "new rule: fishing (winter species once 0179 has them), mining "
              "and regrowth, crafting queues and animals all produce",
              "No greenhouse: plan section 3.1 puts it after 1.0",
              "Winter's look is 0159's; this task adds only the withered "
              "stand-in and the HUD line. DATA moves; SIM does not unless the "
              "determinism scenario crosses a season - say which"],
         dod=["`_task_0171_winter` in `src/tools/headless_v1.gd`: a corn plot "
              "withers on the first morning of autumn and a wheat plot sown "
              "that morning does not; every planted crop withers on Winter 1; "
              "a watered plot gains no day on a winter morning; a seam, a "
              "press queue and a cow still produce on a winter day (direct "
              "calls or a short run)",
              "New `withered` (the first morning of autumn by a summer field) "
              "and `winter_day` scenarios: `python tools/shot.py 0171 "
              "withered winter_day --fhd` shows the withered stand-ins and "
              "the HUD line; opened and looked at"]),

    dict(id=172, phase=P12, title="Crops that grow back",
         slug="regrowing-crops", deps=[168],
         files="src/core/farming.gd, src/core/game_data.gd, "
               "src/ui/world_view.gd, src/ui/placeholder_art.gd, "
               "src/tools/shot.gd, src/tools/headless_v1.gd",
         goal="Strawberry, corn, pepper and grape grow back after picking, so "
              "planting them early in their season is a choice that pays all "
              "season long.",
         req=["`CROPS` gains `regrow_days` (`# LEVER`) for strawberry 4, "
              "corn 4, pepper 3 and grape 3 (plan section 3.1)",
              "`Farming._harvest` on a regrowing crop leaves the plant in a "
              "regrowing state, `regrow_days` short of ready, instead of an "
              "empty plot; watering and the morning credit work as for any "
              "crop, and the hoe clears it",
              "`Farming.stage()` reports a distinct regrowing stage the view "
              "draws as `<crop>_regrow`; until A015/A016/A017 are integrated "
              "by 0198/0199/0200 it is the stage-2 sprite tinted, through the "
              "placeholder road",
              "`value_per_day` and `check_crops` count regrowth: harvests in "
              "a season are one plus the whole regrowths left in it. Put the "
              "table in the journal so the four do not dominate the rest",
              "The season-change withering of 0171 takes regrowing plants "
              "too; if 0171 has landed, assert it",
              "The new plot field is read with a default (plots are "
              "`RUN_DATA`); if it changes what a saved `growth` means, bump "
              "`State.VERSION` and migrate",
              "DATA moves; SIM only if the scenario harvests a regrowing crop"],
         dod=["`_task_0172_regrow` in `src/tools/headless_v1.gd`: a strawberry "
              "harvested when ready is ready again `regrow_days` watered "
              "mornings later without replanting; a carrot leaves an empty "
              "plot",
              "A new `regrowing` scenario: `python tools/shot.py 0172 "
              "regrowing --fhd` shows a regrowing strawberry beside a ripe "
              "one; opened and looked at"]),

    dict(id=173, phase=P12, title="Five tools, three tiers", slug="tool-tiers",
         deps=[148, 126], dresses=["A019"],
         files="src/core/tool_tiers.gd (new), src/core/state.gd, "
               "src/core/game_data.gd, src/core/crafting.gd, "
               "src/core/phases.gd, src/ui/workshop_panel.gd, "
               "src/ui/player_work.gd, src/ui/names.gd, "
               "assets/locale/strings.csv, src/tools/shot.gd, "
               "src/tools/headless_check.gd, src/tools/headless_v1.gd, "
               "src/tools/input_v1.gd",
         goal="Hoe, watering can, axe, pickaxe and rod, each in three tiers "
              "bought at the workshop with money and ore: the first thing day "
              "money buys that makes every later day better (plan section "
              "3.7).",
         req=["`TOOLS` in `game_data.gd`: hoe, can, axe and pickaxe at "
              "basic/iron/gold, the rod at bamboo/fibre/iron, as tiers 0/1/2 "
              "of one ladder; each tier's cost (money + ore) and the effect "
              "fields 0174, 0175 and 0181 read, all `# LEVER`",
              "The tiers held and any pending upgrade live in a `tools` "
              "dictionary (keys from code: `State.TABLES`, through a new "
              "`initial()` - e.g. `src/core/tool_tiers.gd` - and one `_adopt` "
              "line), all tier 0 in a new game. **Tools are not resources**: "
              "`Rewards._loss` iterates `RESOURCES` and must never take one",
              "An upgrade is a workshop recipe whose output names a tool "
              "tier: a new branch in `Crafting._deliver` (and in "
              "`check_recipes`, which accepts only resources and defences "
              "today) records it as pending, and `Phases.begin_day` hands it "
              "over - ready the next morning. The tool keeps its old tier "
              "until then, so no day is spent without a can",
              "This task ships tier 1 for all five (iron hoe, can, axe and "
              "pickaxe; fibre rod) and the rod's tier 2 (iron). The gold "
              "costs arrive with 0176; until then gold is listed and refused "
              "with a reason",
              "Rebalance the tech nodes that did a tool's job: 'sharp tools' "
              "(`gather_percent`) and 'full cans' (`water_can_bonus`) keep "
              "their ids, get smaller numbers or a new role, and their "
              "`note` and `TECHNOTE_*` rows change in both languages; "
              "arithmetic in the journal. `_task_0063_tech_tree` asserts "
              "'sharp tools' makes chopping quicker: keep that true or "
              "rewrite it in place",
              "The tool in the farmer's hand is not tiered by art (decision): "
              "the work frames keep one fixed head ramp and "
              "`player_work.gd` tints it per tier, view only. Tool icons in "
              "the workshop panel and the inventory use the placeholder road "
              "until A019 is integrated by 0202",
              "Names and strings for every tool and tier, and a `Names.KEYS` "
              "entry with a `REC_*` row for every upgrade recipe (every "
              "`RECIPES` id needs one), in both languages; `validate()` "
              "checks every tier cost names a real resource; `TOOLS` goes "
              "into `digest()`",
              "DATA moves (TOOLS, TECH_TREE). SIM moves on purpose: the new "
              "`tools` key is in the state and `State.hash_of` folds every "
              "key - record both"],
         dod=["`_task_0173_tools` in `src/tools/headless_v1.gd`: an iron axe "
              "queued with the money and iron is still basic that evening and "
              "iron the next morning; a lost night takes 25% of the iron and "
              "no tool",
              "`_case_0173_upgrade` in `src/tools/input_v1.gd`: open the "
              "workshop and order an upgrade with the keyboard and with the "
              "mouse; it shows as pending",
              "A new `tool_upgrades` scenario: `python tools/shot.py 0173 "
              "tool_upgrades --fhd` shows "
              "the upgrade list and the farmer chopping with a tinted iron "
              "head; opened and looked at"]),

    dict(id=174, phase=P12, title="The can and the hoe by tier",
         slug="can-and-hoe", deps=[173, 167],
         files="src/core/farming.gd, src/core/player.gd, "
               "src/core/game_data.gd, src/ui/day_hud.gd, "
               "src/ui/world_view.gd, src/tools/headless_v1.gd, "
               "src/tools/input_v1.gd",
         goal="The can and the hoe earn their tiers: one tile, then three, "
              "then five at a stroke, which turns watering a big field from a "
              "chore into a walk.",
         req=["The can's and the hoe's tiers carry an area (`# LEVER`: 1, 3 "
              "and 5 tiles, plan section 3.7): the faced tile and the ones "
              "beside it across the facing. Pick the shape, draw it, write it "
              "down",
              "`Farming._water` and `Player._do_instant` water every tile of "
              "the area that offers `water`, one unit of the can per tile, in "
              "a fixed order; a can short of water waters what it holds",
              "A better hoe tills the area through `Farming._till` in one "
              "action of the hoe's time, skipping cells 0167 refuses",
              "Decide whether the can's tier also raises its capacity (a "
              "per-tier `# LEVER` added in `Farming.can_capacity`), and fix "
              "the known bug: `day_hud.gd` prints the can against "
              "`GameData.WATER_CAN_CAPACITY` instead of "
              "`Farming.can_capacity(state)`, so 'full cans' never showed",
              "The highlight shows every cell the next press will touch "
              "(view only, `world_view.gd`)",
              "DATA moves; SIM moves only if the scenario uses an upgraded "
              "tool (it should not)"],
         dod=["`_task_0174_area` in `src/tools/headless_v1.gd`: an iron can "
              "waters three dry plots in one press and spends three; a gold "
              "hoe (its tier written into the state - gold cannot be ordered "
              "before 0176) tills five grass cells and skips a path cell "
              "among them; "
              "the HUD's capacity equals `Farming.can_capacity` with 'full "
              "cans' bought",
              "`_case_0174_area` in `src/tools/input_v1.gd`: holding interact "
              "along a row with an iron can waters it in a third of the steps",
              "A new `can_area` scenario: `python tools/shot.py 0174 "
              "can_area --fhd` shows the area "
              "highlight; opened and looked at"]),

    dict(id=175, phase=P12, title="The axe and the pickaxe by tier",
         slug="axe-pickaxe", deps=[173],
         files="src/core/interact.gd, src/core/gathering.gd, "
               "src/core/game_data.gd, assets/locale/strings.csv, "
               "src/tools/headless_v1.gd",
         goal="The axe and the pickaxe save time by tier, and the hardest "
              "things on the farm - hardwood stumps and gold - want the iron "
              "ones.",
         req=["Fewer swings by tier: the tool's tier scales the swing in "
              "`Interact.ticks_for` or the `hits` `Gathering.strike` counts - "
              "pick one, keep it integer, and make it compose with 'sharp "
              "tools' (`gather_percent`) rather than replace it",
              "A `GATHERING` entry may name a `min_tier`; below it the cell "
              "still shows its verb but the work is refused with a reason in "
              "both languages ('needs an iron axe'), never a swing that "
              "silently does nothing",
              "The real gates arrive with their nodes - hardwood stumps "
              "(0177) want an iron axe, gold (0176) an iron pickaxe - so test "
              "the rule here with a rigged entry",
              "`validate()` checks `min_tier` against the `TOOLS` ladder; "
              "`check_iron` and `check_reachable` still pass",
              "DATA moves; SIM only if the scenario gathers with an upgraded "
              "tool"],
         dod=["`_task_0175_swings` in `src/tools/headless_v1.gd`: an iron axe "
              "fells a tree in fewer ticks than a basic one, by the percent "
              "the lever claims; a rigged `min_tier` node refuses a basic "
              "pickaxe and yields to an iron one",
              "The refusal fits its control in both languages "
              "(`tools/i18n_check.py`)"]),

    dict(id=176, phase=P12, title="Copper, coal and gold",
         slug="copper-coal-gold", deps=[175, 156], dresses=["A020", "A021"],
         files="src/core/game_data.gd, src/core/gathering.gd, "
               "src/core/interact.gd, src/ui/names.gd, "
               "src/ui/placeholder_art.gd, assets/locale/strings.csv, "
               "src/tools/shot.gd, src/tools/headless_v1.gd",
         goal="The quarry gets copper and coal - for sprinklers, tools and "
              "the generator - and gold from autumn for the top tier (plan "
              "section 3.3).",
         req=["The copper, coal and gold nodes 0156 put on `FARM_MAP` under "
              "their final ids (e.g. `copper_ore`, `coal_seam`, `gold_ore`; "
              "its journal names them and the legend characters) become "
              "`GATHERING` entries with swings, yield and `regrow_ticks` "
              "(`# LEVER`), dearer than stone on the dials the way "
              "`check_iron` holds iron, and `Interact.OCCUPANT_VERBS` "
              "entries (`mine`, so `Sfx.VERB_SOUNDS` already covers them); "
              "gold has `min_tier` 1 (an iron pickaxe, 0175)",
              "Gold from autumn: a gold node offers no verb before the first "
              "autumn, through 0149's calendar helpers; say whether it stays "
              "open in winter",
              "`COPPER`, `COAL` and `GOLD` in `RESOURCES`, `SELL_PRICE`, the "
              "materials group, `Names.KEYS` and `ITEM_*` rows in both "
              "languages (0169's check wants all four)",
              "Coal is fuel (plan section 3.3): the generator may burn it "
              "instead of oil - decide and say so; 0193 uses coal for spring "
              "gunpowder",
              "The gold tier's costs for the hoe, can, axe and pickaxe (money "
              "+ gold, `# LEVER`), so 0173's refused tier opens",
              "Nodes draw through the placeholder road (tinted `ore`/`ore_b`, "
              "16x16, pivot (8,14)) and icons as tinted stand-ins until A021 "
              "(0204) and A020 (0203) are integrated",
              "DATA moves. SIM moves on purpose: three new resources are new "
              "keys in `held`/`gained`, which the state hash folds - record "
              "both"],
         dod=["`_task_0176_ores` in `src/tools/headless_v1.gd`: each new node "
              "yields its resource and regrows; gold refuses before autumn "
              "and with a basic pickaxe and yields after; a gold hoe can be "
              "ordered and arrives the next morning",
              "A new `quarry` scenario: `python tools/shot.py 0176 "
              "quarry --fhd` shows the quarry with "
              "the new nodes by day and by night; opened and looked at"]),

    dict(id=177, phase=P12, title="Hardwood", slug="hardwood",
         deps=[175, 156], dresses=["A020", "A021"],
         files="src/core/game_data.gd, src/core/gathering.gd, "
               "src/core/interact.gd, src/ui/world_view.gd, "
               "src/ui/names.gd, src/ui/placeholder_art.gd, "
               "assets/locale/strings.csv, src/tools/shot.gd, "
               "src/tools/headless_v1.gd",
         goal="Big stumps give hardwood to an iron axe: a reason to upgrade "
              "early, and the stuff of the strong wall (0231).",
         req=["The 2x2 stumps 0156 put on the map (`hardwood_stump`, or "
              "the id its journal names) become a `GATHERING` node with "
              "`min_tier` 1 (iron axe), more swings than a tree, a `HARDWOOD` "
              "yield and a `regrow_ticks` (`# LEVER`) - nothing on the farm "
              "is exhausted for good - and an `Interact.OCCUPANT_VERBS` entry "
              "(`chop`). One occupant over four cells with an anchor, like "
              "the stations: a swing at any of its cells strikes it",
              "A chipped look after the first swing, until it falls (view, "
              "from `Gathering.swings_left`)",
              "`HARDWOOD` in `RESOURCES`, `SELL_PRICE`, the materials group, "
              "names and strings in both languages; its icon is a tinted "
              "stand-in until A020 is integrated by 0203",
              "Its use is 0231's strong wall; here it only sells, and the "
              "journal says so. DATA moves; SIM moves on purpose (a new "
              "resource in `held`/`gained`) - record both",
              "`check_reachable`: every stump has a cell to stand on beside "
              "it; the flow field treats it like a tree",
              "A scaled stand-in of today's `stump` at 32x32 through the "
              "placeholder road until A021 is integrated by 0204"],
         dod=["`_task_0177_hardwood` in `src/tools/headless_v1.gd`: a basic "
              "axe is refused at a big stump; an iron axe fells it in the "
              "swings, for the hardwood, the levers say; it is back after "
              "`regrow_ticks`",
              "A new `hardwood` scenario: `python tools/shot.py 0177 "
              "hardwood --fhd` shows a whole and a "
              "chipped stump beside a tree; opened and looked at",
              "the Deliverables table of "
              "`implementation/backlog/packs/A021-ore-hardwood.md` states the "
              "final geometry this task settled (the node canvas and "
              "variants, the stump's canvas, pivot and states)"]),

    dict(id=178, phase=P12, title="Sprinklers", slug="sprinklers",
         deps=[176, 165], dresses=["A018"],
         files="src/core/game_data.gd, src/core/farming.gd, "
               "src/core/phases.gd, src/core/pathing.gd, "
               "src/core/building.gd, src/ui/names.gd, src/ui/particles.gd, "
               "src/ui/placeholder_art.gd, assets/locale/strings.csv, "
               "src/tools/shot.gd, src/tools/headless_v1.gd, "
               "src/tools/input_v1.gd",
         goal="Sprinklers automate the chore: copper, iron and gold ones "
              "water the plots around them every morning, so a big field "
              "stops costing the whole morning.",
         req=["Three tiers (copper, iron, gold) as `BUILDINGS` entries or one "
              "id with levels - decide - with costs in their metal plus "
              "money, hp and a 1x1 size, built by day like every production "
              "building; recipes or a direct cost, with `check_recipes` and "
              "`check_buildings` still honest",
              "Each morning, after 0165's growth credit, every sprinkler "
              "marks the plots of its pattern watered for the new day (four "
              "neighbours, 3x3, 5x5 - `# LEVER`), in sorted cell order; they "
              "dry at night like any other plot",
              "**Never a wall.** `Pathing._through` makes anything without a "
              "`path_cost` impassable, so a row of sprinklers would fence the "
              "farm. Make them walkable for the flow field like a trap (a "
              "declared flag `_through` reads) and not prey - `is_prey` "
              "counts any `BUILDINGS` entry with no `path_cost` today, so it "
              "reads the same flag - and say whether the farmer walks over "
              "them",
              "A cell with a sprinkler is not a plot: tilling and planting "
              "skip it, and a sprinkler cannot go on a planted plot",
              "The spray is code particles (view only); the body draws "
              "through the placeholder road until A018 is integrated by 0201",
              "`BLD_*`/`REC_*` names and strings in both languages. DATA "
              "moves; SIM moves if the state's shape changes (a new station "
              "in `selected_recipe`) or the scenario places one - say which"],
         dod=["`_task_0178_sprinklers` in `src/tools/headless_v1.gd`: a copper "
              "sprinkler waters its four neighbours on a morning and they "
              "grow the next; the flow field crosses its cell at ground cost; "
              "a breaker does not hunt it",
              "`_case_0178_sprinkler` in `src/tools/input_v1.gd`: place one by "
              "day from the build list",
              "A new `sprinklers` scenario: `python tools/shot.py 0178 "
              "sprinklers --fhd` shows the three tiers "
              "spraying; opened and looked at",
              "the Deliverables table of "
              "`implementation/backlog/packs/A018-sprinklers.md` states the "
              "final geometry this task settled"]),

    dict(id=179, phase=P12, title="Fish by pond, season and hour",
         slug="fish-species", deps=[126, 149, 156], dresses=["A022"],
         files="src/core/fishing.gd, src/core/game_data.gd, "
               "src/core/crafting.gd, src/app/save.gd, src/core/state.gd, "
               "src/ui/names.gd, src/ui/placeholder_art.gd, "
               "assets/locale/strings.csv, src/tools/make_goldens.gd, "
               "tools/goldens/, src/tools/headless_check.gd, "
               "src/tools/input_check.gd, src/tools/headless_v1.gd",
         goal="The one pond becomes three with about twelve species, each "
              "with its place, season, hours and rarity, so fishing asks "
              "where and when as well as whether (plan section 3.2).",
         req=["`FISH_SPECIES` in `game_data.gd`: about twelve species (carp, "
              "perch, catfish, tilapia; trout, pike, eel; dorado, salmon, "
              "sturgeon; two more to fill the seasons) with ponds (the ids "
              "of 0156's `PONDS` table, found from a cell by "
              "`Farm.pond_of`; use 0156's names, not the plan's), seasons, "
              "hours (0126's `Phases.clock_minute`), a rarity weight and a "
              "value, all `# LEVER`, in `digest()`. Legendaries are 0182's",
              "`Fishing.begin` draws the species at the cast from the run "
              "RNG, among those the pond, the season and the hour allow, "
              "weighted by rarity; the bite-delay draw stays. `Fishing.reel` "
              "gives that species and `last_catch` names it. SIM moves",
              "Each species is a resource: `RESOURCES`, `SELL_PRICE`, a fish "
              "group, `Names.KEYS`, `ITEM_*` rows in both languages",
              "**Recipes that took `fish` accept any species**, as a rule: a "
              "recipe input may name the fish group, and `Crafting` pays it "
              "from the species held in a fixed order (cheapest first, then "
              "by name). `check_recipes`, `check_chain` (value it at the "
              "cheapest member) and `Crafting.missing` understand it; "
              "`press_fish_oil` and `cook_fish` use it",
              "The old `fish` resource goes: bump `State.VERSION` by one "
              "(from whatever 0156 and 0165 left it at) with a migration that "
              "moves held `fish` into the commonest species, plus a golden at "
              "the new version - reconcile alone would drop it. Every other "
              "reader follows (`GameData.FISH`, `SELL_PRICE`, the larder "
              "group, `Names.KEYS`/`ITEM_FISH` - `tools/i18n_check.py` flags "
              "an unused key); the `fish` verb keeps its id",
              "`FISHING.common_yield`/`rare_yield` give way to the table; "
              "`check_fishing` is rewritten: every species names real ponds, "
              "seasons and hours, and every pond has a catch in every season "
              "at every hour of the day",
              "Rewrite `_task_0030_fishing` and `_case_0030_fishing` (the "
              "triple 'rare' fish is gone)",
              "Icons draw as tinted `icon_fish` stand-ins through the "
              "placeholder road until A022 is integrated by 0205"],
         dod=["`_task_0179_species` in `src/tools/headless_v1.gd`: the same "
              "seed casts the same species; a summer species never bites in "
              "spring; two of 0156's ponds yield different sets; `cook_fish` "
              "takes the cheapest species held",
              "A migrated golden's old fish arrive as the commonest species, "
              "asserted",
              "the Deliverables table of "
              "`implementation/backlog/packs/A022-fish-icons.md` states the "
              "final species list and sizes this task settled"]),

    dict(id=180, phase=P12, title="The fishing minigame",
         slug="fishing-minigame", deps=[179, 121, 173],
         dresses=["A023", "A024"],
         files="src/core/fishing.gd, src/core/game_data.gd, "
               "src/ui/fishing_bar.gd (new), src/ui/main.gd, "
               "src/app/input_actions.gd, src/app/settings.gd, "
               "project.godot, src/ui/player_work.gd, src/ui/sfx.gd, "
               "src/tools/shot.gd, src/tools/headless_check.gd, "
               "src/tools/input_check.gd, src/tools/headless_v1.gd, "
               "src/tools/input_v1.gd",
         goal="A bite opens a simple timing bar: a marker runs, and you press "
              "as it crosses the green - simpler than Stardew's bar and as "
              "good on a pad as on a mouse.",
         req=["In core, after the bite the line enters a bar stage: the "
              "marker is a pure function of the ticks since the bite (a "
              "triangle sweep, speed per species); the zone's place comes "
              "from the cast's draw and its width from the species and the "
              "rod tier (`# LEVER`s in `FISH_SPECIES` and `TOOLS`, which "
              "`check_fishing` bounds). No RNG after the cast",
              "Presses are intents (the `interact` edge or a dedicated one), "
              "judged against the marker on the tick they are consumed; 1-3 "
              "hits by species land the fish; misses allowed and how long "
              "the bar runs are `# LEVER`s, and running out loses the fish "
              "and nothing else",
              "If the bar adds or retires a verb, `_task_0084_day_sounds` "
              "still passes: every `Interact.DAY_ONLY` verb keeps an "
              "`Sfx.VERB_SOUNDS` entry (borrow `sfx/reel` until 0282 gives "
              "the bar its sounds) and `water` stays the only instant verb. "
              "A new `X.tick(state)` call in `sim.gd` joins `PerfNames.DAY` "
              "and `perf_check.gd`",
              "Keyboard, mouse and pad write the same intent: a new action in "
              "`InputActions.ACTIONS` and `project.godot` with a pad binding, "
              "kept in sync by the existing check",
              "An assist (wider zone, slower marker) is a rule, so it lives "
              "in the state: a run flag written through an intent from a "
              "Settings key, never read by core from `Settings`. The Options "
              "row is 0292's",
              "The view draws the bar, marker, zone and hit/miss flash "
              "through the placeholder road until A023 is integrated by 0206, "
              "and the farmer on today's `fish`/`reel` strips until A024 is "
              "integrated by 0207",
              "Settle the art: the bar's piece sizes into A023, and the "
              "farmer's poses and timings (cast, wait, strike, reel loop, "
              "show the catch) into A024",
              "SIM moves on purpose; rewrite what is left of "
              "`_task_0030_fishing`/`_case_0030_fishing` that reels in one "
              "press"],
         dod=["`_task_0180_minigame` in `src/tools/headless_v1.gd`: a press "
              "on a tick inside the zone counts and one tick outside does "
              "not; a three-hit species needs three; the assist widens the "
              "zone; a replay with the same presses lands the same fish",
              "`_case_0180_minigame` in `src/tools/input_v1.gd`: land a fish "
              "with the keyboard, with the mouse and with a synthetic pad "
              "button",
              "A new `fishing_bar` scenario: `python tools/shot.py 0180 "
              "fishing_bar --fhd` shows the bar mid-catch; opened and looked "
              "at",
              "the Deliverables tables of "
              "`implementation/backlog/packs/A023-fishing-gear.md` and "
              "`A024-farmer-fishing.md` state the final geometry and poses "
              "this task settled"]),

    dict(id=181, phase=P12, title="Rods and bait", slug="rods-bait",
         deps=[179, 173, 167], dresses=["A023"],
         files="src/core/fishing.gd, src/core/farming.gd, "
               "src/core/game_data.gd, src/ui/day_hud.gd, src/ui/names.gd, "
               "src/ui/placeholder_art.gd, assets/locale/strings.csv, "
               "src/tools/headless_v1.gd, src/tools/input_v1.gd",
         goal="The rod's tiers change what bites: fibre brings bites sooner "
              "and rare fish more often, iron adds a bait slot and is the "
              "only rod a legendary takes.",
         req=["Rod effects read from `TOOLS` (`# LEVER`s): the fibre rod "
              "shortens the bite range and raises rare weights; the iron rod "
              "opens a bait slot and is the gate 0182 checks",
              "Worms: tilling (`Farming._till`) finds a `WORM` one time in "
              "`WORM_IN` (`# LEVER`, in `digest()`), drawn from the run RNG "
              "- SIM moves on purpose (the determinism scenario tills) and "
              "the journal records it",
              "A fish-scrap bait recipe (a `RECIPES` entry, so a "
              "`Names.KEYS` entry and a `REC_*` row): a common fish into "
              "several `BAIT` at the workshop or the kitchen - decide. Bait "
              "has a sale price like every resource since 0169, and the "
              "recipe passes `check_chain`",
              "With the iron rod, a held bait is spent at the cast and "
              "shortens the wait or raises rarity (`# LEVER`s); which bait is "
              "on is a choice the HUD shows; no bait means no effect, not a "
              "refusal",
              "`WORM` and `BAIT` with prices, a group, names and strings in "
              "both languages. Zombie bait is 0225's, not here",
              "Icons through the placeholder road until A023 is integrated "
              "by 0206"],
         dod=["`_task_0181_rods` in `src/tools/headless_v1.gd`: on a fixed "
              "seed the fibre rod's mean wait is shorter than bamboo's by "
              "what the levers say; bait is spent at an iron-rod cast and not "
              "at a bamboo one; tilling finds worms at the rate claimed",
              "`_case_0181_bait` in `src/tools/input_v1.gd`: choose a bait "
              "and cast with it"]),

    dict(id=182, phase=P12, title="Legendary fish and the fish book",
         slug="legendary-book", deps=[181], dresses=["A022", "A023"],
         files="src/core/fishing.gd, src/core/game_data.gd, "
               "src/core/stats.gd, src/core/state.gd, "
               "src/ui/fish_book.gd (new), src/ui/inventory_panel.gd, "
               "src/ui/names.gd, assets/locale/strings.csv, "
               "src/tools/shot.gd, src/tools/headless_v1.gd, "
               "src/tools/input_v1.gd",
         goal="Four legendary fish, one a season, each with its own "
              "conditions, and a fish book with a page per species - the "
              "first collection that makes a player come back.",
         req=["Four legendaries in `FISH_SPECIES` - the Old Catfish, the "
              "Golden Queen, the Ghost Pike and the Ice Sturgeon, one per "
              "season - each with a pond, hours and a condition "
              "(`# LEVER`s, bounded by `check_fishing`), catchable only on "
              "the iron rod and with the hardest bar of 0180",
              "Decide whether a legendary can be caught once per run; if so "
              "the draw skips it once the book has it",
              "The book: a `fish_book` dictionary in the state (keys come "
              "from play: `State.RUN_DATA`), species -> times caught and the "
              "first day; folded into the profile through `Stats` so it "
              "outlives the run",
              "A book view (an inventory tab or its own panel) with a page "
              "per species, unknown ones as silhouettes with a hint, and a "
              "collection count (n of every species, legendaries included); "
              "portraits through the placeholder "
              "road until A022's are integrated by 0205, the tab icon until "
              "A023's by 0206",
              "Names and strings for the legendaries and the book in both "
              "languages; every hint fits its control (`tools/i18n_check.py`)",
              "SIM moves (new draws, four new resources and the "
              "`fish_book` key); DATA moves"],
         dod=["`_task_0182_legendary` in `src/tools/headless_v1.gd`: the "
              "spring legendary never bites on the bamboo or fibre rod and "
              "does under its conditions on the iron rod; a catch writes the "
              "book and the profile",
              "`_case_0182_book` in `src/tools/input_v1.gd`: open the book and "
              "turn pages with the keyboard, the mouse and the pad",
              "A new `fish_book` scenario: `python tools/shot.py 0182 "
              "fish_book --fhd` shows a page and the count; opened and looked "
              "at"]),

    dict(id=183, phase=P12, title="The coop and the barn", slug="coop-barn",
         deps=[126, 156], dresses=["A030"],
         files="src/core/game_data.gd, src/core/livestock.gd, "
               "src/core/building.gd, src/core/interact.gd, "
               "src/core/state.gd, src/ui/world_view.gd, "
               "src/ui/transition.gd, src/ui/names.gd, "
               "src/ui/placeholder_art.gd, assets/locale/strings.csv, "
               "src/tools/shot.gd, src/tools/headless_check.gd, "
               "src/tools/input_check.gd, src/tools/headless_v1.gd, "
               "src/tools/input_v1.gd",
         goal="Animals get homes: a coop and a barn, built by day, that hold "
              "them, shelter them at night and - from 0184 - make them worth "
              "feeding (plan section 3.4).",
         req=["Coop and barn are `BUILDINGS` entries (hp, cost in wood, stone "
              "and money, `size`, an animal `capacity`, all `# LEVER`), built "
              "by day on 0156's `MAP_SITES` (room for up to 7x4) or anywhere "
              "buildable, with `Names.KEYS` entries and `BLD_*` rows in both "
              "languages. Decide the footprints and capacities here",
              "Animals live in their building: a record per building of who "
              "lives there (kind, produce waiting, ticks left), inside "
              "`livestock` or under a new key listed in `State.RUN_DATA`; "
              "`Livestock` produces for housed animals and the `collect` verb "
              "(already in `Sfx.VERB_SOUNDS`) moves from the animal to the "
              "building's door",
              "The map's cow and chickens move in: until a coop or barn "
              "exists they stand where `FARM_MAP` put them and behave as "
              "today; the first one built takes the loose animals of its "
              "kind in (removed as occupants, one `Farm.touch`). A save with "
              "loose animals keeps working",
              "`check_livestock` is reworked: every kind names the building "
              "it lives in, and the map or the stall (0190) is its source - "
              "'every animal stands on the map' stops being a rule",
              "Buying animals is 0190's; here the map or a test supplies them",
              "Housed animals stand by their building by day (view only; "
              "wandering is 0185's) and are hidden at night; the buildings "
              "draw as scaled station stand-ins at their footprint through "
              "the placeholder road until A030 is integrated by 0212",
              "Update the animal parts of `_task_0034_cooking` and "
              "`_case_0034_livestock` if they rely on loose animals. DATA "
              "moves; SIM moves if the state gains a key or a station, or "
              "the scenario builds one - say which"],
         dod=["`_task_0183_barns` in `src/tools/headless_v1.gd`: building a "
              "coop moves the map's chickens in and their produce still "
              "comes; a full coop refuses another chicken; a barn holds its "
              "capacity",
              "`_case_0183_barn` in `src/tools/input_v1.gd`: place a coop by "
              "day and collect at its door",
              "A new `coop_barn` scenario: `python tools/shot.py 0183 "
              "coop_barn --fhd` shows the coop and the "
              "barn with their animals by day; opened and looked at",
              "the Deliverables table of "
              "`implementation/backlog/packs/A030-coop-barn.md` states the "
              "footprints, capacities and door/window points this task "
              "settled"]),

    dict(id=184, phase=P12, title="Feeding, eggs and milk",
         slug="feeding-products", deps=[183, 168], dresses=["A029"],
         files="src/core/livestock.gd, src/core/farming.gd, "
               "src/core/phases.gd, src/core/game_data.gd, src/ui/names.gd, "
               "src/ui/placeholder_art.gd, assets/locale/strings.csv, "
               "src/tools/headless_v1.gd",
         goal="Animals are fed and give what they are kept for: chickens lay "
              "eggs, cows give milk, and both eat hay made from the wheat's "
              "straw - one more use for wheat.",
         req=["Harvesting wheat also gives `STRAW` (`# LEVER` per harvest); "
              "a recipe at a station you choose turns straw into `HAY`, the "
              "feed (both exist: the plan makes hay from straw, and straw is "
              "also 0224's decoy material). The peddler's hay outside autumn "
              "is 0193's",
              "A daily feed debit at `Phases.begin_day`: each housed animal "
              "eats `feed_per_day` hay (`# LEVER`); one not fed gives nothing "
              "that day, and never dies or sickens",
              "Products: chickens give `EGG`, cows give `MILK` "
              "(`LIVESTOCK.produces`, the rate and `holds` as `# LEVER`s)",
              "Decide what happens to `MEAT` and write it in the journal: "
              "keep the resource and `cook_roast`, and say how meat is still "
              "had (the stall stocks it, an animal gives it now and then...). "
              "`check_livestock`'s 'nothing produces meat' rule follows the "
              "decision. A saved animal's waiting produce is a count and "
              "comes out as the new product: say so (no version bump)",
              "`STRAW`, `HAY`, `EGG` and `MILK` with prices, groups, names "
              "and strings in both languages, and a `Names.KEYS` entry with a "
              "`REC_*` row for each new recipe; recipes that took meat "
              "adjusted so `check_chain` passes",
              "Icons through the placeholder road until A029 (0211) and, for "
              "hay and straw, A020 (0203) are integrated",
              "SIM moves (four new resources in `held`/`gained`, and the "
              "scenario's animals produce differently); DATA moves"],
         dod=["`_task_0184_feed` in `src/tools/headless_v1.gd`: a fed coop "
              "gives eggs the next day, an unfed one gives none and every "
              "chicken is still there; a wheat harvest gives the straw the "
              "lever says",
              "The journal states the meat decision and `check_livestock` "
              "enforces it (a rigged table without a meat source fails)"]),

    dict(id=185, phase=P12, title="Sheep, pigs and the dog",
         slug="sheep-pigs-dog", deps=[184],
         dresses=["A025", "A026", "A027", "A028"],
         files="src/core/livestock.gd, src/core/game_data.gd, "
               "src/core/interact.gd, src/core/phases.gd, src/core/state.gd, "
               "src/ui/animal_view.gd (new), src/ui/world_view.gd, "
               "src/ui/transition.gd, src/ui/sfx.gd, src/ui/names.gd, "
               "src/ui/placeholder_art.gd, assets/locale/strings.csv, "
               "src/tools/shot.gd, src/tools/headless_v1.gd, "
               "src/tools/input_v1.gd",
         goal="The barn fills out: sheep give wool, pigs dig truffles, and a "
              "dog follows the farmer by day - the farm feels alive between "
              "the chores.",
         req=["Sheep live in the barn, eat hay and give `WOOL` (`# LEVER`s)",
              "Pigs find truffles: each morning a housed pig marks dig spots "
              "on open grass near its barn (a `RUN_DATA` cell -> item record, "
              "deterministic - run RNG or a `(seed, day)` stream, decide; SIM "
              "moves); the farmer collects `TRUFFLE` by day with a verb in "
              "`Interact`; a spot never sits on a plot, a path or an occupied "
              "cell, and is gone at night. A new verb goes in `DAY_ONLY` and "
              "`all_verbs` with an `Sfx.VERB_SOUNDS` entry (borrow "
              "`sfx/collect` until 0281), or `_task_0084_day_sounds` fails",
              "The dog is a pet from day 1 that follows the farmer by day and "
              "sleeps by the porch at night. **View only**: no state key, no "
              "occupant, nothing in `src/core/`, so the hash cannot see it; "
              "petting it is a view-only gesture (a heart). Its night power "
              "is 0233's",
              "View-only wander, eat and sleep states for every animal (cow, "
              "chicken, sheep, pig, dog) near its building, in "
              "`src/ui/animal_view.gd`, never touching the state; at night "
              "`transition.gd`'s `DAY_ONLY` (today cow and chicken: add sheep "
              "and pig) hides them as it does today",
              "`WOOL` and `TRUFFLE` with prices, groups, names and strings in "
              "both languages; `check_livestock` covers sheep and pig. SIM "
              "moves on purpose (new resources, the dig-spot key); DATA moves",
              "Stand-ins through the placeholder road (tinted cow/chicken for "
              "sheep and pig, a small one for the dog, tinted icons and a "
              "code-drawn dig spot) until A026 (0209), A027 (0210), A028 "
              "(0245), the tend pose A025 (0208) and the icons and dig spot "
              "of A029 (0211) are integrated",
              "Settle the art: scales against the 32px farmer, states and "
              "frame counts into A025, A026 and A027"],
         dod=["`_task_0185_animals` in `src/tools/headless_v1.gd`: a sheep "
              "gives wool; a pig's dig spot can be collected and is never on "
              "a plot or a path; a text scan finds no dog in `src/core/`, so "
              "the hash cannot depend on it",
              "`_case_0185_truffle` in `src/tools/input_v1.gd`: walk to a dig "
              "spot and collect a truffle",
              "A new `barnyard` scenario: `python tools/shot.py 0185 "
              "barnyard --fhd` shows the barnyard with "
              "every animal and the dog following; opened and looked at",
              "the Deliverables tables of "
              "`implementation/backlog/packs/A025-farmer-care.md`, "
              "`A026-farm-animals.md` and `A027-cow-chicken.md` state the "
              "scales, states and frames this task settled"]),

    dict(id=186, phase=P12, title="Barns at night", slug="barns-at-night",
         deps=[183, 137], dresses=["A030"],
         files="src/core/farm.gd, src/core/livestock.gd, src/core/repair.gd, "
               "src/core/pathing.gd, src/core/run.gd, src/core/crafting.gd, "
               "src/core/interact.gd, src/core/game_data.gd, "
               "src/ui/world_view.gd, src/ui/placeholder_art.gd, "
               "src/tools/shot.gd, src/tools/headless_v1.gd",
         goal="At night the animals sleep inside and the barn becomes "
              "something to defend: breakers go for it, and a wrecked barn "
              "stands useless until it is mended. No animal ever dies.",
         req=["Animals sleep in their building at night (the view hides "
              "them; livestock already ticks only by day)",
              "Breakers hunt coops and barns: `Pathing.is_prey` counts a "
              "`BUILDINGS` entry with no `path_cost` already - assert it",
              "A wrecked-but-standing state: an entry that declares it "
              "(e.g. `wrecks: true` on coop and barn) is not removed by "
              "`Farm.damage` at 0 HP; it stays an occupant marked wrecked, "
              "still impassable, no longer prey (`Pathing.prey_cells` "
              "already skips 0 HP), with no rubble; decide whether "
              "`Run.lost_a_structure` counts it and assert that",
              "A wrecked building produces nothing and offers only `repair` "
              "(by day, by the farmer, as 0134 left it); any HP above 0 "
              "brings it back; its animals stay inside, alive, throughout",
              "`Crafting.forget_cell` and `Livestock`'s cache must not forget "
              "a wrecked building's residents or queue",
              "Hurt and wrecked looks are tints of the stand-in through the "
              "placeholder road until A030 is integrated by 0212",
              "DATA moves (the new flag); SIM moves only if the scenario "
              "has a barn at night - say so"],
         dod=["`_task_0186_barns_night` in `src/tools/headless_v1.gd`: "
              "breakers reach a barn and wreck it; it stands, produces "
              "nothing the next day, keeps every animal, and works again "
              "after a day repair",
              "A new `barn_night` scenario: `python tools/shot.py 0186 "
              "barn_night --fhd` shows a hurt and a "
              "wrecked barn at night and the next morning; opened and looked "
              "at"]),

    dict(id=187, phase=P12,
         title="Days in a barrel: the keg and the preserves jar",
         slug="keg-and-jar", deps=[184, 168, 149], dresses=["A031", "A032"],
         files="src/core/crafting.gd, src/core/game_data.gd, "
               "src/core/phases.gd, src/ui/workshop_panel.gd, "
               "src/ui/names.gd, src/ui/placeholder_art.gd, "
               "assets/locale/strings.csv, src/tools/headless_v1.gd, "
               "src/tools/input_v1.gd",
         goal="The first artisan machines: a keg and a preserves jar that "
              "turn fruit into wine, juice, jelly and pickles over days - the "
              "road for a player who wants to farm money (plan section 3.5).",
         req=["A per-day recipe credit: a `RECIPES` entry may say `days` "
              "(`# LEVER`) instead of `ticks`; `Crafting` credits such a job "
              "one day each morning (from `Phases.begin_day`), not per tick, "
              "and the panel shows days left (a new string in both "
              "languages: `WORK_MAKING` prints seconds). `check_recipes` "
              "accepts exactly one of `ticks` and `days`",
              "Keg and preserves jar are `BUILDINGS` entries built by day "
              "(size, hp, cost as `# LEVER`s; 0188 writes the final sizes "
              "into A031). The keg makes wine from grapes and juice from "
              "other fruit; the jar makes jelly from fruit and pickles from "
              "vegetables - choose which crops",
              "`WINE`, `JUICE`, `JELLY` and `PICKLES` with prices, an artisan "
              "group, names and strings in both languages; every recipe "
              "passes `check_chain` with a margin worth the days",
              "Decide whether breakers can hit the machines; if so they take "
              "0186's wrecked-but-standing state, and A031 gets wreck frames",
              "Machines and goods draw through the placeholder road until "
              "A031 (0213) and A032 (0214) are integrated",
              "`Names.KEYS` with `BLD_*`/`REC_*` rows for the machines and "
              "every recipe, both languages. DATA moves; SIM moves on "
              "purpose (four resources in `held`/`gained`, two stations in "
              "`selected_recipe`) - record both"],
         dod=["`_task_0187_keg` in `src/tools/headless_v1.gd`: grapes in a "
              "keg are wine after the recipe's mornings and not one before; "
              "a day spent elsewhere still counts; every new recipe has a "
              "positive chain margin",
              "`_case_0187_keg` in `src/tools/input_v1.gd`: queue wine at a "
              "keg from its panel"]),

    dict(id=188, phase=P12, title="The dairy, the loom and the mill",
         slug="dairy-loom-mill", deps=[187, 185], dresses=["A031", "A032"],
         files="src/core/game_data.gd, src/ui/names.gd, "
               "src/ui/placeholder_art.gd, assets/locale/strings.csv, "
               "src/tools/shot.gd, src/tools/headless_v1.gd",
         goal="The dairy, the loom and the mill: milk into cheese and butter, "
              "wool into cloth and sandbags, wheat into flour and beet into "
              "sugar.",
         req=["Dairy, loom and mill as `BUILDINGS` built by day; recipes "
              "(`ticks` or `days`, `# LEVER`s): cheese and butter from milk; "
              "cloth from wool and sandbags from cloth plus a filler you "
              "choose; flour from wheat and sugar from beet",
              "`CHEESE`, `BUTTER`, `CLOTH`, `SANDBAG`, `FLOUR` and `SUGAR` "
              "with prices, groups, names and strings in both languages, "
              "and `BLD_*`/`REC_*` rows for the machines and every recipe; "
              "every value passes `check_chain`. If 0187's jelly should take "
              "sugar, add it now",
              "Sandbags are a material here: their night use is 0231's. "
              "Bread is 0192's (the kitchen, from flour)",
              "Settle the art: the five machines' footprints, states (idle, "
              "active, hurt, and wreck if 0187 said so) and light/smoke "
              "points into A031; the eleven goods into A032 (bread included)",
              "Stand-ins through the placeholder road until A031 (0213) and "
              "A032 (0214) are integrated",
              "DATA moves; SIM moves on purpose (six resources in "
              "`held`/`gained`, three stations in `selected_recipe`) - "
              "record both"],
         dod=["`_task_0188_mills` in `src/tools/headless_v1.gd`: every new "
              "recipe runs and `check_chain` holds for each",
              "A new `machines` scenario: `python tools/shot.py 0188 "
              "machines --fhd` shows the five machines "
              "idle and working; opened and looked at",
              "the Deliverables tables of "
              "`implementation/backlog/packs/A031-machines.md` and "
              "`A032-artisan-goods.md` state the final geometry and item "
              "list this task settled"]),

    dict(id=189, phase=P12, title="The shipping bin", slug="shipping-bin",
         deps=[148, 138, 156], dresses=["A033"],
         files="src/core/shipping.gd (new), src/core/interact.gd, "
               "src/core/phases.gd, src/core/state.gd, src/core/farm.gd, "
               "src/core/game_data.gd, src/app/save.gd, src/ui/shop_panel.gd, "
               "src/ui/result_screen.gd, src/ui/sfx.gd, src/ui/names.gd, "
               "src/ui/placeholder_art.gd, assets/locale/strings.csv, "
               "src/tools/make_goldens.gd, tools/goldens/, src/tools/shot.gd, "
               "src/tools/headless_v1.gd, src/tools/input_v1.gd",
         goal="A shipping bin like Stardew's: drop things in at any hour of "
              "the day and be paid the next morning, so selling no longer "
              "waits on the stall's hours (plan section 3.6).",
         req=["The bin is an occupant with a `ship` verb in "
              "`Interact.OCCUPANT_VERBS` (and `DAY_ONLY`, `all_verbs`, and "
              "an `Sfx.VERB_SOUNDS` entry - borrow `sfx/sell` until 0281 - "
              "or `_task_0084_day_sounds` fails), on the bin site 0156 kept "
              "clear by the porch (`MAP_SITES`)",
              "Fixture or building - decide and say why. A fixture "
              "(`Farm.FIXTURES`, never sold or wrecked) laid by `FARM_MAP` "
              "reaches new farms only: old saves need a `State.VERSION` bump "
              "with a step that places it on the site when that cell is "
              "empty, in the style of 0156's, and a golden at the new "
              "version. A cheap day building needs no bump",
              "What waits is a `shipping` dictionary in the state (resource "
              "-> count; keys come from play: `State.RUN_DATA`); putting a "
              "stack in takes it out of `held` at once",
              "The morning report (0138's, shown in RESULT before "
              "`begin_day`) prints what the bin will pay, worked out with "
              "`Shop.paid_for` (the sell price and the `sell_percent` "
              "bonus) from what waits; the money lands at `Phases.begin_day` "
              "and the bin empties. The line and the ledger agree, asserted",
              "A panel to choose what goes in, reusing the stall's sell rows "
              "(`shop_panel.gd`); decide whether it stops the clock like the "
              "stall (`open_panel`) and say why; keyboard, mouse and pad",
              "Decide what a lost night does to the bin (the horde takes 25% "
              "of the stock): what is in the bin is sold, not stock, or it "
              "is taken - write it down and assert it",
              "Names and strings in both languages; the bin draws through "
              "the placeholder road until A033 is integrated by 0215",
              "DATA moves; SIM moves on purpose (the `shipping` key, and the "
              "bin if it is on the map) - record both"],
         dod=["`_task_0189_bin` in `src/tools/headless_v1.gd`: ten carrots "
              "shipped by day leave `held` at once and are paid the next "
              "morning at the sell price with the tech bonus; the report "
              "line names the total",
              "`_case_0189_bin` in `src/tools/input_v1.gd`: open the bin, put "
              "one stack in with the keyboard and one with the mouse, close it",
              "A new `shipping_bin` scenario: `python tools/shot.py 0189 "
              "shipping_bin --fhd` shows the bin and the "
              "morning line; opened and looked at",
              "the Deliverables table of "
              "`implementation/backlog/packs/A033-shipping-bin.md` states the "
              "final geometry this task settled"]),

    dict(id=190, phase=P12, title="The peddler and his hours", slug="peddler",
         deps=[126, 170, 183, 185, 173], dresses=["A034"],
         files="src/core/shop.gd, src/core/interact.gd, "
               "src/core/game_data.gd, src/core/livestock.gd, "
               "src/ui/shop_panel.gd, src/ui/world_view.gd, src/ui/names.gd, "
               "src/ui/placeholder_art.gd, assets/locale/strings.csv, "
               "src/tools/headless_check.gd, src/tools/input_check.gd, "
               "src/tools/autoplay.gd, src/tools/determinism.gd, "
               "src/tools/shot.gd, src/tools/headless_v1.gd, "
               "src/tools/input_v1.gd",
         goal="The stall gets a peddler who keeps hours, 08:00 to 17:00, and "
              "sells what the farm cannot make for itself: animals and tool "
              "upgrades.",
         req=["`trade` is offered only from `STALL_OPENS` to `STALL_CLOSES` "
              "(`# LEVER`s in game minutes, 08:00 and 17:00, read through "
              "0126's `Phases.clock_minute`; in `digest()`); outside them the "
              "stall shows a closed state and the verb is refused with a "
              "reason in both languages. Gate the verb, not "
              "`Shop.buy`/`sell`: an open panel stops the clock, so the "
              "stall never closes under the player",
              "Stock beyond 0170's seeds: chickens, cows, sheep and pigs, "
              "delivered into a coop or barn with room (refused, money kept, "
              "without one), and 0173's tool upgrades at the same money + "
              "ore price through the same order path, so the rule exists "
              "once. Neither is a resource: `Shop.buy`, the stall's stock "
              "and `check_stall` (resources only today) get a branch",
              "The stock is seasonal through 0170's table; `Shop.buyable` and "
              "`restock` read it; `check_stall` covers animals (a price, no "
              "buy-and-sell-back profit) in every season. The four animals "
              "get `Names.KEYS` entries and `ANIMAL_*` rows in both languages "
              "(the stall lists them by name)",
              "Move what trades through the verb before 08:00 to opening "
              "hours: `_task_0020_shop`, `_task_0040_shop`, "
              "`_case_0020_shop`, `_case_0040_shop`, the autoplayer - grep "
              "the suites and `shot.gd` for `trade` and `Shop.open`. The "
              "determinism scenario calls `Shop.open` at `day_tick` 1500, "
              "before 08:00 on 0166's clock: leave `Shop.open` ungated or "
              "accept the SIM move, and say which",
              "The peddler stands at the stall in open hours, walking in and "
              "out at the edges (view only), through the placeholder road; "
              "the closed stall is a dimmed stand-in until A034 is "
              "integrated by 0216",
              "DATA moves; SIM moves on purpose (the stall's stock in the "
              "state gains animals and upgrades) - record both"],
         dod=["`_task_0190_peddler` in `src/tools/headless_v1.gd`: trade is "
              "refused at 07:59 and at 17:00 and offered at 08:00; a cow "
              "bought with a barn arrives in it, and without one is refused "
              "with the money kept",
              "`_case_0190_peddler` in `src/tools/input_v1.gd`: buy a chicken "
              "in hours; the closed stall refuses",
              "A new `peddler` scenario: `python tools/shot.py 0190 "
              "peddler --fhd` shows the stall open "
              "with the peddler and closed at dusk; opened and looked at",
              "the Deliverables table of "
              "`implementation/backlog/packs/A034-peddler.md` states the "
              "final geometry and states this task settled"]),

    dict(id=191, phase=P12, title="The house in three tiers",
         slug="house-tiers", deps=[148, 114], dresses=["A035"],
         files="src/core/phases.gd, src/core/house.gd, src/core/repair.gd, "
               "src/core/interact.gd, src/core/game_data.gd, "
               "src/ui/house_view.gd, src/ui/world_view.gd, src/ui/sfx.gd, "
               "src/ui/placeholder_art.gd, assets/locale/strings.csv, "
               "src/tools/shot.gd, src/tools/headless_v1.gd, "
               "src/tools/input_v1.gd",
         goal="Money buys a stronger house - tiers I, II and III, each more "
              "hit points and cheaper repairs - because the house is what "
              "keeps the sleeping farmer safe (plan section 3.8).",
         req=["`HOUSE_TIERS` (`# LEVER`s): a price in money (and materials if "
              "wanted), an `hp_bonus` and a repair discount per tier, bought "
              "by day; tier I is the house a new game has. `validate()` "
              "checks it (bonuses never fall from one tier to the next, the "
              "discount within 0-100) and it goes into `digest()`",
              "The tier is a top-level `house_tier` int: reconcile fills it "
              "for old saves (no version bump), but the state hash folds it. "
              "`Phases.house_full` adds the tier's HP, so every reader 0114 "
              "routed through it follows; the house repair in `Repair` "
              "applies the discount and composes with what 0113 decided for "
              "'a full larder' on the house",
              "**There is no storage limit today** and section 3.8's "
              "'more room to keep things' is not invented here; say so in "
              "the journal",
              "Pick one input path for buying (the house's door, the stall, "
              "or a tab in the workshop panel) and test it; the new tier "
              "holds from the next night. A new verb goes in `DAY_ONLY` and "
              "`all_verbs` with an `Sfx.VERB_SOUNDS` entry (borrow "
              "`sfx/trade` until 0281), or `_task_0084_day_sounds` fails",
              "Same 6x4 footprint and pivot; tiers II and III draw as today's "
              "house with a code-drawn mark through the placeholder road "
              "until A035 is integrated by 0217",
              "DATA moves; SIM moves on purpose (the `house_tier` key) - "
              "record both"],
         dod=["`_task_0191_house` in `src/tools/headless_v1.gd`: tier II "
              "raises `house_full` by its bonus with and without 'stout "
              "timbers'; a house repair costs the discounted price; the "
              "untouched-house bonus (0114) reads the new full",
              "`_case_0191_house` in `src/tools/input_v1.gd`: buy tier II by "
              "day",
              "A new `house_tiers` scenario: `python tools/shot.py 0191 "
              "house_tiers --fhd` shows tiers I to III; "
              "opened and looked at",
              "the Deliverables table of "
              "`implementation/backlog/packs/A035-house-tiers.md` states the "
              "final geometry this task settled"]),

    dict(id=192, phase=P12, title="Cooking with the new harvest",
         slug="cooking-v2", deps=[188, 184],
         files="src/core/game_data.gd, src/ui/names.gd, "
               "src/ui/placeholder_art.gd, assets/locale/strings.csv, "
               "src/tools/headless_v1.gd",
         goal="The kitchen cooks the new harvest - potato, egg, milk and "
              "bread - into the food that mends the house at night, and "
              "spring gets a meal without wheat.",
         req=["Kitchen recipes with potato, egg, milk and flour, and `BREAD` "
              "baked from flour (price, group, names and strings in both "
              "languages; a tinted icon until A032 is integrated by 0214), "
              "each recipe with a `Names.KEYS` entry and a `REC_*` row; the "
              "better recipes give `FOOD` in bigger batches (`# LEVER`s)",
              "A spring meal without wheat: potato and carrot into food, so "
              "the house can be mended in spring - today `cook_meal` needs "
              "wheat, an autumn crop",
              "Every recipe passes `check_chain`: cooked is always worth more "
              "than its inputs",
              "Keep the ids `cook_meal`, `cook_fish` and `cook_roast` (tests "
              "and saves name them) unless the journal says why one goes",
              "DATA moves; SIM moves on purpose (`BREAD` in `held`/`gained`, "
              "and the kitchen's default selection if a new recipe sorts "
              "first) - record both"],
         dod=["`_task_0192_kitchen` in `src/tools/headless_v1.gd`: from "
              "spring stock alone (carrot, potato, fish) the kitchen makes "
              "food; bread needs flour; every kitchen recipe has a positive "
              "chain margin",
              "The journal lists every kitchen recipe with its margin"]),

    dict(id=193, phase=P12, title="Every season can make what it needs",
         slug="seasonal-supply", deps=[170, 176, 188, 190, 192],
         files="src/core/game_data.gd, src/core/shop.gd, src/ui/names.gd, "
               "assets/locale/strings.csv, src/tools/headless_v1.gd",
         goal="No defence, round, repair meal or feed may depend on a crop "
              "whose season has not come yet: every season can make what it "
              "needs.",
         req=["`check_seasonal_supply()` in `GameData.validate()`: for each "
              "season S, everything unlocked in S - defence kits, "
              "ammunition, repair food, animal feed - is makeable from the "
              "crops of seasons up to S plus fish, ore, wood, stone and what "
              "the stall sells in S; it walks the recipe graph, and a test "
              "shows it a broken table",
              "What 'unlocked in S' means: a `season` field on `DEFENCES` "
              "entries, default spring. Plan section 5 puts the flamethrower "
              "in summer and the mortar in autumn, but moving them is 0234's "
              "(with the new defences), so today's eight stay spring here",
              "Fix the known breaks: gunpowder in spring (a recipe from coal "
              "and oil pressed from fish by `press_fish_oil`, since corn is "
              "summer), a meal in spring (0192's, checked here), straw and "
              "hay sold by the peddler before autumn",
              "Pepper and sunflower get their plan roles: pepper makes "
              "incendiary rounds at a better yield than wood (a recipe, not "
              "a new ammunition rule), and sunflower is pressed into oil",
              "Every new recipe passes `check_chain` and `check_ammo` and has "
              "a `Names.KEYS` entry and a `REC_*` row in both languages",
              "DATA moves; SIM moves if the stall's stock or a station's "
              "default recipe (both in the state) changes - say which"],
         dod=["`_task_0193_supply` in `src/tools/headless_v1.gd`: the real "
              "tables pass for all four seasons; taking out the coal "
              "gunpowder recipe makes spring fail by name",
              "The journal lists, season by season, the route to each kit, "
              "round, meal and feed"]),

    dict(id=194, phase=P12, title="The day's economy", slug="day-economy",
         deps=[193, 189, 171, 172, 174, 177, 178, 180, 182, 186, 191],
         files="src/core/game_data.gd, tools/balance.py, "
               "src/tools/autoplay.gd, implementation/BALANCE.md, "
               "src/tools/headless_v1.gd",
         goal="The day's money is tuned on purpose: a price for every item, "
              "and targets per season so that a good day buys about one new "
              "defence (plan section 5's rule of thumb).",
         req=["One reviewed price table for every item: `SELL_PRICE`, seed "
              "and animal prices, upgrade and building costs; `check_stall` "
              "and `check_chain` pass",
              "Money-per-day targets by season, as `# LEVER`s or a table the "
              "check reads: a well-worked day at the start of each season "
              "buys about one new defence",
              "`tools/balance.py` gains sweeps of day strategies - crops, "
              "fishing, mining, animals, artisan goods - over a spring and a "
              "summer day, headless and outside the suite; it still refuses "
              "a dirty tree and restores `game_data.gd`",
              "A BALANCE.md section with money per strategy per season "
              "against the target, and every lever moved",
              "No single strategy wins every season: the day has several "
              "ways to earn, which is what 0196 asks",
              "DATA moves on purpose (the target table goes into "
              "`digest()`); SIM moves if a price or a stock the determinism "
              "scenario meets changes - record both"],
         dod=["`_task_0194_economy` in `src/tools/headless_v1.gd`: a computed "
              "(not simulated) day of each strategy lands inside its "
              "season's target band",
              "A `tools/balance.py` run writes the BALANCE.md section, and "
              "the journal quotes its numbers"]),

    dict(id=195, phase=P12, title="Teaching the new day", slug="day-tutorial",
         deps=[194],
         files="src/core/game_data.gd, src/ui/tips.gd (new, e.g.), "
               "src/ui/tutorial_prompt.gd, src/ui/main.gd, src/app/save.gd, "
               "assets/locale/strings.csv, src/tools/shot.gd, "
               "src/tools/headless_v1.gd, src/tools/input_v1.gd",
         goal="The new day explains itself once: tilling grass, the seasons, "
              "the shipping bin, the fishing bar and the animals each get one "
              "tip, at the moment they first matter.",
         req=["Tips, not day-one lines: `MAX_TUTORIAL_LINES` still caps the "
              "first day. A tip fires from the state (the first stand on "
              "open grass with the hoe, the first morning of a new season, "
              "the first stand by the bin, the first bite, the first animal "
              "bought) and is remembered in the profile so it never shows "
              "twice",
              "Tips live in the view: `src/ui/` reads the state for the "
              "trigger and the profile (`Save.read_profile`/`write_profile`) "
              "for what was shown, through a pure `due(state, profile)` the "
              "headless group can call. `src/core/` never learns of them, so "
              "SIM must not move; they never gate or pause anything",
              "`check_tutorial` (or a new check) covers the tip table in "
              "`game_data.gd`: unique, short, naming a string key that "
              "exists. List it in `digest()` (DATA moves) or exempt it in "
              "`_task_0112_digest` as view text - say which",
              "Strings in both languages, each fitting its control "
              "(`tools/i18n_check.py`); a tip sits on the thing it describes "
              "(`tutorial_prompt.gd`)",
              "The guided Spring 1-7 is 0293's, not here"],
         dod=["`_task_0195_tips` in `src/tools/headless_v1.gd`: each tip fires "
              "once on its trigger and never again with the profile flag set",
              "`_case_0195_tips` in `src/tools/input_v1.gd`: a tip appears on "
              "the first bite and is dismissed",
              "A new `tips` scenario: `python tools/shot.py 0195 "
              "tips --fhd` shows two tips in place; "
              "opened and looked at"]),

    dict(id=196, phase=P12, title="Checkpoint: is the day good on its own?",
         slug="checkpoint-day", deps=[194, 195],
         files="implementation/PROGRESS.md, implementation/shots/0196/, "
               "src/tools/autoplay.gd, implementation/prompts/",
         goal="**The plan's Phase 3 checkpoint.** A spring day and a summer "
              "day earn money in different ways, and the day is fun even "
              "without thinking about the night. Phase 13 and everything "
              "after it waits on this answer.",
         req=["Play a spring day and a summer day in the real game, and run "
              "the autoplayer through the same days; compare where the money "
              "came from",
              "FHD captures of both days at morning, noon and dusk in "
              "`implementation/shots/0196/`, opened and looked at",
              "Answer honestly in the journal: is the day fun even without "
              "thinking about the night? What drags, what is busywork, what "
              "is missing",
              "If the answer changes the plan, edit the later prompts (0197 "
              "on) before they run, and say which",
              "If the answer is no, mark this task blocked with the reason, "
              "so phase 13 does not start on a day that does not work",
              "Change no rule here: fixes go into later prompts or new tasks"],
         dod=["The journal says, with numbers, how a spring day and a summer "
              "day each made their money - and that they differ",
              "The journal answers the question in one paragraph a reader "
              "could disagree with",
              "The captures are in `implementation/shots/0196/` and the "
              "journal says what each one shows"]),

    # ------------------------------------------------ art integration leaves
    dict(id=197, phase=P12, title="Art: trampled crops and tilled ground",
         slug="art-crop-ground", deps=[167, 155, 171], art=["A014"],
         files="assets/art_source/crops/, assets/art_source/manifest.json, "
               "tools/check_crop_art.py, src/ui/world_view.gd",
         goal="The trampled crop of 0155, the withered crop of 0171 and the "
              "tilled-grass edges of 0167 get their approved art in place of "
              "their stand-ins.",
         req=[_gate("A014"), _handoff("A014"),
              _promote("crops", "`tools/check_crop_art.py`, which checks "
                       "`tilled`/`tilled_wet` today"),
              "Runtime names: the trampled and withered crops (16x16, pivot "
              "(8,14)) and the edge pieces under the mask names 0167 wrote "
              "into the pack's table; ground pieces keep the soil "
              "conventions (pivot (8,16), wet at least 20 RGB darker)",
              "Replace the stand-ins in `world_view.gd`'s plot drawing left "
              "by 0155, 0167 and 0171, and flip A014's placeholder-registry "
              "entries to raster so 0120's check stops listing it",
              _integrated("A014")],
         dod=_art_dod("`python tools/check_crop_art.py` and `python "
                      "tools/show_art.py --crops --check`", 197)),

    dict(id=198, phase=P12, title="Art: spring crops", slug="art-spring-crops",
         deps=[170, 172], art=["A015"],
         files="assets/art_source/crops/, assets/art_source/ui/, "
               "assets/art_source/manifest.json, tools/check_crop_art.py, "
               "tools/check_ui_art.py",
         goal="Potato, garlic and strawberry, and the spring seed packets, "
              "get their approved art in place of 0168's tinted stand-ins.",
         req=[_gate("A015"), _handoff("A015"),
              _promote("crops` and `assets/art_source/ui",
                       "`check_crop_art.KINDS`; `tools/check_ui_art.py`, "
                       "which counts only task 0018's icons today - give it "
                       "the new family rather than breaking that count"),
              "Runtime names: `<crop>_0..3` for potato, garlic and "
              "strawberry (16x16, pivot (8,14)), strawberry's regrowing "
              "stage under the name 0172 draws, and `ui/icon_<id>` (16x16) "
              "with `ui/hud_<id>` (10x10) cut from one source for the "
              "produce and the carrot, potato, garlic and strawberry seed "
              "packets (ids from 0170)",
              "Replace the stand-ins of 0168, 0170 and 0172 and flip A015's "
              "placeholder-registry entries to raster",
              _integrated("A015")],
         dod=_art_dod("`python tools/check_crop_art.py`, `python "
                      "tools/check_ui_art.py`, `python tools/show_art.py "
                      "--crops --check` and `--ui --check`", 198)),

    dict(id=199, phase=P12, title="Art: summer crops", slug="art-summer-crops",
         deps=[170, 172], art=["A016"],
         files="assets/art_source/crops/, assets/art_source/ui/, "
               "assets/art_source/manifest.json, tools/check_crop_art.py, "
               "tools/check_ui_art.py",
         goal="Pepper, sunflower and melon, corn's regrowing stage and the "
              "summer seed packets get their approved art.",
         req=[_gate("A016"), _handoff("A016"),
              _promote("crops` and `assets/art_source/ui",
                       "`check_crop_art.KINDS`, `tools/check_ui_art.py`"),
              "Runtime names: `<crop>_0..3` for pepper and melon (16x16, "
              "pivot (8,14)) and the tall sunflower at the canvas and pivot "
              "0168 settled, pepper's and corn's regrowing stages, icons "
              "(16x16 + 10x10 from one source) for the produce and the corn, "
              "pepper, sunflower and melon seed packets",
              "Replace the stand-ins of 0168, 0170 and 0172 and flip A016's "
              "placeholder-registry entries to raster",
              _integrated("A016")],
         dod=_art_dod("`python tools/check_crop_art.py`, `python "
                      "tools/check_ui_art.py`, `python tools/show_art.py "
                      "--crops --check` and `--ui --check`", 199)),

    dict(id=200, phase=P12, title="Art: autumn crops", slug="art-autumn-crops",
         deps=[170, 172], art=["A017"],
         files="assets/art_source/crops/, assets/art_source/ui/, "
               "assets/art_source/manifest.json, tools/check_crop_art.py, "
               "tools/check_ui_art.py",
         goal="Pumpkin, the grape on its trellis and beet, and the autumn "
              "seed packets, get their approved art.",
         req=[_gate("A017"), _handoff("A017"),
              _promote("crops` and `assets/art_source/ui",
                       "`check_crop_art.KINDS`, `tools/check_ui_art.py`"),
              "Runtime names: `<crop>_0..3` for pumpkin and beet (16x16, "
              "pivot (8,14)) and the tall grape trellis at the canvas and "
              "pivot 0168 settled with its regrowing stage, icons (16x16 + "
              "10x10 from one source) for the produce and the wheat, "
              "pumpkin, grape and beet seed packets",
              "Replace the stand-ins of 0168, 0170 and 0172 and flip A017's "
              "placeholder-registry entries to raster",
              _integrated("A017")],
         dod=_art_dod("`python tools/check_crop_art.py`, `python "
                      "tools/check_ui_art.py`, `python tools/show_art.py "
                      "--crops --check` and `--ui --check`", 200)),

    dict(id=201, phase=P12, title="Art: sprinklers", slug="art-sprinklers",
         deps=[178], art=["A018"],
         files="assets/art_source/props/, assets/art_source/ui/, "
               "assets/art_source/manifest.json, tools/check_prop_art.py, "
               "tools/check_ui_art.py",
         goal="The copper, iron and gold sprinklers of 0178 get their "
              "approved bodies and icons; the spray stays code particles.",
         req=[_gate("A018"), _handoff("A018"),
              _promote("props` and `assets/art_source/ui",
                       "`check_prop_art.NAMES`, `tools/check_ui_art.py`"),
              "Runtime names for each tier's idle and spray-body frames at "
              "the 16x16 canvas and pivot 0178 settled, and an icon (16x16 + "
              "10x10) per tier for the build list",
              "Replace 0178's stand-ins and flip A018's placeholder-registry "
              "entries to raster; the particle spray is unchanged",
              _integrated("A018")],
         dod=_art_dod("`python tools/check_prop_art.py`, `python "
                      "tools/check_ui_art.py`, `python tools/show_art.py "
                      "--props --check` and `--ui --check`", 201)),

    dict(id=202, phase=P12, title="Art: tool icons", slug="art-tool-icons",
         deps=[173, 176, 190], art=["A019"],
         files="assets/art_source/ui/, assets/art_source/manifest.json, "
               "tools/check_ui_art.py, src/ui/workshop_panel.gd",
         goal="Fifteen tool icons - four tools in three tiers and the three "
              "rods - replace 0173's stand-ins wherever a tool is shown.",
         req=[_gate("A019"), _handoff("A019"),
              _promote("ui", "`tools/check_ui_art.py`, which counts only task "
                       "0018's icons today - give it the new family"),
              "Runtime names `ui/icon_<tool>_<tier>` (16x16, pivot (8,8)) and "
              "`ui/hud_<tool>_<tier>` (10x10, pivot (5,5)) cut from one "
              "source, for hoe, can, axe and pickaxe at basic/iron/gold and "
              "the rod at bamboo/fibre/iron, as 0173 named the tiers",
              "Replace the stand-ins in the workshop panel, the inventory and "
              "the stall (0190) and flip A019's placeholder-registry entries "
              "to raster. The tool in the farmer's hand stays code-tinted",
              _integrated("A019")],
         dod=_art_dod("`python tools/check_ui_art.py` and `python "
                      "tools/show_art.py --ui --check`", 202)),

    dict(id=203, phase=P12, title="Art: material icons",
         slug="art-material-icons", deps=[176, 177, 184], art=["A020"],
         files="assets/art_source/ui/, assets/art_source/manifest.json, "
               "tools/check_ui_art.py",
         goal="Copper, coal, gold, hardwood, hay and straw get their approved "
              "icons in the inventory, the HUD and the panels.",
         req=[_gate("A020"), _handoff("A020"),
              _promote("ui", "`tools/check_ui_art.py`"),
              "Runtime names `ui/icon_<id>` (16x16) and `ui/hud_<id>` "
              "(10x10) cut from one source, for the ids 0176, 0177 and 0184 "
              "gave copper, coal, gold, hardwood, hay and straw",
              "Replace their stand-ins and flip A020's placeholder-registry "
              "entries to raster",
              _integrated("A020")],
         dod=_art_dod("`python tools/check_ui_art.py` and `python "
                      "tools/show_art.py --ui --check`", 203)),

    dict(id=204, phase=P12, title="Art: copper, coal, gold and hardwood",
         slug="art-ore-hardwood", deps=[176, 177], art=["A021"],
         files="assets/art_source/props/, assets/art_source/manifest.json, "
               "tools/check_prop_art.py, src/ui/world_view.gd, "
               "src/ui/art_placement.gd",
         goal="The new quarry nodes and the big hardwood stumps get their "
              "approved art in the world.",
         req=[_gate("A021"), _handoff("A021"),
              _promote("props", "`check_prop_art.NAMES`; `ArtPlacement` if "
                       "the 2x2 stump needs it"),
              "Runtime names: copper, coal and gold nodes at 16x16, pivot "
              "(8,14), each with a `_b` variant through "
              "`WorldView.PROP_VARIANTS`/`_prop_variant` like `ore`/`ore_b`; "
              "the 2x2 stump whole and chipped at the 32x32 "
              "canvas and pivot 0177 settled, placed at the bottom centre of "
              "its footprint",
              "Replace the stand-ins of 0176 and 0177 and flip A021's "
              "placeholder-registry entries to raster",
              _integrated("A021")],
         dod=_art_dod("`python tools/check_prop_art.py` and `python "
                      "tools/show_art.py --props --check`", 204)),

    dict(id=205, phase=P12, title="Art: fish", slug="art-fish-icons",
         deps=[182], art=["A022"],
         files="assets/art_source/ui/, assets/art_source/manifest.json, "
               "tools/check_ui_art.py, src/ui/fish_book.gd",
         goal="Every species and the four legendaries get their icons and "
              "fish-book portraits.",
         req=[_gate("A022"), _handoff("A022"),
              _promote("ui", "`tools/check_ui_art.py`, plus the 32x32 "
                       "portraits as a family of their own"),
              "Runtime names: `ui/icon_<species>` (16x16) and "
              "`ui/hud_<species>` (10x10) from one source per species, for "
              "the list 0179 and 0182 settled, and a 32x32 book portrait "
              "each",
              "Replace the stand-ins in the inventory, the catch line and the "
              "fish book, and flip A022's placeholder-registry entries to "
              "raster",
              _integrated("A022")],
         dod=_art_dod("`python tools/check_ui_art.py` and `python "
                      "tools/show_art.py --ui --check`", 205)),

    dict(id=206, phase=P12, title="Art: fishing gear and the minigame",
         slug="art-fishing-gear", deps=[180, 181, 182], art=["A023"],
         files="assets/art_source/ui/, assets/art_source/effects/, "
               "assets/art_source/manifest.json, tools/check_ui_art.py, "
               "src/ui/fishing_bar.gd",
         goal="The bobber, the bait icons, the pieces of the fishing bar and "
              "the fish-book tab get their approved art.",
         req=[_gate("A023"), _handoff("A023"),
              _promote("ui` and `assets/art_source/effects",
                       "`tools/check_ui_art.py`; `tools/check_effect_art.py` "
                       "if the bobber goes in as an effect"),
              "Runtime names: the 8x8 bobber (float and the 2-3 frame bite "
              "dip) replacing the float the view draws today; worm and bait "
              "icons (16x16 + 10x10); the bar's frame, marker, sweet zone and "
              "hit/miss flash at the sizes 0180 settled; the book tab icon "
              "(0182)",
              "Replace the stand-ins of 0180, 0181 and 0182 and flip A023's "
              "placeholder-registry entries to raster",
              _integrated("A023")],
         dod=_art_dod("`python tools/check_ui_art.py` and `python "
                      "tools/show_art.py --ui --check`", 206)),

    dict(id=207, phase=P12, title="Art: the farmer fishing",
         slug="art-farmer-fishing", deps=[180], art=["A024"],
         files="assets/art_source/player-fhd/, "
               "assets/art_source/manifest.json, src/ui/player_work.gd, "
               "src/ui/player_frames.gd",
         goal="The farmer casts, waits, strikes, reels and shows the catch "
              "at the 32px detail, replacing the legacy fish and reel strips "
              "(0180's poses).",
         req=[_gate("A024"), _handoff("A024"),
              _promote("player-fhd", "the work-verb list `player_work.gd` "
                       "and the showcase read"),
              "Runtime names and timings: cast, wait, strike, reel (loop) and "
              "show the catch (2) for S, N and W, with E mirrored at runtime "
              "(not baked), on the art contract's work canvas (48x48, pivot "
              "(24,44), draw scale 0.5); if a farmer work leaf (0123-0125) "
              "has landed, reuse its `PlayerArt.pose` work-strip path; the "
              "poses follow 0180's bar stages",
              "Retire the legacy 48x48 `fish`/`reel` strips from the manifest "
              "and `ownership.json` once nothing reads them, and flip A024's "
              "placeholder-registry entries to raster",
              _integrated("A024")],
         dod=_art_dod("`python tools/show_art.py --work --check`", 207)),

    dict(id=208, phase=P12, title="Art: the farmer tending animals",
         slug="art-farmer-care", deps=[184, 185], art=["A025"],
         files="assets/art_source/player-fhd/, "
               "assets/art_source/manifest.json, src/ui/player_work.gd",
         goal="The farmer milks, shears and feeds with a proper pose, and "
              "pets the dog, at the 32px detail.",
         req=[_gate("A025"), _handoff("A025"),
              _promote("player-fhd", "the work-verb list `player_work.gd` "
                       "and the showcase read"),
              "Runtime names: a tend-animal pose (4 frames) for S, N and W "
              "with E mirrored at runtime, played for `collect` at a coop or "
              "barn and the truffle dig of 0185; pet the dog (2-4 frames) for "
              "0185's view-only gesture; canvas, pivot and `draw_scale` as "
              "0185 wrote into the pack",
              "Replace the stand-in poses and flip A025's placeholder-"
              "registry entries to raster",
              _integrated("A025")],
         dod=_art_dod("`python tools/show_art.py --work --check`", 208)),

    dict(id=209, phase=P12, title="Art: sheep and pigs",
         slug="art-farm-animals", deps=[185], art=["A026"],
         files="assets/art_source/props/, assets/art_source/manifest.json, "
               "tools/check_prop_art.py, src/ui/animal_view.gd",
         goal="Sheep and pigs get their approved art and the view states "
              "0185 gave them.",
         req=[_gate("A026"), _handoff("A026"),
              _promote("props", "`check_prop_art.NAMES`, where the cow and "
                       "the chicken live today, or a new animals checker "
                       "wired into `tools/verify.py` if the pack says so"),
              "Runtime names: idle (2), walk side-on (4, mirrored at "
              "runtime), eat (2-3) and sleep (1-2) for both, and the pig's "
              "dig (3), at the scale 0185 settled against the 32px farmer; "
              "0185's wander/eat/sleep view states play them",
              "Replace the tinted stand-ins and flip A026's placeholder-"
              "registry entries to raster",
              _integrated("A026")],
         dod=_art_dod("`python tools/check_prop_art.py` and `python "
                      "tools/show_art.py --props --check`", 209)),

    dict(id=210, phase=P12, title="Art: the cow and the chicken redrawn",
         slug="art-cow-chicken", deps=[185], art=["A027"],
         files="assets/art_source/props/, assets/art_source/manifest.json, "
               "tools/check_prop_art.py, src/ui/world_view.gd, "
               "src/ui/animal_view.gd",
         goal="Today's 24x24 cow and chicken are redrawn at the farmer's "
              "scale with idle, walk, eat and sleep.",
         req=[_gate("A027"), _handoff("A027"),
              _promote("props", "`check_prop_art.NAMES`, which names `cow` "
                       "and `chicken` today"),
              "Runtime names: idle, walk (side-on, mirrored at runtime), eat "
              "and sleep for the cow and the chicken at the canvas and pivot "
              "0185 settled; drop the cow and chicken from the "
              "`AMBIENT_MOTION` shader's `species` parameter in "
              "`world_view.gd` if the frames replace that sway, and keep "
              "`transition.gd`'s `DAY_ONLY` finding them",
              "Retire the old 24x24 `props/cow` and `props/chicken` once "
              "nothing reads them, and flip A027's placeholder-registry "
              "entries to raster",
              _integrated("A027")],
         dod=_art_dod("`python tools/check_prop_art.py` and `python "
                      "tools/show_art.py --props --check`", 210)),

    dict(id=211, phase=P12, title="Art: animal goods",
         slug="art-animal-goods", deps=[185], art=["A029"],
         files="assets/art_source/ui/, assets/art_source/props/, "
               "assets/art_source/manifest.json, tools/check_ui_art.py, "
               "tools/check_prop_art.py",
         goal="Egg, milk, wool and truffle get their icons, and the pig's dig "
              "spot its look in the world.",
         req=[_gate("A029"), _handoff("A029"),
              _promote("ui` and `assets/art_source/props",
                       "`tools/check_ui_art.py`, `check_prop_art.NAMES`"),
              "Runtime names: `ui/icon_<id>` (16x16) and `ui/hud_<id>` "
              "(10x10) from one source for the ids 0184 and 0185 gave egg, "
              "milk, wool and truffle, and the 16x16 dig spot drawn where "
              "0185 marks one",
              "Replace their stand-ins and flip A029's placeholder-registry "
              "entries to raster",
              _integrated("A029")],
         dod=_art_dod("`python tools/check_ui_art.py`, `python "
                      "tools/check_prop_art.py` and `python tools/show_art.py "
                      "--ui --check`", 211)),

    dict(id=212, phase=P12, title="Art: the coop and the barn",
         slug="art-coop-barn", deps=[186], art=["A030"],
         files="assets/art_source/buildings/, "
               "assets/art_source/manifest.json, tools/check_station_art.py, "
               "src/ui/art_placement.gd",
         goal="The coop and the barn get their approved art - whole, hurt "
              "and wrecked-but-standing - in place of 0183's stand-ins.",
         req=[_gate("A030"), _handoff("A030"),
              _promote("buildings", "`check_station_art.FAMILY` or a "
                       "buildings checker wired into `tools/verify.py`"),
              "Runtime names: `<id>`, `<id>_hurt` and the wrecked state 0186 "
              "added, at the footprints 0183 settled, with door/window light "
              "points on opaque pixels; full density - they do **not** join "
              "`ArtPlacement.visual_scale`'s 2.0 list",
              "Replace the stand-ins of 0183 and 0186 and flip A030's "
              "placeholder-registry entries to raster",
              _integrated("A030")],
         dod=_art_dod("`python tools/check_station_art.py` and `python "
                      "tools/show_art.py --stations --check`", 212)),

    dict(id=213, phase=P12, title="Art: the artisan machines",
         slug="art-machines", deps=[188], art=["A031"],
         files="assets/art_source/buildings/, assets/art_source/props/, "
               "assets/art_source/manifest.json, tools/check_station_art.py",
         goal="The keg, the preserves jar, the dairy, the loom and the mill "
              "get their approved art, idle and working.",
         req=[_gate("A031"), _handoff("A031"),
              _promote("buildings", "`check_station_art.FAMILY`"),
              "Runtime names: `<id>`, `<id>_active` and `<id>_hurt` (and the "
              "wreck if 0187 chose it) for the five, at the sizes 0188 "
              "settled, with `light_xy`/`smoke_xy` on opaque active pixels; "
              "full density, not in `ArtPlacement.visual_scale`'s 2.0 list",
              "Replace the stand-ins of 0187 and 0188 and flip A031's "
              "placeholder-registry entries to raster",
              _integrated("A031")],
         dod=_art_dod("`python tools/check_station_art.py` and `python "
                      "tools/show_art.py --stations --check`", 213)),

    dict(id=214, phase=P12, title="Art: artisan goods",
         slug="art-artisan-goods", deps=[188, 192], art=["A032"],
         files="assets/art_source/ui/, assets/art_source/manifest.json, "
               "tools/check_ui_art.py",
         goal="Wine, juice, jelly, pickles, cheese, butter, cloth, sandbags, "
              "flour, bread and sugar get their approved icons.",
         req=[_gate("A032"), _handoff("A032"),
              _promote("ui", "`tools/check_ui_art.py`"),
              "Runtime names: `ui/icon_<id>` (16x16) and `ui/hud_<id>` "
              "(10x10) from one source for the eleven ids 0187, 0188 and "
              "0192 gave them",
              "Replace their stand-ins and flip A032's placeholder-registry "
              "entries to raster",
              _integrated("A032")],
         dod=_art_dod("`python tools/check_ui_art.py` and `python "
                      "tools/show_art.py --ui --check`", 214)),

    dict(id=215, phase=P12, title="Art: the shipping bin",
         slug="art-shipping-bin", deps=[189], art=["A033"],
         files="assets/art_source/props/, assets/art_source/manifest.json, "
               "tools/check_prop_art.py",
         goal="The shipping bin of 0189 gets its approved art, lid and all.",
         req=[_gate("A033"), _handoff("A033"),
              _promote("props", "`check_prop_art.NAMES`"),
              "Runtime names: the closed bin and its lid-opening strip (2-3 "
              "frames, one-shot) at the canvas and pivot 0189 settled; the "
              "view plays the lid when the bin's panel opens (view only)",
              "Replace 0189's stand-in and flip A033's placeholder-registry "
              "entries to raster",
              _integrated("A033")],
         dod=_art_dod("`python tools/check_prop_art.py` and `python "
                      "tools/show_art.py --props --check`", 215)),

    dict(id=216, phase=P12, title="Art: the peddler", slug="art-peddler",
         deps=[190], art=["A034"],
         files="assets/art_source/npc/, assets/art_source/props/, "
               "assets/art_source/manifest.json, tools/check_station_art.py, "
               "tools/check_npc_art.py (new), tools/verify.py",
         goal="The peddler at the stall and the stall's closed state get "
              "their approved art.",
         req=[_gate("A034"), _handoff("A034"),
              _promote("npc` and `assets/art_source/props",
                       "`check_station_art.FAMILY` for the closed stall; a "
                       "new `tools/check_npc_art.py` wired into "
                       "`tools/verify.py` for the peddler, saying why in the "
                       "journal"),
              "Runtime names: idle (2-4), talk/wave (2-4) and the walk in/out "
              "side cycle (4-8, mirrored at runtime) at the farmer's scale "
              "and the pivot 0190 settled; the closed stall matches today's "
              "`shop` (32x40, pivot (16,36))",
              "Replace 0190's stand-ins and flip A034's placeholder-registry "
              "entries to raster",
              _integrated("A034")],
         dod=_art_dod("`python tools/check_station_art.py`, `python "
                      "tools/check_npc_art.py` and `python tools/show_art.py "
                      "--stations --check`", 216)),

    dict(id=217, phase=P12, title="Art: the house in three tiers",
         slug="art-house-tiers", deps=[191], art=["A035"],
         files="assets/art_source/buildings/, "
               "assets/art_source/manifest.json, tools/check_house_art.py, "
               "src/ui/art_placement.gd, src/ui/house_view.gd",
         goal="House tiers I, II and III get their approved exteriors, whole "
              "and hurt; tier III reads as a small fortified farmhouse.",
         req=[_gate("A035"), _handoff("A035"),
              _promote("buildings", "`tools/check_house_art.py`, which "
                       "hard-codes `house`/`house_hurt` and their window "
                       "points today - extend it per tier"),
              "Runtime names: each tier whole and hurt with its slices, "
              "`windows_xy`, `window_rects_xywh`, `light_xy` and `smoke_xy` "
              "on the same 6x4 footprint and pivot conventions as today's "
              "house; follow the density 0191 wrote into the pack "
              "(`ArtPlacement.visual_scale` doubles every file whose name "
              "starts `house_`, so a tier named `house_2` is doubled too - "
              "rename or extend the rule on purpose)",
              "Replace 0191's code-marked stand-ins and flip A035's "
              "placeholder-registry entries to raster",
              _integrated("A035")],
         dod=_art_dod("`python tools/check_house_art.py` and `python "
                      "tools/show_art.py --house --check`", 217)),
]
