# -*- coding: utf-8 -*-
"""Backlog part 10: the enemies and bosses of the year.

Phase 5 of the plan: six new enemies, three new bosses and the night events
(fog, rain, the Blood Moon), each asking the arsenal of phase 13 for a
different answer. It sits after the weapons, so every enemy has a counter to
be measured against, and before the fifty-six nights (0270), so the night
authors have every piece and the matchup report of 0259 in hand.
"""

P14 = "14 - Enemies and bosses"

TASKS = [
    # ============================================ phase 14 - enemies and bosses
    dict(id=246, phase=P14, title="Bosses in general", slug="bosses-general",
         deps=[153, 196],
         files="src/core/combat.gd, src/ui/night_hud.gd, src/ui/log_panel.gd, "
               "src/ui/enemy_motion.gd, src/ui/enemy_deaths.gd, "
               "src/ui/pixel_effects.gd, src/ui/world_view.gd, src/ui/sfx.gd, "
               "assets/locale/strings.csv, tools/check_giant_art.py, "
               "tools/show_art.py, src/tools/giant_showcase.gd, "
               "src/tools/shot.gd, src/tools/headless_check.gd, "
               "src/tools/headless_v1.gd, src/tools/input_v1.gd",
         goal="Three more bosses are coming, and everything that knows about a "
              "boss today knows about the Giant by name. Make the bar, the "
              "counters, the arrival line, the sounds and the art checks work "
              "for anything with `is_boss`, so 0253-0255 are a data entry and "
              "a behaviour each.",
         req=["`Combat.boss_here` stays the lowest-id boss on the farm; add "
              "`Combat.bosses_here(state)` (sorted ids) and "
              "`Combat.full_hp(state, id)` (the table's `hp` today), so the "
              "boss bar (`NightHud._refresh_boss` reads "
              "`ENEMIES[kind][\"hp\"]` today) reads a body's full health from "
              "the one place 0257's "
              "elites will change; `Describe.enemy` describes a kind and keeps "
              "the table's number",
              "Per-boss counters without a new State key: "
              "`Combat.bosses_down_of(state, kind)` reads "
              "`killed_by_kind_all_run` (RUN_DATA) for `is_boss` kinds; "
              "`bosses_down` stays the run total `Run` reports. Raising "
              "`boss_arrived` for any `is_boss` is 0153's, not this task's",
              "The night HUD's boss bar (`NightHud._refresh_boss`, or wherever "
              "0139 moved it) names whichever boss is up, adds `x2` when more "
              "than one is alive (Endless already sends two Giants) and keeps "
              "the wind-up flash for any boss with `telegraph_ticks`",
              "A boss intro line: `LOG_BOSS` ('the giant is coming') becomes "
              "one literal key per boss in a const map in the view "
              "(`BOSS_INTRO_GIANT` first; key,width,en,pt_BR rows in "
              "`assets/locale/strings.csv`), shown as a banner on "
              "`boss_arrived` and as the log line; delete the `LOG_BOSS` row, "
              "since `tools/i18n_check.py` fails on unused keys",
              "View hard-codes on the Giant's id become boss-generic where "
              "the art follows the Giant's pose names (`EnemyMotion.TRACKED` "
              "and `_giant_pose`, the five death frames in `EnemyDeaths`, the "
              "impact offset in `PixelEffects`, the `giant_windup_` test in "
              "`WorldView`): a boss with no authored poses falls back to the "
              "ordinary path, and the Giant draws exactly as before. `Sfx` "
              "too: `_watch_bodies` announces any `is_boss` on arrival with "
              "no position, `nearest_by_kind` leaves every boss out and "
              "`_ducks` ducks for any boss voice - so 0253-0255 borrow "
              "`sfx/roar_giant` in `ENEMY_SOUNDS` until 0284 voices them",
              "`tools/check_giant_art.py` becomes table-driven (family -> "
              "motion counts, canvas, pivot, generation task; only the Giant "
              "today) and its exact `migrated_enemies() == {five}` becomes a "
              "subset check, so a new enemy family cannot fail it; "
              "`giant_showcase.gd` takes the family and `tools/show_art.py` "
              "routes a new `--boss=<family>` to it (`--giant` unchanged) for "
              "the leaves 0266-0268",
              "Rewrite `_task_0058_giant`'s 'the only boss in the table' and "
              "'outlasts every other enemy' asserts as every boss against "
              "every non-boss (hp, armour, walking `ticks_per_tile`), because "
              "0247-0255 add both kinds",
              "Hashes unchanged: helpers, view and tests only"],
         dod=["`_task_0246_bosses` in `src/tools/headless_v1.gd`: two Giants "
              "on the farm give `bosses_here` both ids in order; killing one "
              "moves `bosses_down_of(state, &\"giant\")` and `bosses_down` by "
              "one each; every `is_boss` entry has an intro key in the map "
              "and in the strings table",
              "`_case_0246_boss_bar` in `src/tools/input_v1.gd`: a spawned "
              "Giant raises the bar and the banner, `Sfx.nearest_by_kind()` "
              "has no entry for it, and the bar goes when it dies",
              "`python tools/check_giant_art.py` and "
              "`python tools/show_art.py --giant --check` pass and report the "
              "Giant as before",
              "`python tools/shot.py 0246 boss` (a new scenario: a Giant "
              "winding up) opened and looked at: bar, name and banner overlap "
              "neither the hotbar nor the time to dawn"]),

    dict(id=247, phase=P14, title="The spitter", slug="spitter",
         deps=[218, 132], dresses=["A046"],
         files="src/core/enemies.gd, src/core/game_data.gd, "
               "src/ui/world_view.gd, src/ui/describe.gd, src/ui/names.gd, "
               "src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, "
               "src/tools/headless_check.gd, src/tools/input_check.gd, "
               "src/tools/headless_v1.gd",
         goal="The first enemy that hurts what you built without touching it: "
              "it stops at range and spits at a tower. A tower line in the "
              "open becomes something to cover, not only something to build.",
         req=["`ENEMIES.spitter` with `# LEVER`s: hp, `ticks_per_tile`, damage "
              "to the house, reward, `spit_range` (tiles, 3-5), "
              "`spit_damage` (to a structure), `spit_every_ticks`, "
              "`spit_tiles_per_second`; `check_enemies` refuses a spit range "
              "of zero or one that reaches as far as the gun tower's base "
              "`range` (5), so a tower can always answer it. Keep it inside "
              "`_task_0051_tank`'s non-boss bounds (less hp and armour than "
              "the tank, faster than it) and `_task_0058_giant`'s",
              "In `Enemies._walk`: with a tower (a DEFENCES entry with "
              "`reload_ticks`) within `spit_range` - Chebyshev, nearest first, "
              "ties by the lower cell index - it stands and spits; with none "
              "it walks the flow field and bites like a walker",
              "Enemy projectiles are new and kept apart from the towers' "
              "`projectiles`, which `Combat.incoming` and `worth_shooting` "
              "read: a top-level `enemy_shots` Array (only Dictionaries need a "
              "TABLES/RUN_DATA line), integer positions, aimed at a cell when "
              "fired, landing through `Farm.damage` after its flight",
              "Advance them inside `Enemies.tick` so `PerfNames.NIGHT` stays "
              "true; if a new `X.tick` goes into `Sim._tick_night` instead, "
              "add it to `src/tools/perf_names.gd` and `perf_check.gd` in "
              "this task",
              "`Enemies.withdraw` clears `enemy_shots` at dawn; a spit landing "
              "on an empty cell does nothing; a tower it destroys leaves "
              "rubble and a `structure_lost` event like a bite",
              "Names.KEYS `spitter`, rows `ENEMY_SPITTER` and "
              "`ENEMY_SPITTER.other` (spitter/spitters, cuspidor/cuspidores) "
              "and a `Describe.enemy` line `DESC_SPITS` ('spits at towers "
              "from %d tiles' / 'cospe nas torres a %d ladrilhos'); "
              "`Sfx.ENEMY_SOUNDS.spitter` borrows the nearest generated voice "
              "(`sfx/groan_walker`) so `_task_0085_night_sounds` passes, until "
              "0284 gives it its own",
              "On screen through 0120's placeholder road: the spitter at "
              "64x48 pivot (32,44), the spit in flight (8x8) and a code-drawn "
              "splat, plus its forecast head - placeholders until A046 is "
              "integrated by 0260",
              "The first kind past the MVP's five breaks the art groups that "
              "count `ENEMIES`: rewrite in place `_task_0074_zombie_art` "
              "(`kinds.size() == 5`, a file per pose, the silhouette and "
              "biggest-Giant tests) and `_task_0088_juice` (a death body per "
              "kind) to check the kinds with raster art, leaving stand-ins to "
              "0120's `_task_0120_placeholders`; `_case_0074_zombie_art` in "
              "`input_check.gd` counts a stand-in through 0120's lookup as "
              "drawn. If `_task_0059_wave_data` still wants every `ENEMIES` "
              "kind in the authored nights, exempt the kinds no night sends "
              "yet in one named list (0270-0274 put them in the year). Later "
              "enemy tasks only add to what this leaves",
              "Hashes: DATA moves (a new ENEMIES entry); SIM moves once, "
              "because the state gains `enemy_shots` - nothing else in the "
              "determinism scenario may change, and the journal says so"],
         dod=["`_task_0247_spitter` in `src/tools/headless_v1.gd`: with a gun "
              "tower inside `spit_range` it stops and lands `spit_damage` "
              "every `spit_every_ticks` (measured); with none it walks to the "
              "house; two runs of one seed land the same spits on the same "
              "ticks; nothing is left in `enemy_shots` after dawn",
              "The same group: a tower whose reach covers it kills it before "
              "losing the tower, and a tower that cannot reach it is worn "
              "down - print both numbers",
              "`python tools/shot.py 0247 spitter` (a new scenario: a spitter "
              "working on a tower line) opened and looked at; the rewritten "
              "`_task_0074_zombie_art`, `_task_0088_juice` and "
              "`_case_0074_zombie_art` pass with the spitter on its stand-in",
              "the Deliverables table of "
              "`implementation/backlog/packs/A046-spitter.md` states the final "
              "geometry this task settled"]),

    dict(id=248, phase=P14, title="The rat swarm", slug="rat-swarm",
         deps=[218, 132], dresses=["A047"],
         files="src/core/game_data.gd, src/core/waves.gd, "
               "src/core/enemies.gd, src/tools/perf_check.gd, "
               "tools/perf_baseline.txt, src/ui/names.gd, src/ui/describe.gd, "
               "src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, "
               "src/tools/headless_v1.gd",
         goal="A crowd of small fast bodies that a single-target tower wastes "
              "shots on and a mine or a flame cone eats. It is also the perf "
              "case the groundwork of 0218 was built for.",
         req=["`ENEMIES.rat` with `# LEVER`s: hp 2-6, `ticks_per_tile` "
              "10-14, damage 1-2, reward 1, armour 0, `cluster` (rats per "
              "spawn, 4-10; `check_enemies` refuses a `cluster` below 1); a "
              "swarm must not out-earn a day - check the night's bounty "
              "against 0219's levers",
              "`check_enemies` wants every `ignores_structures` kind faster "
              "than the fastest kind that stops for walls (the runner, 9 "
              "ticks a tile): a rat that stops for walls at 9 or less would "
              "fail the runner, so keep it at 10-14 or make it go round like "
              "one - decide, and never weaken the check to pass",
              "Clusters: a wave record still counts bodies, so the forecast "
              "and `Waves.size_of` stay true; `Waves.tick` releases up to "
              "`cluster` per `SPAWN_INTERVAL_TICKS`, the first on a cell from "
              "the run RNG as today (`Enemies.spawn`) and the rest through "
              "`Entities.spawn` on that cell's walkable, reachable neighbours "
              "in `Enemies.NEIGHBOURS` order (four of them), then back round "
              "onto the same cells - bodies may share a cell, as they already "
              "can - with no extra draws",
              "Mines and fire are the answer by construction: a gun tower "
              "overkills a rat, a mine's splash and the flamethrower cone "
              "take many. Put the cost per rat killed for the gun tower, the "
              "crossbow, the mine and the flamethrower in the journal",
              "Perf through 0218's caches: 0218's swarm scenario in "
              "`src/tools/perf_check.gd` swaps its walker stand-ins for rats "
              "(a few hundred alive); its `swarm_tick`, `swarm_towers` and "
              "`swarm_enemies` lines stay inside `TICK_BUDGET_US` (8333 us); "
              "a moved baseline is accepted (`python tools/perf.py --accept`) "
              "only with the journal saying why",
              "Names.KEYS `rat`, `ENEMY_RAT`/`ENEMY_RAT.other` (rat/rats, "
              "rato/ratos), and `DESC_SWARMS` ('comes %d at a time' / 'chega "
              "%d de cada vez') in `Describe.enemy`; "
              "`Sfx.ENEMY_SOUNDS.rat` borrows `sfx/groan_runner` until 0284",
              "Drawn through 0120's placeholder road at the pack's small "
              "canvas (~24x16), forecast head included - placeholders until "
              "A047 is integrated by 0261",
              "Hashes: DATA moves; SIM should not (no rats in the determinism "
              "night) - if it does, find out why before accepting"],
         dod=["`_task_0248_rats` in `src/tools/headless_v1.gd`: one wave "
              "member releases `cluster` rats on adjacent cells on one tick, "
              "the bodies sent match `Waves.size_of`, and a mine under the "
              "cluster kills more rats per unit of cost than a gun tower in "
              "the same lane",
              "`python tools/perf.py --report` prints the swarm lines with "
              "rats inside `TICK_BUDGET_US` and every other line inside its "
              "tolerance",
              "`python tools/shot.py 0248 rats` (a new scenario) opened and "
              "looked at: a cluster reads as a crowd, not a smear",
              "the Deliverables table of "
              "`implementation/backlog/packs/A047-rats.md` states the final "
              "geometry this task settled"]),

    # Added 0233, 0234: the crow decides `hits_flying` for every defence and
    # power, so the whole arsenal (0224-0231 through 0234) and the three new
    # powers must exist when it runs.
    dict(id=249, phase=P14, title="The crow", slug="crow",
         deps=[218, 168, 233, 234], dresses=["A048"],
         files="src/core/enemies.gd, src/core/traps.gd, src/core/towers.gd, "
               "src/core/farming.gd, src/core/events.gd, "
               "src/core/game_data.gd, src/ui/world_view.gd, "
               "src/ui/log_panel.gd, src/ui/names.gd, src/ui/describe.gd, "
               "src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, "
               "src/tools/headless_v1.gd",
         goal="The first thing that does not walk: it flies over walls and "
              "mines and lands to eat the field. Defending the farm stops "
              "being only about the house and starts being about the harvest.",
         req=["`ENEMIES.crow` with `# LEVER`s (hp, `ticks_per_tile` in "
              "flight, damage, reward, `peck_ticks` to eat one crop) and a "
              "`flies` flag; `check_enemies`: a flyer declares neither "
              "`ignores_structures` nor `targets_structures` and is left out "
              "of the 'fastest kind that stops' comparison (a fast crow "
              "counted there would fail the runner). Inside "
              "`_task_0051_tank`'s non-boss bounds",
              "Straight flight, no sweep: it heads for the nearest plot with "
              "a crop in `state[\"plots\"]` (Manhattan, ties by the lower cell "
              "index) one unit at a time along the dominant axis, like "
              "`_walk`'s inner loop, ignoring walls and occupants; with no "
              "crop on the farm it flies at the house and bites",
              "Landed, it waits `peck_ticks`, then the crop is eaten through a "
              "`Farming` helper (the plot stays tilled and loses crop and "
              "growth - reuse 0155's trampling path if it fits) and it takes "
              "off for the next one; a new `Events.KINDS` entry `crop_eaten` "
              "with a `LogPanel.SEVERITY` entry and a `line_for` branch "
              "(`LOG_CROP_EATEN`, 'a crow ate the %s' / 'um corvo comeu %s')",
              "Barriers and mines never see it: `Traps.tick` skips flyers, "
              "and it never reaches `_gnaw` or the fields; it moves inside "
              "`Enemies.tick`, so `PerfNames` is unchanged",
              "Which defences hit it is data: a `hits_flying` flag on every "
              "DEFENCES entry with `reload_ticks` (0224-0231's included), "
              "refused by `check_defences` when missing so any later defence "
              "must choose; `Towers._acquire`, `_burn_cone`, `_pierce_line` "
              "and splash landings (`_land_at`) skip flyers otherwise. Decide "
              "the powers too (the flare and 0233's bell and dog) and whether "
              "a landed crow counts as on the ground; the table and the "
              "reasons go in the journal",
              "Names.KEYS `crow`, `ENEMY_CROW`/`ENEMY_CROW.other` "
              "(crow/crows, corvo/corvos); `DESC_FLIES` in `Describe.enemy`; "
              "`Sfx.ENEMY_SOUNDS.crow` borrows `sfx/groan_runner` until 0284",
              "On screen: drawn above its cell with a code-drawn shadow on the "
              "ground (the pack's flying exception), through 0120's "
              "placeholder road with its forecast head until A048 is "
              "integrated by 0262",
              "Hashes: DATA moves (ENEMIES and the DEFENCES flags); SIM "
              "should not"],
         dod=["`_task_0249_crow` in `src/tools/headless_v1.gd`: a crow "
              "spawned behind a wall line reaches a planted plot in the "
              "straight-line tick count, eats it after `peck_ticks`, crosses "
              "a mine without setting it off, and is acquired only by "
              "`hits_flying` towers",
              "With nothing planted it reaches the house and bites, so an "
              "empty field never softlocks a night",
              "`python tools/shot.py 0249 crow` (a new scenario) opened and "
              "looked at: in flight it reads as above the wall, landed as on "
              "the field",
              "the Deliverables table of "
              "`implementation/backlog/packs/A048-crow.md` states the final "
              "geometry this task settled"]),

    # Added 0234: every barrier must declare `burrowable`, so 0230's electric
    # fence and 0231's sandbags (both reached through 0234) must exist when
    # it runs.
    dict(id=250, phase=P14, title="The digger", slug="digger",
         deps=[218, 234], dresses=["A049"],
         files="src/core/pathing.gd, src/core/enemies.gd, "
               "src/core/towers.gd, src/core/game_data.gd, "
               "src/ui/world_view.gd, src/ui/names.gd, src/ui/describe.gd, "
               "src/ui/sfx.gd, assets/locale/strings.csv, "
               "src/tools/perf_check.gd, tools/perf_baseline.txt, "
               "src/tools/shot.gd, src/tools/headless_v1.gd",
         goal="The enemy that makes a fence a different thing from a wall: it "
              "tunnels under fences and barricades and comes up on the other "
              "side. Only a real wall stops it.",
         req=["`ENEMIES.digger` with `# LEVER`s (hp, `ticks_per_tile` slower "
              "than the runner's 9 so `check_enemies` holds, damage, reward, "
              "armour) and a `burrows` flag; inside `_task_0051_tank`'s "
              "non-boss bounds",
              "A burrow field through 0218's named-field registry, built on "
              "first request by a digger, so a night without one never builds "
              "it: a barrier flagged `burrowable` costs only the ground under "
              "it (`Pathing._through` and `_entry_costs`), everything else as "
              "in the flow field",
              "`check_defences` makes every barrier (`path_cost` > 0) declare "
              "`burrowable`: fence and barricade yes, wall no (0231's hardwood "
              "wall is the wall's `TOWER_LEVELS` row and inherits it); 0231's "
              "sandbag barrier, 0230's electric fence and anything else with "
              "a `path_cost` decided and written in the journal",
              "On a `burrowable` barrier's cell it is underground: in "
              "`Enemies._walk` it passes instead of `_gnaw`ing, "
              "`Towers._acquire` (0218's bucketed version) cannot target it "
              "and the barrier loses nothing; on open ground it surfaces, and "
              "walls and the house are gnawed and bitten as a walker does "
              "(`_gnaw`, `_bite`)",
              "The tie-breaks of `Grid.STEPS` and 0049's rule hold: a digger "
              "never alternates between two cells for 20 ticks",
              "A digger case in `src/tools/perf_check.gd` (its own `PERF` "
              "line, fifty walls and fences, the burrow field built): its "
              "path rebuild stays inside `PATH_BUDGET_US` (33333 us) in "
              "`python tools/perf.py --report`, the baseline accepted with "
              "the reason in the journal",
              "Names.KEYS `digger`, `ENEMY_DIGGER`/`ENEMY_DIGGER.other` "
              "(digger/diggers, escavador/escavadores); `DESC_BURROWS` "
              "('digs under fences' / 'cava por baixo das cercas'); "
              "`Sfx.ENEMY_SOUNDS.digger` borrows `sfx/groan_breaker` until "
              "0284",
              "On screen through 0120's placeholder road: a tinted stand-in, "
              "a code-drawn mound while underground and its forecast head, "
              "until A049 is integrated by 0263",
              "Hashes: DATA moves; SIM should not (no digger in the "
              "determinism night, so no field is built)"],
         dod=["`_task_0250_digger` in `src/tools/headless_v1.gd`: a digger "
              "reaches the house through a ring of fences without a fence "
              "losing a hit point, a ring of walls makes it gnaw, and a tower "
              "cannot target it while it is under a fence",
              "The same group asserts the burrow field is never built on a "
              "night without a digger",
              "`python tools/shot.py 0250 digger` (a new scenario) opened and "
              "looked at: the mound reads as under the fence",
              "the Deliverables table of "
              "`implementation/backlog/packs/A049-digger.md` states the final "
              "geometry this task settled"]),

    dict(id=251, phase=P14, title="The frost zombie", slug="frost-zombie",
         deps=[218], dresses=["A050"],
         files="src/core/combat.gd, src/core/towers.gd, "
               "src/core/enemies.gd, src/core/game_data.gd, "
               "src/ui/world_view.gd, src/ui/names.gd, src/ui/describe.gd, "
               "src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, "
               "src/tools/headless_v1.gd",
         goal="An enemy whose death is the attack: it bursts into ice and the "
              "towers near it reload slowly for a while. Killing it right "
              "under the line now costs something.",
         req=["`ENEMIES.frost_zombie` with `# LEVER`s (hp, `ticks_per_tile`, "
              "damage, reward, armour; inside `_task_0051_tank`'s non-boss "
              "bounds) plus `chill_tiles` (radius, 1-3), `chill_ticks` and "
              "`chill_reload_percent` (reload speed while chilled, 25-75: "
              "fifty is twice as slow); `check_enemies` refuses a chill field "
              "of zero or a percent outside 1-99",
              "The hook is `Combat._kill`: every tower within `chill_tiles` "
              "(Chebyshev, from `Towers`' cached tower cells, sorted) gets a "
              "countdown on its occupant dictionary (`tower[\"chill\"]`) - "
              "never through `Farm.touch`, so `grid_version` and every field "
              "stay put",
              "Refreshed, never stacked (the `Combat.set_alight` rule); "
              "`Towers.tick` and `_cool_down` count it down; while it lasts "
              "the reload set after a shot is scaled by "
              "`chill_reload_percent` in integers",
              "No chill outlives the night: cleared in `Enemies.withdraw`, "
              "which `Phases.begin_day` already calls; a save made mid-night "
              "keeps it, since occupants are RUN_DATA",
              "`Towers.chill_left(state, cell)` for the view and for the "
              "Winter Lord, whose freeze (0255) sits beside this chill",
              "Names.KEYS `frost_zombie`, `ENEMY_FROST_ZOMBIE`/`.other` "
              "(frost zombie/frost zombies, zumbi de gelo/zumbis de gelo); "
              "`DESC_CHILLS` ('slows towers when it dies' / 'deixa as torres "
              "lentas ao morrer'); `Sfx.ENEMY_SOUNDS.frost_zombie` borrows "
              "`sfx/groan_tank` until 0284",
              "On screen through 0120's placeholder road: the zombie, a "
              "code-drawn ice burst on death, a frost tint on chilled towers "
              "(view only) and its forecast head, until A050 is integrated "
              "by 0264",
              "Hashes: DATA moves; SIM should not"],
         dod=["`_task_0251_frost` in `src/tools/headless_v1.gd`: one killed "
              "beside two towers makes their next reload "
              "`chill_reload_percent` slower for exactly `chill_ticks`, a "
              "tower outside `chill_tiles` is untouched, `grid_version` does "
              "not move, and the chill is gone the next morning",
              "Two deaths beside one tower refresh rather than stack - "
              "asserted on the reload number",
              "`python tools/shot.py 0251 frost` (a new scenario) opened and "
              "looked at: a chilled tower is visibly different",
              "the Deliverables table of "
              "`implementation/backlog/packs/A050-frost-zombie.md` states the "
              "final geometry this task settled"]),

    # Added 0218: Towers._acquire is rewritten into a spatial bucket there,
    # and the wraith's skip belongs in that version, not the old scan.
    dict(id=252, phase=P14, title="The wraith", slug="wraith",
         deps=[229, 218], dresses=["A051"],
         files="src/core/towers.gd, src/core/combat.gd, "
               "src/core/game_data.gd, src/ui/world_view.gd, "
               "src/ui/wraith_fade.gdshader (new), src/ui/names.gd, "
               "src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, "
               "src/tools/shot.gd, src/tools/headless_v1.gd, "
               "src/tools/input_v1.gd",
         goal="Winter's answer to a defence that only shoots: in the dark it "
              "cannot be aimed at. Light - the searchlight, the flare, fire, "
              "the porch - becomes a weapon of its own.",
         req=["`ENEMIES.wraith` with `# LEVER`s (hp, `ticks_per_tile`, "
              "damage, reward, armour; inside `_task_0051_tank`'s non-boss "
              "bounds) and a `needs_light` flag",
              "Light comes only from 0229's core rule - "
              "`Light.is_lit(state, cell)` in `src/core/light.gd`, or whatever "
              "name 0229's journal gives it (searchlight cells, the flare "
              "area, burning cells, the porch) - never from `lighting.gd`; "
              "if that rule cannot be asked about one cell, add the query "
              "there rather than a second definition here",
              "`Towers._acquire` (0218's bucketed version) and "
              "`Combat.worth_shooting` skip a `needs_light` enemy on an "
              "unlit cell; it is a target from the tick it steps into light, "
              "and a shot already in the air still lands",
              "Decide and document what is not aiming - splash landings, "
              "mines, the cone, the flare. Recommendation: area damage still "
              "hurts it, so the dark has answers that are not light",
              "Names.KEYS `wraith`, `ENEMY_WRAITH`/`ENEMY_WRAITH.other` "
              "(wraith/wraiths, assombração/assombrações); "
              "`DESC_NEEDS_LIGHT` ('can only be aimed at in light' / 'só dá "
              "para mirar nela na luz'); `Sfx.ENEMY_SOUNDS.wraith` borrows "
              "`sfx/groan_walker` until 0284",
              "On screen: a view-only alpha shader in `src/ui/` reading the "
              "same core rule - faint outside light, solid in it, never fully "
              "invisible to the player - over 0120's placeholder road with "
              "its forecast head until A051 is integrated by 0265 (the "
              "pack's art is opaque with binary alpha; transparency is the "
              "shader's)",
              "Hashes: DATA moves; SIM should not; the shader moves neither"],
         dod=["`_task_0252_wraith` in `src/tools/headless_v1.gd`: a gun tower "
              "ignores a wraith walking past it in the dark and shoots it on "
              "the first tick it stands in a searchlight cell, a flare's "
              "area or a burning cell",
              "`_case_0252_wraith_fade` in `src/tools/input_v1.gd`: the "
              "wraith's sprite is faint outside light and solid in it",
              "`python tools/shot.py 0252 wraith` (a new scenario: one in the "
              "beam, one outside it) opened and looked at",
              "the Deliverables table of "
              "`implementation/backlog/packs/A051-wraith.md` states the final "
              "geometry this task settled"]),

    # Added 0231: the charge is tuned so a stone wall falls and 0231's
    # hardwood level of the wall holds, so that level must exist.
    dict(id=253, phase=P14, title="The Harvester", slug="harvester",
         deps=[246, 231], dresses=["A052"],
         files="src/core/enemies.gd, src/core/game_data.gd, "
               "src/ui/enemy_motion.gd, src/ui/world_view.gd, "
               "src/ui/night_hud.gd, src/ui/names.gd, src/ui/describe.gd, "
               "src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, "
               "src/tools/headless_v1.gd",
         goal="Summer's boss: a possessed machine that winds up and charges "
              "in a straight line, flattening the walls in its row. It tests "
              "defence in depth - one thick wall is a speed bump, layers are "
              "a defence.",
         req=["`ENEMIES.harvester` with `is_boss` and `# LEVER`s: hp, armour, "
              "walking `ticks_per_tile`, damage, reward, `telegraph_ticks`, "
              "`charge_every_ticks`, `charge_tiles`, `charge_ticks_per_tile`, "
              "`crush_damage`; `check_enemies` refuses a charger missing any "
              "of them or with a zero; it passes 0246's 'every boss outlasts "
              "every non-boss' asserts",
              "The charge, in `Enemies` (inside `Enemies.tick`, `PerfNames` "
              "unchanged): every `charge_every_ticks` it stops and winds up "
              "with the line fixed when the wind-up starts - the row or column "
              "towards the house centre along the dominant axis, ties to the "
              "row - then moves along it at `charge_ticks_per_tile`, ignoring "
              "the flow field. `telegraph_ticks` already times the wind-up "
              "before every gnaw and at the house (`_gnaw`, "
              "`_swung_at_the_house`): reuse it for the charge or add "
              "`charge_windup_ticks`, and say which",
              "Every structure entered takes `crush_damage` through "
              "`Farm.damage`; it carries on through what it destroys and "
              "stops at the first that survives, at impassable terrain, at "
              "`charge_tiles` or at the house (a bite), then walks and gnaws "
              "as usual. Set the numbers so a stone wall falls and the wall's "
              "hardwood level (0231's `TOWER_LEVELS` row, read through "
              "`Building.entry_at`) holds a charge, and state them",
              "`Enemies.charge_line(state, id)` returns the telegraphed cells "
              "for the view and the tests; the wind-up goes through "
              "`is_winding`/`winding_at` so the 0246 bar flashes",
              "Destroyed walls rebuild the fields at most once a tick (they "
              "are rebuilt lazily by `Pathing.refresh`; assert one rebuild "
              "after a charge crushes three walls in one tick)",
              "Summer's day-14 boss: `GameData.SEASON_BOSSES[1]` (0153's "
              "table) becomes `&\"harvester\"`, and any 0153-0160 group or "
              "shot scenario that put a Giant on Summer 14 is rewritten in "
              "place; its 0246 intro `BOSS_INTRO_HARVESTER`; Names.KEYS "
              "`harvester`, `ENEMY_HARVESTER`/`.other` (harvester/harvesters, "
              "colheitadeira/colheitadeiras) and `DESC_CHARGES` ('charges in "
              "a straight line' / 'investe em linha reta'); "
              "`Sfx.ENEMY_SOUNDS.harvester` borrows `sfx/roar_giant` (0246 "
              "made `Sfx` boss-generic) until 0284",
              "On screen: a strip on the telegraphed cells during the wind-up "
              "(view only) and the boss through 0120's placeholder road at "
              "the Giant's 80x64 pivot (40,60), with its forecast mark, until "
              "A052 is integrated by 0266",
              "Hashes: DATA moves (ENEMIES, SEASON_BOSSES); SIM should not - "
              "the determinism night is Spring 1"],
         dod=["`_task_0253_harvester` in `src/tools/headless_v1.gd`: the line "
              "is fixed when the wind-up starts and the wind-up lasts exactly "
              "the levers' ticks; three stone layers lose what the levers say "
              "and a structure with more hp than `crush_damage` stops the "
              "charge; it never leaves the map or crosses water",
              "The same group: sealed in, it still reaches the house, and "
              "killing it moves `bosses_down_of(state, &\"harvester\")`",
              "`python tools/shot.py 0253 harvester` (wind-up with its strip, "
              "and the line after the charge) opened and looked at",
              "the Deliverables table of "
              "`implementation/backlog/packs/A052-harvester.md` states the "
              "final geometry this task settled (80x64, or up to 112x80 if "
              "justified)"]),

    dict(id=254, phase=P14, title="The Scarecrow King",
         slug="scarecrow-king", deps=[246, 249], dresses=["A053"],
         files="src/core/enemies.gd, src/core/game_data.gd, "
               "src/ui/enemy_motion.gd, src/ui/world_view.gd, "
               "src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, "
               "assets/locale/strings.csv, src/tools/shot.gd, "
               "src/tools/headless_v1.gd",
         goal="Autumn's boss calls the sky down: it stops, casts, and a flock "
              "of crows rises around it. It asks what the crow asked - cover "
              "in the air and care for the field - under pressure.",
         req=["`ENEMIES.scarecrow_king` with `is_boss` and `# LEVER`s: hp, "
              "armour, `ticks_per_tile`, damage, reward, `telegraph_ticks` "
              "(the cast), `summon_every_ticks`, `flock_size`, `summon_cap` "
              "(crows it may raise in one night, so a long fight cannot flood "
              "the farm); it passes 0246's boss-against-non-boss asserts",
              "Summons on deterministic cells: a fixed list of offsets around "
              "its cell (a table in `game_data.gd`, listed in `digest()`), "
              "clipped to the map, taken in list order - no RNG draw. They "
              "are 0249's `crow` through `Entities.spawn`, flying from there "
              "to the field; `check_enemies` refuses a `flock_size` above the "
              "offsets, a `summon_cap` below `flock_size`, or a summoned kind "
              "that does not fly",
              "Summoned crows are not wave members: `Waves` counts and the "
              "forecast are unchanged, and the night still ends at dawn "
              "(0137) or when everything is dead; decide whether they pay "
              "bounty (a farmable King is an exploit) and say why",
              "The cast is the telegraph: it stands for `telegraph_ticks` and "
              "is `is_winding` (reusing `winding_at`/`chew_wait`, as `_gnaw` "
              "does), so the 0246 bar flashes; otherwise it walks the flow "
              "field and bites like a walker, inside `Enemies.tick`",
              "Autumn's day-14 boss: `GameData.SEASON_BOSSES[2]` becomes "
              "`&\"scarecrow_king\"` (any group that put a Giant on Autumn 14 "
              "is rewritten in place); `BOSS_INTRO_SCARECROW_KING`; "
              "Names.KEYS `scarecrow_king`, `ENEMY_SCARECROW_KING`/`.other` "
              "(scarecrow king/scarecrow kings, rei espantalho/reis "
              "espantalhos) and `DESC_SUMMONS` ('calls down crows' / 'chama "
              "os corvos'); `Sfx.ENEMY_SOUNDS.scarecrow_king` borrows "
              "`sfx/roar_giant` until 0284",
              "On screen through 0120's placeholder road: a cast pose, the "
              "flock rising and its forecast mark at the boss canvas, until "
              "A053 is integrated by 0267",
              "Hashes: DATA moves (ENEMIES, the offsets, SEASON_BOSSES); SIM "
              "should not - the determinism night is Spring 1"],
         dod=["`_task_0254_scarecrow_king` in `src/tools/headless_v1.gd`: each "
              "cast raises `flock_size` crows on the listed cells after "
              "exactly `telegraph_ticks`, two runs agree cell for cell, and "
              "no night raises more than `summon_cap`",
              "The same group: a King with a planted field and no "
              "`hits_flying` cover costs crops, one with cover over the field "
              "costs few - print both counts",
              "`python tools/shot.py 0254 scarecrow_king` (mid-cast) opened "
              "and looked at",
              "the Deliverables table of "
              "`implementation/backlog/packs/A053-scarecrow-king.md` states "
              "the final geometry this task settled"]),

    # Added 0160: the ending fires when Winter 14's boss falls, and this task
    # makes that boss the Winter Lord - 0160's hook must already exist.
    # Added 0253, 0254: it must be asserted the strongest boss, so the other
    # two bosses must already be in the table.
    dict(id=255, phase=P14, title="The Winter Lord", slug="winter-lord",
         deps=[246, 251, 160, 253, 254], dresses=["A054"],
         files="src/core/enemies.gd, src/core/towers.gd, "
               "src/core/game_data.gd, src/ui/world_view.gd, "
               "src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, "
               "assets/locale/strings.csv, src/tools/shot.gd, "
               "src/tools/headless_v1.gd",
         goal="The last night of the year: a lord of ice whose cast freezes "
              "every tower around it. It tests the whole build - spread, "
              "depth, light and the powers - and its fall is the ending.",
         req=["`ENEMIES.winter_lord` with `is_boss` and `# LEVER`s: hp, "
              "armour, `ticks_per_tile`, damage, reward, `telegraph_ticks` "
              "(the cast), `freeze_every_ticks`, `aura_tiles`, "
              "`freeze_ticks` (`check_enemies` refuses a zero); the strongest "
              "boss in the table (more hp than the Harvester and the King - "
              "asserted)",
              "The freeze sits beside 0251's chill on the occupant, never "
              "through `Farm.touch`: towers within `aura_tiles` when the cast "
              "lands stop counting their reload for `freeze_ticks` (a "
              "`frozen` countdown in `Towers.tick`/`_cool_down`); refreshed, "
              "never stacked, cleared in `Enemies.withdraw` at dawn",
              "The cast is telegraphed (`is_winding` for `telegraph_ticks`, "
              "so the 0246 bar flashes) and the aura's cells are a core query "
              "for the view",
              "Winter's day-14 boss: `GameData.SEASON_BOSSES[3]` becomes "
              "`&\"winter_lord\"`, and 0160's ending fires on it falling: "
              "rewrite `_task_0160_year_end` and `_case_0160_ending` to kill "
              "a Winter Lord on Winter 14 and see the ending; a Giant on that "
              "night no longer ends the year",
              "`BOSS_INTRO_WINTER_LORD`; Names.KEYS `winter_lord`, "
              "`ENEMY_WINTER_LORD`/`.other` (winter lord/winter lords, senhor "
              "do inverno/senhores do inverno) and `DESC_FREEZES` ('freezes "
              "the towers around it' / 'congela as torres em volta'); "
              "`Sfx.ENEMY_SOUNDS.winter_lord` borrows `sfx/roar_giant` until "
              "0284",
              "On screen through 0120's placeholder road: a cast pose, the "
              "aura's reach on the ground during the wind-up, ice on frozen "
              "towers (view only) and its forecast mark, until A054 is "
              "integrated by 0268",
              "Hashes: DATA moves; SIM should not"],
         dod=["`_task_0255_winter_lord` in `src/tools/headless_v1.gd`: a cast "
              "freezes exactly the towers inside `aura_tiles` for "
              "`freeze_ticks`, `grid_version` does not move, and every tower "
              "fires again afterwards",
              "Killing it on Winter 14 brings up the year's ending through "
              "0160's path and `bosses_down_of(state, &\"winter_lord\")` is "
              "one",
              "`python tools/shot.py 0255 winter_lord` (the aura during a "
              "cast) opened and looked at",
              "the Deliverables table of "
              "`implementation/backlog/packs/A054-winter-lord.md` states the "
              "final geometry this task settled"]),

    dict(id=256, phase=P14, title="Fog and rain", slug="fog-and-rain",
         deps=[158, 229], dresses=["A055"],
         files="src/core/weather.gd (new), src/core/forecast.gd, "
               "src/core/game_data.gd, src/core/towers.gd, "
               "src/core/combat.gd, src/core/enemies.gd, "
               "src/ui/forecast_panel.gd, assets/locale/strings.csv, "
               "src/tools/shot.gd, src/tools/headless_v1.gd",
         goal="Nights that are not all alike: some are foggy, some rain. Both "
              "are known at dusk, so they change what you build rather than "
              "punish you for not guessing.",
         req=["`Weather.event(seed, date)` in a new `src/core/weather.gd` "
              "(class name `Weather` - `Events` is already the log), keyed on "
              "the calendar date (`Calendar.date`, which 0153's hold keeps on "
              "14), not on `day`: a fresh stream mixed like "
              "`Endless._stream_for` but salted so it is not the wave table's "
              "stream, never `state[\"rng\"]`; at most one event a night; it "
              "returns none on date 1 and on `Calendar.is_calm(date)`; no "
              "State key, and none may be named `moon_phase`. The one function "
              "every reader calls (0270 will let a night record pin or forbid "
              "an event through it)",
              "`GameData.NIGHT_EVENTS` with per-season weights (percent, "
              "`# LEVER`) for `fog` and `rain` and their levers, listed in "
              "`GameData.digest()` and checked by a new `check_night_events` "
              "in `validate()`: weights 0-100, a season's weights summing to "
              "at most 100, each lever in range",
              "Fog: `Towers.reach_of` (which 0229 taught the tower's cell) "
              "loses `fog_reach_penalty` (1) down to a floor of 1, except for "
              "a tower on a lit cell (`Light.is_lit`, 0229) - the searchlight "
              "cancels it; every shape that reads reach gets the same answer",
              "Rain: `DAMAGE_FIRE` hits and burn ticks deal "
              "`rain_fire_percent` (bees are not fire, even if 0226 reused "
              "`burning`), and mud slows walkers by `rain_mud_percent` in "
              "`Enemies._walk`, composed with the flare's "
              "(`Ability.slowed_ticks`) and the garlic's slows by one written "
              "rule; flyers (0249's `flies`) are not slowed",
              "Ask `Weather` once per system tick (`Towers.tick`, "
              "`Enemies.tick`, `Combat.tick`), not once per body, so a swarm "
              "does not pay for it; `python tools/perf.py --report` stays "
              "inside its tolerance",
              "The `event` slot 0158 left in `Forecast.of(seed, date)` is "
              "filled from `Weather.event`; `src/ui/forecast_panel.gd` shows "
              "its icon (placeholder until A055 is integrated by 0269) and "
              "`FCAST_FOG`/`FCAST_RAIN` (FOG / NEBLINA, RAIN / CHUVA, widths "
              "measured), beside 0158's `FCAST_*` rows",
              "Rules only: fog and rain on screen are 0258's",
              "Hashes: DATA moves (a new table); SIM should not, since the "
              "determinism night is Spring 1 - if it does, the journal says "
              "why"],
         dod=["`_task_0256_fog_rain` in `src/tools/headless_v1.gd`: the event "
              "for a (seed, date) is the same however often it is asked and "
              "whatever the run RNG did; over seeds 0-49 and dates 1-56 (pure "
              "calls, no simulation) each season's share of fog and rain is "
              "within 5 points of its weight (printed); date 1 and a calm "
              "date have none; `Forecast.of` names the same event",
              "The same group: in fog a gun tower reaches one tile less "
              "unless its cell is lit; in rain a burn deals "
              "`rain_fire_percent` and a walker takes the slower count per "
              "tile",
              "`python tools/shot.py 0256 forecast_fog --fhd` (a new scenario "
              "in `src/tools/shot.gd` that finds a foggy (seed, date) through "
              "`Weather.event`, never an override) shows the event in the "
              "forecast, opened and looked at"]),

    # Added 0219: the extra essence goes through 0219's earn rules. Added
    # 0246: elites change full hp, which 0246 reads from one helper.
    dict(id=257, phase=P14, title="The Blood Moon", slug="blood-moon",
         deps=[256, 219, 246], dresses=["A055"],
         files="src/core/weather.gd, src/core/entities.gd, "
               "src/core/combat.gd, src/core/game_data.gd, "
               "src/core/rewards.gd, src/core/tech.gd, "
               "src/ui/forecast_panel.gd, src/ui/result_screen.gd, "
               "assets/locale/strings.csv, src/tools/shot.gd, "
               "src/tools/headless_v1.gd",
         goal="A rare red night from autumn on: the horde comes back stronger "
              "and pays in essence. Rare enough to be an occasion, forecast so "
              "it is never an ambush.",
         req=["`blood_moon` joins `GameData.NIGHT_EVENTS`: weight 0 in spring "
              "and summer (refused otherwise by `check_night_events`), a small "
              "`# LEVER` weight in autumn and winter; `Weather.event` never "
              "returns it when `Calendar.is_boss_night(date)` (an elite boss "
              "is another balance problem); decide whether it may fall on "
              "`Calendar.is_full_moon(date)` and say why",
              "Elites: on a Blood Moon night `Entities.spawn` (reading "
              "`Weather.event` for `Calendar.date(state)`) scales hp by "
              "`blood_moon_hp_percent` (120-200, integers) and writes "
              "`max_hp` on the elite only, so ordinary nights are untouched "
              "and 0246's `Combat.full_hp` (and any health bar that reads it) "
              "uses it",
              "Extra essence through 0219's earn rules: a "
              "`blood_moon_essence` `# LEVER` in `GameData.REWARDS`, its own "
              "itemised line in `Tech.would_pay` on a won night, shown in "
              "the morning report as a `RES_*` row in both languages; "
              "`nights_paid` still stops it paying twice",
              "In the forecast slot (`Forecast.of`'s `event`, "
              "`forecast_panel.gd`): `FCAST_BLOOD_MOON` (BLOOD MOON / LUA DE "
              "SANGUE) and the icon placeholder until A055 is integrated by "
              "0269",
              "`Waves.size_of` and the forecast count do not change: elites "
              "are tougher, not more",
              "Hashes: DATA moves; SIM should not (`max_hp` exists only on "
              "elites)"],
         dod=["`_task_0257_blood_moon` in `src/tools/headless_v1.gd`: over "
              "seeds 0-49 and dates 1-56 (pure calls) no Blood Moon falls in "
              "spring, summer or on a boss night, and the autumn and winter "
              "counts are printed; on one, a walker spawns with the scaled "
              "hp and `full_hp` reads it; winning pays the extra essence, "
              "once",
              "`python tools/shot.py 0257 forecast_blood_moon --fhd` (a new "
              "scenario that finds a Blood Moon (seed, date) through "
              "`Weather.event`) shows it in the forecast, opened and looked "
              "at",
              "the Deliverables table of "
              "`implementation/backlog/packs/A055-event-icons.md` states the "
              "final geometry this task settled (fog, rain and Blood Moon at "
              "16x16 and 10x10)"]),

    dict(id=258, phase=P14, title="Fog, rain and a red moon on screen",
         slug="event-visuals", deps=[256, 257],
         files="src/ui/lighting.gd, src/ui/particles.gd, "
               "src/ui/fog.gdshader (new), src/ui/world_view.gd, "
               "tools/palette.py, src/ui/palette_data.gd (generated), "
               "src/tools/perf_check.gd, tools/perf_baseline.txt, "
               "src/tools/shot.gd, src/tools/input_v1.gd",
         goal="Fog that looks like fog, rain you can see, a red moon that "
              "makes the farm look wrong - and none of it touches a rule.",
         req=["View only, both hashes unchanged: everything reads "
              "`Weather.event` (0256, 0257) and `Light.is_lit` (0229), and "
              "nothing writes the state",
              "Fog: a code noise shader over the world (no new PNG), thinner "
              "on lit cells so the searchlight visibly cuts it",
              "Rain: particles in `particles.gd` bounded by the accessibility "
              "particle density setting (`a11y/particle_density`), a darker "
              "night ramp, and a mud tint on walkable ground",
              "Blood Moon: a red night ramp. Ramps go the road 0152 used for "
              "the Full Moon: `rain` and `blood_moon` entries in "
              "`tools/palette.py` `RAMPS`, written into `PaletteData` by "
              "`python tools/gen_sprites.py` (never edit `palette_data.gd`), "
              "picked by `WorldView._night_ramp()`. Check that the Full Moon "
              "still reads brighter than an ordinary night and that the ramps "
              "(ordinary, Full Moon, fog, rain, Blood Moon) are told apart at "
              "a glance",
              "Cost: `perf_check.gd`'s view timing (`_view`, today's "
              "`view_lighting`/`view_particles`) gains a rain night at 4x as "
              "its own `PERF` line (e.g. `view_rain`), inside "
              "`tools/perf.py`'s tolerance and accepted with the reason in "
              "the journal",
              "Shot scenarios `fog`, `rain`, `blood_moon` and `full_moon` in "
              "`src/tools/shot.gd`, each finding a (seed, date) through "
              "`Weather.event` or `Calendar.is_full_moon` rather than an "
              "override"],
         dod=["`_case_0258_event_visuals` in `src/tools/input_v1.gd`: each "
              "event turns its layer on with the night and off at dawn, the "
              "rain particle count follows the density setting, and a night "
              "with the layers on and one with them off end on the same SIM "
              "hash",
              "`python tools/shot.py 0258 fog rain blood_moon full_moon "
              "--fhd` opened and looked at beside `docs/reference-sheet.png`: "
              "the farm stays readable in every one"]),

    dict(id=259, phase=P14, title="Every weapon has its night",
         slug="matchups",
         deps=[234, 247, 248, 249, 250, 251, 252, 253, 254, 255, 256, 257],
         files="src/tools/matchups.gd, tools/matchups.py, "
               "implementation/MATCHUPS.md",
         goal="The plan's test for phases 4 and 5 turned into numbers: every "
              "weapon is the best buy somewhere, and every enemy needs a "
              "different answer. The report is what the night authors of "
              "0270-0274 build the year from.",
         req=["A headless tool, not a suite group: `src/tools/matchups.gd` "
              "run by `tools/matchups.py`, seeded and deterministic, printing "
              "its run time, with `--only=<enemy>` for quick reruns; it stays "
              "out of `verify.py` (the 120 s per-suite timeout). Keep a full "
              "run to about ten minutes by shortening the lane's fight, not "
              "by dropping rows of the grid",
              "The arena: one fixed lane on the real farm map with a fixed "
              "base defence; for every `GameData.DEFENCES` entry (the plan's "
              "fourteen plus 0225's bait and 0231's sandbags - print the "
              "count), the same budget (0234's money plus materials, "
              "materials at `SELL_PRICE`) spent on it at the level its season "
              "allows, "
              "placed by a fixed rule; a fixed group of one enemy kind, and "
              "each boss with its season's escort",
              "Per pair: house damage, kills, ticks to clear and structures "
              "lost; the score is house damage prevented per unit of cost "
              "against the base alone",
              "The same grid under fog, rain and the Blood Moon, so the "
              "searchlight, fire and the mines get their nights",
              "Prove: every defence is the top buy against at least one "
              "enemy, boss or event (a barrier or a support piece - decoy, "
              "garlic, searchlight - may be scored as the best addition to "
              "the base line rather than alone; say how); no defence is top "
              "against every enemy; every new enemy's top answer differs "
              "from the walker's. Where a claim fails, a lever may move here "
              "(at most a few, DATA recorded) or the failure goes to 0277 "
              "with its numbers",
              "`implementation/MATCHUPS.md`: the table, each enemy's top three "
              "answers, each defence's best night, and a line per enemy for "
              "the night authors (e.g. 'rats: mines, flamethrower')"],
         dod=["`python tools/matchups.py` exits 0 and names, for every "
              "`DEFENCES` entry, the enemy or event where it is the best buy, "
              "or marks it UNPROVEN with its numbers; every UNPROVEN line is "
              "in the journal as handed to 0277",
              "Two runs write the same `implementation/MATCHUPS.md` byte for "
              "byte",
              "The journal answers in one paragraph, with the numbers, "
              "whether each enemy asks for a different answer, and lists any "
              "lever moved"]),

    # ======================================================= art integration
    # Added 0246 to 0260-0265: a leaf adds its family to
    # `gen_sprites.migrated_enemies()`, which fails `check_giant_art.py`'s
    # exact five-family check until 0246 turns it into a subset check.
    dict(id=260, phase=P14, title="Art: the spitter", slug="art-spitter",
         deps=[247, 246], art=["A046"],
         files="assets/art_source/enemies/spitter/, "
               "assets/art_source/effects/, "
               "assets/art_source/manifest.json, "
               "assets/art_source/ownership.json, tools/check_enemy_art.py, "
               "tools/gen_sprites.py, "
               "tools/check_effect_art.py, src/ui/enemy_motion.gd",
         goal="The spitter as Codex drew it, in place of 0247's stand-in: its "
              "walk, the spit, the splat and its forecast head.",
         req=["`python tools/task.py next` only offers this task once "
              "`python implementation/backlog/assets.py status A046` says "
              "`approved`. Check it again first; if it does not, stop and "
              "change nothing (the task stays todo and waits). This task "
              "never draws, generates or substitutes art.",
              "Use only the folder named in the pack's "
              "`CLAUDE-A046-PROMPT.txt` handoff; check every file against its "
              "`contract.json` sha256 before promoting; never resample, "
              "regenerate, or cut from previews or GIFs.",
              "Promote through the raster pipeline: versioned sources under "
              "`assets/art_source/enemies/spitter/`, manifest entries with "
              "prompt/approval provenance, `assets/art_source/ownership.json`, "
              "then `python tools/import_art.py`; extend the hard-coded family "
              "lists the art checks use (`gen_sprites.migrated_enemies()`, "
              "`check_enemy_art.FAMILIES` and its "
              "pinned generation task `'0015'`, the effect checker's pinned "
              "0017 set, `EnemyMotion.FAMILIES`/`TRACKED`) with a block for "
              "this pack rather than loosening the old counts.",
              "Runtime names as the ordinary enemies at 64x48 pivot (32,44): "
              "`enemies/spitter`, `spitter_walk_0..3` (0.125 s, loop), "
              "`spitter_attack_0..2` (the spit), `spitter_death_0..3`, with "
              "the `_walk_b`/`_attack`/`_death` aliases; the spit (8x8, 2 "
              "frames) and the splat (3) in the effects family; the 16x16 "
              "forecast head where 0158 put the others",
              "Replace 0247's placeholders in 0120's registry (the leaf flips "
              "ownership to raster) and drive the attack pose from the real "
              "spit, not a bite.",
              "Set the pack to integrated: "
              "`python implementation/backlog/assets.py set A046 integrated`."],
         dod=["`python tools/check_enemy_art.py`, "
              "`python tools/check_effect_art.py` and "
              "`python tools/show_art.py --enemies --check` pass",
              "`python tools/import_art.py --check` passes",
              "FHD (1920x1080) captures in the real game by day (its head in "
              "the dusk forecast) and by night (spitting at a tower), opened "
              "and looked at, in `implementation/shots/0260/`",
              "the sim and data hashes are unchanged (art never moves them)"]),

    dict(id=261, phase=P14, title="Art: the rat swarm", slug="art-rats",
         deps=[248, 246], art=["A047"],
         files="assets/art_source/enemies/rat/, "
               "assets/art_source/manifest.json, "
               "assets/art_source/ownership.json, tools/check_enemy_art.py, "
               "tools/gen_sprites.py, "
               "src/ui/enemy_motion.gd, src/ui/enemy_deaths.gd",
         goal="The rats as Codex drew them, in place of 0248's stand-in: "
              "small enough to read as a swarm and still read as rats.",
         req=["`python tools/task.py next` only offers this task once "
              "`python implementation/backlog/assets.py status A047` says "
              "`approved`. Check it again first; if it does not, stop and "
              "change nothing (the task stays todo and waits). This task "
              "never draws, generates or substitutes art.",
              "Use only the folder named in the pack's "
              "`CLAUDE-A047-PROMPT.txt` handoff; check every file against its "
              "`contract.json` sha256 before promoting; never resample, "
              "regenerate, or cut from previews or GIFs.",
              "Promote through the raster pipeline: versioned sources under "
              "`assets/art_source/enemies/rat/`, manifest entries with "
              "prompt/approval provenance, `assets/art_source/ownership.json`, "
              "then `python tools/import_art.py`; extend the hard-coded family "
              "lists the art checks use (`gen_sprites.migrated_enemies()`, "
              "`check_enemy_art.FAMILIES`, "
              "`EnemyMotion.FAMILIES`/`TRACKED`).",
              "The rat is not 64x48: `check_enemy_art.py` takes canvas, "
              "pivot, contact row and motion counts per family (rat: walk 4, "
              "attack 3 from the pack's bite, death 3, at the canvas 0248 "
              "settled, ~24x16) instead of asserting `[64,48]` for everyone, "
              "and `EnemyDeaths` plays three death frames for it",
              "Runtime names `enemies/rat`, `rat_walk_0..3`, "
              "`rat_attack_0..2`, `rat_death_0..2` with the usual aliases, "
              "and the forecast head; "
              "replace 0248's placeholders in 0120's registry",
              "Set the pack to integrated: "
              "`python implementation/backlog/assets.py set A047 integrated`."],
         dod=["`python tools/check_enemy_art.py` and "
              "`python tools/show_art.py --enemies --check` pass",
              "`python tools/import_art.py --check` passes",
              "FHD (1920x1080) captures in the real game by day (the head in "
              "the dusk forecast) and by night (a cluster crossing a mine), "
              "opened and looked at, in `implementation/shots/0261/`",
              "the sim and data hashes are unchanged (art never moves them)"]),

    dict(id=262, phase=P14, title="Art: the crow", slug="art-crow",
         deps=[249, 246], art=["A048"],
         files="assets/art_source/enemies/crow/, "
               "assets/art_source/manifest.json, "
               "assets/art_source/ownership.json, tools/check_enemy_art.py, "
               "tools/gen_sprites.py, "
               "src/ui/enemy_motion.gd, src/ui/world_view.gd",
         goal="The crow as Codex drew it, in place of 0249's stand-in: in "
              "the air, landing, pecking and falling.",
         req=["`python tools/task.py next` only offers this task once "
              "`python implementation/backlog/assets.py status A048` says "
              "`approved`. Check it again first; if it does not, stop and "
              "change nothing (the task stays todo and waits). This task "
              "never draws, generates or substitutes art.",
              "Use only the folder named in the pack's "
              "`CLAUDE-A048-PROMPT.txt` handoff; check every file against its "
              "`contract.json` sha256 before promoting; never resample, "
              "regenerate, or cut from previews or GIFs.",
              "Promote through the raster pipeline: versioned sources under "
              "`assets/art_source/enemies/crow/`, manifest entries with "
              "prompt/approval provenance, `assets/art_source/ownership.json`, "
              "then `python tools/import_art.py`; extend the hard-coded family "
              "lists the art checks use (`gen_sprites.migrated_enemies()`, "
              "`check_enemy_art.FAMILIES`, "
              "`EnemyMotion.FAMILIES`/`TRACKED`).",
              "The flying exception: `crow_fly_0..3` (loop), `crow_land_0`, "
              "`crow_peck_0..2`, `crow_death_0..3` (the fall), side view "
              "mirrored at runtime; the checker takes this family's motions "
              "from its own row (not the fixed walk/attack/death `COUNTS`), "
              "exempts flying frames from the ground-contact row and asserts "
              "no baked shadow - the shadow stays 0249's code shadow. Keep "
              "`crow`, `_walk_b`, `_attack`, `_death` aliases (or teach "
              "`_task_0074_zombie_art` the exception) so the suite's art "
              "groups still pass",
              "`EnemyMotion` maps 0249's states (in flight, landed, pecking, "
              "falling) to these names and keeps 0249's height offset; "
              "replace 0249's placeholders and the forecast head in 0120's "
              "registry",
              "Set the pack to integrated: "
              "`python implementation/backlog/assets.py set A048 integrated`."],
         dod=["`python tools/check_enemy_art.py` and "
              "`python tools/show_art.py --enemies --check` pass",
              "`python tools/import_art.py --check` passes",
              "FHD (1920x1080) captures in the real game by day (the head in "
              "the dusk forecast) and by night (one over a wall, one pecking "
              "a crop), opened and looked at, in "
              "`implementation/shots/0262/`",
              "the sim and data hashes are unchanged (art never moves them)"]),

    dict(id=263, phase=P14, title="Art: the digger", slug="art-digger",
         deps=[250, 246], art=["A049"],
         files="assets/art_source/enemies/digger/, "
               "assets/art_source/manifest.json, "
               "assets/art_source/ownership.json, tools/check_enemy_art.py, "
               "tools/gen_sprites.py, "
               "src/ui/enemy_motion.gd",
         goal="The digger as Codex drew it, in place of 0250's stand-in: "
              "going down, the mound moving under the fence, coming up.",
         req=["`python tools/task.py next` only offers this task once "
              "`python implementation/backlog/assets.py status A049` says "
              "`approved`. Check it again first; if it does not, stop and "
              "change nothing (the task stays todo and waits). This task "
              "never draws, generates or substitutes art.",
              "Use only the folder named in the pack's "
              "`CLAUDE-A049-PROMPT.txt` handoff; check every file against its "
              "`contract.json` sha256 before promoting; never resample, "
              "regenerate, or cut from previews or GIFs.",
              "Promote through the raster pipeline: versioned sources under "
              "`assets/art_source/enemies/digger/`, manifest entries with "
              "prompt/approval provenance, `assets/art_source/ownership.json`, "
              "then `python tools/import_art.py`; extend the hard-coded family "
              "lists the art checks use (`gen_sprites.migrated_enemies()`, "
              "`check_enemy_art.FAMILIES` with its "
              "extra motions, `EnemyMotion.FAMILIES`/`TRACKED`).",
              "At 64x48 pivot (32,44): `digger_walk_0..3`, "
              "`digger_burrow_0..3` (one-shot), `digger_mound_0..N` (loop, 2-3 "
              "frames), `digger_emerge_0..3`, `digger_attack_0..2`, "
              "`digger_death_0..3` with the usual aliases, and the forecast "
              "head",
              "`EnemyMotion` plays burrow on the tick 0250 puts it "
              "underground, the mound while it stays there and emerge when it "
              "surfaces; replace 0250's placeholders in 0120's registry",
              "Set the pack to integrated: "
              "`python implementation/backlog/assets.py set A049 integrated`."],
         dod=["`python tools/check_enemy_art.py` and "
              "`python tools/show_art.py --enemies --check` pass",
              "`python tools/import_art.py --check` passes",
              "FHD (1920x1080) captures in the real game by day (the head in "
              "the dusk forecast) and by night (a mound under a fence line), "
              "opened and looked at, in `implementation/shots/0263/`",
              "the sim and data hashes are unchanged (art never moves them)"]),

    dict(id=264, phase=P14, title="Art: the frost zombie",
         slug="art-frost-zombie", deps=[251, 246], art=["A050"],
         files="assets/art_source/enemies/frost_zombie/, "
               "assets/art_source/effects/, "
               "assets/art_source/manifest.json, "
               "assets/art_source/ownership.json, tools/check_enemy_art.py, "
               "tools/gen_sprites.py, "
               "tools/check_effect_art.py, src/ui/enemy_motion.gd",
         goal="The frost zombie as Codex drew it, in place of 0251's "
              "stand-in, with the ice shattering when it dies.",
         req=["`python tools/task.py next` only offers this task once "
              "`python implementation/backlog/assets.py status A050` says "
              "`approved`. Check it again first; if it does not, stop and "
              "change nothing (the task stays todo and waits). This task "
              "never draws, generates or substitutes art.",
              "Use only the folder named in the pack's "
              "`CLAUDE-A050-PROMPT.txt` handoff; check every file against its "
              "`contract.json` sha256 before promoting; never resample, "
              "regenerate, or cut from previews or GIFs.",
              "Promote through the raster pipeline: versioned sources under "
              "`assets/art_source/enemies/frost_zombie/`, manifest entries "
              "with prompt/approval provenance, "
              "`assets/art_source/ownership.json`, then "
              "`python tools/import_art.py`; extend the hard-coded family "
              "lists the art checks use (`gen_sprites.migrated_enemies()`, "
              "`check_enemy_art.FAMILIES`, the "
              "effect checker's pinned set, `EnemyMotion.FAMILIES`/`TRACKED`).",
              "At 64x48 pivot (32,44): `frost_zombie_walk_0..3`, "
              "`_attack_0..2`, `_death_0..3` with the usual aliases; the "
              "ice-shatter burst (4 frames, one-shot) in the effects family, "
              "played where 0251's code burst was; the forecast head",
              "Replace 0251's placeholders in 0120's registry; the frost tint "
              "on chilled towers stays code",
              "Set the pack to integrated: "
              "`python implementation/backlog/assets.py set A050 integrated`."],
         dod=["`python tools/check_enemy_art.py`, "
              "`python tools/check_effect_art.py` and "
              "`python tools/show_art.py --enemies --check` pass",
              "`python tools/import_art.py --check` passes",
              "FHD (1920x1080) captures in the real game by day (the head in "
              "the dusk forecast) and by night (a shatter beside a tower), "
              "opened and looked at, in `implementation/shots/0264/`",
              "the sim and data hashes are unchanged (art never moves them)"]),

    dict(id=265, phase=P14, title="Art: the wraith", slug="art-wraith",
         deps=[252, 246], art=["A051"],
         files="assets/art_source/enemies/wraith/, "
               "assets/art_source/manifest.json, "
               "assets/art_source/ownership.json, tools/check_enemy_art.py, "
               "tools/gen_sprites.py, "
               "src/ui/enemy_motion.gd, src/ui/wraith_fade.gdshader",
         goal="The wraith as Codex drew it, in place of 0252's stand-in, "
              "fading in and out of the light through 0252's shader.",
         req=["`python tools/task.py next` only offers this task once "
              "`python implementation/backlog/assets.py status A051` says "
              "`approved`. Check it again first; if it does not, stop and "
              "change nothing (the task stays todo and waits). This task "
              "never draws, generates or substitutes art.",
              "Use only the folder named in the pack's "
              "`CLAUDE-A051-PROMPT.txt` handoff; check every file against its "
              "`contract.json` sha256 before promoting; never resample, "
              "regenerate, or cut from previews or GIFs.",
              "Promote through the raster pipeline: versioned sources under "
              "`assets/art_source/enemies/wraith/`, manifest entries with "
              "prompt/approval provenance, `assets/art_source/ownership.json`, "
              "then `python tools/import_art.py`; extend the hard-coded family "
              "lists the art checks use (`gen_sprites.migrated_enemies()`, "
              "`check_enemy_art.FAMILIES`, "
              "`EnemyMotion.FAMILIES`/`TRACKED`).",
              "At 64x48 pivot (32,44): the float loop as `wraith_walk_0..3`, "
              "`wraith_attack_0..2`, the dissipate as `wraith_death_0..3`, "
              "with the usual aliases and the forecast head; the art is "
              "opaque with binary alpha (the checker refuses any partial "
              "alpha), transparency is 0252's shader",
              "Replace 0252's placeholders in 0120's registry and check the "
              "shader on the real art: faint in the dark, solid in light",
              "Set the pack to integrated: "
              "`python implementation/backlog/assets.py set A051 integrated`."],
         dod=["`python tools/check_enemy_art.py` and "
              "`python tools/show_art.py --enemies --check` pass",
              "`python tools/import_art.py --check` passes",
              "FHD (1920x1080) captures in the real game by day (the head in "
              "the dusk forecast) and by night (one in the searchlight beam, "
              "one outside it), opened and looked at, in "
              "`implementation/shots/0265/`",
              "the sim and data hashes are unchanged (art never moves them)"]),

    dict(id=266, phase=P14, title="Art: the Harvester", slug="art-harvester",
         deps=[253], art=["A052"],
         files="assets/art_source/enemies/harvester/, "
               "assets/art_source/manifest.json, "
               "assets/art_source/ownership.json, tools/check_giant_art.py, "
               "tools/gen_sprites.py, src/tools/headless_check.gd, "
               "src/tools/giant_showcase.gd, src/ui/enemy_motion.gd",
         goal="The Harvester as Codex drew it, in place of 0253's stand-in: "
              "the wind-up you learn to fear and the charge that follows it.",
         req=["`python tools/task.py next` only offers this task once "
              "`python implementation/backlog/assets.py status A052` says "
              "`approved`. Check it again first; if it does not, stop and "
              "change nothing (the task stays todo and waits). This task "
              "never draws, generates or substitutes art.",
              "Use only the folder named in the pack's "
              "`CLAUDE-A052-PROMPT.txt` handoff; check every file against its "
              "`contract.json` sha256 before promoting; never resample, "
              "regenerate, or cut from previews or GIFs.",
              "Promote through the raster pipeline: versioned sources under "
              "`assets/art_source/enemies/harvester/`, manifest entries with "
              "prompt/approval provenance, `assets/art_source/ownership.json`, "
              "then `python tools/import_art.py`; extend the hard-coded family "
              "lists the art checks use (`gen_sprites.migrated_enemies()`, "
              "0246's boss table in "
              "`check_giant_art.py`, `ArtPlacement` if the canvas is larger "
              "than 80x64).",
              "At the canvas 0253 settled (80x64 pivot (40,60), or up to "
              "112x80): `harvester` master, `harvester_walk_0..3` (move), "
              "`harvester_windup_0..2`, the charge/crush frames, "
              "`harvester_death_0..4`, the wreck debris and the forecast "
              "mark; 0246's boss path picks the windup on the telegraph and "
              "the charge frames while 0253's charge runs",
              "Replace 0253's placeholders in 0120's registry; the "
              "telegraph strip on the ground stays code. The first boss leaf "
              "to land (0266-0268, any order) rewrites `_task_0074_zombie_art`"
              "'s 'the Giant is the biggest thing on the field' as 'every "
              "boss outsizes every non-boss'",
              "Set the pack to integrated: "
              "`python implementation/backlog/assets.py set A052 integrated`."],
         dod=["`python tools/check_giant_art.py` and "
              "`python tools/show_art.py --boss=harvester --check` pass",
              "`python tools/import_art.py --check` passes",
              "FHD (1920x1080) captures in the real game by day (the mark in "
              "the dusk forecast) and by night (wind-up with the strip, and "
              "mid-charge), opened and looked at, in "
              "`implementation/shots/0266/`",
              "the sim and data hashes are unchanged (art never moves them)"]),

    dict(id=267, phase=P14, title="Art: the Scarecrow King",
         slug="art-scarecrow-king", deps=[254], art=["A053"],
         files="assets/art_source/enemies/scarecrow_king/, "
               "assets/art_source/manifest.json, "
               "assets/art_source/ownership.json, tools/check_giant_art.py, "
               "tools/gen_sprites.py, src/tools/headless_check.gd, "
               "src/tools/giant_showcase.gd, src/ui/enemy_motion.gd",
         goal="The Scarecrow King as Codex drew it, in place of 0254's "
              "stand-in, raising its arms as the flock comes up.",
         req=["`python tools/task.py next` only offers this task once "
              "`python implementation/backlog/assets.py status A053` says "
              "`approved`. Check it again first; if it does not, stop and "
              "change nothing (the task stays todo and waits). This task "
              "never draws, generates or substitutes art.",
              "Use only the folder named in the pack's "
              "`CLAUDE-A053-PROMPT.txt` handoff; check every file against its "
              "`contract.json` sha256 before promoting; never resample, "
              "regenerate, or cut from previews or GIFs.",
              "Promote through the raster pipeline: versioned sources under "
              "`assets/art_source/enemies/scarecrow_king/`, manifest entries "
              "with prompt/approval provenance, "
              "`assets/art_source/ownership.json`, then "
              "`python tools/import_art.py`; extend the hard-coded family "
              "lists the art checks use (`gen_sprites.migrated_enemies()`, "
              "0246's boss table in "
              "`check_giant_art.py`, `ArtPlacement` if needed).",
              "At the canvas 0254 settled: master, `scarecrow_king_walk_0..3`, "
              "the summon cast (4 frames) played for 0254's "
              "`telegraph_ticks`, `_attack_0..2`, `_death_0..4`, and the "
              "forecast mark",
              "Replace 0254's placeholders in 0120's registry; if no boss "
              "leaf has yet, rewrite `_task_0074_zombie_art`'s 'the Giant is "
              "the biggest thing on the field' as 'every boss outsizes every "
              "non-boss' (see 0266)",
              "Set the pack to integrated: "
              "`python implementation/backlog/assets.py set A053 integrated`."],
         dod=["`python tools/check_giant_art.py` and "
              "`python tools/show_art.py --boss=scarecrow_king --check` pass",
              "`python tools/import_art.py --check` passes",
              "FHD (1920x1080) captures in the real game by day (the mark in "
              "the dusk forecast) and by night (mid-cast with the flock "
              "rising), opened and looked at, in "
              "`implementation/shots/0267/`",
              "the sim and data hashes are unchanged (art never moves them)"]),

    dict(id=268, phase=P14, title="Art: the Winter Lord",
         slug="art-winter-lord", deps=[255], art=["A054"],
         files="assets/art_source/enemies/winter_lord/, "
               "assets/art_source/effects/, "
               "assets/art_source/manifest.json, "
               "assets/art_source/ownership.json, tools/check_giant_art.py, "
               "tools/gen_sprites.py, src/tools/headless_check.gd, "
               "tools/check_effect_art.py, src/tools/giant_showcase.gd, "
               "src/ui/enemy_motion.gd",
         goal="The Winter Lord as Codex drew it, in place of 0255's stand-in: "
              "the last thing the year sends, and the cast that freezes the "
              "line.",
         req=["`python tools/task.py next` only offers this task once "
              "`python implementation/backlog/assets.py status A054` says "
              "`approved`. Check it again first; if it does not, stop and "
              "change nothing (the task stays todo and waits). This task "
              "never draws, generates or substitutes art.",
              "Use only the folder named in the pack's "
              "`CLAUDE-A054-PROMPT.txt` handoff; check every file against its "
              "`contract.json` sha256 before promoting; never resample, "
              "regenerate, or cut from previews or GIFs.",
              "Promote through the raster pipeline: versioned sources under "
              "`assets/art_source/enemies/winter_lord/`, manifest entries with "
              "prompt/approval provenance, `assets/art_source/ownership.json`, "
              "then `python tools/import_art.py`; extend the hard-coded family "
              "lists the art checks use (`gen_sprites.migrated_enemies()`, "
              "0246's boss table in "
              "`check_giant_art.py`, the effect checker for the shards, "
              "`ArtPlacement` if needed).",
              "At the canvas 0255 settled: master, `winter_lord_walk_0..3`, "
              "the freeze cast (4) for 0255's `telegraph_ticks`, "
              "`_attack_0..2`, `_death_0..4`, the ice aura shards (4) in the "
              "effects family, and the forecast mark",
              "Replace 0255's placeholders in 0120's registry; the aura's "
              "reach on the ground and the ice on frozen towers stay code. If "
              "no boss leaf has yet, rewrite `_task_0074_zombie_art`'s 'the "
              "Giant is the biggest thing on the field' as 'every boss "
              "outsizes every non-boss' (see 0266)",
              "Set the pack to integrated: "
              "`python implementation/backlog/assets.py set A054 integrated`."],
         dod=["`python tools/check_giant_art.py`, "
              "`python tools/check_effect_art.py` and "
              "`python tools/show_art.py --boss=winter_lord --check` pass",
              "`python tools/import_art.py --check` passes",
              "FHD (1920x1080) captures in the real game by day (the mark in "
              "the dusk forecast) and by night (mid-cast, towers freezing), "
              "opened and looked at, in `implementation/shots/0268/`",
              "the sim and data hashes are unchanged (art never moves them)"]),

    dict(id=269, phase=P14, title="Art: fog, rain and the Blood Moon icons",
         slug="art-event-icons", deps=[256, 257], art=["A055"],
         files="assets/art_source/ui/, assets/art_source/manifest.json, "
               "assets/art_source/ownership.json, tools/check_ui_art.py, "
               "src/ui/forecast_panel.gd",
         goal="The three night events as Codex drew them, in the forecast slot "
              "where 0256 and 0257 left placeholders.",
         req=["`python tools/task.py next` only offers this task once "
              "`python implementation/backlog/assets.py status A055` says "
              "`approved`. Check it again first; if it does not, stop and "
              "change nothing (the task stays todo and waits). This task "
              "never draws, generates or substitutes art.",
              "Use only the folder named in the pack's "
              "`CLAUDE-A055-PROMPT.txt` handoff; check every file against its "
              "`contract.json` sha256 before promoting; never resample, "
              "regenerate, or cut from previews or GIFs.",
              "Promote through the raster pipeline: versioned sources under "
              "`assets/art_source/ui/`, manifest entries with prompt/approval "
              "provenance, `assets/art_source/ownership.json`, then "
              "`python tools/import_art.py`; extend the hard-coded family "
              "lists the art checks use (`check_ui_art.py` pins the 0018 "
              "resource set - add this pack as its own checked block).",
              "`ui/icon_fog`, `ui/icon_rain`, `ui/icon_blood_moon` at 16x16 "
              "pivot (8,8) and the matching `ui/hud_*` at 10x10 pivot (5,5), "
              "each pair cut from the same raw source at different nearest "
              "scales (visible size at most 14 and 8 px)",
              "Replace 0256's and 0257's placeholders in the forecast slot "
              "(`src/ui/forecast_panel.gd`, 0158) through 0120's registry",
              "Set the pack to integrated: "
              "`python implementation/backlog/assets.py set A055 integrated`."],
         dod=["`python tools/check_ui_art.py` and "
              "`python tools/show_art.py --ui --check` pass",
              "`python tools/import_art.py --check` passes",
              "FHD (1920x1080) captures in the real game by day (each event "
              "in the dusk forecast) and by night (the build step's "
              "forecast), opened and looked at, in "
              "`implementation/shots/0269/`",
              "the sim and data hashes are unchanged (art never moves them)"]),
]
