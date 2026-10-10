# -*- coding: utf-8 -*-
"""Backlog part 9: the weapons of the night.

Phase 4 of the 1.0 plan (`docs/PLANO-DO-JOGO.md`, sections 4.4, 4.6, 5 and 7):
the six new defences plus the hardwood wall and sandbags, three new powers,
the technology tree by season, essence, and the leftovers a night leaves on
the farm. It sits after the day checkpoint (0196) because every weapon here is
paid for with something the day makes - straw, sunflowers, pumpkins, garlic,
copper, hardwood, fish - and after phase 10's cursor, which places all of it.
The perf groundwork (0218) goes first: the decoy here and the swarms of phase
14 add fields and bodies to a night that is already measured.
"""

P13 = "13 - Weapons of the night"


# ------------------------------------------------- the art leaves' fixed lines

def _approved_first(pack):
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


def _and(items):
    return items[0] if len(items) == 1 else \
        ", ".join(items[:-1]) + " and " + items[-1]


def _promote(families, checks):
    where = _and(["`assets/art_source/%s/`" % f for f in families])
    return ("Promote through the raster pipeline: versioned sources under "
            "%s, manifest entries with prompt/approval provenance, "
            "`assets/art_source/ownership.json`, then "
            "`python tools/import_art.py`; extend the hard-coded family "
            "lists the art checks use (%s, `ArtPlacement` if needed)."
            % (where, checks))


def _integrated(pack):
    return ("Set the pack to integrated: "
            "`python implementation/backlog/assets.py set %s integrated`."
            % pack)


def _leaf_dod(task, checks, showcases, what):
    shows = _and(["`python tools/show_art.py %s`" % s for s in showcases])
    return ["The family checks (%s) and the showcase (%s) pass"
            % (checks, shows),
            "`python tools/import_art.py --check` passes",
            "FHD (1920x1080) captures by day and by night of %s in the real "
            "game, opened and looked at, in `implementation/shots/%04d/`"
            % (what, task),
            "The sim and data hashes are unchanged (art never moves them)"]


