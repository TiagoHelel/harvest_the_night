# -*- coding: utf-8 -*-
"""Backlog part 5: phase 9, the groundwork for 1.0.

Nothing here is new to a player. It settles what the code audit of 2026-10-07
confirmed or suspected (section 13 of `docs/PLANO-DO-JOGO.md`), makes room in
the test suites for the ~180 tasks after it, gives phase 10 one road into the
waves to change, and lays down the placeholder road and the pad bindings the
guardian's cursor is built on. It comes first because every later phase leans
on it; the farmer's missing art (run and work) waits here for Codex.
"""

P9 = "9 - v1.0 groundwork"

# The lines every art leaf (0122-0125) shares word for word: the approval
# gate, where the files come from, and the hand-back to the Codex queue.
_LEAF_GATE = ("`python tools/task.py next` only offers this task once "
              "`python implementation/backlog/assets.py status {p}` says "
              "`approved`. Check it again first; if it does not, stop and "
              "change nothing (the task stays todo and waits). This task "
              "never draws, generates or substitutes art.")
_LEAF_FOLDER = ("Use only the folder named in the pack's "
                "`CLAUDE-{p}-PROMPT.txt` handoff (under "
                "`implementation/backlog/deliveries/`); check every file "
                "against its `contract.json` sha256 before promoting; never "
                "resample, regenerate, or cut from previews or GIFs.")
_LEAF_DONE = ("Set the pack to integrated: "
              "`python implementation/backlog/assets.py set {p} integrated`.")

