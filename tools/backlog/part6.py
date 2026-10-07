# -*- coding: utf-8 -*-
"""Backlog part 6: phase 10, sleep is the night.

The plan's Phase 1 and its test. Going to bed becomes the reality switch, the
clock runs from 06:00 to 02:00 and ends in a pass-out, the farmer sleeps
through the night while the player defends by cursor from a free camera, the
build step waits for START and the night ends at 06:00 with a morning report.
It comes straight after the groundwork of phase 9 because every later phase
is built on this night, and 0148 asks whether it is better before any season,
crop or weapon is made for it.
"""

P10 = "10 - Sleep is the night"

TASKS = [
    # ================================================ phase 10 - the clock
    dict(id=126, phase=P10, title="The clock: 06:00 to 02:00", slug="clock",
         deps=[118],
         files="src/core/phases.gd, src/core/game_data.gd, "
               "src/ui/day_hud.gd, src/ui/world_view.gd, "
               "assets/locale/strings.csv, src/tools/headless_v1.gd",
         goal="The day gets an hour. Today's `DAY_TICKS` is mapped onto a "
              "clock that runs from 06:00 to 02:00, dusk falls at 18:00, and "
              "the light and the HUD read the hour, so every later task can "
              "speak in times of day.",
         req=["Clock levers in `game_data.gd`: `DAY_START_MINUTE := 6 * 60` "
              "(`# LEVER`, 05:00-08:00), `DAY_END_MINUTE := 26 * 60` (02:00 "
              "the next morning, `# LEVER`, 24:00-27:00) and `DUSK_MINUTE := "
              "18 * 60` (`# LEVER`, 16:00-20:00). `DUSK_AT_TICK` becomes a "
              "constant derived from them, so none of its callers change",
              "Integer helpers in `Phases`: `clock_minute(state)` (minutes "
              "since midnight of the day that began: 360 at `day_tick` 0, "
              "1560 at `DAY_TICKS`), `tick_at_minute(minute)` (the inverse, "
              "for tests and tools), and `is_dusk` reading the dusk minute. "
              "Outside DAY they answer for the moment the day ended. Until "
              "0128 the clock keeps counting past 02:00 rather than clamping",
              "`GameData.validate()` (through a `check_clock(start, dusk, end, "
              "day_ticks)` that takes its numbers as arguments, like "
              "`check_tutorial(steps)`, so a test can feed it a bad clock; "
              "it replaces today's `DUSK_AT_TICK > DAY_TICKS` line): start < "
              "dusk < end, and `DAY_TICKS` is a whole number of ticks per "
              "game minute (6 today, 12-15 after 0166), so the clock never "
              "shows a minute twice or skips one",
              "`DHUD_DAY` (today `DAY %d   %d:%02d%s`, elapsed m:ss) shows the "
              "hour as 24-hour HH:MM in both languages "
              "(`assets/locale/strings.csv`), wrapping after midnight "
              "(01:30, never 25:30); keep `DHUD_DUSK` read or delete its row, "
              "so `tools/i18n_check.py` finds no unused key. 0140 gives the "
              "clock its final look",
              "`WorldView._daylight_now` and `_ramp_now` read the hour: dawn "
              "to noon, noon to dusk at 18:00, the dusk light deepening until "
              "02:00. The night ramp does not change",
              "No rule changes: `day_percent` and `overtime_percent` keep "
              "their meaning (overtime now starts at 18:00), and the real "
              "length of the day is 0166's",
              "SIM must not move. DATA moves on purpose - dusk goes from 192 s "
              "to 144 s of the 240 s day (22:00 to 18:00 on the new clock) "
              "and the clock levers join the `time` row of `digest()`; write "
              "both numbers in PROGRESS"],
         dod=["`_task_0126_clock` in `src/tools/headless_v1.gd` asserts 06:00 "
              "at tick 0, 16:00 at `DAY_TICKS / 2`, 18:00 at `DUSK_AT_TICK`, "
              "02:00 at `DAY_TICKS`, `tick_at_minute(clock_minute(t)) == t` "
              "on minute boundaries, and that `check_clock` refuses a dusk "
              "after the end of the day and a day that is not a whole number "
              "of ticks per minute",
              "`python tools/shot.py 0126 noon dusk` opened: the HUD reads "
              "HH:MM and the evening light starts at 18:00, not later"]),

    # ================================================ phase 10 - to bed
    dict(id=127, phase=P10, title="Going to bed starts the night", slug="bed",
         deps=[126],
         files="src/core/phases.gd, src/core/house.gd, src/core/sim.gd, "
               "src/core/player.gd, src/ui/day_hud.gd, src/ui/house_view.gd, "
               "src/ui/title_screen.gd, src/ui/player_work.gd, "
               "src/tools/shot.gd, src/tools/art_showcase.gd, "
               "src/tools/house_check.gd, assets/locale/strings.csv, "
               "src/tools/headless_check.gd, src/tools/input_check.gd, "
               "src/tools/headless_v1.gd, src/tools/input_v1.gd",
         goal="Going to bed is the reality switch. The bed in the farmhouse "
              "and the night button both put the farmer to sleep, and sleeping "
              "is what starts the build step - the plan's section 12, 'when he "
              "sleeps, the farm switches reality'.",
         req=["One road: the `begin_night` intent edge becomes `sleep` in "
              "`Player.initial()`, `Sim._tick_day`, the day HUD "
              "(`day_hud.gd` ~285), the `night` action, the title backdrop "
              "(`title_screen.gd` ~231), `player_work.gd` (~40, which reads "
              "it), `shot.gd` (~317, ~443), `art_showcase.gd` (~1692), "
              "`house_check.gd` (~168) and every test (grep "
              "`\"begin_night\"`; `Phases.begin_night` the transition keeps "
              "its name). `intent` is in `State.TABLES`, so reconcile drops "
              "the old field and fills the new one: no `State.VERSION` bump, "
              "and the goldens still load",
              "`Phases.go_to_bed(state)` (DAY only; refuses and says so "
              "otherwise) is what the intent and the bed call; it runs "
              "`begin_preparation`, and **`begin_preparation` is what sets** a "
              "new `asleep` field of `house_visit` (a TABLES structure), so "
              "every road into the build step - the bed, the button, 0128's "
              "pass-out and 0118's `NightRoad` used by the tests and tools - "
              "leaves him asleep, and 0129's rule holds everywhere. **Asleep "
              "is not `House.inside`**: `begin_preparation` still calls "
              "`House.leave`, so `Building.why_not`, `Building.set_active` "
              "and the world view keep working. Add `House.asleep(state)`; "
              "`begin_day` clears the flag until 0138 wakes him in bed",
              "The bed gets a verb: indoors, interact on a floor cell next to "
              "the bed's `HOUSE_FURNITURE` rectangle writes the same `sleep` "
              "intent (in `House.tick`), with a `HOUSE_BED_HINT` line "
              "('%s: go to bed', en and pt_BR, beside `HOUSE_ENTER_HINT`) in "
              "the house view. Keep it out of `Interact.DAY_ONLY`: a verb on "
              "that list needs a `Sfx.VERB_SOUNDS` entry "
              "(`_task_0084_day_sounds`); if it goes there anyway, map it to "
              "the nearest existing sound until 0281 gives it its own",
              "The day HUD's `NightButton` keeps its node name and becomes GO "
              "TO BED / IR DORMIR (`DHUD_TO_NIGHT`, `DHUD_NIGHT_WAITING` "
              "reworded); pressed anywhere on the farm, the farmer goes home "
              "and sleeps behind a fade, with no walking. The `night` action "
              "keeps its id (saved bindings are keyed by it) and `ACT_NIGHT` "
              "reads 'Go to bed'. 0140 owns the button's look and reminders",
              "Sleeping early skips the rest of the day. Decide what the "
              "skipped hours do and write why in the journal. This prompt "
              "recommends that they are neither lived nor credited: crafting "
              "queues, regrowth, livestock and the generator keep their "
              "progress and resume at 06:00 (no lost work), and nothing is "
              "produced for hours nobody lived (no exploit). That is what "
              "the night button does today, so the recommended choice needs "
              "no new code - only the decision, the journal line and the "
              "assert",
              "Rewrite the tests this task owns: `_task_0021_night_intent` "
              "(the sleep intent gets the build step, is consumed, is refused "
              "twice, and dusk never presses it), `_task_0111_house` ('defence "
              "starts outside' becomes 'the night starts asleep, not inside'; "
              "a house visit still cannot bypass the night), "
              "`_case_0111_farm_house` (~1956, 'starting night inside returns "
              "outside for defence'), every `NightButton` site in input_check "
              "(clicks ~1066-4993, requires ~1060-6355), the text case ~6355 "
              "('GO TO BED' / 'IR DORMIR') and the intent at ~6452",
              "SIM moves on purpose (an intent field is renamed and "
              "`house_visit` gains a field, and both are hashed): record the "
              "old and new numbers. DATA does not move"],
         dod=["`_task_0127_bed` in `headless_v1.gd`: the bed and the intent "
              "both land in PREPARATION with `asleep` true and `inside` "
              "false; both are refused in PREPARATION, NIGHT and RESULT; the "
              "early-sleep rule the journal chose holds (e.g. a queue started "
              "at 09:00 and slept on keeps its progress and is not finished "
              "overnight)",
              "`_case_0127_bed` in `input_v1.gd`: walk into the house, stand "
              "by the bed, press interact - the build step begins; clicking "
              "GO TO BED from the far field does the same",
              "`python tools/shot.py 0127 house_interior dusk` opened, also "
              "with `--pt_BR`: the bed hint and the GO TO BED button read "
              "right and fit"]),

    dict(id=128, phase=P10, title="Passing out at 02:00", slug="pass-out",
         deps=[127],
         files="src/core/sim.gd, src/core/phases.gd, src/core/house.gd, "
               "src/core/game_data.gd, src/core/events.gd, "
               "src/ui/title_screen.gd, src/ui/log_panel.gd, "
               "src/tools/autoplay.gd, assets/locale/strings.csv, "
               "src/tools/headless_check.gd, src/tools/input_check.gd, "
               "src/tools/headless_v1.gd",
         goal="The day finally ends. A farmer still awake at 02:00 collapses "
              "where he stands and the night begins anyway, with only a "
              "thirty-second build step: staying up late is allowed, and it "
              "costs preparation, not the run.",
         req=["In `Sim._tick_day`, on the tick `day_tick` reaches `DAY_TICKS` "
              "(02:00), `Phases.pass_out(state)`: whatever he was doing stops "
              "(his action, a fishing cast), `house_visit.asleep` and a new "
              "`house_visit.passed_out` are set, and `begin_preparation` runs "
              "- indoors or out. A panel that stops the clock also stops "
              "02:00 from arriving, as today",
              "`PASS_OUT_PREPARATION_TICKS := 30 * SECONDS` (`# LEVER`, 15-60 "
              "seconds worth): after a pass-out the build step ends itself "
              "after this many ticks, through 0118's `Phases.start_waves`; "
              "an ordinary bedtime keeps today's "
              "`PREPARATION_TICKS` until 0136 removes it (the build step's "
              "`phase_tick` is the counter; no new key). `validate()` checks "
              "it is positive and below `Sim.MOST_TICKS_IN_A_NIGHT`, and it "
              "joins the `time` row of `digest()`",
              "The clock clamps at 02:00, and `overtime_percent` now runs "
              "0-100 from dusk to 02:00 and never past it",
              "A `passed_out` event: a new `Events.KINDS` entry, a severity "
              "in `log_panel.gd` and a `LOG_PASSED_OUT` line in both "
              "languages, so the log says why the build step is short; add "
              "its sample to `_task_0090_log` (headless_check), which fails "
              "on a kind without one. The fade from where he fell is the "
              "transition's; the collapse itself is A001's (0129 registers "
              "it, 0143 integrates it)",
              "Anything that spends a whole `DAY_TICKS` by day now passes "
              "out into a night. `Autoplay._a_day` spends exactly that and "
              "then calls the road into the build step, which would find it "
              "already there: make it stop short of 02:00 and go to bed (0142 "
              "rewrites the loop properly). Check the long day advances in "
              "the suites too - `_task_0002_tick_and_rng`'s 10000 ticks, "
              "`_task_0005_guards`' 20000-tick replay, `_task_0030_fishing`'s "
              "idle `DAY_TICKS`, `_task_0038_idle`, `_mine_for_a_day` - and "
              "either keep them inside the day or accept the night on "
              "purpose; report the suite times",
              "Rewrite `_task_0039_clock`: 'the night never starts itself' "
              "becomes 'at 02:00 he passes out and the night starts itself'. "
              "The stubborn-player block keeps its point - ignoring the clock "
              "costs nothing beyond the short build step (house, money, wood "
              "and the planted crop are what they were at 02:00)",
              "The title backdrop (`title_screen.gd`) stops writing the sleep "
              "intent at dusk: it starts its clock shortly before 02:00 and "
              "lets the pass-out bring the night. Update `_case_0091_title`, "
              "which compares `backdrop_tick()` with `DUSK_AT_TICK` (~5439)",
              "SIM moves on purpose: `house_visit` gains `passed_out` (hashed "
              "like every state key), and the determinism scenario's second "
              "day (about 12700 ticks after `begin_day`) now runs past 02:00 "
              "into a pass-out night. Record both numbers. DATA moves (a new "
              "lever in `digest()`)"],
         dod=["`_task_0128_pass_out` in `headless_v1.gd` (write `day_tick` "
              "near the end rather than playing the day): still DAY at "
              "`DAY_TICKS - 1`; PREPARATION with `asleep` and `passed_out` at "
              "`DAY_TICKS`; NIGHT after exactly `PASS_OUT_PREPARATION_TICKS`; "
              "a farmer indoors passes out too; going to bed at 01:59 is an "
              "ordinary night",
              "The rewritten `_task_0039_clock`, `_task_0090_log` and "
              "`_case_0091_title` pass, and `python tools/autoplay.py` still "
              "plays its nights",
              "`python tools/shot.py 0128 --title` opened: the backdrop farm "
              "still reaches the night"]),

    # ============================================ phase 10 - asleep, camera
    dict(id=129, phase=P10, title="He stays in bed all night",
         slug="asleep-all-night", deps=[127, 120, 128],
         dresses=["A001", "A002"],
         files="src/core/player.gd, src/core/ability.gd, "
               "src/core/building.gd, src/ui/main.gd, src/ui/night_hud.gd, "
               "src/ui/player_view.gd, src/ui/house_view.gd, "
               "src/ui/world_view.gd, src/ui/placeholder_art.gd, "
               "src/tools/headless_check.gd, src/tools/input_check.gd, "
               "src/tools/headless_v1.gd, src/tools/input_v1.gd",
         goal="Nobody walks at night. The farmer is in bed from the moment he "
              "sleeps until the morning, and the two things the night used "
              "him for - the flare and the repair - keep working without him "
              "until the cursor takes them over.",
         req=["`Player.tick` returns at once while `House.asleep` (consuming "
              "the `interact` and `cancel` edges): no movement, no verbs, no "
              "turn in PREPARATION or NIGHT. `main.gd` writes `intent.move = "
              "[0, 0]` and no highlight outside DAY, which frees the move "
              "axes for 0130's camera",
              "Interim flare until 0135: `Ability.use` centres on "
              "`Farm.house_centre(state)` instead of `Player.cell`; "
              "`_task_0054_ability`'s and `_case_0054_ability`'s (~3140, "
              "'recorded where the player is standing') 'goes off at the "
              "player' becomes the house, for now",
              "Interim repair until 0134: a new edge intent `repair_cell` "
              "(`[-1, -1]` when idle; a new field of `intent`, which is in "
              "TABLES, so reconcile fills it) is consumed in `Building.tick` "
              "in PREPARATION and NIGHT and calls `Repair.apply_all` on that "
              "cell; the night HUD's REPAIR button writes the house's cell "
              "and is enabled while `Repair.can_mend` allows it. No new "
              "`X.tick` in `sim.gd`, so `PerfNames` is untouched",
              "Rewrite `_task_0022_reality`'s 'the player walks his defences "
              "at night' as 'he stays in bed all night' (600 ticks of move "
              "and interact change nothing about him)",
              "Every test that has the farmer walk or use a verb in "
              "PREPARATION or NIGHT now fails - a scratch run of both suites "
              "lists them. Known ones: `_task_0053_repair` and "
              "`_case_0053_repair` mend a wall at night with the held key "
              "(move those night mends onto `repair_cell`; 0134 then takes "
              "the defences' day verb away), and `_case_0056_night_hud`'s "
              "REPAIR block (~3395-3420, 'facing a broken wall') now mends a "
              "damaged house",
              "View: at night the farm shows nobody on the porch; the "
              "farmhouse windows stay lit (`lighting.gd` lights them already) "
              "and a Zzz drifts up from the house - a view cue, not a "
              "`Reactions` kind, so the hash never sees it",
              "Register the four A001 animations in 0120's placeholder "
              "registry under the names the pack will deliver - get into "
              "bed, the sleep loop, wake and stretch, pass out on the farm - "
              "with stand-ins (the idle frame turned or tinted is enough), "
              "and the Zzz for A002. The switch opens with a short interior "
              "beat of him getting into bed and asleep (view only: the rules "
              "are already in PREPARATION), the pass-out plays where he fell, "
              "and 0138 plays the wake",
              "SIM moves on purpose: `intent` gains `repair_cell`, and every "
              "state key is hashed (and more if the determinism scenario "
              "walks or flares at night - say which). Record both numbers. "
              "DATA does not move"],
         dod=["`_task_0129_asleep` in `headless_v1.gd`: in PREPARATION and in "
              "NIGHT, 600 ticks of move and interact leave his position, "
              "facing and action unchanged; a flare lands on the house "
              "centre; `repair_cell` on a damaged house mends it, charges "
              "what `Repair.cost_at` says, and changes nothing when the "
              "ledger cannot pay",
              "`_case_0129_asleep` in `input_v1.gd`: holding D at night does "
              "not move `Player.position`; clicking `RepairButton` mends a "
              "damaged house",
              "`python tools/shot.py 0129 dusk wave` and "
              "`python tools/shot.py 0129 --switch` opened: the bed beat, "
              "nobody on the porch at night, the windows lit, the Zzz "
              "visible"]),

    dict(id=130, phase=P10, title="The night camera", slug="night-camera",
         deps=[129, 121],
         files="src/ui/main.gd, src/ui/world_view.gd, src/core/game_data.gd, "
               "project.godot, src/app/input_actions.gd, "
               "assets/locale/strings.csv, src/tools/shot.gd, "
               "src/tools/input_v1.gd",
         goal="At night the camera belongs to the player, not to the farmer: "
              "it pans over the whole farm with the keys, the screen edge or "
              "the right stick, so the guardian can look wherever the horde "
              "is.",
         req=["From PREPARATION until the day begins, `main.gd` stops calling "
              "`follow_player` and the world camera pans: with the move axes "
              "(WASD, the arrows, and the left stick 0121 bound to them), "
              "with the mouse inside an edge band of the window (only while "
              "the window has focus and the pointer is in it), and with the "
              "right stick",
              "The right stick gets actions of its own: `pan_left`, "
              "`pan_right`, `pan_up`, `pan_down` in `project.godot` and "
              "`InputActions.ACTIONS` (`ACT_GROUP_NIGHT`, `ACT_PAN_*` strings "
              "in both languages), rebindable, with the sync and clash checks "
              "passing",
              "Pan speed and edge width are `# LEVER`s in `game_data.gd` - "
              "view feel, not balance, so they stay out of `digest()`. Speed "
              "is in real seconds whatever 1x/2x/4x is set, and nothing pans "
              "while the pause menu is up",
              "Clamped by `WorldView._camera_bounds`, no zoom. The night "
              "opens with the camera on the house; RESULT leaves it where it "
              "is; when the day begins it goes back to the farmer",
              "`shot.gd` gains a camera hook that a night scenario can set "
              "(rewrite the comment that says the camera cannot be set); "
              "`dusk`, `wave` and `result` use it",
              "View only: neither hash moves"],
         dod=["`_case_0130_night_camera` in `input_v1.gd`: holding D at night "
              "moves the camera right by about speed x time and leaves the "
              "farmer where he is; panning past the farm edge stops at the "
              "bound; a synthetic right-stick motion pans; after the morning "
              "the camera is back on the farmer",
              "`python tools/shot.py 0130 wave` opened: the camera is where "
              "the scenario put it, not on the porch"]),

    # ============================================ phase 10 - the guardian
    dict(id=131, phase=P10, title="The guardian's cursor",
         slug="guardian-cursor", deps=[130, 121, 120],
         dresses=["A003", "A004"],
         files="src/ui/guardian_cursor.gd (new), src/ui/guardian_view.gd "
               "(new), src/ui/main.gd, src/ui/world_view.gd, "
               "src/ui/build_mode.gd, src/ui/tooltip.gd, src/ui/describe.gd, "
               "src/ui/lighting.gd, src/ui/placeholder_art.gd, "
               "src/app/input_actions.gd, project.godot, "
               "assets/locale/strings.csv, src/tools/headless_v1.gd, "
               "src/tools/input_v1.gd, implementation/backlog/packs/",
         goal="The player's hand at night: a cell cursor that the mouse or "
              "the pad drives, that says what is under it, and that every "
              "night action points at - held by the porch scarecrow, who "
              "wakes up to be the guardian.",
         req=["A cell cursor in PREPARATION and NIGHT only. With the mouse it "
              "is the cell under the pointer (`WorldView.screen_to_cell`); "
              "with a pad the dpad and the left stick step it one cell per "
              "press with a hold-repeat (delay and rate are view levers) and "
              "the camera follows it near the edge. The last device used "
              "decides, as 0121's glyphs do, so the keyboard keeps panning "
              "(0130) while a pad steps",
              "It writes the levels the rules read - `build_cell` now, "
              "`ability_cell` from 0135 - and BuildMode's ghost and its "
              "`Pathing.route_if_blocked` preview follow the cursor instead "
              "of the raw pointer",
              "A tooltip of what is under it through `tooltip.gd` and "
              "`Describe`: a structure (name, HP against its levelled "
              "maximum, level), an enemy (kind, HP) or empty ground, with "
              "strings in both languages",
              "Seven highlight states, all registered now in 0120's "
              "placeholder registry so later tasks only switch them on: "
              "neutral, can place, blocked, upgrade, sell, repair, aim - a "
              "code-drawn outline with a 2-frame pulse until A004 is "
              "integrated by 0146. This task uses neutral, can place and "
              "blocked",
              "Any new pad action (a confirm or back for the cursor, if 0121 "
              "left `place` and `remove` without a pad button) goes into "
              "`project.godot` and `InputActions.ACTIONS` with `ACT_*` "
              "strings and is rebindable on the controls page; the clash "
              "check passes",
              "The porch guardian: a view-only prop at a fixed offset from "
              "`House.porch`, on a cell nothing can ever be built on (the "
              "house's own footprint beside the door is one) - not an "
              "occupant and not in the state, so the hash cannot see it. "
              "States: day (still), wake (plays at the reality switch), "
              "night (idle, the eyes lit as emission points `lighting.gd` "
              "reads) and point; placeholder until A003 is integrated by "
              "0145. This task registers all four and plays the first three; "
              "0133 makes it point when a defence goes down",
              "Settle A003's and A004's geometry from what this task drew: "
              "canvas, pivot, frames per state, seconds per frame, emission "
              "points",
              "View only: neither hash moves"],
         dod=["`_case_0131_cursor` in `input_v1.gd`: a synthetic mouse move "
              "puts the cursor on that cell; synthetic dpad presses step it "
              "one cell each and repeat when held; a placement at the cursor "
              "in PREPARATION lands on that cell; there is no cursor by day",
              "`_task_0131_guardian` in `headless_v1.gd`: the guardian's cell "
              "is never buildable (`Farm.buildable` false) on a new farm",
              "The Deliverables tables of "
              "`implementation/backlog/packs/A003-guardian.md` and "
              "`implementation/backlog/packs/A004-cursor.md` state the final "
              "geometry this task settled",
              "`python tools/shot.py 0131 dusk wave` and `--fhd` captures "
              "opened: the cursor reads over dark ground, the tooltip does "
              "not cover the HUD, the guardian stands by the porch with its "
              "eyes lit at night"]),

    dict(id=132, phase=P10, title="Defences go down only at night",
         slug="defences-at-night", deps=[131, 119],
         files="src/core/building.gd, src/core/game_data.gd, "
               "src/core/phases.gd, src/core/tutorial.gd, src/core/sim.gd, "
               "src/ui/build_mode.gd, assets/locale/strings.csv, "
               "src/tools/headless_check.gd, src/tools/input_check.gd, "
               "src/tools/headless_v1.gd",
         goal="The plan's decision 4: defences are placed, upgraded and sold "
              "only at night, by cursor, and production buildings only by "
              "day. The day earns and the night spends.",
         req=["`Building.allowed_in_phase`: a `DEFENCES` id only in "
              "PREPARATION and NIGHT, a `BUILDINGS` id only in DAY. `why_not` "
              "answers `WHY_ONLY_AT_NIGHT` for a defence by day (the string "
              "exists) and `WHY_NOT_AT_NIGHT` for a building after dark; "
              "`why_not_upgrade` and `sell` follow the same rule; "
              "`catalogue()` keeps following `allowed_in_phase`. The plan "
              "(4.3) lets upgrades go on during the waves, so "
              "`why_not_upgrade`'s `WHY_MID_NIGHT` refusal goes: rewrite "
              "`_task_0064_tower_levels` (~11931), and delete the "
              "`WHY_MID_NIGHT` row if nothing reads it any more "
              "(`tools/i18n_check.py` fails on an unused key)",
              "`placeable_at_night` goes: drop it from the barricade and drop "
              "the `check_defences` rule that tied it to a lifetime and a "
              "nightly limit. The barricade keeps `lifetime_ticks` and "
              "`per_night_limit` as its own identity (cheap, temporary, "
              "limited). Section 13's bug must not come back in the build "
              "step, which has no clock after 0136: a barricade placed in "
              "PREPARATION counts against tonight's limit "
              "(`Building.forget_tonight` moves from `begin_night` to "
              "`begin_preparation`) and its lifetime starts with the waves, "
              "not when it went down",
              "At night upgrade and sell go through the cursor: BuildMode's "
              "`upgrade` and `remove` write `build_upgrade` and `build_sell` "
              "at the cursor cell, and the cursor shows its upgrade and sell "
              "states (0131's registry)",
              "By day `B` lists only production buildings; at night the "
              "palette lists only defences (0133 turns it into the hotbar)",
              "The tutorial's `build` step moves to the night: it follows "
              "`night` in `TUTORIAL`, `Tutorial.tick` also runs on its beat "
              "in `_tick_preparation`, and `TUT_BUILD` says it happens at "
              "night, in both languages. 0141 writes the rest of the night's "
              "steps",
              "Rewrite `_task_0047_barricades` ('only the barricade goes down "
              "at night' becomes 'every defence goes down at night and none "
              "by day; buildings only by day'), `_task_0022_reality`'s 'built "
              "by day' wording and `_task_0041_tutorial`'s build step; any "
              "input_check case still placing a defence by day moves to the "
              "build step (0119 should already have moved them)",
              "A rule change: if SIM moves, record both numbers and why (0119 "
              "moved the determinism scenario's placements into PREPARATION, "
              "so it may not). DATA moves (the barricade and the tutorial)"],
         dod=["`_task_0132_night_build` in `headless_v1.gd`: for every "
              "`DEFENCES` id, `can_place` is false by day with the night "
              "refusal and true in PREPARATION and NIGHT on a clear cell; the "
              "reverse for every `BUILDINGS` id; upgrade and sell follow, and "
              "a tower upgrades mid-wave; the barricade still expires and "
              "still has its nightly limit, and one placed in PREPARATION "
              "counts against that limit and still stands for "
              "`lifetime_ticks` after the waves begin",
              "`python tools/shot.py 0132 refused` and a day build-mode "
              "capture opened: by day the list holds buildings only, at "
              "night defences only"]),

    dict(id=133, phase=P10, title="The hotbar of defences", slug="hotbar",
         deps=[132],
         dresses=["A005"],
         files="src/ui/hotbar.gd (new), src/ui/build_mode.gd, "
               "src/ui/night_hud.gd, src/ui/day_hud.gd, src/ui/tooltip.gd, "
               "src/ui/guardian_view.gd, src/ui/placeholder_art.gd, "
               "project.godot, src/app/input_actions.gd, "
               "assets/locale/strings.csv, src/tools/input_v1.gd",
         goal="The night's shop window: a hotbar of every defence with its "
              "price, picked with a number key, a click or a bumper instead "
              "of a text list, so what the day earned is visible as walls "
              "and towers.",
         req=["In PREPARATION and NIGHT a hotbar along the bottom replaces "
              "BuildMode's text palette: one slot per id of "
              "`Building.catalogue(state)`, in that order, with its icon and "
              "price - the kit count when a kit is held, else "
              "`Building.cost_of`, greyed with what is short when "
              "`Building.affordable` says no, and the barricade's "
              "`left_tonight`. By day `B` keeps the text list of buildings",
              "Built from the catalogue, not a list: phase 13's six new "
              "defences appear with no edit here, and more slots than fit "
              "page or scroll",
              "Selection goes through `Building.select`, the road the palette "
              "rows use today: a click on a slot; `slot_1`..`slot_8` (add "
              "`slot_7` and `slot_8` - slots 1-6 are the seed keys by day "
              "(`DayHud.SEED_ACTIONS`) and mean hotbar slots at night, when "
              "the seed strip ignores them; `ACT_SLOT_*` stop saying 'SEED' "
              "in both languages); and `hotbar_prev`/`hotbar_next` on two "
              "pad buttons 0121's layout left free (the bumpers if they are) "
              "and a key pair, wrapping. New actions go into `project.godot` "
              "and `InputActions.ACTIONS` with `ACT_*` strings, rebindable, "
              "with the clash check passing. `cancel` clears the selection "
              "and the cursor goes back to inspecting",
              "Each slot's tooltip shows name, cost, HP, range and damage "
              "read from `GameData` (never copied) through `tooltip.gd`",
              "Icons through the placeholder road - the structure's own "
              "sprite scaled down is enough - until A005 is integrated by "
              "0147",
              "The porch guardian (0131) plays its point state when a "
              "defence goes down, spotted by the view the way `sfx.gd` and "
              "`particles.gd` compare this frame's occupants with the last - "
              "no new `Events` kind, which would move SIM",
              "View only: neither hash moves. The night HUD's bottom-right "
              "controls stay clickable (0139 settles the final layout)"],
         dod=["`_case_0133_hotbar` in `input_v1.gd`: `slot_2` selects the "
              "second defence, clicking a slot selects it, a bumper cycles "
              "and wraps, a placement at the cursor uses the selection, an "
              "unaffordable slot shows its shortfall, `slot_2` at night "
              "leaves the selected seed alone, and the guardian is in its "
              "point state after the placement",
              "`python tools/shot.py 0133 wave refused` and `--fhd` captures "
              "opened, also with `--pt_BR`: prices legible, nothing "
              "overlapping the night HUD"]),

    dict(id=134, phase=P10, title="Repairing by cursor",
         slug="repair-by-cursor", deps=[131, 113, 133],
         files="src/core/interact.gd, src/core/building.gd, "
               "src/core/repair.gd, src/ui/guardian_cursor.gd, "
               "src/ui/night_hud.gd, src/ui/build_mode.gd, "
               "assets/locale/strings.csv, src/tools/headless_check.gd, "
               "src/tools/input_check.gd, src/tools/headless_v1.gd, "
               "src/tools/input_v1.gd",
         goal="Repairs at night are made by pointing, not by walking. A "
              "damaged defence or the house is mended by selecting it with "
              "the cursor, paid as today, and defences are mended no other "
              "way.",
         req=["At night, confirming the cursor on a damaged structure or the "
              "house (an occupied cell, or nothing selected in the hotbar) "
              "writes 0129's `repair_cell` at the cursor; any part of a "
              "multi-cell structure mends its anchor (`Building.anchor_of`). "
              "Mending is `Repair.apply_all`: as far as the ledger covers, at "
              "today's price (`Repair.cost_at`, the house at "
              "`HOUSE_REPAIR_PERCENT`), up to 0113's real maximum",
              "The cursor shows its repair state over anything "
              "`Repair.can_mend` allows, and the tooltip adds what a full "
              "repair costs and how much can be afforded "
              "(`Repair.max_affordable`)",
              "Defences lose the farmer's repair verb: `Interact._offered` "
              "offers `repair` only for the house, production buildings and "
              "stations, by day. A damaged defence by day offers nothing and "
              "waits for the night. Gate it in `_offered`, not by adding "
              "`repair` to `Interact.DAY_ONLY`: every verb there needs a "
              "`Sfx.VERB_SOUNDS` entry (`_task_0084_day_sounds`) and there "
              "is no repair sound; if it must go there, map it to the "
              "nearest existing sound until 0281",
              "There is no farmer, so there is no per-HP work time any more: "
              "write in the journal what that does to a siege (a scripted "
              "wall under attack, mended every second, against today's held "
              "key) and whether a lever will be needed",
              "The interim REPAIR button of 0129 leaves the night HUD (0139 "
              "lays out what is there instead), and with it its string: "
              "delete the `NHUD_REPAIR` row, or `tools/i18n_check.py` fails "
              "on an unused key. Update what names `RepairButton`: "
              "`_case_0056_night_hud` (~3355, ~3407), `_case_0081_theme`'s "
              "size loop (~4403) and the RepairButton half of 0129's "
              "`_case_0129_asleep`, which now mends through the cursor",
              "Rewrite `_task_0053_repair` and `_case_0053_repair` where they "
              "mend a defence with the farmer's verb by day; the house by "
              "day keeps the verb",
              "A rule change: SIM moves if the determinism scenario repairs a "
              "defence by day - say which"],
         dod=["`_task_0134_cursor_repair` in `headless_v1.gd`: a damaged gun "
              "tower mended through `repair_cell` at night costs exactly "
              "`Repair.cost_at`; it is refused, changing nothing, when the "
              "ledger cannot pay; a damaged wall by day offers the farmer no "
              "verb; the house by day still does",
              "`_case_0134_repair` in `input_v1.gd`: confirming the cursor on "
              "a damaged wall at night mends it, with the mouse and with a "
              "synthetic pad press; no `RepairButton` exists any more and "
              "`python tools/i18n_check.py` passes",
              "A capture of the repair cursor and its tooltip, opened"]),

    dict(id=135, phase=P10, title="The flare goes where you aim it",
         slug="aimed-flare", deps=[131],
         files="src/core/ability.gd, src/core/player.gd, src/ui/main.gd, "
               "src/ui/guardian_cursor.gd, src/ui/world_view.gd, "
               "src/ui/night_hud.gd, src/tools/headless_check.gd, "
               "src/tools/input_check.gd, src/tools/headless_v1.gd, "
               "src/tools/input_v1.gd",
         goal="The flare goes off where the player aims it, not where "
              "somebody is standing. It is the night's one power today and "
              "the first of the plan's aimed powers.",
         req=["A level intent `ability_cell` (`[-1, -1]` is nowhere), written "
              "every frame from the cursor like `build_cell`; a new field of "
              "`intent`, filled in old saves by reconcile",
              "`Ability.use` centres on `ability_cell`. Nowhere or off the "
              "farm is refused and spends nothing - no cooldown, no `flares` "
              "count. 0129's interim house centre goes",
              "Aiming: while the flare is ready, holding the ability key or "
              "arming the FLARE button shows the radius around the cursor "
              "(`ABILITY.radius_tiles`, a Chebyshev square, the way "
              "`Ability.use` measures it) and the cursor's aim state. The key "
              "fires on press at the cursor; the armed button fires on the "
              "next confirm; `cancel` disarms. The pad uses the same actions "
              "through 0121's bindings",
              "Final `_task_0054_ability` and `_case_0054_ability`: the flare "
              "lands on the aimed cell; rewrite the flare half of 0129's "
              "`_task_0129_asleep` (it asserted the interim house centre)",
              "SIM moves on purpose: `intent` gains `ability_cell`, and every "
              "state key is hashed (more if the determinism scenario fires a "
              "flare - say which). Record both numbers. DATA does not move"],
         dod=["`_task_0135_aimed_flare` in `headless_v1.gd`: with one zombie "
              "by the aimed cell and one by the house, only the first is hit "
              "and slowed; a flare at nowhere is refused and keeps its charge",
              "`_case_0135_flare_aim` in `input_v1.gd`: moving the cursor and "
              "pressing the ability key flares that cell; arming the button "
              "and clicking flares the clicked cell",
              "A capture of the aiming preview, opened: the square matches "
              "what the flare hits"]),

    # ======================================== phase 10 - START and dawn
    dict(id=136, phase=P10, title="The build step waits for START",
         slug="start-button", deps=[118, 132, 128],
         files="src/core/sim.gd, src/core/phases.gd, src/core/game_data.gd, "
               "src/core/player.gd, src/ui/night_hud.gd, project.godot, "
               "src/app/input_actions.gd, assets/locale/strings.csv, "
               "src/tools/night_road.gd, src/tools/shot.gd, "
               "src/tools/headless_check.gd, src/tools/input_check.gd, "
               "src/tools/headless_v1.gd, src/tools/input_v1.gd",
         goal="The build step has no clock. The night waits while the player "
              "builds and starts when they press START - except after a "
              "pass-out, when the horde is already at the gate and gives "
              "thirty seconds.",
         req=["`Sim._tick_preparation` no longer starts the night by itself: "
              "a new edge intent `start_waves` (consumed by the tick, ignored "
              "outside PREPARATION) calls 0118's `Phases.start_waves`; after "
              "a pass-out the night also starts by itself at "
              "`PASS_OUT_PREPARATION_TICKS` (0128), and that timer is the "
              "only one left",
              "`PREPARATION_TICKS` leaves `game_data.gd` and `digest()`; the "
              "day clock stays stopped through the build step",
              "A START button on the night HUD (`StartButton`, `NHUD_START` "
              "'START' / 'COMEÇAR') and a `start_waves` action in "
              "`project.godot` and "
              "`InputActions.ACTIONS`, with a pad button (0121) and a default "
              "key that is not the GO TO BED key, so a double press cannot "
              "skip the build step; `ACT_START` in both languages. After a "
              "pass-out the button counts down (`NHUD_START_IN`)",
              "0118's road (the `NightRoad` helper, or whatever 0118 named "
              "it) now writes `start_waves` instead of advancing "
              "`PREPARATION_TICKS`, so autoplay, determinism, shot, "
              "perf_check, play_nights and make_goldens change nowhere else. "
              "A loop that waits the build step out without naming the "
              "constant would now spin for ever - `shot.gd`'s trailer "
              "(~322, `while ... == Phases.PREPARATION`) is one: route it "
              "through the road too",
              "Rewrite `_task_0006_phases` ('preparation ends itself' becomes "
              "'preparation waits for START') and every assert 0118 left on "
              "the timer with a comment pointing here; input cases that "
              "waited out the build step use the road. 0118's "
              "`_task_0118_road` text scan allowed `PREPARATION_TICKS` in the "
              "road: it now allows it nowhere. Check 0128's "
              "`_task_0128_pass_out` ordinary-bedtime half still holds",
              "SIM moves on purpose (`intent` gains `start_waves`, and the "
              "determinism scenario's build step is one tick instead of "
              "600): record both numbers. DATA moves (`PREPARATION_TICKS` "
              "leaves `digest()`)"],
         dod=["`_task_0136_start` in `headless_v1.gd`: two minutes of ticks "
              "in PREPARATION (past the old 20 s and the 30 s pass-out "
              "timer) stay in PREPARATION; `start_waves` begins the "
              "night on the next tick; `start_waves` by day or at night "
              "changes nothing; after a pass-out the night begins at exactly "
              "`PASS_OUT_PREPARATION_TICKS`, or sooner on START",
              "`_case_0136_start` in `input_v1.gd`: clicking `StartButton` "
              "and pressing the START key each begin the waves",
              "A capture of the build step with START on screen, opened"]),

    dict(id=137, phase=P10, title="The night ends at 06:00",
         slug="dawn-ends-night", deps=[136],
         files="src/core/sim.gd, src/core/phases.gd, src/core/waves.gd, "
               "src/core/game_data.gd, src/core/events.gd, "
               "src/ui/night_hud.gd, src/ui/log_panel.gd, "
               "assets/locale/strings.csv, src/tools/determinism.gd, "
               "src/tools/night_road.gd, src/tools/nights.gd, "
               "src/tools/headless_check.gd, src/tools/input_check.gd, "
               "src/tools/headless_v1.gd, tools/nights.py",
         goal="The night has an end you know in advance: 06:00. A house still "
              "standing at dawn is a won night and whatever is left walks off "
              "into the light; killing everything sooner still wins.",
         req=["`NIGHT_TICKS := 240 * SECONDS` (`# LEVER`, 180-300 seconds "
              "worth: the plan's three to five real minutes) is the waves' "
              "length from `begin_night` to dawn, the same after a 21:00 "
              "bedtime and after a pass-out. `validate()`: below "
              "`Sim.MOST_TICKS_IN_A_NIGHT`",
              "`begin_night` writes the dawn tick into the state (e.g. "
              "`wave.dawn_at`, a TABLES field whose `initial()` is "
              "`NIGHT_TICKS`, so an old save gets a whole night) and "
              "`Phases.ticks_to_dawn(state)` reads it. The park of 0118's "
              "`NightRoad` (today's `_park_the_waves`) parks dawn too "
              "(`dawn_at` out of reach), so parked nights still never end",
              "In `Sim._tick_night`, after `Combat.tick`: still NIGHT and "
              "`night_tick >= dawn_at` -> `Rewards.settle(state, true)` and "
              "`Phases.enter_result(state, true)` with the survivors still on "
              "the farm; `begin_day`'s `Enemies.withdraw` and "
              "`EnemyRetreats` walk them off. A `dawn` event (a new "
              "`Events.KINDS` entry with a severity in `log_panel.gd` and a "
              "sample in `_task_0090_log`) with `LOG_DAWN` ('dawn - %d walked "
              "off', en and pt_BR). The house at 0 still loses and "
              "`_test_for_the_end` still wins early",
              "Interim until 0153: dawn does not end a night while a boss is "
              "on the farm (`Combat.boss_here`), so night 10 still ends only "
              "with the Giant or the house down, and the run can never end "
              "with the Giant standing",
              "`check_nights`: every night's schedule (the opening, each "
              "wave's members x `SPAWN_INTERVAL_TICKS`, the gaps) ends at "
              "least a margin `# LEVER` before `NIGHT_TICKS`; a headless "
              "assert samples the endless curve (nights 11-40, a few seeds) "
              "against the same rule, from the schedule functions and "
              "without playing a night; `tools/nights.py` (through "
              "`src/tools/nights.gd`) prints each night's schedule against "
              "the night",
              "The night HUD shows the time left to dawn as a countdown "
              "(`NHUD_DAWN`), never a wall clock - after a pass-out a "
              "22:00-06:00 mapping would lie - holding at 0:00 while a boss "
              "keeps the night going. Skip and 1x/2x/4x simply run to dawn",
              "Owns `_task_0027_the_loop` ('ends by itself' becomes 'ends at "
              "dawn or when everything is dead'), `_task_0055_speed` (skip "
              "runs to dawn) and the `Sim.skip_night` in input_check's "
              "`_case_0082_shots` (~4461). `determinism.gd` stops calling "
              "`enter_result` directly and fights until the night ends "
              "itself: SIM moves on purpose (that, and `wave` gains "
              "`dawn_at`), record both numbers. DATA moves too: "
              "`NIGHT_TICKS` and the margin join the `time` row of "
              "`digest()`. A bounty only for kills is 0219's"],
         dod=["`_task_0137_dawn` in `headless_v1.gd` (write a near "
              "`dawn_at` into the test's state rather than playing 240 s, so "
              "the group stays a few seconds): a night whose horde "
              "cannot reach the house ends at exactly `dawn_at` with "
              "`survived` true, and the survivors are gone after `begin_day`; "
              "killing everything ends it sooner; a house at 0 before dawn "
              "loses; `check_nights` refuses a schedule longer than the night",
              "`Sim.skip_night` from mid-night takes at most the ticks left "
              "to dawn and lands in RESULT",
              "`python tools/nights.py` shows all ten nights inside the night "
              "with their margins; the numbers are in the journal",
              "`python tools/shot.py 0137 wave` opened: the dawn countdown "
              "is on screen"]),

    dict(id=138, phase=P10, title="Waking up: the morning report",
         slug="morning-report", deps=[137],
         dresses=["A057"],
         files="src/core/phases.gd, src/core/house.gd, "
               "src/ui/result_screen.gd, src/ui/house_view.gd, "
               "src/ui/main.gd, src/ui/placeholder_art.gd, "
               "assets/locale/strings.csv, src/tools/autoplay.gd, "
               "src/tools/shot.gd, src/tools/headless_check.gd, "
               "src/tools/input_check.gd, src/tools/headless_v1.gd, "
               "src/tools/input_v1.gd, "
               "implementation/backlog/packs/A057-morning-report.md",
         goal="Every night, won or lost, closes on a morning report, and "
              "confirming it starts the day with the farmer getting out of "
              "bed at 06:00.",
         req=["`begin_day` wakes him in bed: `House.wake(state)` puts him "
              "inside on the floor cell beside the bed - `inside` true, "
              "`asleep` and `passed_out` false, `outside_pos` the porch - so "
              "he walks out of the door into the day, and the clock reads "
              "06:00. The wake animation 0129 registered plays (A001 stand-in "
              "until 0143)",
              "Tests and tools that walk the farmer outside after a night "
              "step him out with `House.leave` or a helper (the "
              "determinism scenario's second day, `Autoplay._a_day`, the "
              "suites' `_to_the_next_night`-style helpers); list the ones "
              "touched in the journal. The autoplayer keeps working",
              "`result_screen.gd` becomes the morning report: a heading with "
              "the day, what came in (the `Rewards` lines), what was lost "
              "(stock taken on a loss, structures lost), how many walked off "
              "at dawn, a line when the night began with a pass-out, and a "
              "leftovers line that says nothing is on the farm yet (phase "
              "13's bones and moon stones fill it). Confirming is the same "
              "`confirm_result` intent. The ending and endless branches stay "
              "as they are (0160 reworks them)",
              "An optional header, a sunrise over the farmhouse, through the "
              "placeholder road (a code-drawn band is enough) until A057 is "
              "integrated by 0289; if the owner declines A057 the band stays",
              "`main._bank_if_a_night_ended` banks every night's end, won or "
              "lost (key it on `day` or `last_result`, not `nights_won`), "
              "without `Stats.fold` counting a night twice",
              "Strings in both languages, and the report fits 480x270 in "
              "both; a row nothing prints any more leaves strings.csv. The "
              "input cases that read `ResultScreen` keep passing: "
              "`_case_0027_the_loop` (~1303), `_case_0070_endless` (~3616) "
              "and `_case_0082_shots`' crowding check (~4466). SIM moves on "
              "purpose (where `begin_day` leaves the farmer): record both "
              "numbers"],
         dod=["`_task_0138_morning` in `headless_v1.gd`: after a won and "
              "after a lost night, `confirm_result` leaves him inside beside "
              "the bed, awake, at `day_tick` 0 and 06:00; a state saved and "
              "loaded in RESULT confirms into the same",
              "`_case_0138_morning` in `input_v1.gd`: the report shows its "
              "lines; confirming brings up the house view; a lost night "
              "writes the run save (the saved `day` matches)",
              "The Deliverables table of "
              "`implementation/backlog/packs/A057-morning-report.md` states "
              "the final geometry this task settled",
              "`python tools/shot.py 0138 result` opened, also with "
              "`--pt_BR`: nothing clipped or overlapping"]),

    # ============================================ phase 10 - the two HUDs
    dict(id=139, phase=P10, title="The night HUD for the guardian",
         slug="night-hud-guardian", deps=[133, 134, 135, 136, 137],
         dresses=["A005"],
         files="src/ui/night_hud.gd, src/ui/day_hud.gd, src/ui/hotbar.gd, "
               "src/ui/ui_kit.gd, src/ui/placeholder_art.gd, "
               "assets/locale/strings.csv, src/tools/headless_check.gd, "
               "src/tools/input_check.gd, src/tools/input_v1.gd",
         goal="One night HUD built for the guardian rather than for a farmer "
              "in the yard: the time to dawn, the house, the wave, START, "
              "speed, skip, the flare and the hotbar, all reachable by mouse "
              "and by pad.",
         req=["Top strip: the night, wave x/y, the dawn countdown (0137) and "
              "the house bar against `Phases.house_full` (the boss bar stays "
              "where it is). Bottom: the hotbar (0133). Bottom right: START "
              "in the build step; speed, skip and the flare with its charge "
              "during the waves",
              "A mode hint line says what a confirm does now - place, "
              "upgrade, sell, repair or aim - with the key or the pad glyph "
              "from 0121, following the cursor's state",
              "Skip becomes a button whose tooltip is its refusal "
              "(`Sim.why_not_skip`), and the day HUD's `SkipLine` read-out "
              "goes. The farmer-centric REPAIR button is gone (0134). The day "
              "HUD's `NightButton` belongs to 0127 and 0140 and is not "
              "touched here",
              "Every control writes an intent or asks the driver, as today; "
              "on a pad each one is reachable by focus or by its own action",
              "Icons through the placeholder road until A005 is integrated "
              "by 0147",
              "Rewrite `_case_0056_night_hud` (and `_task_0056_night_hud` "
              "where it reads the old layout) and the `SkipLine` read in "
              "`_case_0055_speed` (~3178); remove strings nothing reads any "
              "more (`DHUD_SKIP` and `DHUD_SKIP_NO`; 0134 already took "
              "`NHUD_REPAIR`) so `tools/i18n_check.py` stays clean",
              "View only: neither hash moves"],
         dod=["`_case_0139_night_hud` in `input_v1.gd`: START is up in the "
              "build step and starts the waves; speed cycles 1/2/4; skip is "
              "refused under `SKIP_MIN_HOUSE_PERCENT` with its reason and "
              "allowed above it; the flare shows its charge; no "
              "`RepairButton` exists; the hint changes with what is under the "
              "cursor",
              "`python tools/shot.py 0139 dusk wave` and `--fhd` captures "
              "opened, also with `--pt_BR`: no two labels on top of each "
              "other and nothing over the hotbar"]),

    dict(id=140, phase=P10, title="The day HUD: the hour and bedtime",
         slug="day-hud-clock", deps=[126, 127, 128],
         files="src/ui/day_hud.gd, src/core/game_data.gd, "
               "assets/locale/strings.csv, src/tools/shot.gd, "
               "src/tools/input_v1.gd",
         goal="The day HUD tells the time and says when it is time for bed: "
              "an HH:MM clock, a GO TO BED button that looks like the way "
              "into the night, a reminder from 22:00 and a warning before "
              "the 02:00 pass-out.",
         req=["The HH:MM clock (0126's format) gets its final place and "
              "look, tinted from dusk; it reads the `Phases` clock helpers "
              "and nothing else",
              "The GO TO BED button (`NightButton`) is dressed with the UI "
              "kit and lights up from the reminder hour",
              "`BEDTIME_REMINDER_MINUTE := 22 * 60` and "
              "`PASS_OUT_WARNING_MINUTE := 25 * 60 + 30` (01:30) as `# "
              "LEVER`s with ranges; `validate()`: dusk <= reminder < warning "
              "< `DAY_END_MINUTE`. They are view thresholds, not balance, so "
              "they stay out of `digest()` and neither hash moves (0112's "
              "coverage assert reads only Dictionary and Array tables)",
              "From 22:00 a quiet 'time for bed' line naming the GO TO BED "
              "key (the `night` action through `InputActions.label_of`, so a "
              "pad player reads 0121's glyph); from 01:30 a warning in the "
              "warn colour with the minutes "
              "left before he passes out (`DHUD_BEDTIME`, "
              "`DHUD_PASS_OUT_SOON`, both languages, inside "
              "`tools/i18n_check.py`'s widths)",
              "A `bedtime` scenario in `shot.gd` (the farm at 22:30) beside "
              "`noon` and `dusk`"],
         dod=["`_case_0140_bedtime` in `input_v1.gd`: no reminder at 21:59, "
              "the reminder at 22:00, the warning at 01:30; clicking GO TO "
              "BED at 23:00 starts the night",
              "`python tools/shot.py 0140 noon dusk bedtime` opened, also "
              "with `--pt_BR`"]),

    # ===================================== phase 10 - teaching and tools
    dict(id=141, phase=P10, title="Teaching the new night",
         slug="tutorial-sleep", deps=[139, 140],
         files="src/core/game_data.gd, src/core/tutorial.gd, "
               "src/core/sim.gd, src/ui/tutorial_prompt.gd, "
               "src/tools/perf_names.gd, assets/locale/strings.csv, "
               "src/tools/headless_check.gd, src/tools/input_check.gd, "
               "src/tools/headless_v1.gd, src/tools/input_v1.gd",
         goal="Day one teaches the new night - go to bed, build with the "
              "cursor, press START, hold until dawn - by watching the state "
              "and never gating anything.",
         req=["`TUTORIAL` has seven steps today (chop, plant, water, sell, "
              "craft, then 0132's night and build) and "
              "`MAX_TUTORIAL_LINES := 7` with a 3-9 range, so seven plus "
              "three does not fit: the `night` step becomes the bed step "
              "(`TUT_NIGHT` - 'N, or the button' - is replaced by `TUT_BED` "
              "and its row leaves strings.csv), START and dawn follow the "
              "night `build` step, and the lever goes to 9 - or two day "
              "steps merge; say which. `check_tutorial` still passes",
              "`Tutorial._happened` arms that read the state only: asleep "
              "seen, a defence placed in a build step, NIGHT reached, a night "
              "that ended at dawn or by a win",
              "`Tutorial.tick` runs on its beat in NIGHT too (0132 added "
              "PREPARATION; never indoors). `PerfNames.NIGHT` gains "
              "`Tutorial`: `_task_0102_budget` only compares the union of "
              "the two lists, so it would not notice a night system the "
              "benchmark does not time. `points_at` aims each step at "
              "something real: the bed (in the house view), a cell between "
              "the house and the spawn, the START button, the dawn countdown",
              "`TUT_BED`, `TUT_BUILD` (rewritten), `TUT_START` and `TUT_DAWN` "
              "in both languages, inside the widths `tools/i18n_check.py` "
              "measures - practical lines, not a description of the "
              "reality switch",
              "Rewrite `_task_0041_tutorial` and `_case_0041_tutorial` for "
              "the new steps",
              "DATA moves (`TUTORIAL`); SIM moves only if the tutorial state "
              "differs in the determinism scenario - say which"],
         dod=["`_task_0141_tutorial` in `headless_v1.gd` (jump `day_tick` and "
              "`dawn_at` rather than playing whole spans): a scripted first "
              "day and night completes every step in order; ignoring the "
              "prompts reaches the same night with the same state apart from "
              "`tutorial`",
              "`_case_0141_tutorial` in `input_v1.gd`: the bed line shows on "
              "day one after the day steps, the START line in the build step",
              "Captures of the bed, START and dawn prompts, opened"]),

    dict(id=142, phase=P10, title="The autoplayer sleeps too",
         slug="autoplay-sleep", deps=[137, 132, 138],
         files="src/tools/autoplay.gd, src/tools/autoplay_run.gd, "
               "src/tools/nights.gd, src/tools/play_nights.gd, "
               "tools/autoplay.py, tools/nights.py, tools/balance.py, "
               "tools/play_nights.py, implementation/BALANCE.md, "
               "src/tools/headless_check.gd",
         goal="The autoplayer plays the game as it now is - a day, bed, "
              "building by cursor, START, the night to dawn - and keeps "
              "playing after a loss, so the balance tools measure the real "
              "loop again.",
         req=["`Autoplay.play`, per night: `_a_day` (gathering, crafting and "
              "production buildings by day only, starting from 0138's wake "
              "in bed); the `sleep` intent at a policy hour or when the "
              "day's plan is done, never passing out by accident (0128 only "
              "made it stop short of 02:00); the policy's defences in "
              "PREPARATION through the intent road (`build_cell` with "
              "`build_place`, `build_upgrade`, `repair_cell`); "
              "`start_waves`; ticks until RESULT, capped at `NIGHT_TICKS` "
              "plus a margin; then `confirm_result`",
              "It carries on after a loss instead of stopping; the per-night "
              "report adds how the night ended (dawn, everything dead, house "
              "down), the house left and how many walked off",
              "Policies keep their lists; nothing is placed by day (it would "
              "be refused)",
              "`tools/autoplay.py`, `tools/nights.py`, `tools/balance.py` and "
              "`tools/play_nights.py` still run; `balance.py` still restores "
              "`game_data.gd` and still refuses a dirty tree",
              "`_task_0067_autoplay` and `_task_0068_balance` are rewritten "
              "to the new loop and kept inside the suite's time (one day and "
              "one night per policy); report the group times",
              "A note in `implementation/BALANCE.md`: survival per night for "
              "the four policies over the same seeds before and after the "
              "new loop, and what changed",
              "Tools only: neither hash moves"],
         dod=["`_task_0067_autoplay` and `_task_0068_balance` pass, with "
              "their times in the journal",
              "`python tools/autoplay.py` plays ten nights for every policy "
              "and prints the table; the numbers are in the journal and in "
              "BALANCE.md",
              "`python tools/balance.py` with a short sweep finishes and "
              "leaves the git tree clean"]),

    # ================================================ phase 10 - the art
    dict(id=143, phase=P10,
         title="Art: going to bed, sleeping, waking, passing out",
         slug="art-farmer-bed", deps=[129, 128],
         art=["A001"],
         files="assets/art_source/player-fhd/, "
               "assets/art_source/manifest.json, "
               "assets/art_source/ownership.json, src/ui/player_frames.gd, "
               "src/ui/raster_art.gd, src/ui/placeholder_art.gd, "
               "src/ui/house_view.gd, src/ui/player_view.gd, tools/verify.py",
         goal="The farmer's night in his own art - getting into bed, the "
              "sleep loop, waking and stretching, passing out on the farm - "
              "from Codex pack A001, replacing 0129's stand-ins.",
         req=["`python tools/task.py next` only offers this task once "
              "`python implementation/backlog/assets.py status A001` says "
              "`approved`. Check it again first; if it does not, stop and "
              "change nothing (the task stays todo and waits). This task "
              "never draws, generates or substitutes art.",
              "Use only the folder named in the pack's "
              "`CLAUDE-A001-PROMPT.txt` handoff; check every file against "
              "its `contract.json` sha256 before promoting; never resample, "
              "regenerate, or cut from previews or GIFs.",
              "Promote through the raster pipeline: versioned sources under "
              "`assets/art_source/player-fhd/`, manifest entries with "
              "prompt/approval provenance, `assets/art_source/ownership.json`"
              ", then `python tools/import_art.py`. The farmer has no "
              "`check_*_art.py`: its gates are a hash-checking promoter with "
              "a `--check` mode wired into `tools/verify.py` (like "
              "`implementation/fhd-player/pilots/2026-10-04/palette-variants/"
              "promote_blue_walk.py`) and the `show_art.py` showcases",
              "Runtime: the canvas, pivot and `draw_scale` the pack's "
              "contract states, one per animation; the get-in, sleep and "
              "wake strips play in `house_view.gd` sitting exactly on the "
              "bed (`FURNITURE_OFFSETS` for the bed), the pass-out in "
              "`player_view.gd` where he fell, over the shared shadow; the "
              "one-shots stay one-shots and the sleep loop loops",
              "Delete A001's entries from 0120's placeholder registry: the "
              "raster outputs land under the names 0129 registered, so no "
              "view code changes (`python tools/placeholders.py --check` "
              "fails on an entry left for an integrated pack). Extend the "
              "`--house-visit` and `--work` showcases with the four "
              "animations",
              "Set the pack to integrated: "
              "`python implementation/backlog/assets.py set A001 integrated`."],
         dod=["`python tools/show_art.py --house-visit --check`, "
              "`python tools/show_art.py --work --check` and the farmer's "
              "promoter check pass; `python tools/import_art.py --check` "
              "passes; `python tools/placeholders.py` no longer lists A001",
              "FHD (1920x1080) captures by day and by night of the art in "
              "the real game - going to bed, asleep, waking, a pass-out - "
              "opened and looked at, in `implementation/shots/0143/`",
              "The sim and data hashes are unchanged (art never moves them)"]),

    dict(id=144, phase=P10, title="Art: the farmer's reactions and Zzz",
         slug="art-reactions", deps=[129],
         art=["A002"],
         files="assets/art_source/player-fhd/, "
               "assets/art_source/manifest.json, "
               "assets/art_source/ownership.json, src/ui/raster_art.gd, "
               "src/ui/placeholder_art.gd, src/ui/player_view.gd, "
               "src/ui/world_view.gd, src/ui/house_view.gd",
         goal="The farmer's reactions at the 32px detail of his new body, and "
              "the Zzz that rises from the farmhouse at night, from Codex "
              "pack A002.",
         req=["`python tools/task.py next` only offers this task once "
              "`python implementation/backlog/assets.py status A002` says "
              "`approved`. Check it again first; if it does not, stop and "
              "change nothing (the task stays todo and waits). This task "
              "never draws, generates or substitutes art.",
              "Use only the folder named in the pack's "
              "`CLAUDE-A002-PROMPT.txt` handoff; check every file against "
              "its `contract.json` sha256 before promoting; never resample, "
              "regenerate, or cut from previews or GIFs.",
              "Promote through the raster pipeline: versioned sources under "
              "`assets/art_source/player-fhd/`, manifest entries with "
              "prompt/approval provenance, `assets/art_source/ownership.json`"
              ", then `python tools/import_art.py`; the gates are the "
              "`--reactions` showcase and the importer's bubble checks",
              "Runtime: `react_bang`, `react_question`, `react_note` and "
              "`react_heart` keep their names (the legacy 48x48 frames are "
              "retired) and the Zzz takes the name 0129 registered; every "
              "frame carries a `bubble_xywh` covering every glyph pixel and "
              "no body pixel (`validate_bubble` in `import_art.py`)",
              "The Zzz replaces 0129's stand-in over the farmhouse at night "
              "and over him in bed indoors by deleting A002's entry from "
              "0120's placeholder registry; `Reactions.KINDS` is untouched, "
              "because the Zzz is a view cue",
              "Set the pack to integrated: "
              "`python implementation/backlog/assets.py set A002 integrated`."],
         dod=["`python tools/show_art.py --reactions --check` passes and "
              "shows the Zzz; `python tools/import_art.py --check` passes; "
              "`python tools/placeholders.py` no longer lists A002",
              "FHD (1920x1080) captures by day and by night of the art in "
              "the real game - a reaction by day, the Zzz at night - opened "
              "and looked at, in `implementation/shots/0144/`",
              "The sim and data hashes are unchanged (art never moves them)"]),

    dict(id=145, phase=P10, title="Art: the porch guardian",
         slug="art-guardian", deps=[131, 133],
         art=["A003"],
         files="assets/art_source/guardian/, "
               "assets/art_source/manifest.json, "
               "assets/art_source/ownership.json, src/ui/raster_art.gd, "
               "src/ui/placeholder_art.gd, src/ui/guardian_view.gd, "
               "src/ui/lighting.gd, tools/check_prop_art.py, "
               "tools/show_art.py, tools/verify.py",
         goal="The porch scarecrow that becomes the guardian at night, from "
              "Codex pack A003, replacing 0131's placeholder.",
         req=["`python tools/task.py next` only offers this task once "
              "`python implementation/backlog/assets.py status A003` says "
              "`approved`. Check it again first; if it does not, stop and "
              "change nothing (the task stays todo and waits). This task "
              "never draws, generates or substitutes art.",
              "Use only the folder named in the pack's "
              "`CLAUDE-A003-PROMPT.txt` handoff; check every file against "
              "its `contract.json` sha256 before promoting; never resample, "
              "regenerate, or cut from previews or GIFs.",
              "Promote through the raster pipeline: versioned sources under "
              "`assets/art_source/guardian/`, manifest entries with "
              "prompt/approval provenance, `assets/art_source/ownership.json`"
              ", then `python tools/import_art.py`. It is a new family: "
              "extend `tools/check_prop_art.py`'s `NAMES` or add a "
              "`tools/check_guardian_art.py` wired into `tools/verify.py`, "
              "with a showcase",
              "Runtime: the day, wake, night and point states with the "
              "canvas, pivot and timings 0131 wrote into the pack's "
              "Deliverables table, at draw scale 1.0 (`ArtPlacement`'s 2x "
              "list is not extended); the eyes' light points become emission "
              "metadata, like `light_xy`, that `lighting.gd` reads - nothing "
              "else on the scarecrow emits",
              "Replace 0131's placeholder by deleting A003's entries from "
              "0120's placeholder registry (runtime names "
              "`guardian_<anim>_<i>`, as 0131 registered them); the wake "
              "still plays at the reality switch and the point (0133) when "
              "something is placed",
              "Set the pack to integrated: "
              "`python implementation/backlog/assets.py set A003 integrated`."],
         dod=["The guardian's checker and showcase pass; "
              "`python tools/import_art.py --check` passes; "
              "`python tools/placeholders.py` no longer lists A003",
              "FHD (1920x1080) captures by day and by night of the art in "
              "the real game - still by day, awake with its eyes lit at "
              "night, pointing at a placement - opened and looked at, in "
              "`implementation/shots/0145/`",
              "The sim and data hashes are unchanged (art never moves them)"]),

    dict(id=146, phase=P10, title="Art: the guardian's cursor",
         slug="art-cursor", deps=[131],
         art=["A004"],
         files="assets/art_source/ui/, assets/art_source/manifest.json, "
               "assets/art_source/ownership.json, src/ui/raster_art.gd, "
               "src/ui/placeholder_art.gd, src/ui/guardian_cursor.gd, "
               "tools/check_ui_art.py, tools/show_art.py",
         goal="The cursor's seven states in drawn pixels, from Codex pack "
              "A004, replacing 0131's code-drawn outline.",
         req=["`python tools/task.py next` only offers this task once "
              "`python implementation/backlog/assets.py status A004` says "
              "`approved`. Check it again first; if it does not, stop and "
              "change nothing (the task stays todo and waits). This task "
              "never draws, generates or substitutes art.",
              "Use only the folder named in the pack's "
              "`CLAUDE-A004-PROMPT.txt` handoff; check every file against "
              "its `contract.json` sha256 before promoting; never resample, "
              "regenerate, or cut from previews or GIFs.",
              "Promote through the raster pipeline: versioned sources under "
              "`assets/art_source/ui/`, manifest entries with prompt/approval "
              "provenance, `assets/art_source/ownership.json`, then "
              "`python tools/import_art.py`; extend the hard-coded lists of "
              "`tools/check_ui_art.py` and the `--ui` showcase",
              "Runtime: neutral, can place, blocked, upgrade, sell, repair "
              "and aim as one-cell 16x16 frames with a 2-frame pulse each, "
              "under the names 0131 registered; no text; readable over the "
              "night ramp on grass, soil and a wall",
              "Replace 0131's placeholder by deleting A004's entries from "
              "0120's placeholder registry, so the states 0132, 0134 and "
              "0135 switched on all show the new art",
              "Set the pack to integrated: "
              "`python implementation/backlog/assets.py set A004 integrated`."],
         dod=["`python tools/check_ui_art.py` and "
              "`python tools/show_art.py --ui --check` pass; "
              "`python tools/import_art.py --check` passes; "
              "`python tools/placeholders.py` no longer lists A004",
              "FHD (1920x1080) captures by day and by night of the art in "
              "the real game - the cursor in each state over dark ground - "
              "opened and looked at, in `implementation/shots/0146/`",
              "The sim and data hashes are unchanged (art never moves them)"]),

    dict(id=147, phase=P10, title="Art: the night hotbar and HUD icons",
         slug="art-night-icons", deps=[133, 139],
         art=["A005"],
         files="assets/art_source/ui/, assets/art_source/manifest.json, "
               "assets/art_source/ownership.json, src/ui/raster_art.gd, "
               "src/ui/placeholder_art.gd, src/ui/hotbar.gd, "
               "src/ui/night_hud.gd, tools/check_ui_art.py, "
               "tools/show_art.py",
         goal="The icons of the night - the eight defences, the flare, START, "
              "speed and the moon of the dawn countdown - from Codex pack "
              "A005, replacing the hotbar's and the night HUD's placeholders.",
         req=["`python tools/task.py next` only offers this task once "
              "`python implementation/backlog/assets.py status A005` says "
              "`approved`. Check it again first; if it does not, stop and "
              "change nothing (the task stays todo and waits). This task "
              "never draws, generates or substitutes art.",
              "Use only the folder named in the pack's "
              "`CLAUDE-A005-PROMPT.txt` handoff; check every file against "
              "its `contract.json` sha256 before promoting; never resample, "
              "regenerate, or cut from previews or GIFs.",
              "Promote through the raster pipeline: versioned sources under "
              "`assets/art_source/ui/`, manifest entries with prompt/approval "
              "provenance, `assets/art_source/ownership.json`, then "
              "`python tools/import_art.py`; extend the hard-coded lists of "
              "`tools/check_ui_art.py` and the `--ui` showcase",
              "Runtime: one raw source each, cut into a 16x16 `icon_<id>` and "
              "a 10x10 `hud_<id>` (visible at most 14 and 8 px) for "
              "`gun_tower`, `auto_crossbow`, `flame_tower`, `mortar`, `mine`, "
              "`fence`, `wall`, `barricade`, the flare, START, speed and the "
              "dawn moon",
              "The hotbar (0133) takes the 16x16 cuts and the night HUD "
              "(0139) the 10x10 ones, replacing their placeholders by "
              "deleting A005's entries from 0120's placeholder registry",
              "Set the pack to integrated: "
              "`python implementation/backlog/assets.py set A005 integrated`."],
         dod=["`python tools/check_ui_art.py` and "
              "`python tools/show_art.py --ui --check` pass; "
              "`python tools/import_art.py --check` passes; "
              "`python tools/placeholders.py` no longer lists A005",
              "FHD (1920x1080) captures by day and by night of the art in "
              "the real game - the hotbar and the night HUD in the build step "
              "and mid-wave - opened and looked at, in "
              "`implementation/shots/0147/`",
              "The sim and data hashes are unchanged (art never moves them)"]),

    # ============================================ phase 10 - the checkpoint
    dict(id=148, phase=P10,
         title="Checkpoint: is the night better with him asleep?",
         slug="checkpoint-sleep", deps=[137, 138, 139, 140, 141, 142],
         files="implementation/PROGRESS.md, implementation/shots/0148/, "
               "implementation/prompts/",
         goal="**The plan's Phase 1 test.** Play the new night - the farmer "
              "asleep, the cursor, START, dawn - with a mouse and with a pad, "
              "and answer honestly whether it is better than the MVP's "
              "night. Every later phase waits on the answer.",
         req=["Play at least three whole days and nights by hand with mouse "
              "and keyboard and at least one with only a pad (a real one if "
              "attached; say honestly if it was synthetic): bed, cursor "
              "building, START, a repair, a flare, an upgrade and a sale by "
              "cursor, speed and skip, dawn, the morning report - and one "
              "night that follows a pass-out",
              "Run the autoplayer for every policy over ten nights and note "
              "how the nights end: at dawn, with everything dead, or with the "
              "house down",
              "FHD captures of one night from START to dawn - the build step "
              "with the cursor and the hotbar, the first wave, a repair, the "
              "flare aimed, the walk-off at dawn, the morning report - in "
              "`implementation/shots/0148/`, opened and looked at",
              "Answer the plan's question in the journal, 'is the night "
              "better with him asleep?', against the MVP's night: what is "
              "better, what is worse, what is missing, and what is slow or "
              "fiddly (the camera, the cursor, the pad)",
              "Fix here only what is small and inside this phase's rules; "
              "anything bigger becomes an edit to a later prompt or a note "
              "for the phase it belongs to",
              "Every later phase depends on this task. If the answer is no, "
              "run `python tools/task.py blocked 0148 \"<the reason>\"` and "
              "edit the later prompts that must change before any content is "
              "produced; never tick or untick a box by hand"],
         dod=["The journal has the answer, the nights played (device, how "
              "each ended, house left), the autoplayer's numbers, and every "
              "later prompt edited and why",
              "The captures in `implementation/shots/0148/` exist and were "
              "opened",
              "Either the task is done on a yes, or it is blocked with the "
              "reason and the later prompts are edited"]),
]