TASKS = [
    # ======================================= phase 13 - weapons of the night
    dict(id=218, phase=P13, title="Room for more fields and more bodies",
         slug="perf-groundwork", deps=[196],
         files="src/core/pathing.gd, src/core/entities.gd, src/core/towers.gd, "
               "src/tools/perf_check.gd, tools/perf.py, "
               "tools/perf_baseline.txt, src/tools/headless_v1.gd",
         goal="Nothing changes for the player. The decoy, the bait, the digger "
              "and the rat swarm are coming, and today every wall placed "
              "re-sweeps every path field and every tower scans every zombie; "
              "make room before adding to either, with the game playing "
              "exactly as it does now.",
         req=["A named-field registry in `Pathing`, in code (a const table and "
              "one accessor such as `Pathing.field(state, name)`): a field is "
              "registered with its seeds, its cost rule and the state keys it "
              "is stored under, and is built on first request for the "
              "current `grid_version`, never on a rebuild nobody asked for. "
              "Today's three (`flow`, `flow_open`, `flow_hunt` and their "
              "`*_cost` arrays, under `flow_version`) keep being built eagerly "
              "in `refresh` exactly as now, because those keys are folded into "
              "SIM. The registry is for 0224's lure field and 0250's digger "
              "field, which add their own storage keys (and move SIM) then",
              "`Entities.ids` stops sorting on every call, on the strength of "
              "an asserted invariant: ids are handed out ascending and never "
              "reused (`next_entity_id`), so the table's own order is already "
              "ascending - assert it after spawns, kills, `Enemies.withdraw` "
              "and a save round trip (if a loaded table does not keep the "
              "order, sort it once where the save is read, e.g. "
              "`State.reconcile`). No static cache shared between states",
              "A spatial bucket for `Towers._acquire`, built once per "
              "`Towers.tick` as a local (never stored in the state) from the "
              "entity cells, so a tower looks only at the buckets its reach "
              "touches. It must pick exactly what the full scan picks for "
              "every `TARGETING` mode, ties to the lowest id included; "
              "`acquire_for` keeps working for the tests",
              "Both hashes unchanged is the bar. `State.hash_of` folds every "
              "state key, caches included, so nothing here may add a key to "
              "a new game's state. If that proves impossible, prove play "
              "identical (kills, house HP and every entity cell at fixed "
              "ticks of one seeded night, before and after) and record both "
              "numbers in `implementation/PROGRESS.md`",
              "A swarm scenario in `src/tools/perf_check.gd`: a few hundred "
              "walkers (the rat swarm's stand-in until 0248) against the "
              "worst case's towers, with its own `PERF` lines (e.g. "
              "`swarm_tick`, `swarm_towers`, `swarm_enemies`) and a `COUNT` "
              "of bodies. `PerfNames` is unchanged: no system is added",
              "The swarm must sit inside `TICK_BUDGET_US` (8333 us), and "
              "`tools/perf.py` holds only `night_tick`, `day_tick` and "
              "`path_refresh` to a budget today: add `swarm_tick` to that "
              "list so the bar is enforced. If it does not fit, write down "
              "what it would take rather than shrinking the swarm",
              "Accept the new baseline with `python tools/perf.py --accept` "
              "and say in the journal why each number moved"],
         dod=["`_task_0218_perf_ground` in `src/tools/headless_v1.gd` asserts "
              "the bucketed acquire equals the full scan over a seeded crowd "
              "for all four targeting modes, `Entities.ids` is ascending after "
              "spawns, kills and a save round trip, and a registered field is "
              "not built until it is asked for",
              "`python tools/perf.py --report` shows `night_towers` below its "
              "baseline at the start of this task (1028 us when this was "
              "written) on the old worst case, and `python tools/perf.py` "
              "passes with `swarm_tick` inside the tick budget",
              "The journal has the perf table before and after"]),

    dict(id=219, phase=P13, title="Essence", slug="essence",
         deps=[196, 137, 152], dresses=["A036"],
         files="src/core/rewards.gd, src/core/tech.gd, src/core/game_data.gd, "
               "src/ui/night_hud.gd, src/ui/result_screen.gd, "
               "src/ui/tech_panel.gd, assets/locale/strings.csv, "
               "implementation/BALANCE.md, src/tools/headless_check.gd, "
               "src/tools/headless_v1.gd",
         goal="The night stops paying like a day. It hands over essence - "
              "today's technology points under a new name - for holding the "
              "farm, and a smaller purse, so money is what the day earns and "
              "the night spends (plan section 4.6).",
         req=["Keep the id `tech` (`GameData.TECH`, `Rewards._is_tech`, the "
              "saves): only the words change, so no `State.VERSION` bump. "
              "`ITEM_TECH` becomes essence / essência and every line that "
              "names the currency follows (`DESC_TECH_COST`, `TECH_HELD`'s "
              "'points', any result or HUD line); the tree itself may stay "
              "the technology tree (`TECH_TITLE`)",
              "Earn rules as LEVERs in `GameData.REWARDS` and `TECH_BONUSES`: "
              "a night won pays `tech_points`; the three bonuses stay (house "
              "untouched measured against `Phases.house_full`, as 0114 left "
              "it); a Full Moon night (`Calendar.is_full_moon`, 0152) "
              "multiplies the night's essence by a percent LEVER (100-300), "
              "its own line in `Tech.would_pay`; `GameData.validate()` "
              "refuses a percent under 100. `nights_paid` still stops a night "
              "paying twice",
              "The night's money shrinks: `base_money`, `money_per_night` and "
              "the material handout (`resources`, `resources_per_night`), "
              "read through 0150's `Rewards.night_step`, come down to numbers "
              "argued against 0194's money-per-day targets in "
              "`implementation/BALANCE.md`; the journal says what a spring "
              "night paid before and after",
              "The bounty is paid for kills only. `Rewards._money_from` "
              "already reads `killed_by_kind`; assert that survivors who walk "
              "off at dawn (0137, `Enemies.withdraw`) pay nothing and are not "
              "counted as killed",
              "Essence on screen: the night HUD shows what is held (plan "
              "section 9) and the morning report of 0138 has a '+N essence' "
              "line itemised from the lines `Tech.would_pay` gave inside "
              "`Rewards.settle`, kept in `payout` for the screen - after "
              "`Tech.award` the night is paid and `would_pay` answers empty. "
              "The icon is the existing tech icon through the placeholder "
              "road until A036 is integrated by 0235",
              "Asserts that pin night money or technology (`_task_0061`, "
              "`_task_0062`, `_task_0068` and whatever 0150 left of them) are "
              "rewritten in place in `src/tools/headless_check.gd` to read "
              "the LEVERs rather than literals; `tools/i18n_check.py` is "
              "clean in both languages",
              "SIM and DATA both move on purpose (the payout and the REWARDS "
              "table): record the old and the new numbers in "
              "`implementation/PROGRESS.md`"],
         dod=["`_task_0219_essence` in `src/tools/headless_v1.gd` asserts a "
              "won night pays `tech_points` plus each bonus earned, a Full "
              "Moon night pays the multiplied amount, a replayed night pays "
              "no essence, and a dawn win with survivors pays bounty for the "
              "kills only",
              "`python tools/shot.py 0219` captures of the night HUD and the "
              "morning report say essence, opened and looked at",
              "The BALANCE.md section sets a spring night's money and essence "
              "beside a spring day's money"]),

    dict(id=220, phase=P13, title="The technology tree by season",
         slug="tech-by-season", deps=[219, 149],
         files="src/core/game_data.gd, src/core/tech.gd, "
               "src/core/calendar.gd, src/ui/tech_panel.gd, "
               "src/ui/names.gd, assets/locale/strings.csv, "
               "src/tools/headless_v1.gd, src/tools/input_v1.gd",
         goal="Each season opens a new floor of the tree, so summer's essence "
              "buys something spring could not and the tree grows with the "
              "year instead of being finished in the first fortnight (plan "
              "section 7).",
         req=["`TECH_TREE` rows gain a `season` (0 spring to 3 winter, the "
              "calendar of 0149). Today's twelve nodes are spring's floor; "
              "summer, autumn and winter each add one node per branch "
              "(production, defence, survival) - nine new nodes with notes",
              "The gate is the seasons the run has reached, not the season it "
              "is in: a winter node stays available in Year 2's spring. Put "
              "that question in one pure helper beside 0149's, e.g. "
              "`Calendar.season_reached(state, season)` (every season from "
              "Year 2 on) - 0233 and 0234 reuse it. `Tech.why_not_buy` "
              "refuses an unreached season with a new key (e.g. "
              "`WHY_NOT_YET_SEASON` and the season name, a `strings.csv` row "
              "in both languages), checked before the price",
              "Every new node gives a number a system already reads, or a new "
              "`Tech.bonus` key read by the one system that owns it. "
              "`Tech.bonus` returns the first owned node that gives a key, so "
              "a later tier improving an existing key needs a rule (best "
              "value wins, or a key of its own): decide, write it in "
              "`tech.gd` and assert it",
              "Price it the way task 0063 did: every node reachable in a "
              "year, not all of them, against `Tech.total_available()` over "
              "the calendar (0150); the arithmetic goes in the journal",
              "Leave the powers to 0233, which adds one survival node per "
              "season from summer; nothing here gives a power",
              "`tech_panel.gd` pages the tree by season (keyboard, mouse and "
              "pad), greys an unreached season with its reason and still fits "
              "480x270. `Names.KEYS`, `Names.NOTES` and `TECH_*`/`TECHNOTE_*` "
              "rows in `assets/locale/strings.csv` for every new node, in both "
              "languages",
              "A `GameData.validate()` rule: every `season` is 0-3, `needs` "
              "never points at a later season, and each branch has a node in "
              "every season. DATA moves on purpose (the tree is in "
              "`GameData.digest()`): record it. SIM must not move - no state "
              "key is added and the determinism scenario buys nothing"],
         dod=["`_task_0220_tree_seasons` in `src/tools/headless_v1.gd` asserts "
              "a summer node is refused in spring with the season reason, is "
              "buyable once summer is reached and still in Year 2's spring, "
              "and the stacking rule for a repeated bonus key holds",
              "`_case_0220_tree_pages` in `src/tools/input_v1.gd` pages to "
              "summer and buys a node with the keyboard and with the pad",
              "`python tools/shot.py 0220` captures of the tree in spring and "
              "in autumn, opened and looked at: no node cut off, no two "
              "labels on top of each other"]),

    dict(id=221, phase=P13, title="What the night leaves behind",
         slug="night-loot", deps=[219, 152], dresses=["A036"],
         files="src/core/combat.gd, src/core/loot.gd (new), "
               "src/core/phases.gd, src/core/player.gd, src/core/state.gd, "
               "src/core/game_data.gd, src/core/tech.gd, src/ui/names.gd, "
               "src/ui/world_view.gd, src/ui/result_screen.gd, "
               "assets/locale/strings.csv, src/tools/headless_v1.gd, "
               "src/tools/input_v1.gd",
         goal="The night leaves something for the morning: bones where zombies "
              "fell and, after a Full Moon, moon stones along the road the "
              "horde came by - picked up on the morning round and worth money, "
              "essence or fertiliser (plan sections 3.3 and 4.6).",
         req=["Loot is a RUN_DATA dictionary (cell index -> {item: count}) "
              "listed in `State.RUN_DATA` and adopted through an `initial()` "
              "(a small `src/core/loot.gd`). It is not an occupant - nothing "
              "walks round it or builds on it - and it survives "
              "`Farm.clear_rubble` at `begin_day`. Never name a key "
              "`moon_phase`",
              "Bones drop in `Combat._kill` on the cell the enemy died on: a "
              "per-kind count in `ENEMIES` (`bones`, LEVER 0-6, the Giant "
              "more; a row without `bones` drops none, so the enemies of "
              "phase 14 opt in), piled per cell up to a cap LEVER, no RNG. "
              "Survivors that walk off at dawn drop nothing. A pile on a cell "
              "the farmer cannot stand on (a wall, water) goes to the nearest "
              "walkable cell by a fixed rule - decide and assert",
              "Moon stones: the morning after a Full Moon night (0152), a "
              "LEVER number (2-8) lies on cells of the horde's route - e.g. "
              "every Kth cell of the flow field from tonight's spawn regions "
              "toward the house - chosen deterministically or from a fresh "
              "`(seed, day)` stream like `Endless._stream_for`, never the run "
              "stream",
              "Picked up by day only, when the farmer steps onto the cell in "
              "`Player.tick` (no verb, no tool); the pile goes into the ledger "
              "and the cell is cleared. Uncollected loot stays, or fades after "
              "a LEVER of days - decide and say so",
              "`bones` and `moon_stone` are resources: `RESOURCES`, "
              "`SELL_PRICE`, a leftovers group in `RESOURCE_GROUPS`, "
              "`Names.KEYS` (`ITEM_BONES`, `ITEM_MOON_STONE`) and both "
              "languages. Moon stones sell at the stall or trade for essence "
              "by day at a LEVER rate through one core function (e.g. "
              "`Tech.trade_moon_stones`), offered where an input path already "
              "exists - a button in the tech panel, or a station recipe "
              "through the workshop panel if `check_chain` can value essence "
              "(a recipe needs its `REC_*` key). Every new constant goes into "
              "`GameData.digest()` (0112's coverage assert) and "
              "`validate()` refuses a cap, a stone count or a rate of zero",
              "The morning report's leftovers line (0138) says what is lying "
              "on the farm: N bones, M moon stones to collect",
              "Drawn through the placeholder road until A036 is integrated by "
              "0235: a code-drawn bone pile and a moon stone with a 2-frame "
              "shimmer (the glow is code, view only)",
              "SIM moves on purpose (drops in `_kill`, a new state key) and "
              "DATA moves (new resources and prices): record both"],
         dod=["`_task_0221_night_loot` in `src/tools/headless_v1.gd` asserts a "
              "killed walker leaves its bones on its cell, the pile survives "
              "`begin_day`, stepping on it by day collects it and at night "
              "does not, a Full Moon morning lays its stones on the same "
              "cells for the same seed, and a traded stone pays the essence "
              "LEVER",
              "`_case_0221_collect` in `src/tools/input_v1.gd` walks the "
              "farmer over a bone pile and sees the count rise, then trades "
              "a moon stone for essence through the panel that offers it",
              "`python tools/shot.py 0221` morning captures show the piles on "
              "the road, opened and looked at"]),

    dict(id=222, phase=P13, title="Bone meal", slug="bone-meal",
         deps=[221, 165], dresses=["A036"],
         files="src/core/game_data.gd, src/core/farming.gd, "
               "src/core/interact.gd, src/ui/day_hud.gd, src/ui/sfx.gd, "
               "src/ui/names.gd, src/ui/world_view.gd, "
               "assets/locale/strings.csv, src/tools/headless_v1.gd, "
               "src/tools/input_v1.gd",
         goal="Bones go back into the ground: ground into bone meal, they give "
              "a plot one day of growth for free, once - the night paying for "
              "the day.",
         req=["A recipe (e.g. `grind_bone_meal`, at the workshop or 0188's "
              "mill) turns bones into `bone_meal`, a new resource with a "
              "price, a group, `Names.KEYS` (`ITEM_BONE_MEAL`, its `REC_*`) "
              "and both languages; `check_chain` holds (bone meal is worth "
              "more than its bones)",
              "How many bones there are (0221): one body of a kind in "
              "`BONES_EVERY` (8) leaves its bones - about 11 a spring night "
              "held well and 82 a winter one (`src/tools/night_pay.gd`'s "
              "Bones column). Set the bones a bone meal takes against that, "
              "so a night's bones fertilise a handful of plots and not the "
              "field, and say the ratio in BALANCE.md",
              "Fertilising: with bone meal selected in the day HUD's strip "
              "beside the seeds (keyboard, mouse and pad), interact on a "
              "tilled plot spends one and marks the plot `fertilised` - a new "
              "field on the plot in `state[\"plots\"]` (RUN_DATA), read with a "
              "default so old saves' plots need no migration and no "
              "`State.VERSION` bump. If it is a new verb (e.g. `fertilise` in "
              "`Farming.verb_at`), it goes in `Interact.DAY_ONLY` and "
              "`DEFAULT_TICKS`, and `Sfx.VERB_SOUNDS` maps it to the nearest "
              "generated sound (`sfx/plant`) so `_task_0084_day_sounds` stays "
              "green until 0281 gives it its own",
              "The rule: at the next morning's growth credit (0165) a "
              "fertilised plot grows one extra day, once, and the mark "
              "clears. Decide and assert whether it must also have been "
              "watered; it never gets round a regrowth (0172) or winter "
              "(0171) rule",
              "A fertilised plot not yet planted keeps the mark until it is; "
              "harvesting clears it",
              "The soil marker is drawn through the placeholder road (a "
              "tinted tilled tile, dry and wet) until A036 is integrated by "
              "0235",
              "SIM and DATA move on purpose: record both"],
         dod=["`_task_0222_bone_meal` in `src/tools/headless_v1.gd` asserts "
              "two plots of one crop planted together, one of them "
              "fertilised, finish exactly one day apart, and a second "
              "morning grants nothing extra - driving 0165's morning credit "
              "directly rather than simulating whole days, which the 120 s "
              "suite budget cannot afford",
              "`_case_0222_fertilise` in `src/tools/input_v1.gd` selects bone "
              "meal and fertilises a plot with the keyboard",
              "The Deliverables table of "
              "`implementation/backlog/packs/A036-night-loot.md` states the "
              "final geometry this task settled (the pickups, the fertilised "
              "soil, the four icons)",
              "`python tools/shot.py 0222` captures of a fertilised plot dry "
              "and wet, opened and looked at"]),

    dict(id=223, phase=P13, title="Defences sleep under tarps",
         slug="defence-tarps", deps=[196, 132, 120], dresses=["A044"],
         files="src/ui/world_view.gd, src/ui/transition.gd, "
               "src/ui/placeholder_art.gd, src/tools/shot.gd, "
               "src/tools/headless_v1.gd, "
               "implementation/backlog/packs/A044-tarps.md",
         goal="By day the defences sleep under tarps and the farm looks like a "
              "farm; when the night comes the covers come off with the wake "
              "the transition already plays (plan section 5).",
         req=["View only: no rule reads a tarp, and both hashes stay where "
              "they are",
              "In the DAY phase every defence of a tarp family is drawn "
              "covered; during the switch into the night the tarps come off "
              "with the wake pass in `transition.gd` (`WAKES` kept - the "
              "generator still wakes, without a tarp) and go back on when the "
              "day begins",
              "Decide which families get tarps and why: probably the towers "
              "and the other standing one-cell defences, not barriers, mines "
              "or traps (a covered wall is still a wall, a covered mine is a "
              "lie). Drive the unveil from one list in the view so a later "
              "defence joins by being listed; 0234 lists the families of "
              "0224-0231, which leave the list alone",
              "A hurt or wrecked defence shows its state by day - through the "
              "tarp or instead of it, decide - so the morning never hides "
              "damage",
              "Drawn through the placeholder road of 0120: a code-drawn or "
              "tinted cover per footprint (32x48 towers, 16x32, 16x24) with "
              "two unveil frames, until A044 is integrated by 0243",
              "Write the chosen families and footprints into the Deliverables "
              "table of `implementation/backlog/packs/A044-tarps.md`; 0234 "
              "settles the final list"],
         dod=["`_task_0223_tarps` in `src/tools/headless_v1.gd` asserts every "
              "id in the view's tarp list is a `DEFENCES` id and nothing in "
              "`src/core/` mentions a tarp",
              "`python tools/shot.py 0223` captures of the same towers by day "
              "(covered), at dusk and at night (uncovered), opened and looked "
              "at"]),

    dict(id=224, phase=P13, title="The scarecrow decoy", slug="decoy",
         deps=[218, 132], dresses=["A037"],
         files="src/core/game_data.gd, src/core/pathing.gd, "
               "src/core/enemies.gd, src/ui/names.gd, src/ui/describe.gd, "
               "assets/locale/strings.csv, src/tools/perf_check.gd, "
               "src/tools/shot.gd, src/tools/headless_v1.gd, "
               "src/tools/input_v1.gd",
         goal="A straw figure that pulls nearby zombies off their road and "
              "takes their blows while the towers work - the first defence "
              "that changes where the horde goes without walling it in.",
         req=["Id `decoy` (not `scarecrow`, which is the porch guardian, and "
              "no crop id). A `DEFENCES` row: a cost in straw (the resource "
              "0184 and 0193 brought in) and wood, a high `hp` LEVER "
              "(100-250), a `lure_tiles` LEVER (3-8), no `reload_ticks` (it "
              "is not a tower) and no `path_cost`, so breakers already hunt "
              "it as prey. Its `season` (0193's field on `DEFENCES`) is "
              "summer, per the plan's table, so `check_seasonal_supply` "
              "judges it right; 0234 does the gating. No `damage` either, so "
              "no `Sfx.TOWER_SOUNDS` entry: `_task_0085_night_sounds` wants a "
              "sound exactly when a defence has `damage`",
              "The lure rule: a lure field registered in 0218's `Pathing` "
              "registry, swept from decoy cells and built only while a decoy "
              "stands. An enemy whose `ENEMIES` row says it can be lured (a "
              "new flag: walker and runner yes, bosses never; decide the tank "
              "and the breaker) and is within `lure_tiles` of a decoy by the "
              "lure field walks down that field instead of its own, and "
              "bites the decoy through `Enemies._gnaw` when it is the next "
              "cell",
              "When the decoy falls the lured go back to their own field the "
              "same tick. Two decoys: the nearer by the field wins, ties by "
              "`Grid.STEPS`",
              "`GameData.validate()`: a lure has `lure_tiles` > 0 and hit "
              "points (`check_defences`); no boss is lurable "
              "(`check_enemies`)",
              "Perf: a farm without decoys pays nothing for the lure field; "
              "with four decoys the rebuild stays inside `PATH_BUDGET_US`. "
              "Add decoys to perf_check's swarm scenario",
              "`Names.KEYS` `DEF_DECOY`, a `Describe.defence` line for the "
              "lure (a `DESC_*` key), strings in both languages; placed by "
              "cursor at night like every defence (0132)",
              "Drawn through the placeholder road (a code-drawn straw figure "
              "at 16x32, whole/hurt/wreck) until A037 is integrated by 0236; "
              "the hit sway is view only",
              "DATA moves (a new row and the lurable flags). SIM moves on "
              "purpose too if the lure field's storage keys are in a new "
              "game's state, because `State.hash_of` folds every key, cached "
              "fields included: record both numbers and why"],
         dod=["`_task_0224_decoy` in `src/tools/headless_v1.gd` asserts a "
              "walker within `lure_tiles` walks to the decoy and bites it "
              "while one beyond walks on to the house, a runner is lured, the "
              "Giant is not, and the lured return to the road the tick the "
              "decoy falls",
              "`_case_0224_decoy` in `src/tools/input_v1.gd` places a decoy "
              "with the cursor at night",
              "`python tools/perf.py` passes with decoys in the swarm, and a "
              "`shot.gd` scenario of a lured crowd, captured with "
              "`python tools/shot.py 0224`, is opened and looked at"]),

    dict(id=225, phase=P13, title="Zombie bait", slug="zombie-bait",
         deps=[224, 179], dresses=["A037"],
         files="src/core/game_data.gd, src/core/pathing.gd, "
               "src/core/enemies.gd, src/core/building.gd, src/ui/names.gd, "
               "src/ui/describe.gd, assets/locale/strings.csv, "
               "src/tools/headless_v1.gd, src/tools/input_v1.gd",
         goal="Rotten fish made by day and thrown down at night: for a few "
              "seconds the whole crowd around it turns toward it - the pond "
              "paying into the night (plan section 3.2).",
         req=["Id `zombie_bait`: a recipe at the kitchen (or the press) turns "
              "fish into a bait kit, through 0179's rule that a recipe taking "
              "`fish` accepts any species; the kit's inputs equal the "
              "`DEFENCES` cost, as `check_recipes` demands. 0179's fish group "
              "is understood by `Crafting`, not by `Resources.pay`: either "
              "the bait goes down from a kit only (the ledger road refused "
              "with a reason) or its `cost` names a real resource - decide. "
              "Its `season` (0193's field) is summer, as 0234's table says",
              "It reuses 0224's lure rule and lurable flags, with a wider "
              "`lure_tiles` LEVER (6-14). Decide how one lure field honours "
              "two reaches (each source seeded with its own head start, or "
              "the bait as a second registered field) and keep 'the nearer by "
              "the field wins'",
              "Walkable like a mine: a `walkable` flag on the `DEFENCES` row "
              "that `Pathing._through` (the ground's cost) and "
              "`Pathing.is_prey` (left out) both read, so nothing breaks "
              "through it and breakers do not hunt it. 0228's garlic braid "
              "uses the same flag - if 0228 landed first, reuse it. "
              "`check_defences` refuses a walkable row with a `path_cost`",
              "Consumed: it lasts `lifetime_ticks` (LEVER, 5-20 s) and goes "
              "when that runs out or when a LEVER number of zombies have "
              "reached it, whichever is first; it leaves no rubble",
              "A per-night limit LEVER like the barricade's, read through "
              "`Building.left_tonight` - which today adds the tree's "
              "`barricade_bonus` to every `per_night_limit`: make that the "
              "barricade's alone, or decide the bait shares it, and assert "
              "which",
              "`Names.KEYS` (`DEF_ZOMBIE_BAIT`, its `REC_*`), a "
              "`Describe.defence` line, strings in both languages; no "
              "`damage`, so no `Sfx.TOWER_SOUNDS` entry; drawn through the "
              "placeholder road (a 16x16 fish on the ground and its icon) "
              "until A037 is integrated by 0236",
              "DATA moves (a row and a recipe); SIM moves only if a state key "
              "is added or the determinism scenario meets a bait - record "
              "which"],
         dod=["`_task_0225_bait` in `src/tools/headless_v1.gd` asserts a crowd "
              "beyond any decoy's reach turns toward the bait, the bait goes "
              "at its lifetime or its arrival count, and the crowd is back on "
              "its road the same tick",
              "`_case_0225_bait` in `src/tools/input_v1.gd` makes a bait by "
              "day and places it with the cursor at night",
              "The Deliverables table of "
              "`implementation/backlog/packs/A037-decoy.md` states the final "
              "geometry this task settled (decoy states and sway frames, the "
              "bait on the ground, its icon)"]),

    dict(id=226, phase=P13, title="The beehive", slug="beehive",
         deps=[218, 132, 168], dresses=["A038"],
         files="src/core/game_data.gd, src/core/towers.gd, src/core/combat.gd, "
               "src/core/phases.gd, src/core/building.gd, src/core/state.gd, "
               "src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, "
               "assets/locale/strings.csv, src/tools/headless_v1.gd",
         goal="Bees sting what comes near and keep stinging, and the hive is "
              "as strong as the sunflowers around it - a defence that asks "
              "for a field to be planted beside it (plan section 5).",
         req=["Id `beehive`: a `DEFENCES` row with `reload_ticks` (so "
              "`Towers` collects it), a short `range`, a cost in wood and "
              "sunflowers, `season` summer (0193's field), and a sting - "
              "damage over time refreshed, never stacked, the way "
              "`Combat.set_alight` works. Either generalise `burning` to "
              "carry a damage type (fire must stay fire for 0256's rain; an "
              "entry saved without a type reads as fire, so no version bump) "
              "or add a sibling RUN_DATA table ticked in sorted id order in "
              "`Combat.tick`; decide and say which",
              "The row has a `damage` (the sting's per-hit number), so "
              "`_task_0085_night_sounds` wants a `Sfx.TOWER_SOUNDS` entry: "
              "map `beehive` to the nearest generated sound (e.g. "
              "`sfx/flame`) until 0283 gives it a buzz",
              "Strength from sunflowers, worked out once at "
              "`Phases.begin_night` and written on the occupant (no "
              "`Farm.touch`): growing sunflower plots within N tiles "
              "(`Farming.crop_on`, LEVER 2-4) raise the sting; when too few "
              "grow - autumn and winter - the hive takes sunflowers from the "
              "stock instead (LEVER per hive per night). Decide the curve and "
              "write it in the journal; a hive with neither still stings, "
              "weakly",
              "`TOWER_LEVELS` 1-2 for `beehive`. `Building.why_not_upgrade` "
              "only checks `TOP_TOWER_LEVEL`, so a family with fewer rows can "
              "be upgraded past its last one: refuse that, for every family",
              "`check_defences` accepts a sting (damage and ticks above zero) "
              "and refuses a sting with either at zero; the sunflower radius "
              "and per-night stock LEVERs are checked above zero too",
              "`Names.KEYS` `DEF_BEEHIVE`, a `Describe.defence` line (the "
              "sting, the sunflowers), strings in both languages; drawn "
              "through the placeholder road (a tinted 32x48 tower per level "
              "and state, an 8x8 bee swarm) until A038 is integrated by 0237",
              "SIM and DATA move on purpose: record both"],
         dod=["`_task_0226_beehive` in `src/tools/headless_v1.gd` asserts the "
              "sting refreshes rather than stacks, a hive among growing "
              "sunflowers outdoes one without, a hive with stocked sunflowers "
              "takes them at `begin_night`, and a two-level family refuses a "
              "third upgrade",
              "The Deliverables table of "
              "`implementation/backlog/packs/A038-beehive.md` states the final "
              "geometry this task settled (levels 1-2, the states, the swarm)",
              "`python tools/shot.py 0226` captures of a hive at work beside a "
              "sunflower bed at night, opened and looked at"]),

    dict(id=227, phase=P13, title="The pumpkin catapult", slug="catapult",
         deps=[196, 132, 168], dresses=["A039"],
         files="src/core/game_data.gd, src/core/towers.gd, src/core/ammo.gd, "
               "src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, "
               "assets/locale/strings.csv, src/tools/shot.gd, "
               "src/tools/headless_v1.gd",
         goal="A lobbed splash that burns pumpkins instead of gunpowder, so an "
              "autumn harvest becomes an autumn defence (plan section 5).",
         req=["Id `catapult` (never `pumpkin`, which is the crop): `shape` "
              "splash, `aim` ballistic with `flight_ticks`, `ammo` "
              "{pumpkin: 1}, a cost in wood and pumpkins, `season` autumn "
              "(0193's field - pumpkins are autumn's, so "
              "`check_seasonal_supply` fails it as spring). Not a cheaper "
              "mortar: shorter reach, no gunpowder, a reason of its own - the "
              "journal says when it is the better buy",
              "It has `damage`, so `_task_0085_night_sounds` wants a "
              "`Sfx.TOWER_SOUNDS` entry: borrow `sfx/mortar` until 0283 "
              "gives it a thunk",
              "`check_ammo` refuses ammunition no recipe makes. Allow what a "
              "crop yields (the `CROPS` table) as well as recipe outputs, or "
              "add a recipe - decide, and keep the rule's intent: a tower "
              "must be able to fire a proper shot",
              "An empty pumpkin pool gives the weak shot every tower has "
              "(`Ammo.weak_damage`, `Ammo.weak_reload`), never a silent "
              "catapult",
              "`TOWER_LEVELS` 1-3 for `catapult`, gated on the same tree "
              "nodes as the other towers (`true sights`, `oiled works`)",
              "`Names.KEYS` `DEF_CATAPULT`, a `Describe.defence` line, strings "
              "in both languages; drawn through the placeholder road (a "
              "tinted 32x48 tower per level and state, an 8x8 pumpkin shot, "
              "a 4-frame splat) until A039 is integrated by 0238",
              "DATA moves (a row, its levels, the ammunition rule); SIM moves "
              "only if a state key appears or the scenario builds one - "
              "record both numbers"],
         dod=["`_task_0227_catapult` in `src/tools/headless_v1.gd` asserts a "
              "pumpkin lands where it was aimed with the splash falloff the "
              "LEVER claims, an empty pool still fires weakly, and levels 1-3 "
              "read through `Building.entry_at`",
              "The Deliverables table of "
              "`implementation/backlog/packs/A039-catapult.md` states the "
              "final geometry this task settled (levels, states, muzzle "
              "points, the shot, the splat)",
              "`python tools/shot.py 0227` captures of a volley landing, "
              "opened and looked at"]),

    dict(id=228, phase=P13, title="The garlic braid", slug="garlic-braid",
         deps=[218, 132, 168], dresses=["A040"],
         files="src/core/game_data.gd, src/core/pathing.gd, "
               "src/core/enemies.gd, src/core/phases.gd, src/ui/names.gd, "
               "src/ui/describe.gd, assets/locale/strings.csv, "
               "src/tools/perf_check.gd, src/tools/headless_v1.gd",
         goal="Hung on a post, it makes the ground around it somewhere zombies "
              "would rather walk round, and slows the ones that come through "
              "anyway (plan sections 3.1 and 5).",
         req=["Id `garlic_braid` (never `garlic`, the crop), paid in garlic "
              "and a little wood, `season` autumn (0193's field, per the "
              "plan's table). Walkable like a trap through the `walkable` "
              "flag 0225 puts on `DEFENCES` (add it here if 0225 has not "
              "landed): `Pathing._through` gives it the ground's cost and "
              "`Pathing.is_prey` leaves it out (today a defence with no "
              "`path_cost` is prey); it is not `one_shot`, so `Traps` never "
              "sees it. No `damage`, so no `Sfx.TOWER_SOUNDS` entry",
              "Repelling is a cost: cells within N tiles (LEVER 1-3) cost a "
              "LEVER more in `Pathing._entry_costs`, in the shared and the "
              "open field, never more than one braid's worth however many "
              "overlap. Every step stays within `WIDEST_STEP` (32): extend "
              "`check_pathing` to add the garlic extra to the worst terrain "
              "and the worst `path_cost`",
              "Slowing: inside the area an enemy walks at a percent of its "
              "speed (LEVER) in `Enemies._walk`, worked out like "
              "`Ability.slowed_ticks`; with a flare too, the stronger of the "
              "two applies, not both. Build the area as a per-cell array with "
              "the field (the pass over the occupants is already there) so "
              "`_walk` reads one entry, never a search per zombie per tick",
              "It wears out: full strength the first night, wilted (a LEVER "
              "share) the second, spent after - kept on the occupant, moved "
              "on at `Phases.begin_night`. The strength is part of the path "
              "costs, so a night that changes any braid bumps the grid once "
              "(`Farm.touch`) and the fields rebuild; the no-touch rule is "
              "for per-tick status. A spent braid does nothing and stays "
              "until sold, or goes (decide). The states match A040: fresh, "
              "wilted, spent",
              "Perf: the area cost is part of `_entry_costs`, so measure "
              "`path_refresh` with ten braids; it stays inside "
              "`PATH_BUDGET_US`",
              "`Names.KEYS` `DEF_GARLIC_BRAID`, a `Describe.defence` line, "
              "strings in both languages; drawn through the placeholder road "
              "(16x24, fresh/wilted/spent) until A040 is integrated by 0239",
              "SIM and DATA: record both"],
         dod=["`_task_0228_garlic` in `src/tools/headless_v1.gd` asserts a "
              "route with a cheap way round avoids the braid, a crowd forced "
              "through walks at the LEVER's speed, the braid wilts and is "
              "spent on the nights it says (driven through "
              "`Phases.begin_night`, not whole played nights), and "
              "`GameData.validate()` refuses a garlic extra that would pass "
              "`WIDEST_STEP`",
              "The Deliverables table of "
              "`implementation/backlog/packs/A040-garlic-braid.md` states the "
              "final geometry this task settled",
              "`python tools/shot.py 0228` captures of the route bending round "
              "a braid (0130's camera hook), opened and looked at"]),

    # Added 0226: the searchlight has two levels, and 0226 is where
    # `Building.why_not_upgrade` stops a short family going past its rows.
    dict(id=229, phase=P13, title="The searchlight", slug="searchlight",
         deps=[196, 132, 226], dresses=["A041"],
         files="src/core/light.gd (new), src/core/game_data.gd, "
               "src/core/towers.gd, src/core/ability.gd, src/core/combat.gd, "
               "src/ui/lighting.gd, src/ui/names.gd, src/ui/describe.gd, "
               "assets/locale/strings.csv, src/tools/headless_check.gd, "
               "src/tools/headless_v1.gd",
         goal="A powered lamp that lights the ground around it and lets the "
              "towers in its light see a tile further - and the moment light "
              "becomes a rule that the wraith and the fog will read (plan "
              "section 5).",
         req=["Id `searchlight`: a `DEFENCES` row with no `reload_ticks` (it "
              "does not shoot) and no `damage` (so no `Sfx.TOWER_SOUNDS` "
              "entry), an `energy_draw`, a `light_tiles` LEVER (3-6), a cost "
              "in iron and copper (0176) and `season` winter (0193's field). "
              "Breakers hunt it like anything built. `check_defences` "
              "refuses a light with `light_tiles` of zero; a new constant "
              "(the porch radius, the reach bonus) goes into "
              "`GameData.digest()`",
              "Light is a core rule in one place (e.g. `src/core/light.gd`): "
              "`Light.is_lit(state, cell)` is true on searchlight cells, in "
              "the flare's area while it burns (`Ability.flare_at`), on the "
              "cells of burning enemies (`Combat.is_burning`) and on the "
              "porch (a LEVER radius round the house door). 0252 and 0256 "
              "read it; `lighting.gd` may draw from it, never the other way "
              "round",
              "Searchlight cells are cached against `grid_version`, like "
              "`Towers._towers` (new state keys: SIM moves; a Dictionary "
              "cache goes in `State.TABLES` or `RUN_DATA`); the flare and the "
              "fires are asked fresh. `Light` is asked, never ticked - if it "
              "grows a `tick`, it goes in `PerfNames` and `perf_check`",
              "A tower standing in light reaches +1 (LEVER): `Towers.reach_of` "
              "learns the tower's cell (or `_acquire` passes it) - move every "
              "caller: `_acquire` (0218's bucketed version), `acquire_for`, "
              "the old asserts that call `reach_of` in `headless_check.gd`, "
              "and any range drawing the view gained (0131's cursor)",
              "Needs power, degraded never dead like the rest of `Power`: on "
              "a short farm the light shrinks (e.g. by a tile) instead of "
              "going out; decide and assert",
              "`TOWER_LEVELS` 1-2 for `searchlight` (a wider light), refused "
              "past its last row by 0226's fix to "
              "`Building.why_not_upgrade`",
              "`Names.KEYS` `DEF_SEARCHLIGHT`, a `Describe.defence` line, "
              "strings in both languages; drawn through the placeholder road "
              "(32x48 per level and state, a `light_xy` point) with the beam "
              "in code, until A041 is integrated by 0240",
              "SIM and DATA: record both"],
         dod=["`_task_0229_light` in `src/tools/headless_v1.gd` asserts the "
              "lit cells of each source (a searchlight, the flare, a burning "
              "zombie, the porch), a gun tower in light acquiring one tile "
              "further than one in the dark, a short farm shrinking the "
              "light, and the cache rebuilding when a searchlight goes up or "
              "comes down",
              "The Deliverables table of "
              "`implementation/backlog/packs/A041-searchlight.md` states the "
              "final geometry this task settled",
              "`python tools/shot.py 0229` captures of a lit and an unlit "
              "tower line at night, opened and looked at"]),

    dict(id=230, phase=P13, title="The electric fence",
         slug="electric-fence", deps=[196, 132, 176], dresses=["A042"],
         files="src/core/game_data.gd, src/core/enemies.gd, "
               "src/ui/world_view.gd, src/ui/placeholder_art.gd, "
               "src/ui/names.gd, src/ui/describe.gd, "
               "assets/locale/strings.csv, src/tools/headless_v1.gd",
         goal="A barrier like the wooden fence, except whatever bites it is "
              "thrown back stunned for a moment - a winter answer that needs "
              "the generator running (plan section 5).",
         req=["Id `electric_fence`: a barrier (`path_cost` and `hp` LEVERs, "
              "within `WIDEST_STEP` by `check_pathing`) with an "
              "`energy_draw`, a cost in copper (0176), with wood if it needs "
              "a frame, and `season` winter (0193's field). The shock is a "
              "stun, not `damage`, so no `Sfx.TOWER_SOUNDS` entry "
              "(`_task_0085_night_sounds` wants one exactly when a defence "
              "has `damage`; 0283 adds the zap)",
              "Stun in `Enemies._gnaw`: an enemy biting an electric fence is "
              "stunned for a LEVER of ticks (1-3 s) - a generic entity "
              "counter (any source may set it) read at the top of "
              "`Enemies._walk`, so a stunned enemy neither moves nor bites; "
              "0233's farm bell writes the same counter. The bite still "
              "lands; decide whether bosses get a shorter stun or none. "
              "`check_defences` refuses a stun of zero ticks",
              "Needs power, degraded never dead: on a short farm the stun is "
              "scaled down by `Power.percent`, never to zero",
              "Joins like the fence: `WorldView.barrier_mask` joins only "
              "`wall` and `fence` today - add the electric fence (decide "
              "whether it meets a wooden one) and the placeholder road's "
              "`connected` flag, so the joins draw before the art arrives",
              "`Names.KEYS` `DEF_ELECTRIC_FENCE`, a `Describe.defence` line, "
              "strings in both languages; drawn through the placeholder road "
              "(fence-style modules for the 16 masks, whole/hurt, a wreck, a "
              "3-frame zap) until A042 is integrated by 0241",
              "DATA moves (a new row); SIM moves only if the scenario meets "
              "one or a state key appears - record both numbers"],
         dod=["`_task_0230_electric_fence` in `src/tools/headless_v1.gd` "
              "asserts a walker that bites it stands still for the stun and "
              "then bites again, a short farm shortens the stun without "
              "removing it, and the field prices it like a barrier",
              "The Deliverables table of "
              "`implementation/backlog/packs/A042-electric-fence.md` states "
              "the final geometry this task settled",
              "`python tools/shot.py 0230` captures of a joined run of "
              "electric fence, opened and looked at"]),

    # Added 0226: the wall gets one `TOWER_LEVELS` row, and 0226 is where
    # `Building.why_not_upgrade` stops a short family going past its rows.
    dict(id=231, phase=P13, title="Hardwood walls and sandbags",
         slug="strong-walls", deps=[196, 177, 188, 132, 226],
         dresses=["A043"],
         files="src/core/game_data.gd, src/core/building.gd, "
               "src/core/pathing.gd, src/core/repair.gd, "
               "src/ui/world_view.gd, src/ui/names.gd, src/ui/describe.gd, "
               "assets/locale/strings.csv, src/tools/headless_v1.gd",
         goal="Two more ways to hold a line: the stone wall upgraded with "
              "hardwood into something a breaker has to work at, and sandbags "
              "from the loom as a cheap barrier that soaks more than a fence "
              "(plan sections 3.3 and 3.5).",
         req=["A `TOWER_LEVELS` row for `wall`: level 2 paid in hardwood "
              "(0177), more `hp` and `path_cost`, upgraded by cursor like a "
              "tower (0226's fix refuses a third level). "
              "`Building.entry_at` already lays a level over any id, but the "
              "field does not read it: `Pathing._through` prices an occupant "
              "from `Building.entry_of` (the base row), so `_entry_costs` "
              "must price a levelled occupant from its levelled entry, and "
              "`check_pathing` must read `TOWER_LEVELS`' `path_cost` too, so "
              "the level stays within `WIDEST_STEP`",
              "Sandbags: 0188 planned `SANDBAG` as a material (read what it "
              "actually made). A material means the barrier gets its own id "
              "(e.g. `sandbag_wall`) paid in sandbags, because `Names.KEYS` "
              "is keyed by id; if 0188 made a kit instead, it becomes the "
              "`DEFENCES` row that kit places. Its `hp` and `path_cost` "
              "LEVERs sit between the fence and the wall, and its `season` "
              "(0193's field) is decided here and confirmed by 0234. Neither "
              "has `damage`, so no `Sfx.TOWER_SOUNDS` entry",
              "A level-2 wall mends to its levelled HP (0113) and costs what "
              "that level is made of - assert it",
              "Joins: `WorldView.barrier_mask` decides who meets whom - a "
              "hardwood wall joins stone walls, sandbags join sandbags "
              "(decide whether they meet walls) - and `_barrier_name` learns "
              "the wall's level",
              "`Names.KEYS` and strings in both languages for the new id and "
              "the upgrade; drawn through the placeholder road (level-2 wall "
              "modules for the 16 masks, whole/hurt/wreck; the sandbag "
              "pieces) until A043 is integrated by 0242",
              "DATA moves (a level row, a new barrier). SIM must not move "
              "for the determinism scenario's level-1 walls; if pricing "
              "levelled occupants moves it, say why - record both numbers"],
         dod=["`_task_0231_strong_walls` in `src/tools/headless_v1.gd` asserts "
              "a level-2 wall takes the LEVER's longer to chew through and "
              "costs the field its levelled `path_cost`, a third upgrade is "
              "refused, sandbags sit between fence and wall on hit points "
              "and path cost, and repair restores the level-2 maximum",
              "The Deliverables table of "
              "`implementation/backlog/packs/A043-strong-walls.md` states the "
              "final geometry this task settled (and whether sandbags are "
              "modules or one piece)",
              "`python tools/shot.py 0231` captures of a mixed line - stone, "
              "hardwood, sandbags - opened and looked at"]),

    dict(id=232, phase=P13, title="Powers as a list", slug="powers-refactor",
         deps=[196, 135],
         files="src/core/ability.gd, src/ui/night_hud.gd, src/ui/main.gd, "
               "src/ui/world_view.gd, src/ui/pixel_effects.gd, "
               "src/tools/effect_showcase.gd, src/tools/perf_check.gd, "
               "src/tools/headless_check.gd, src/tools/input_check.gd, "
               "src/tools/headless_v1.gd, src/tools/input_v1.gd",
         goal="Nothing changes for the player. The one flare becomes the first "
              "entry of a list of powers, each with its own cooldown and aim "
              "cell, so 0233 can add three without a second copy of the "
              "cooldown and aiming code.",
         req=["`Ability` takes a power id: `ready(state, id)`, "
              "`cooldown_left(state, id)`, `charge_percent(state, id)` and "
              "`use(state, id, cell)` with the aim cell from 0135's "
              "`ability_cell` intent. The flare is the only power and behaves "
              "exactly as it does now",
              "Hashes unchanged is the bar. `state[\"ability\"]` is in "
              "`State.TABLES` and folded into SIM, so the flare keeps its "
              "keys (`cooldown`, `flare`, `flare_ticks`, `flares`) and no new "
              "state key appears until 0233 adds a power; `intent.ability` "
              "stays the flare's edge for the same reason; "
              "`GameData.ABILITY` stays byte-identical so DATA does not move",
              "If a key truly has to move, prove play identical (a scripted "
              "night with two aimed flares, before and after) and record "
              "both numbers in `implementation/PROGRESS.md`",
              "`Ability.recharge` and `Ability.put_out` work over every "
              "power; the `flare_percent` tree bonus stays the flare's",
              "Every caller moves to the new signatures - today `main.gd`, "
              "`night_hud.gd`, `world_view.gd`, `pixel_effects.gd`, "
              "`effect_showcase.gd`, `perf_check.gd`, `_task_0054` as 0135 "
              "left it and the input cases (grep `Ability.` for whatever "
              "0135-0142 added: the shot scenarios, the autoplayer) - and no "
              "flare-only path is left"],
         dod=["`_task_0232_powers_list` in `src/tools/headless_v1.gd` asserts "
              "the flare's cooldown, aim and damage through the new API match "
              "the numbers before the refactor, and an unknown power id is "
              "refused without touching the state",
              "`_case_0135_flare_aim` in `src/tools/input_v1.gd` passes with "
              "nothing changed but its calls moved to the new API"]),

    # Added 0230: the farm bell stops zombies through the entity stun
    # counter 0230 adds, so it has one owner and no "if it is not done".
    dict(id=233, phase=P13, title="Three new powers", slug="new-powers",
         deps=[232, 185, 220, 230], dresses=["A045"],
         files="src/core/ability.gd, src/core/game_data.gd, "
               "src/core/enemies.gd, src/core/repair.gd, src/ui/night_hud.gd, "
               "src/ui/names.gd, src/app/input_actions.gd, project.godot, "
               "assets/locale/strings.csv, src/tools/headless_v1.gd, "
               "src/tools/input_v1.gd",
         goal="Three more buttons for a night going wrong: the farm bell stops "
              "every zombie for two seconds, the dog runs out and bites one, "
              "and an emergency repair puts a structure back on its feet - "
              "each aimed with the cursor, each with its wait (plan section "
              "4.4).",
         req=["Power ids `farm_bell`, `call_dog` and `emergency_repair` (not "
              "`dog`, the animal of 0185), every number a LEVER in a "
              "`GameData` table beside `ABILITY`, listed in "
              "`GameData.digest()` (0112's coverage assert) and checked by "
              "`validate()` (a cooldown above zero, a node that gives each "
              "power). Their state goes inside `state[\"ability\"]` "
              "(`State.TABLES`, so reconcile fills old saves)",
              "The bell stops every zombie on the farm for 2 s (1-4) through "
              "0230's entity stun counter; decide whether bosses stop, for "
              "less or not at all",
              "The dog bites the enemy nearest the aimed cell within a radius, "
              "for a LEVER damage, after a delay worked out from its distance "
              "to the house - no RNG; its run and bite are view only",
              "The repair restores 30% (LEVER 15-50) of the aimed "
              "structure's levelled maximum (0113), free, through one "
              "`Repair` function that `apply` also uses for the cap; decide "
              "whether the house counts. A destroyed structure is rubble and "
              "cannot be aimed at",
              "Own cooldowns (LEVERs), recharged at `begin_night` like the "
              "flare. Unlocked by the tree, one per season from summer: three "
              "survival rows in `TECH_TREE` with 0220's `season` gate "
              "(summer the bell, autumn the dog, winter the repair), each "
              "giving its power, priced with 0220's arithmetic (redo it in "
              "the journal with the three added); a locked power shows "
              "greyed with its node, never hidden",
              "Aimed with the cursor through 0232's API; an input action per "
              "power in `InputActions.ACTIONS` and `project.godot` with pad "
              "bindings (0121's sync check) and `ACT_*` strings in both "
              "languages, rebindable",
              "The night dog is 0185's stand-in through the placeholder road "
              "until A028 is integrated by 0245; the power icons are "
              "placeholders until A045 is integrated by 0244",
              "`Names.KEYS`/`NOTES` for the new nodes, `POWER_*` names and "
              "notes, strings in both languages; the night HUD shows each "
              "power's charge or lock",
              "SIM and DATA move on purpose: record both"],
         dod=["`_task_0233_powers` in `src/tools/headless_v1.gd` asserts the "
              "bell holds every walker for exactly its ticks, the dog's bite "
              "lands on the enemy nearest the aimed cell after the computed "
              "delay, the repair restores the LEVER share of a levelled "
              "tower, and each power is refused before its node is bought",
              "`_case_0233_powers` in `src/tools/input_v1.gd` aims and fires "
              "each power with the mouse and with the pad",
              "The Deliverables table of "
              "`implementation/backlog/packs/A028-dog.md` states the final "
              "geometry this task settled (the night run and bite, the scale "
              "against the farmer)"]),

    # Added 0220: the season gate reuses 0220's season-reached helper and its
    # refusal key. Added 0223: this task lists the new families in 0223's
    # tarp list and settles A044 from it.
    dict(id=234, phase=P13, title="The arsenal grows with the seasons",
         slug="arsenal-by-season",
         deps=[224, 225, 226, 227, 228, 229, 230, 231, 149, 220, 223],
         dresses=["A045"],
         files="src/core/game_data.gd, src/core/building.gd, "
               "src/ui/hotbar.gd, src/ui/build_mode.gd, src/ui/night_hud.gd, "
               "src/ui/world_view.gd, src/ui/transition.gd, "
               "assets/locale/strings.csv, implementation/BALANCE.md, "
               "src/tools/headless_check.gd, src/tools/headless_v1.gd, "
               "src/tools/input_v1.gd",
         goal="The arsenal arrives with the calendar - spring's six, then "
              "summer's, autumn's and winter's - and every defence costs money "
              "as well as materials, so the day's purse is what the night is "
              "built with (plan sections 2, 5 and 7).",
         req=["The `season` field 0193 put on `DEFENCES` (default spring; "
              "0224-0231 set their own) becomes a rule, per the plan's "
              "table: spring the gun tower, crossbow, mine, fence, barricade "
              "and wall; summer the flamethrower, decoy, beehive and bait; "
              "autumn the mortar, catapult and garlic braid; winter the "
              "searchlight and electric fence. Confirm the hardwood wall "
              "level and the sandbags and say why. Gated through 0220's "
              "`Calendar.season_reached` (Year 2 keeps all), refused in "
              "`Building.why_not` with 0220's season key, shown greyed in "
              "the hotbar with its season; `validate()` refuses a `season` "
              "outside 0-3",
              "Moving the flamethrower and the mortar out of spring is a rule "
              "change: every test, tool and showcase that builds them on day "
              "1 (perf_check's worst case, `_task_0043`, `_task_0044`, the "
              "tower groups, `tower_showcase`, the autoplayer) gets a test "
              "helper that sets the calendar - never a switch in core",
              "Money in the cost (plan sections 1 and 7): each `cost` gains a "
              "money share (LEVERs). A kit pays the materials in advance and "
              "placing it still charges the money: `check_recipes` compares "
              "the kit's inputs with the cost less its money, "
              "`Building.affordable` and `why_not` ask for the money even "
              "when a kit is held (today a kit alone says yes), "
              "`Building.place` takes the money either way, and refunds "
              "follow `refund_for_cost`",
              "The hotbar of 0133 already pages or scrolls: give it a fixed "
              "order, by season then by cost, and group or page it by season "
              "if that reads better - decide; keyboard, mouse and pad still "
              "reach every slot",
              "0223's tarp list and `transition.gd`'s `WAKES` take the new "
              "families; every new defence has its hotbar icon through the "
              "placeholder road until A045 is integrated by 0244",
              "Prices argued against 0194's money per day: at the start of a "
              "season a good day buys about one new defence (plan section 5) "
              "- a table in `implementation/BALANCE.md`",
              "SIM and DATA move on purpose: record both"],
         dod=["`_task_0234_arsenal` in `src/tools/headless_v1.gd` asserts each "
              "defence is refused before its season with the season reason "
              "and placeable after, Year 2's spring keeps winter's defences, "
              "a placed kit still charges its money, and `GameData.validate()` "
              "refuses a kit whose inputs drift from the materials",
              "`_case_0234_hotbar_pages` in `src/tools/input_v1.gd` pages the "
              "hotbar and places an autumn defence in autumn",
              "The Deliverables tables of "
              "`implementation/backlog/packs/A044-tarps.md` and "
              "`implementation/backlog/packs/A045-power-weapon-icons.md` "
              "state the final geometry this task settled (the tarp families "
              "and footprints, the icon list)",
              "`python tools/shot.py 0234` captures of the hotbar in spring "
              "and in winter, opened and looked at"]),

    # ------------------------------------------------------- the art leaves
    dict(id=235, phase=P13, title="Art: bones, moon stones and essence",
         slug="art-night-loot", deps=[221, 222, 219], art=["A036"],
         files="assets/art_source/props/, assets/art_source/crops/, "
               "assets/art_source/ui/, assets/art_source/manifest.json, "
               "tools/check_prop_art.py, tools/check_crop_art.py, "
               "tools/check_ui_art.py",
         goal="The approved bones, moon stones, fertilised soil and night-loot "
              "icons go into the game in place of the stand-ins 0219, 0221 "
              "and 0222 left - essence's icon included.",
         req=[_approved_first("A036"),
              _handoff("A036"),
              _promote(["props", "crops", "ui"],
                       "`tools/check_prop_art.py` `NAMES`, "
                       "`check_crop_art.py`'s soil names, "
                       "`check_ui_art.py`"),
              "Runtime names: the bone pile and the moon stone as 16x16 "
              "props on a ground pivot (the stone's 2-frame shimmer an "
              "animation, its glow left in code); the fertilised ground dry "
              "and wet beside `tilled`/`tilled_wet` (the wet one at least 20 "
              "RGB darker, as `check_crop_art.py` holds soil to); "
              "`icon_`/`hud_` for `bones`, `bone_meal` and `moon_stone`, and "
              "the essence art as `ui/icon_tech` and `ui/hud_tech`, since "
              "the id stays `tech`",
              "`check_ui_art.py` counts the resource icons by "
              "`generation_task` (15 plans, 30 entries today, `tech` among "
              "them): extend it to the pack's entries rather than loosening "
              "the count, and move `tech` out of task 0018's set on purpose "
              "(the plan list and the count, with the reason) since the "
              "essence icon replaces it",
              "Retire the stand-ins of 0219, 0221 and 0222 from 0120's "
              "placeholder registry, so its check no longer lists A036",
              _integrated("A036")],
         dod=_leaf_dod(235, "`check_prop_art.py`, `check_crop_art.py`, "
                       "`check_ui_art.py`",
                       ["--props --check", "--crops --check", "--ui --check"],
                       "bone piles, a moon stone, a fertilised plot and the "
                       "essence counter")),

    dict(id=236, phase=P13,
         title="Art: the scarecrow decoy and zombie bait",
         slug="art-decoy", deps=[224, 225], art=["A037"],
         files="assets/art_source/defences/, assets/art_source/ui/, "
               "assets/art_source/manifest.json, tools/check_barrier_art.py, "
               "tools/check_ui_art.py, tools/verify.py",
         goal="The approved straw decoy and rotten-fish bait replace the "
              "stand-ins 0224 and 0225 left.",
         req=[_approved_first("A037"),
              _handoff("A037"),
              _promote(["defences", "ui"],
                       "`tools/check_barrier_art.py`, `check_ui_art.py`"),
              "Runtime names follow the one-cell pieces: `buildings/decoy`, "
              "`_hurt` and `_wreck` at 16x32 on the ground pivot, the hit "
              "sway (2-3 frames) as a short one-shot the view plays when it "
              "is struck; the bait on the ground at 16x16 like the mine; "
              "`icon_`/`hud_` for the bait kit",
              "`check_barrier_art.py` counts task 0014's 84 entries and "
              "checks the mine's single pieces: extend it for the pack's "
              "entries, or add a `check_decoy_art.py` wired into "
              "`tools/verify.py` if the shape does not fit",
              "Retire the stand-ins of 0224 and 0225 from 0120's placeholder "
              "registry; if 0223/0234 gave the decoy a tarp, check it still "
              "unveils",
              _integrated("A037")],
         dod=_leaf_dod(236, "`check_barrier_art.py`, `check_ui_art.py`",
                       ["--barriers --check", "--ui --check"],
                       "a decoy whole, hurt and struck, and a bait on the "
                       "ground")),

    dict(id=237, phase=P13, title="Art: the beehive", slug="art-beehive",
         deps=[226], art=["A038"],
         files="assets/art_source/defences/, assets/art_source/effects/, "
               "assets/art_source/manifest.json, tools/check_tower_art.py, "
               "tools/check_effect_art.py, tools/import_art.py",
         goal="The approved beehive and its bees replace the stand-ins 0226 "
              "left.",
         req=[_approved_first("A038"),
              _handoff("A038"),
              _promote(["defences", "effects"],
                       "`tools/check_tower_art.py` `FAMILIES`, "
                       "`check_effect_art.py`"),
              "`buildings/beehive` and `beehive_2` x {'', `_hurt`, `_fire`, "
              "`_wreck`} at 32x48, pivot (16,44), one scale per level. "
              "`check_tower_art.py` loops levels 1-3 for every family, "
              "accepts only `generation_task` 0013 and demands a "
              "`muzzle_xy` on every non-wreck state: make the level count "
              "and the metadata point per family (the hive's own point, "
              "where the swarm leaves, or none - as the pack's contract "
              "says) and accept the pack. Keep "
              "`gen_sprites.migrated_towers()` to the four legacy families "
              "(the checker compares it with `FAMILIES`). `import_art.py` "
              "writes `\"tower\": true` only for 0013 - extend it",
              "The bee swarm (8x8, 3 frames) loops while a hive stings: a "
              "looping effect, which `check_effect_art.py` (one-shots only) "
              "has to be taught deliberately",
              "Retire 0226's stand-ins from 0120's placeholder registry",
              _integrated("A038")],
         dod=_leaf_dod(237, "`check_tower_art.py`, `check_effect_art.py`",
                       ["--towers --check", "--effects --check"],
                       "a hive at each level stinging a crowd")),

    dict(id=238, phase=P13, title="Art: the pumpkin catapult",
         slug="art-catapult", deps=[227], art=["A039"],
         files="assets/art_source/defences/, assets/art_source/effects/, "
               "assets/art_source/manifest.json, tools/check_tower_art.py, "
               "tools/check_effect_art.py, tools/import_art.py",
         goal="The approved catapult, its pumpkin and its splat replace the "
              "stand-ins 0227 left.",
         req=[_approved_first("A039"),
              _handoff("A039"),
              _promote(["defences", "effects"],
                       "`tools/check_tower_art.py` `FAMILIES`, "
                       "`check_effect_art.py`"),
              "`buildings/catapult`, `catapult_2` and `catapult_3` x the four "
              "states at 32x48 with `muzzle_xy`/`muzzles_xy` on opaque "
              "pixels; the `tower` metadata in `import_art.py` for this pack; "
              "the per-family checks 0237 made in `check_tower_art.py` (if "
              "0237 has not landed, make them here), with "
              "`gen_sprites.migrated_towers()` still the four legacy "
              "families",
              "The pumpkin shot (8x8) drawn where the view draws a mortar "
              "shell, and the splat (4 frames, one-shot) as an effect family "
              "in `check_effect_art.py` - its own checked block, leaving task "
              "0017's count of 25 frames alone",
              "Retire 0227's stand-ins from 0120's placeholder registry",
              _integrated("A039")],
         dod=_leaf_dod(238, "`check_tower_art.py`, `check_effect_art.py`",
                       ["--towers --check", "--effects --check"],
                       "each level firing and a pumpkin landing")),

    dict(id=239, phase=P13, title="Art: the garlic braid", slug="art-garlic",
         deps=[228], art=["A040"],
         files="assets/art_source/defences/, assets/art_source/manifest.json, "
               "tools/check_barrier_art.py, tools/verify.py",
         goal="The approved garlic braid, fresh, wilted and spent, replaces "
              "the stand-in 0228 left.",
         req=[_approved_first("A040"),
              _handoff("A040"),
              _promote(["defences"], "`tools/check_barrier_art.py`"),
              "`buildings/garlic_braid`, `_wilted` and `_spent` at 16x24 on "
              "the barricade's ground pivot; the wear state 0228 keeps on the "
              "occupant picks the frame",
              "Extend `check_barrier_art.py`'s single-piece checks (or a "
              "family checker wired into `tools/verify.py`) for the three "
              "states",
              "Retire 0228's stand-in from 0120's placeholder registry",
              _integrated("A040")],
         dod=_leaf_dod(239, "`check_barrier_art.py`", ["--barriers --check"],
                       "braids fresh, wilted and spent beside a route")),

    dict(id=240, phase=P13, title="Art: the searchlight",
         slug="art-searchlight", deps=[229], art=["A041"],
         files="assets/art_source/defences/, assets/art_source/manifest.json, "
               "tools/check_tower_art.py, tools/import_art.py",
         goal="The approved searchlight replaces the stand-in 0229 left, and "
              "its beam starts from the lamp the art draws.",
         req=[_approved_first("A041"),
              _handoff("A041"),
              _promote(["defences"], "`tools/check_tower_art.py` `FAMILIES`"),
              "`buildings/searchlight` and `searchlight_2` x the four states "
              "at 32x48 with a `light_xy` point on an opaque pixel in place "
              "of the muzzle `check_tower_art.py` demands of a gun; the "
              "per-family level count, metadata point and `tower` metadata "
              "as 0237 left them (make them here if it has not landed), "
              "`gen_sprites.migrated_towers()` still the four legacy "
              "families",
              "The beam stays code and starts from `light_xy`; what is lit "
              "is still `Light.is_lit` (0229), never the sprite",
              "Retire 0229's stand-in from 0120's placeholder registry",
              _integrated("A041")],
         dod=_leaf_dod(240, "`check_tower_art.py`", ["--towers --check"],
                       "searchlights at both levels lighting a tower line")),

    dict(id=241, phase=P13, title="Art: the electric fence",
         slug="art-electric-fence", deps=[230], art=["A042"],
         files="assets/art_source/defences/, assets/art_source/effects/, "
               "assets/art_source/manifest.json, tools/check_barrier_art.py, "
               "tools/check_effect_art.py",
         goal="The approved electric fence, joined on all sixteen masks, and "
              "its zap replace the stand-ins 0230 left.",
         req=[_approved_first("A042"),
              _handoff("A042"),
              _promote(["defences", "effects"],
                       "`tools/check_barrier_art.py`, `check_effect_art.py`"),
              "Source modules `buildings/modules/electric_fence_{post,"
              "horizontal,vertical}` (and `_hurt`) composed into "
              "`electric_fence_join_<mask>` for the 16 N1/E2/S4/W8 masks and "
              "`_hurt`, plus `_wreck`, at 16x32 / (8,28) like the fence. "
              "`check_barrier_art.py` checks `('wall', 'fence')` and 84 "
              "entries of task 0014: add the family and its count",
              "`WorldView.connected_barrier` reads the `connected` flag the "
              "importer writes from `join_mask`, so the joined art replaces "
              "0230's placeholder joins with no view change - check it. The "
              "zap (3 frames, one-shot) is an effect family played when the "
              "stun lands, its own checked block in `check_effect_art.py` "
              "beside task 0017's 25 frames",
              "Retire 0230's stand-ins from 0120's placeholder registry",
              _integrated("A042")],
         dod=_leaf_dod(241, "`check_barrier_art.py`, `check_effect_art.py`",
                       ["--barriers --check", "--effects --check"],
                       "a joined run of electric fence zapping a biter")),

    dict(id=242, phase=P13, title="Art: hardwood walls and sandbags",
         slug="art-strong-walls", deps=[231], art=["A043"],
         files="assets/art_source/defences/, assets/art_source/manifest.json, "
               "tools/check_barrier_art.py",
         goal="The approved hardwood wall and sandbags replace the stand-ins "
              "0231 left.",
         req=[_approved_first("A043"),
              _handoff("A043"),
              _promote(["defences"], "`tools/check_barrier_art.py`"),
              "The level-2 wall's modules composed into its join names (the "
              "naming 0231 gave `_barrier_name`) for the 16 masks, "
              "whole/hurt, plus a wreck; the sandbags as modules or one "
              "piece, as 0231 settled, whole/hurt/wreck",
              "Extend `check_barrier_art.py` with both families and their "
              "counts rather than loosening the 84",
              "Retire 0231's stand-ins from 0120's placeholder registry",
              _integrated("A043")],
         dod=_leaf_dod(242, "`check_barrier_art.py`", ["--barriers --check"],
                       "a mixed line of stone, hardwood and sandbags")),

    dict(id=243, phase=P13, title="Art: the day tarps", slug="art-tarps",
         deps=[223, 234], art=["A044"],
         files="assets/art_source/defences/, assets/art_source/manifest.json, "
               "src/ui/world_view.gd, tools/verify.py",
         goal="The approved tarps cover the defences by day and unveil at "
              "nightfall, in place of the code-drawn covers 0223 left.",
         req=[_approved_first("A044"),
              _handoff("A044"),
              _promote(["defences"],
                       "a tarp checker such as `tools/check_tarp_art.py` "
                       "wired into `tools/verify.py`, or the tower and "
                       "barrier checkers"),
              "One cover per footprint 0234 settled (32x48 towers, 16x32, "
              "16x24) plus its 2 unveil frames; the family list comes from "
              "the pack's Deliverables table, and the unveil plays in the "
              "transition's wake pass",
              "A hurt or wrecked defence still reads by day the way 0223 "
              "decided",
              "Retire 0223's code-drawn covers from 0120's placeholder "
              "registry",
              _integrated("A044")],
         dod=_leaf_dod(243, "the tarp checks - the new checker, or the "
                       "tower and barrier checkers that took them",
                       ["--towers --check", "--barriers --check"],
                       "covered defences of every footprint and their unveil "
                       "at nightfall")),

    dict(id=244, phase=P13, title="Art: power and new weapon icons",
         slug="art-power-icons", deps=[233, 234], art=["A045"],
         files="assets/art_source/ui/, assets/art_source/manifest.json, "
               "tools/check_ui_art.py",
         goal="The approved icons of the three powers and the nine new "
              "defences replace the hotbar and HUD stand-ins 0233 and 0234 "
              "left.",
         req=[_approved_first("A045"),
              _handoff("A045"),
              _promote(["ui"], "`tools/check_ui_art.py`"),
              "`ui/icon_*` (16x16) and `ui/hud_*` (10x10) cut from one source "
              "each, as the resource icons are, for `farm_bell`, `call_dog`, "
              "`emergency_repair` and the decoy, zombie bait, beehive, "
              "catapult, garlic braid, searchlight, electric fence, hardwood "
              "wall and sandbags (the ids 0231 and 0233 chose)",
              "The hotbar and the night HUD read them by id; extend "
              "`check_ui_art.py`'s counts for the pack",
              "Retire the icon stand-ins of 0233 and 0234 from 0120's "
              "placeholder registry",
              _integrated("A045")],
         dod=_leaf_dod(244, "`check_ui_art.py`", ["--ui --check"],
                       "the hotbar and the power bar")),

    dict(id=245, phase=P13, title="Art: the dog", slug="art-dog",
         deps=[185, 233], art=["A028"],
         files="assets/art_source/props/, assets/art_source/manifest.json, "
               "tools/check_prop_art.py, src/ui/art_placement.gd",
         goal="The approved farm dog replaces the stand-ins of 0185 by day "
              "and of 0233's call-the-dog power at night.",
         req=[_approved_first("A028"),
              _handoff("A028"),
              _promote(["props"], "`tools/check_prop_art.py` `NAMES` and its "
                       "animal canvas rule"),
              "The dog as an animal like the cow and the chicken (24x24 / "
              "(12,22) unless the pack's contract says otherwise - read it): "
              "day sit, wag, follow-walk (4) and bark (2-3); night run (4) "
              "and bite (3); side view mirrored at runtime like the enemies "
              "unless the contract bakes directions",
              "The pet's states of 0185 and the power's run and bite of 0233 "
              "pick their frames; retire both stand-ins from 0120's "
              "placeholder registry",
              _integrated("A028")],
         dod=_leaf_dod(245, "`check_prop_art.py`", ["--props --check"],
                       "the dog following the farmer and the dog called at "
                       "night")),
]