TASKS = [
    # ===================================================== the suites and bugs
    dict(id=112, phase=P9, title="Room in the test suites",
         slug="suite-headroom", deps=[],
         files="src/tools/headless_v1.gd, src/tools/input_v1.gd, "
               "tools/verify.py, src/core/game_data.gd",
         goal="`headless_check` and `input_check` already take about 74 s each "
              "of the 120 s verify allows a script, and some 180 tasks are "
              "coming. Give 1.0 its own pair of suites, so a new rule never "
              "has to choose between being tested and the suite finishing.",
         req=["`src/tools/headless_v1.gd` copies `headless_check`'s harness: "
              "`expect()`, `passed`/`failed`, its own `GROUPS` constant with "
              "`_completed += 1` as each group's last line and `_finish()` "
              "failing a short count, the `_process()` watchdog "
              "(`WATCHDOG_SECONDS`) for an `_initialize()` that never "
              "returns, and a last line `N asserts, M failed` with a "
              "non-zero exit on any failure",
              "`src/tools/input_v1.gd` does the same for `input_check`: "
              "`MAIN_SCENE`, its own `CASES`, the 20 s stall watchdog that "
              "every `expect()` resets, the last line `N cases, M failed`; "
              "its first case boots Main and presses one real action, so the "
              "harness itself is tested",
              "Wire both into `tools/verify.py` through `check_script()` with "
              "the same patterns as the old suites (`\\d+ asserts?, \\d+ "
              "failed`, `\\d+ cases?, \\d+ failed`), skipped by `--hashes` "
              "like them, each run bounded by `SCRIPT_TIMEOUT_S` as the old "
              "two are",
              "Move nothing: every existing `_task_NNNN_*` group and "
              "`_case_NNNN_*` case stays put and `GROUPS := 103` / "
              "`CASES := 61` do not change. A plain helper the new files "
              "need (`_stand_the_farmer`, `_moved`, ...) is shared, not "
              "copied: move it into one small static script under "
              "`src/tools/` that both suites call - moving a helper is "
              "allowed, a group is not. An input helper that needs the "
              "running tree (`click_control`, `until`) takes the tree as an "
              "argument, or `input_v1` reuses `input_check`'s script some "
              "other way that keeps the two counters apart; say which",
              "Say in both new file headers that every group and case from "
              "task 0112 on lives here (`00-RUNNER-LOOP.md` already says so), "
              "and that a defence a test puts down, upgrades or sells is "
              "handled in PREPARATION, never by day (0132 forbids it by day "
              "and 0119 moves the old suites the same way)",
              "`_task_0112_digest` in `headless_v1`: read "
              "`src/core/game_data.gd` as text, collect every top-level "
              "`const` whose value is a Dictionary or Array literal (typed "
              "ones too, `const X: Array[Vector2i] = [`), and fail on any "
              "that is neither named inside `GameData.digest()` nor in an "
              "exemption list in the assert with a one-line reason each "
              "(derived enum lists such as `TARGETING`, `SHAPES`, `AIMS`, "
              "`DAMAGE_TYPES`; geometry helpers such as `NEIGHBOUR_STEPS`; "
              "view-only data). Scalar consts are not its business",
              "Run it on today's file before deciding: `MAP_LEGEND`, for one, "
              "is not in the digest. A table that is balance goes into "
              "`digest()` - DATA then moves on purpose: `python "
              "tools/verify.py --accept` and both numbers in the journal; one "
              "that is not gets its exemption and its reason. SIM does not "
              "move: this task changes no rule and no state key",
              "Write the four suite rows' times and the whole run against "
              "`BUDGET_S` in the journal"],
         dod=["verify prints a `headless_v1` row ending `N asserts, 0 failed` "
              "and an `input_v1` row ending `N cases, 0 failed`, each timed, "
              "while `headless_check` still finishes 103 groups and "
              "`input_check` 61 cases",
              "A scratch `const TEST_TABLE := {}` in `game_data.gd` makes "
              "`_task_0112_digest` fail and removing it passes again - tried "
              "and said so in the journal",
              "A deliberate early `return` before `_completed += 1` in a "
              "`headless_v1` group makes verify fail on the group count; then "
              "put back"]),

    dict(id=113, phase=P9, title="Repairs mend to the real maximum",
         slug="repairs-full-max", deps=[112],
         files="src/core/repair.gd, src/core/building.gd, "
               "src/core/game_data.gd, src/ui/world_view.gd, "
               "assets/locale/strings.csv, src/tools/headless_v1.gd, "
               "src/tools/headless_check.gd",
         goal="Mending stops at the wrong number: the house comes back only to "
              "100 when 'stout timbers' made it 140, and an upgraded tower "
              "only to its level-one hit points. A repair should put back what "
              "the thing really has when it is whole.",
         req=["`Repair.damage_at`: the house is missing `Phases.house_full("
              "state) - house_hp`, not `GameData.HOUSE_HP - house_hp`",
              "A structure's maximum is its levelled one - "
              "`Building.entry_at(state, cell)`, the base row with "
              "`TOWER_LEVELS` laid over it - not `Building.entry_of(id)`, in "
              "`damage_at` and in the cap inside `Repair.apply`",
              "`per_hp_hundredths` shares a structure's price over the same "
              "levelled maximum, so a full mend of a level-3 tower costs "
              "`REPAIR_PERCENT` of its build cost like any other; or the "
              "journal says why the base hit points stay the divisor. Either "
              "way the cost of one full repair is asserted",
              "'a full larder' (`repair_percent` 60, note `TECHNOTE_A_FULL_"
              "LARDER` 'mending costs two fifths less') reaches structures "
              "through `Tech.bonus` but the house branch of "
              "`per_hp_hundredths` ignores it. Decide whether the house gets "
              "the discount, make the code, the `note` in `TECH_TREE` and "
              "both languages of `TECHNOTE_A_FULL_LARDER` agree, and assert "
              "the decision. The `note` is inside `TECH_TREE`, which "
              "`digest()` hashes: rewording it moves DATA on purpose (accept "
              "it and write both numbers); leaving it alone moves nothing",
              "View: `world_view.gd` `_wear_of` tints by the base-table hp "
              "while `_is_hurt` uses `WorldView.levelled_stat`; make the tint "
              "read the levelled maximum too (view only)",
              "Asserts go in `headless_v1`. `Interact` offers repair through "
              "`Repair.can_mend`, so the verb follows the fix by itself - "
              "check rather than assume. An old assert that pinned the base "
              "maximum or price (`_task_0034_cooking`, `_task_0053_repair`, "
              "`_task_0057_structures` call `Repair`) is rewritten in place "
              "in `headless_check` with a comment pointing at 0113",
              "Run `python tools/autoplay.py` before and after: the robot "
              "repairs everything it can, so its nights may change. SIM can "
              "only move if the determinism scenario repairs (it does not) - "
              "say which happened"],
         dod=["`_task_0113_repairs` in `headless_v1`: with 'stout timbers' "
              "owned, food enough and the house at 90 of 140, "
              "`Repair.apply_all` on a house cell puts back exactly 50 and "
              "`needs_repair` is then false",
              "A level-3 gun tower (placed and upgraded twice in "
              "PREPARATION, where 0132 will still allow it; the upgrades "
              "need 'true sights' then 'oiled works' owned - or set the "
              "occupant's `level` to 3) at 60 of 120 is "
              "mended to 120; a level-1 tower still stops at its table hp "
              "(60)",
              "The house-discount decision is asserted with and without 'a "
              "full larder', and `python tools/i18n_check.py` passes",
              "The journal has the autoplay table before and after"]),

    dict(id=114, phase=P9, title="Untouched means the house the night "
                                  "started with",
         slug="untouched-house", deps=[112, 113],
         files="src/core/rewards.gd, src/core/tech.gd, src/core/sim.gd, "
               "src/core/enemies.gd, src/ui/night_hud.gd, "
               "src/ui/result_screen.gd, src/tools/play_nights.gd, "
               "src/tools/headless_v1.gd, src/tools/input_v1.gd, "
               "src/tools/input_check.gd",
         goal="With 'stout timbers' the house starts the night at 140, yet "
              "four rules still measure it against 100: it can lose 40 and "
              "still pay the untouched bonus, and the skip refusal and the "
              "danger bar read the wrong share. Every 'how whole is the house' "
              "question is asked of the house the night started with.",
         req=["Route through `Phases.house_full(state)`: the 'the house "
              "untouched' line in `rewards.gd` (`house_hp >= "
              "GameData.HOUSE_HP`), `Tech._earned` `&\"house untouched\"`, "
              "the percentage `Sim.why_not_skip` compares with "
              "`SKIP_MIN_HOUSE_PERCENT`, and `Enemies.house_fraction`",
              "The view reads the same number: the night HUD house bar, its "
              "text and its `HOUSE_DANGER_PERCENT` pulse (`night_hud.gd`, "
              "`full := maxi(GameData.HOUSE_HP, 1)`), the result screen's "
              "`RES_HOUSE` line, and `play_nights.gd`'s report",
              "If the tree can change between the night and its result "
              "screen, `Rewards.settle` records the full value in the payout "
              "and the screen prints that instead of recomputing it - check "
              "and say which",
              "`GameData.HOUSE_HP` outside `game_data.gd` is left only in "
              "`Phases.house_full` and `Farm.initial` (a new run's house, "
              "before any tree); 0113 (a dependency) has already taken it "
              "out of `repair.gd`. `_task_0114_untouched` in `headless_v1` "
              "reads the code lines of `src/core/` and `src/ui/` as text and "
              "keeps it so, the way `_task_0095_controls` scans for raw keys",
              "Update `input_check`'s house-bar case (~l.3350, it reads "
              "`str(GameData.HOUSE_HP)`) only if it now fails; its no-tree "
              "house is still 100",
              "No new number: 0191's house tiers build on `house_full`. The "
              "determinism scenario owns no tech, so the comparisons give "
              "the same answers and SIM should not move - but a new key in "
              "the payout (above) is hashed and moves it if the scenario's "
              "night settles; if SIM moves, say which and accept it with "
              "both numbers. DATA does not move"],
         dod=["`_task_0114_untouched`: with 'stout timbers', a night ending at "
              "120 of 140 pays no 'the house untouched' money and earns no "
              "'house untouched' tech; one ending at 140 earns both",
              "`Sim.why_not_skip` with 'stout timbers' allows a skip at 75 of "
              "140 (53 %) and refuses at 65 of 140 with `[&\"WHY_HOUSE_LOW\", "
              "46]`",
              "`_case_0114_house_bar` in `input_v1`: a 140 house reads "
              "`140/140` on the night HUD with no danger pulse"]),

    dict(id=115, phase=P9, title="Spawn ground that cannot be built shut",
         slug="spawn-room", deps=[112],
         files="src/core/waves.gd, src/core/enemies.gd, src/core/building.gd, "
               "src/core/state.gd, assets/locale/strings.csv, "
               "src/tools/headless_v1.gd",
         goal="The plan suspects that fencing every cell of a spawn line makes "
              "that side's zombies vanish: `Enemies.spawn` returns 0 when no "
              "cell is free and `Waves.tick` counts the member as sent anyway. "
              "About seventeen fences would win a night. Prove it, and if it "
              "is real, no wave member is ever lost without a trace.",
         req=["Reproduce first, headless: in PREPARATION, `Building.place` a "
              "fence on every cell of `GameData.SPAWNS[0]` (ten cells on "
              "x=68), run night 1 to its end and compare "
              "`Waves.size_of(1, seed)` with `state[\"killed\"]` plus "
              "`Entities.count`. Write the numbers in the journal whether or "
              "not the suspicion holds",
              "If it holds, pick one fix and say why: `Building.why_not` "
              "refuses the last free cells of a spawn region (a new `WHY_*` "
              "key, en and pt_BR rows in `assets/locale/strings.csv`, shown "
              "by the red ghost); or a member with nowhere to stand waits in "
              "`Waves.tick` without counting as sent; or it falls back "
              "deterministically to another cell or region",
              "Whatever is chosen draws from the run RNG only when it places "
              "somebody, exactly as `Enemies.spawn` does now",
              "No softlock: a member that never finds a cell must not hold the "
              "night open for ever. 0137's dawn will end nights, but this "
              "task cannot lean on it",
              "A save written with a region already sealed behaves by the "
              "same rule. A new state key gets a default in `initial()` and "
              "reconcile, with no `State.VERSION` bump: inside `wave` (already "
              "in `State.TABLES`) if it can live there, and a new nested "
              "Dictionary is listed in `State.TABLES` or `State.RUN_DATA`",
              "Check `SPAWNS[1]` (seven cells) and a part-blocked region too: "
              "spawning still picks only among free reachable cells, and "
              "`Enemies.spawn_cells` stays the one place that answers where "
              "one can stand (0157 adds regions on this rule)",
              "Hashes: the determinism scenario seals no region, so the "
              "rule alone changes nothing there - but `State.hash_of` hashes "
              "every key, so a new state key moves SIM by itself. If it "
              "moves, it is on purpose: accept it and write both numbers and "
              "why. A refusal key moves nothing; DATA does not move"],
         dod=["`_task_0115_spawn_room` in `headless_v1`: with the east line "
              "built over as far as the rules now allow, night 1 run to its "
              "end accounts for every member - killed plus alive plus still "
              "waiting equals `Waves.size_of(1, seed)`",
              "The same night ends within a bounded number of ticks in the "
              "assert, whichever fix was chosen",
              "If a refusal was added, it reads in both languages and "
              "`python tools/i18n_check.py` passes",
              "The journal says whether the suspicion was real, with the "
              "before numbers"]),

    dict(id=116, phase=P9, title="The mortar and the flamethrower, empty "
                                  "and upgraded",
         slug="mortar-flame-ammo", deps=[112],
         files="src/core/towers.gd, src/core/ammo.gd, src/core/game_data.gd, "
               "src/tools/headless_v1.gd, src/tools/headless_check.gd",
         goal="Two towers may not do what their tables say. An empty mortar "
              "may lob a rock that hits nobody, and the flamethrower may "
              "ignore the tree's damage and range bonuses while burning two "
              "incendiary rounds a second. Reproduce each and fix only what is "
              "real.",
         req=["Mortar: `Towers._fire` makes an unarmed shot `SHAPE_SINGLE` "
              "but leaves it ballistic, and `_advance_projectiles` lands a "
              "ballistic shot with `_land_at(state, shot, cell)` and no "
              "target, so a single-shape landing hits nobody. Reproduce "
              "through `Towers.tick`: a mortar placed in PREPARATION, a "
              "walker standing in range beyond `min_range`, the gunpowder "
              "pool empty, ticks until the shell lands. The seams "
              "`land_for_test`/`land_at_for_test` always build an armed shot "
              "with the entry's shape, so they cannot show it; give one an "
              "`armed` argument if a seam helps",
              "If real, the empty shell deals `Ammo.weak_damage` to what it "
              "lands on - the walker on the aimed cell or the target it was "
              "fired at, decide - and never 0: out of ammunition is a worse "
              "shot, never a silent tower (0035)",
              "Flamethrower: `_burn_cone` reads `entry[\"damage\"]` and "
              "`entry[\"range\"]` raw while `_acquire` uses `reach_of`; with "
              "'long barrels' it can pick a target one tile past its cone, "
              "spend a round and hit nothing. Use `Towers.damage_of(state, "
              "entry, armed)` and `reach_of(state, entry)`, and decide "
              "whether `tower_damage_percent` scales `burn_damage` too",
              "`ammo_every_ticks` (2 s on the flame tower) is read by nothing: "
              "`Ammo.spend` runs on every cone, twice a second "
              "(`reload_ticks` is `SECONDS / 2`). Charge one round per "
              "`ammo_every_ticks` of firing, the countdown on the occupant "
              "dictionary without `Farm.touch`, defaulting when an old save "
              "has no such key",
              "Mark `ammo_every_ticks` `# LEVER: ticks, 1-4 seconds worth`; "
              "`check_defences` refuses one on an entry without `ammo` or "
              "shorter than its `reload_ticks`",
              "New asserts go in `headless_v1`. An old assert that encoded a "
              "bug (`_task_0035_ammunition`, `_task_0043_flame`, "
              "`_task_0044_mortar` are where to look) is rewritten in place "
              "with a comment pointing at 0116",
              "Run `python tools/autoplay.py` before and after (its policies "
              "build mortars); SIM moves only if the determinism scenario "
              "touches these towers (it builds gun towers, which use no "
              "ammunition, and walls) - say which. DATA moves only if a "
              "table value changes; a `# LEVER` comment moves nothing"],
         dod=["`_task_0116_ammo` in `headless_v1`: an unarmed mortar shell "
              "landing on a walker takes `Ammo.weak_damage` of the mortar's "
              "damage off it (40 -> 12 at `EMPTY_DAMAGE_PERCENT` 30)",
              "With 'long barrels' a flame tower's cone hits a walker at "
              "range + 1; with 'true sights' (`tower_damage_percent` 120) "
              "the cone deals `Towers.damage_of` - assert it on the level-3 "
              "flame row (damage 5 -> 6), because level one's 3 rounds back "
              "to 3 in integer arithmetic",
              "A flame tower firing for 10 s on a full pool spends 5 rounds "
              "(10 s / `ammo_every_ticks`), not 20",
              "The journal says which of the three suspicions were real, with "
              "the autoplay table before and after"]),

    dict(id=117, phase=P9, title="Three stale documents", slug="stale-docs",
         deps=[],
         files="CHANGELOG.md, docs/PLAYTEST.md, assets/locale/strings.csv",
         goal="Three places tell a player something the game does not do. Fix "
              "the words and nothing else.",
         req=["`CHANGELOG.md` 0.1.0 says 'Sixteen crops'; there are three "
              "(`GameData.CROPS`: wheat, corn, carrot). Say three, and read "
              "the rest of that section against the game while there",
              "`docs/PLAYTEST.md` 'What to ignore' says 'Anything after night "
              "ten. It stops.' - it does not: the run carries on into "
              "generated endless nights (`Endless`, `Run.go_endless`). Say "
              "what really happens. Keep the headings `_task_0105_playtest` "
              "looks for ('What to try', 'What to ignore', 'What to report') "
              "and the line that names the note key",
              "`TUT_SELL` says the stall 'sells seeds'; it does not - seeds "
              "are paid for at planting (`CROPS[...][\"seed_cost\"]`) and "
              "`DAILY_STOCK` has none. Rewrite the line in English and "
              "Brazilian Portuguese, about as long as today's: its `width` "
              "column is 0, so `tools/i18n_check.py` checks that both "
              "languages are there and agree on `%` specifiers, and "
              "`MAX_TUTORIAL_LINE_LENGTH` measures the key, not the words",
              "Words only, no rule changes: the day-barricade allowance is "
              "0132's, the can's '/8' is 0174's, and seeds sold by season "
              "arrive with 0170 (the line moves again then). `TUTORIAL` "
              "holds the key, not the text, so neither hash moves"],
         dod=["A grep of `CHANGELOG.md` and `docs/PLAYTEST.md` finds no "
              "'Sixteen' and no 'It stops'",
              "`python tools/i18n_check.py` passes with the new `TUT_SELL` in "
              "both languages"]),

    # ================================================ one road into the night
    dict(id=118, phase=P9, title="One road into the waves",
         slug="one-road-into-night", deps=[112],
         files="src/core/phases.gd, src/core/sim.gd, "
               "src/tools/night_road.gd (new), "
               "src/tools/headless_check.gd, src/tools/input_check.gd, "
               "src/tools/headless_v1.gd, src/tools/input_v1.gd, "
               "src/tools/shot.gd, src/tools/autoplay.gd, "
               "src/tools/determinism.gd, src/tools/make_goldens.gd, "
               "src/tools/perf_check.gd, src/tools/play_nights.gd, "
               "src/tools/art_showcase.gd, src/tools/capture_dawn.gd",
         goal="About sixty-five places in the tests and tools start a night "
              "the same way: `begin_preparation`, then wait out "
              "`PREPARATION_TICKS`. Phase 10 changes how the build step ends "
              "twice (0136's START, 0137's dawn). Put the road into the waves "
              "in one place first, so those tasks change it once.",
         req=["A refactor: both hashes stay where they are and no test changes "
              "what it asserts",
              "One core entry starts the waves: `Phases.start_waves(state)`, "
              "PREPARATION to NIGHT, refusing any other phase with "
              "`push_error` like the other transitions; `Sim._tick_preparation"
              "`'s timer calls it. 0136's START intent and 0128's 30 s "
              "pass-out step will be its other callers",
              "Nothing in `src/tools/` or `src/ui/` calls `Phases.begin_night` "
              "directly any more (`art_showcase.gd` and `capture_dawn.gd` do "
              "today); `_task_0006_phases`' refused-transition check (`not "
              "Phases.begin_night(guard)`, ~l.2089) asks `start_waves` "
              "instead, or stays as an allowed exception",
              "A shared tool/test helper, e.g. `src/tools/night_road.gd` "
              "(`class_name NightRoad`, static): into the build step "
              "(`begin_preparation`); through it (the rest of the build "
              "step, `PREPARATION_TICKS - phase_tick`: on a fresh one exactly "
              "today's `Sim.advance(state, GameData.PREPARATION_TICKS)`, so "
              "the ticks are identical); both together; the night runner "
              "(step until the phase leaves NIGHT, with a cap - autoplay's "
              "40000 loop); and the park (today's `_park_the_waves`)",
              "The park is where 0137 will also hold back dawn: say so in its "
              "doc comment, and add no state key for it now (any new key "
              "moves SIM)",
              "Route every site through it: `headless_check`'s "
              "`_scheduled_night`, `_fresh_night`, `_night_falls`, "
              "`_a_run_at_night`, `_to_the_next_night`, `_armed_prep`, "
              "`_defended_night` and the inline ones; the 19 lines in "
              "`input_check`; anything 0113-0117 put in the v1 suites; "
              "`shot.gd` (its `PREPARATION_TICKS + 1` too), `autoplay.gd`, "
              "`make_goldens.gd`, `perf_check.gd`, `play_nights.gd`. "
              "`determinism.gd` folds the state into SIM every "
              "`SAMPLE_EVERY` ticks through `_advance_sampling`: its build "
              "step must keep folding at the same ticks (the road tells it "
              "how many ticks are left, or takes the stepper), or SIM moves",
              "Leave the asserts whose subject is the timer itself "
              "(`_task_0006_phases`, 'then the night begins' after "
              "`PREPARATION_TICKS - 1`), each with a comment that 0136 "
              "rewrites it",
              "A brand-new `class_name` is invisible to `--script` runs until "
              "`--import` refreshes the cache: run verify, not the scripts by "
              "hand"],
         dod=["`_task_0118_road` in `headless_v1` reads the code lines "
              "(comments skipped) of `src/tools/*.gd` and `src/ui/*.gd`: "
              "`PREPARATION_TICKS` appears only in the road and in an "
              "allow-list of timer asserts named in the assert, and "
              "`Phases.begin_night(` nowhere outside `src/core/` but its "
              "allowed exceptions (the assert's own needles excluded)",
              "`Phases.start_waves` from DAY or NIGHT returns false and "
              "changes nothing - asserted",
              "`python tools/autoplay.py` prints the same table as before the "
              "refactor, and `python tools/perf.py` stays within tolerance"]),

    dict(id=119, phase=P9, title="Tests and tools build in the build step",
         slug="build-in-preparation", deps=[118],
         files="src/tools/headless_check.gd, src/tools/input_check.gd, "
               "src/tools/headless_v1.gd, src/tools/input_v1.gd, "
               "src/tools/autoplay.gd, src/tools/determinism.gd, "
               "src/tools/shot.gd, src/tools/make_goldens.gd, "
               "src/tools/perf_check.gd, src/tools/play_nights.gd, "
               "src/tools/tower_showcase.gd, src/tools/barrier_showcase.gd, "
               "src/tools/effect_showcase.gd, src/tools/enemy_showcase.gd, "
               "src/tools/giant_showcase.gd",
         goal="0132 will forbid defences by day. Before it does, move every "
              "defence the tests and tools put down into the build step, where "
              "they are allowed today, so that rule change is a rule change "
              "and not a hundred broken set-ups.",
         req=["Every set-up `Building.place` of a defence (an id in "
              "`GameData.DEFENCES`) happens in PREPARATION, after the road's "
              "'into the build step' and before the waves: "
              "`_arm_the_farm`/`_defended_night` and the rest of "
              "`headless_check`'s ~62 place sites, `input_check`'s ~10, the "
              "v1 suites' groups from 0113-0118, `shot.gd`'s scenarios, "
              "`determinism.gd` `_set_the_farm_going`, `make_goldens.gd`, "
              "`perf_check.gd`, `play_nights.gd`. The same for every set-up "
              "`Building.upgrade` and `Building.sell` of a defence "
              "(~11 in `headless_check`): 0132 makes them follow the same "
              "rule",
              "The art gates verify runs place real defences after setting "
              "`phase` to DAY: `tower_showcase.gd`, `barrier_showcase.gd`, "
              "`effect_showcase.gd`, `enemy_showcase.gd`, "
              "`giant_showcase.gd`. They set PREPARATION around the "
              "placement, upgrade and sale instead, and their `show_art.py "
              "... --check` rows still pass (`art_showcase.gd`'s stations "
              "are buildings and stay by day)",
              "Production buildings (`GameData.BUILDINGS`: press, generator, "
              "kitchen...) stay by day: decision #4 keeps them a day job",
              "`Autoplay`: `_a_day` still gathers, crafts, buys tech and puts "
              "up production buildings; a new build step between "
              "`begin_preparation` and the waves places, upgrades and repairs "
              "defences off the same plan cursor (`_wants`, `_room_for`, "
              "`_next_step`)",
              "`_task_0068_balance` asserts 'builds what its plan names "
              "first' straight after `_a_day`: rewrite it to look after the "
              "build step",
              "Leave the asserts whose subject is the day-placement rule "
              "itself - e.g. `_task_0022`'s 'built by day', `_task_0047`'s "
              "night barricade, the tutorial's day `build` step in "
              "`_task_0041` - with a comment at each pointing at 0132",
              "In `input_check`, a defence placed through the real build mode "
              "goes down after the night button; if build mode cannot open in "
              "PREPARATION, that is a bug to fix here and say so",
              "Only SIM may move, because the determinism scenario's towers "
              "and walls now go down in PREPARATION: accept it and write both "
              "numbers and why in the journal. DATA does not move"],
         dod=["With a scratch edit to `Building.allowed_in_phase` and "
              "`why_not_upgrade` refusing every `DEFENCES` id by day "
              "(reverted before the end), a full `python tools/verify.py` "
              "fails only on the day-rule asserts this task leaves for 0132, "
              "in `headless_check` and `input_check` - listed in the "
              "journal; the v1 suites, the art showcases, autoplay and the "
              "tools pass",
              "`python tools/autoplay.py` runs, and the journal has the nights "
              "held per policy before and after",
              "`python tools/shot.py 0119` taken and opened: `wave` and "
              "`refused` still show their towers and walls"]),

    # ==================================================== placeholders and pad
    dict(id=120, phase=P9, title="One road for art that has not arrived",
         slug="placeholder-road", deps=[112],
         files="src/ui/placeholder_art.gd (new), src/ui/art_placement.gd, "
               "src/ui/house_view.gd, src/ui/pixel_effects.gd, "
               "src/ui/player_view.gd, src/ui/player_art.gd, "
               "src/ui/world_view.gd, src/ui/README.md, "
               "tools/placeholders.py (new), tools/verify.py, "
               "src/tools/headless_v1.gd",
         goal="From here on code tasks put new things on screen long before "
              "Codex has drawn them. Give them one road: a stand-in with the "
              "real pack's canvas and pivot, found through the lookup the "
              "views already use, so the leaf that brings the real art for a "
              "new thing only deletes its entry and no view code changes.",
         req=["A registry, e.g. `src/ui/placeholder_art.gd`: for each runtime "
              "path drawn before its pack is integrated, the pack id "
              "(`Axxx`), canvas, pivot, frames, seconds, loop and draw scale, "
              "taken from the Deliverables table of "
              "`implementation/backlog/packs/Axxx-<slug>.md`; where a pack "
              "has a `Spec after` task, the entry names the task that "
              "settles its geometry",
              "One lookup: views read geometry straight from "
              "`RasterArt.FRAMES` today (`art_placement.gd`, "
              "`house_view.gd`, `pixel_effects.gd`, `player_view.gd`, "
              "`world_view.gd`). Put one function in front of it that "
              "answers from `RasterArt.FRAMES` first and the registry second, "
              "and move those call sites onto it",
              "Player poses too: `PlayerArt.pose` errors on a name missing "
              "from `PlayerFrames.COUNT` (generated by `import_art.py`, never "
              "edited by hand), so a stand-in pose (0129's sleeping farmer) "
              "gets its frame count, seconds and texture path from the "
              "registry when `PlayerFrames` has no such name",
              "A stand-in is never a hand-painted PNG: an existing texture "
              "(reused, tinted or scaled), an ASCII map in "
              "`tools/sprite_maps.py` built by `tools/gen_sprites.py` and "
              "owned `ascii` in `assets/art_source/ownership.json`, or a "
              "code-drawn shape - at the canvas and pivot the real art will "
              "have, so placement and y-sorting do not move when it arrives",
              "A leaf's whole view work for a new thing is deleting the "
              "registry entry when the raster outputs land at the same paths",
              "Record the stand-ins that exist today, so the tool lists them "
              "from the start: A006's `run_<dir>_0..7` (stand-in: the walk "
              "frames at `PlayerArt.RUN_FRAME_SECONDS`) and the `<verb>_<dir>"
              "_0..3` names A007 (till, plant, water, harvest), A008 (chop, "
              "mine, collect, carry) and A009 (craft, trade, repair) will "
              "deliver (stand-in: the legacy west strip, east mirrored). "
              "These replace art already in the game under other names, so "
              "nothing asks for them yet: their leaves (0122-0125) rename the "
              "poses in `PlayerArt` and delete the entries; this task leaves "
              "`PlayerArt.pose` naming `walk_<dir>` and `<verb>` as today. "
              "The legacy strips are 48x48/(24,44) at draw 1.0 - the same "
              "screen box as the contract's 96x96/(48,88) at 0.5; record the "
              "stand-in's own geometry and note the final one",
              "`python tools/placeholders.py` prints which packs are still on "
              "stand-ins; `--check`, wired into `tools/verify.py`, fails on an "
              "entry naming a pack that does not exist or is already "
              "`integrated` (read through `implementation/backlog/assets.py`'s "
              "own loader), or a path that is also raster-owned. 0290's "
              "visual gate reads it",
              "Document the road (registry, lookup, how to add and delete an "
              "entry) at the top of the registry and in `src/ui/README.md`: "
              "the `## Art` paragraph gen_backlog adds to every dressed "
              "prompt sends the agent to task 0120's road. View only: "
              "neither hash moves"],
         dod=["`python tools/placeholders.py` lists A006, A007, A008 and A009, "
              "and `--check` fails on a scratch entry naming `A999` (then "
              "removed)",
              "`_task_0120_placeholders` in `headless_v1`: every entry "
              "resolves through the lookup to a texture whose size and pivot "
              "match the entry; the player road answers a registered name "
              "(`run_south`: 8 frames, frame 0 is the walk's texture) the "
              "way `PlayerFrames` answers a real one; and no file in "
              "`src/ui/` other than the lookup reads `RasterArt.FRAMES` "
              "directly",
              "`python tools/shot.py 0120` taken and opened: nothing on "
              "screen moved, the farmer included"]),

    dict(id=121, phase=P9, title="A controller for every action",
         slug="gamepad-bindings", deps=[112],
         files="project.godot, src/app/input_actions.gd, src/ui/main.gd, "
               "src/ui/options_controls.gd, src/ui/pause_menu.gd, "
               "src/ui/title_screen.gd, src/ui/studio_intro.gd, "
               "assets/locale/strings.csv, src/tools/input_v1.gd, "
               "src/tools/headless_v1.gd",
         goal="The plan promises a night played on a controller, and "
              "`project.godot` has not one joypad binding: only the pause "
              "menu, the title and the ident read raw pad buttons. Bind every "
              "action now, before phase 10's cursor and hotbar are built on "
              "top of them.",
         req=["A pad event for every action in `InputActions.ACTIONS`, in "
              "`project.godot`: `move_*` on the left stick and the d-pad; "
              "face, shoulder, trigger and Start/Back buttons for run, "
              "interact, cancel, build, place/remove/upgrade, inventory, "
              "night (0127's GO TO BED), ability, speed, skip_night, pause, "
              "tech, stats, log. Where there are more actions than buttons "
              "(the six seed slots), decide, write the layout in the journal "
              "and name any action left without a pad event on purpose in "
              "the assert below, with its reason",
              "Analog walking: `main.gd` writes `intent.move` as "
              "`int(Input.get_axis(...))`, which truncates a half-tilted "
              "stick to 0. Turn the stick into -1/0/1 through the action's "
              "deadzone, so a stick walks exactly like a key",
              "`InputActions.label_of` names pad buttons and axes from the "
              "strings table: new `ACT_PAD_*` rows (A, B, X, Y, LB, RB, LT, "
              "RT, Start, Back, d-pad and stick directions) in en and pt_BR. "
              "Hints and the controls screen show the pad's name when the "
              "last input came from a pad - a view-only flag in "
              "`InputActions`",
              "Rebinding keeps the devices apart: today `apply()` replaces "
              "all of an action's events with the one saved, so a rebound key "
              "would drop the pad button. Save one binding per device kind "
              "(`as_text`/`from_text` learn `joy:<button>` and "
              "`axis:<axis>:<sign>`, `is_bindable` accepts pad events), read "
              "old single `key:`/`mouse:` values as keyboard ones, and apply "
              "the clash rule within a device kind",
              "`pause_menu.gd`, `title_screen.gd` and `studio_intro.gd` read "
              "actions rather than raw `JOY_BUTTON_*`; menus and panels move "
              "focus on the d-pad/stick and accept/cancel on the face buttons "
              "through the `ui_*` actions",
              "Keep `_task_0095_controls`' sync check (project.godot "
              "`[input]` against `ACTIONS`) passing. Tutorial lines that name "
              "a key in their text (`TUT_CHOP`, `TUT_BUILD`, `TUT_NIGHT`) are "
              "0141's and 0195's; a deadzone option is 0292's",
              "Cases go in `input_v1` with synthetic events "
              "(`Input.parse_input_event` with `InputEventJoypadButton` and "
              "`InputEventJoypadMotion`). Input and view only: neither hash "
              "moves (a stick walks exactly like a key, so the intents a "
              "keyboard writes are unchanged)"],
         dod=["`_case_0121_pad` in `input_v1`: synthetic pad events walk the "
              "farmer on the stick and on the d-pad, chop a tree, open and "
              "leave build mode, press the night button and open and close the "
              "pause menu - each asserted through the state or the scene",
              "Rebinding interact to another key keeps its pad button, and "
              "rebinding its pad button keeps the key - asserted, then reset",
              "`_task_0121_pad` in `headless_v1`: every action in `ACTIONS` "
              "has a joypad event in `project.godot` except the ones the "
              "assert names with a reason, every `ACT_PAD_*` key "
              "`label_of` can return is in the strings table, and no code "
              "line in `src/ui/` names a `JOY_` constant",
              "`python tools/i18n_check.py` passes; `python tools/shot.py 0121 "
              "options_controls` opened: the pad labels fit"]),

    # ============================================ art: the farmer, finished
    dict(id=122, phase=P9, title="Art: the farmer's run", slug="art-farmer-run",
         deps=[120], art=["A006"],
         files="assets/art_source/player-fhd/, "
               "assets/art_source/manifest.json, "
               "assets/art_source/ownership.json, src/ui/player_art.gd, "
               "src/ui/placeholder_art.gd, src/tools/art_showcase.gd, "
               "src/tools/headless_check.gd, implementation/fhd-player/"
               "pilots/2026-10-04/palette-variants/promote_blue_walk.py, "
               "tools/verify.py, src/tools/shot.gd",
         goal="Running is the walk played faster. Put in the eight-direction "
              "run Codex drew for A006 at the approved 32px detail, so holding "
              "run looks like running.",
         req=[_LEAF_GATE.format(p="A006"),
              _LEAF_FOLDER.format(p="A006"),
              "Promote through the raster pipeline: versioned sources under "
              "`assets/art_source/player-fhd/`, manifest entries with "
              "prompt/approval provenance, `assets/art_source/ownership.json`, "
              "then `python tools/import_art.py`. The farmer's checks are "
              "`art_showcase.gd --locomotion` and the FHD player sources "
              "check (`promote_blue_walk.py --check`), which knows only walk "
              "and idle: extend it, or give the run its own promoter with a "
              "`--check` wired into `tools/verify.py`",
              "Runtime names `run_<dir>_0..7` for the eight directions of "
              "`PlayerArt.HEADINGS`: 80x80, pivot (40,72), `draw_scale` 0.5, "
              "`exact-source` inside the 12-colour blue garment ramp; `01.png` "
              "is frame 0, seconds and loop from the pack's contract, mirrors "
              "exactly as the handoff says (never flip a baked mirror again)",
              "`PlayerArt.pose` plays `run_<direction>` while running instead "
              "of `walk_<direction>` at `RUN_FRAME_SECONDS` (0120 left it "
              "naming the walk), its seconds from `PlayerFrames.SECONDS`; "
              "retire `RUN_FRAME_SECONDS` if nothing else reads it. Rewrite "
              "what pinned the stand-in: `_task_0073_player_art`'s running "
              "pose (~l.13300, 'runs its eight walking poses at a faster "
              "pace') and `art_showcase.gd`'s `_locomotion` (~l.1245-1290: "
              "the expected name and the seconds check)",
              "Delete A006's entry from the 0120 placeholder registry",
              _LEAF_DONE.format(p="A006")],
         dod=["`python tools/show_art.py --locomotion --check` and the FHD "
              "player sources check pass with the run in them; `python "
              "tools/import_art.py --check` passes",
              "`python tools/placeholders.py` no longer lists A006",
              "FHD captures (`python tools/shot.py 0122 --fhd`, with the "
              "farmer running; add a scenario if none shows it) by day and "
              "in the dark, in `implementation/shots/0122/`, opened: feet on "
              "the ground line, body as tall as the walk, no blue drift",
              "The sim and data hashes are unchanged (art never moves them)"]),

    dict(id=123, phase=P9, title="Art: the farmer tilling, planting, watering "
                                  "and harvesting",
         slug="art-farmer-field-work", deps=[120], art=["A007"],
         files="assets/art_source/player-fhd/, "
               "assets/art_source/manifest.json, "
               "assets/art_source/ownership.json, src/ui/player_art.gd, "
               "src/ui/placeholder_art.gd, src/tools/art_showcase.gd, "
               "src/tools/headless_check.gd, src/tools/shot.gd",
         goal="The field verbs still play the older, stockier 48x48 farmer "
              "next to the 32px walk. Put in A007's till, plant, water and "
              "harvest, drawn facing south, north and west, so the farmer is "
              "one person whatever he is doing.",
         req=[_LEAF_GATE.format(p="A007"),
              _LEAF_FOLDER.format(p="A007"),
              "Promote through the raster pipeline: versioned sources under "
              "`assets/art_source/player-fhd/`, manifest entries with "
              "prompt/approval provenance, `assets/art_source/ownership.json`, "
              "then `python tools/import_art.py`; extend "
              "`art_showcase.gd --work` (and the FHD player sources check if "
              "the pack is exact-source) for the new strips",
              "Runtime names `<verb>_<dir>_0..3` for till, plant, water and "
              "harvest x south, north, west - anticipation, contact, "
              "follow-through, recovery - at the canvas, pivot and draw scale "
              "the pack's contract states; east is west mirrored at runtime",
              "`PlayerArt.pose` picks a verb's strip by facing (today `VERBS` "
              "maps a verb to one west strip, drawn for every facing), "
              "`flip` only for `Player.EAST`; one code path for every verb, "
              "with verbs not yet converted keeping their one legacy strip, "
              "which 0124 and 0125 reuse if this lands first. The contact "
              "frame still meets the rules' completion (`player_work.gd`)",
              "The tool in hand is not tiered by art: keep the pack's fixed "
              "head ramp as delivered and record which colours it is "
              "(manifest metadata or a constant beside `PlayerArt`) so 0173 "
              "can tint it per tier; this task draws it untinted",
              "Retire the legacy `till_*`, `plant_*`, `water_*`, `harvest_*` "
              "48x48 outputs from the manifest and `ownership.json`, and "
              "their `PlayerArt.SECONDS` rows; rewrite `_task_0073_player_art`"
              " (its verb loops, ~l.13253-13276, and 'a verb is drawn even "
              "while a direction is held') and `art_showcase.gd`'s `--work` "
              "checks (`_work_frame` and `_work_cycles`, ~l.1491-1530, which "
              "pin `PlayerFrames.FEET`/`CANVAS` 48x48 and `pose(...)[\"name\"] "
              "== verb` for north and south); delete A007's registry entry",
              _LEAF_DONE.format(p="A007")],
         dod=["`python tools/show_art.py --work --check` passes with the four "
              "verbs in three directions; `python tools/import_art.py "
              "--check` passes",
              "`python tools/placeholders.py` no longer lists A007",
              "FHD captures (`python tools/shot.py 0123 --fhd`; add a "
              "scenario that holds the farmer mid-verb if none does) of each "
              "verb facing south, north, west and east, by day and in the "
              "dark, in `implementation/shots/0123/`, "
              "opened: feet planted, the same body height as the walk",
              "The sim and data hashes are unchanged (art never moves them)"]),

    dict(id=124, phase=P9, title="Art: the farmer chopping, mining, "
                                  "collecting and carrying",
         slug="art-farmer-gather-work", deps=[120], art=["A008"],
         files="assets/art_source/player-fhd/, "
               "assets/art_source/manifest.json, "
               "assets/art_source/ownership.json, src/ui/player_art.gd, "
               "src/ui/placeholder_art.gd, src/tools/art_showcase.gd, "
               "src/tools/headless_check.gd, src/tools/shot.gd",
         goal="Chopping and mining are what a first day is made of, and they "
              "still play the old 48x48 farmer. Put in A008's chop, mine, "
              "collect and carry in the 32px body.",
         req=[_LEAF_GATE.format(p="A008"),
              _LEAF_FOLDER.format(p="A008"),
              "Promote through the raster pipeline: versioned sources under "
              "`assets/art_source/player-fhd/`, manifest entries with "
              "prompt/approval provenance, `assets/art_source/ownership.json`, "
              "then `python tools/import_art.py`; extend "
              "`art_showcase.gd --work` for the new strips",
              "Runtime names `<verb>_<dir>_0..3` for chop, mine, collect and "
              "carry x south, north, west, east mirrored at runtime, at the "
              "pack's canvas, pivot and draw scale. `carry` is a view cue "
              "(`PlayerArt.COSMETIC`), not a core verb, and maps the same way",
              "If 0123 has not yet made `PlayerArt.pose` choose a strip by "
              "facing, do it here as the one path for every verb. The axe and "
              "pickaxe heads keep the pack's fixed ramp, recorded for 0173's "
              "tint, drawn untinted",
              "Retire the legacy `chop_*`, `mine_*`, `collect_*`, `carry_*` "
              "48x48 outputs and their `SECONDS` rows; update "
              "`_task_0073_player_art` and the `--work` checks for the new "
              "names; delete A008's registry entry",
              _LEAF_DONE.format(p="A008")],
         dod=["`python tools/show_art.py --work --check` and `python "
              "tools/import_art.py --check` pass",
              "`python tools/placeholders.py` no longer lists A008",
              "FHD captures (`python tools/shot.py 0124 --fhd`, with an "
              "earlier leaf's mid-verb scenario or a new one) of each verb in "
              "four facings, "
              "by day and in the dark, in `implementation/shots/0124/`, "
              "opened: the axe meets "
              "the tree and the pick meets the rock on the contact frame",
              "The sim and data hashes are unchanged (art never moves them)"]),

    dict(id=125, phase=P9, title="Art: the farmer crafting, trading and "
                                  "repairing",
         slug="art-farmer-make-work", deps=[120], art=["A009"],
         files="assets/art_source/player-fhd/, "
               "assets/art_source/manifest.json, "
               "assets/art_source/ownership.json, src/ui/player_art.gd, "
               "src/ui/placeholder_art.gd, src/tools/art_showcase.gd, "
               "src/tools/headless_check.gd, src/tools/shot.gd",
         goal="The last three legacy strips: A009's craft, trade and repair in "
              "the 32px body. Repair becomes a day job in 1.0 - the house, the "
              "barns and the stations, mended by the farmer while defences "
              "are mended by cursor at night.",
         req=[_LEAF_GATE.format(p="A009"),
              _LEAF_FOLDER.format(p="A009"),
              "Promote through the raster pipeline: versioned sources under "
              "`assets/art_source/player-fhd/`, manifest entries with "
              "prompt/approval provenance, `assets/art_source/ownership.json`, "
              "then `python tools/import_art.py`; extend "
              "`art_showcase.gd --work` for the new strips",
              "Runtime names `<verb>_<dir>_0..3` for craft, trade and repair x "
              "south, north, west, east mirrored at runtime, at the pack's "
              "canvas, pivot and draw scale; if no earlier leaf has made "
              "`PlayerArt.pose` choose a strip by facing, do it here",
              "The `repair` verb plays this strip wherever the rules still "
              "offer it (by day today, and at night until 0129/0134 move "
              "night repair to the cursor); the hammer head keeps the pack's "
              "fixed ramp for 0173",
              "Retire the legacy `craft_*`, `trade_*`, `repair_*` 48x48 "
              "outputs and their `SECONDS` rows; update "
              "`_task_0073_player_art` and the `--work` checks; delete A009's "
              "registry entry. After this no 48x48 work strip is left except "
              "fish/reel (A024)",
              _LEAF_DONE.format(p="A009")],
         dod=["`python tools/show_art.py --work --check` and `python "
              "tools/import_art.py --check` pass",
              "`python tools/placeholders.py` no longer lists A009",
              "FHD captures (`python tools/shot.py 0125 --fhd`, with an "
              "earlier leaf's mid-verb scenario or a new one) of craft at "
              "the workshop, trade at the "
              "stall and repair on the house, by day and in the dark, in "
              "`implementation/shots/0125/`, opened",
              "The sim and data hashes are unchanged (art never moves them)"]),
]
