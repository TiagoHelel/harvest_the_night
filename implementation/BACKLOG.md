# Backlog - HARVEST THE NIGHT

`#########...............`  **110 / 296 done**

0 doing / 186 todo / 0 blocked across 18 phases.

Run one task - `/next-task`, which reads
`implementation/prompts/00-RUNNER-LOOP.md` and does exactly one:

```
/next-task
```

Keep going until it is all ticked:

```
/loop /next-task
```

First up: **0112 - Room in the test suites**. The whole of what is left is
spelled out under *What is open* below, ready ones first.

The boxes below are **generated** from the `Status:` line inside each
prompt file. Do not tick them by hand: use `python tools/task.py done 0042`,
which rewrites this file for you.

## What is open

186 task(s) left, the ready ones first, then what they
unlock. Generated from `tools/backlog/part*.py` together
with the prompt files, so the two cannot disagree.

### 0112 - Room in the test suites

Ready to pick up.  Likely files: `src/tools/headless_v1.gd, src/tools/input_v1.gd, tools/verify.py, src/core/game_data.gd`.

`headless_check` and `input_check` already take about 74 s each of the 120 s verify allows a script, and some 180 tasks are coming. Give 1.0 its own pair of suites, so a new rule never has to choose between being tested and the suite finishing.

- `src/tools/headless_v1.gd` copies `headless_check`'s harness: `expect()`, `passed`/`failed`, its own `GROUPS` constant with `_completed += 1` as each group's last line and `_finish()` failing a short count, the `_process()` watchdog (`WATCHDOG_SECONDS`) for an `_initialize()` that never returns, and a last line `N asserts, M failed` with a non-zero exit on any failure
- `src/tools/input_v1.gd` does the same for `input_check`: `MAIN_SCENE`, its own `CASES`, the 20 s stall watchdog that every `expect()` resets, the last line `N cases, M failed`; its first case boots Main and presses one real action, so the harness itself is tested
- Wire both into `tools/verify.py` through `check_script()` with the same patterns as the old suites (`\d+ asserts?, \d+ failed`, `\d+ cases?, \d+ failed`), skipped by `--hashes` like them, each run bounded by `SCRIPT_TIMEOUT_S` as the old two are
- Move nothing: every existing `_task_NNNN_*` group and `_case_NNNN_*` case stays put and `GROUPS := 103` / `CASES := 61` do not change. A plain helper the new files need (`_stand_the_farmer`, `_moved`, ...) is shared, not copied: move it into one small static script under `src/tools/` that both suites call - moving a helper is allowed, a group is not. An input helper that needs the running tree (`click_control`, `until`) takes the tree as an argument, or `input_v1` reuses `input_check`'s script some other way that keeps the two counters apart; say which
- Say in both new file headers that every group and case from task 0112 on lives here (`00-RUNNER-LOOP.md` already says so), and that a defence a test puts down, upgrades or sells is handled in PREPARATION, never by day (0132 forbids it by day and 0119 moves the old suites the same way)
- `_task_0112_digest` in `headless_v1`: read `src/core/game_data.gd` as text, collect every top-level `const` whose value is a Dictionary or Array literal (typed ones too, `const X: Array[Vector2i] = [`), and fail on any that is neither named inside `GameData.digest()` nor in an exemption list in the assert with a one-line reason each (derived enum lists such as `TARGETING`, `SHAPES`, `AIMS`, `DAMAGE_TYPES`; geometry helpers such as `NEIGHBOUR_STEPS`; view-only data). Scalar consts are not its business
- Run it on today's file before deciding: `MAP_LEGEND`, for one, is not in the digest. A table that is balance goes into `digest()` - DATA then moves on purpose: `python tools/verify.py --accept` and both numbers in the journal; one that is not gets its exemption and its reason. SIM does not move: this task changes no rule and no state key
- Write the four suite rows' times and the whole run against `BUDGET_S` in the journal

  - done when: verify prints a `headless_v1` row ending `N asserts, 0 failed` and an `input_v1` row ending `N cases, 0 failed`, each timed, while `headless_check` still finishes 103 groups and `input_check` 61 cases
  - done when: A scratch `const TEST_TABLE := {}` in `game_data.gd` makes `_task_0112_digest` fail and removing it passes again - tried and said so in the journal
  - done when: A deliberate early `return` before `_completed += 1` in a `headless_v1` group makes verify fail on the group count; then put back

### 0117 - Three stale documents

Ready to pick up.  Likely files: `CHANGELOG.md, docs/PLAYTEST.md, assets/locale/strings.csv`.

Three places tell a player something the game does not do. Fix the words and nothing else.

- `CHANGELOG.md` 0.1.0 says 'Sixteen crops'; there are three (`GameData.CROPS`: wheat, corn, carrot). Say three, and read the rest of that section against the game while there
- `docs/PLAYTEST.md` 'What to ignore' says 'Anything after night ten. It stops.' - it does not: the run carries on into generated endless nights (`Endless`, `Run.go_endless`). Say what really happens. Keep the headings `_task_0105_playtest` looks for ('What to try', 'What to ignore', 'What to report') and the line that names the note key
- `TUT_SELL` says the stall 'sells seeds'; it does not - seeds are paid for at planting (`CROPS[...]["seed_cost"]`) and `DAILY_STOCK` has none. Rewrite the line in English and Brazilian Portuguese, about as long as today's: its `width` column is 0, so `tools/i18n_check.py` checks that both languages are there and agree on `%` specifiers, and `MAX_TUTORIAL_LINE_LENGTH` measures the key, not the words
- Words only, no rule changes: the day-barricade allowance is 0132's, the can's '/8' is 0174's, and seeds sold by season arrive with 0170 (the line moves again then). `TUTORIAL` holds the key, not the text, so neither hash moves

  - done when: A grep of `CHANGELOG.md` and `docs/PLAYTEST.md` finds no 'Sixteen' and no 'It stops'
  - done when: `python tools/i18n_check.py` passes with the new `TUT_SELL` in both languages

### 0113 - Repairs mend to the real maximum

Waits on 0112.  Likely files: `src/core/repair.gd, src/core/building.gd, src/core/game_data.gd, src/ui/world_view.gd, assets/locale/strings.csv, src/tools/headless_v1.gd, src/tools/headless_check.gd`.

Mending stops at the wrong number: the house comes back only to 100 when 'stout timbers' made it 140, and an upgraded tower only to its level-one hit points. A repair should put back what the thing really has when it is whole.

- `Repair.damage_at`: the house is missing `Phases.house_full(state) - house_hp`, not `GameData.HOUSE_HP - house_hp`
- A structure's maximum is its levelled one - `Building.entry_at(state, cell)`, the base row with `TOWER_LEVELS` laid over it - not `Building.entry_of(id)`, in `damage_at` and in the cap inside `Repair.apply`
- `per_hp_hundredths` shares a structure's price over the same levelled maximum, so a full mend of a level-3 tower costs `REPAIR_PERCENT` of its build cost like any other; or the journal says why the base hit points stay the divisor. Either way the cost of one full repair is asserted
- 'a full larder' (`repair_percent` 60, note `TECHNOTE_A_FULL_LARDER` 'mending costs two fifths less') reaches structures through `Tech.bonus` but the house branch of `per_hp_hundredths` ignores it. Decide whether the house gets the discount, make the code, the `note` in `TECH_TREE` and both languages of `TECHNOTE_A_FULL_LARDER` agree, and assert the decision. The `note` is inside `TECH_TREE`, which `digest()` hashes: rewording it moves DATA on purpose (accept it and write both numbers); leaving it alone moves nothing
- View: `world_view.gd` `_wear_of` tints by the base-table hp while `_is_hurt` uses `WorldView.levelled_stat`; make the tint read the levelled maximum too (view only)
- Asserts go in `headless_v1`. `Interact` offers repair through `Repair.can_mend`, so the verb follows the fix by itself - check rather than assume. An old assert that pinned the base maximum or price (`_task_0034_cooking`, `_task_0053_repair`, `_task_0057_structures` call `Repair`) is rewritten in place in `headless_check` with a comment pointing at 0113
- Run `python tools/autoplay.py` before and after: the robot repairs everything it can, so its nights may change. SIM can only move if the determinism scenario repairs (it does not) - say which happened

  - done when: `_task_0113_repairs` in `headless_v1`: with 'stout timbers' owned, food enough and the house at 90 of 140, `Repair.apply_all` on a house cell puts back exactly 50 and `needs_repair` is then false
  - done when: A level-3 gun tower (placed and upgraded twice in PREPARATION, where 0132 will still allow it; the upgrades need 'true sights' then 'oiled works' owned - or set the occupant's `level` to 3) at 60 of 120 is mended to 120; a level-1 tower still stops at its table hp (60)
  - done when: The house-discount decision is asserted with and without 'a full larder', and `python tools/i18n_check.py` passes
  - done when: The journal has the autoplay table before and after

### 0115 - Spawn ground that cannot be built shut

Waits on 0112.  Likely files: `src/core/waves.gd, src/core/enemies.gd, src/core/building.gd, src/core/state.gd, assets/locale/strings.csv, src/tools/headless_v1.gd`.

The plan suspects that fencing every cell of a spawn line makes that side's zombies vanish: `Enemies.spawn` returns 0 when no cell is free and `Waves.tick` counts the member as sent anyway. About seventeen fences would win a night. Prove it, and if it is real, no wave member is ever lost without a trace.

- Reproduce first, headless: in PREPARATION, `Building.place` a fence on every cell of `GameData.SPAWNS[0]` (ten cells on x=68), run night 1 to its end and compare `Waves.size_of(1, seed)` with `state["killed"]` plus `Entities.count`. Write the numbers in the journal whether or not the suspicion holds
- If it holds, pick one fix and say why: `Building.why_not` refuses the last free cells of a spawn region (a new `WHY_*` key, en and pt_BR rows in `assets/locale/strings.csv`, shown by the red ghost); or a member with nowhere to stand waits in `Waves.tick` without counting as sent; or it falls back deterministically to another cell or region
- Whatever is chosen draws from the run RNG only when it places somebody, exactly as `Enemies.spawn` does now
- No softlock: a member that never finds a cell must not hold the night open for ever. 0137's dawn will end nights, but this task cannot lean on it
- A save written with a region already sealed behaves by the same rule. A new state key gets a default in `initial()` and reconcile, with no `State.VERSION` bump: inside `wave` (already in `State.TABLES`) if it can live there, and a new nested Dictionary is listed in `State.TABLES` or `State.RUN_DATA`
- Check `SPAWNS[1]` (seven cells) and a part-blocked region too: spawning still picks only among free reachable cells, and `Enemies.spawn_cells` stays the one place that answers where one can stand (0157 adds regions on this rule)
- Hashes: the determinism scenario seals no region, so the rule alone changes nothing there - but `State.hash_of` hashes every key, so a new state key moves SIM by itself. If it moves, it is on purpose: accept it and write both numbers and why. A refusal key moves nothing; DATA does not move

  - done when: `_task_0115_spawn_room` in `headless_v1`: with the east line built over as far as the rules now allow, night 1 run to its end accounts for every member - killed plus alive plus still waiting equals `Waves.size_of(1, seed)`
  - done when: The same night ends within a bounded number of ticks in the assert, whichever fix was chosen
  - done when: If a refusal was added, it reads in both languages and `python tools/i18n_check.py` passes
  - done when: The journal says whether the suspicion was real, with the before numbers

### 0116 - The mortar and the flamethrower, empty and upgraded

Waits on 0112.  Likely files: `src/core/towers.gd, src/core/ammo.gd, src/core/game_data.gd, src/tools/headless_v1.gd, src/tools/headless_check.gd`.

Two towers may not do what their tables say. An empty mortar may lob a rock that hits nobody, and the flamethrower may ignore the tree's damage and range bonuses while burning two incendiary rounds a second. Reproduce each and fix only what is real.

- Mortar: `Towers._fire` makes an unarmed shot `SHAPE_SINGLE` but leaves it ballistic, and `_advance_projectiles` lands a ballistic shot with `_land_at(state, shot, cell)` and no target, so a single-shape landing hits nobody. Reproduce through `Towers.tick`: a mortar placed in PREPARATION, a walker standing in range beyond `min_range`, the gunpowder pool empty, ticks until the shell lands. The seams `land_for_test`/`land_at_for_test` always build an armed shot with the entry's shape, so they cannot show it; give one an `armed` argument if a seam helps
- If real, the empty shell deals `Ammo.weak_damage` to what it lands on - the walker on the aimed cell or the target it was fired at, decide - and never 0: out of ammunition is a worse shot, never a silent tower (0035)
- Flamethrower: `_burn_cone` reads `entry["damage"]` and `entry["range"]` raw while `_acquire` uses `reach_of`; with 'long barrels' it can pick a target one tile past its cone, spend a round and hit nothing. Use `Towers.damage_of(state, entry, armed)` and `reach_of(state, entry)`, and decide whether `tower_damage_percent` scales `burn_damage` too
- `ammo_every_ticks` (2 s on the flame tower) is read by nothing: `Ammo.spend` runs on every cone, twice a second (`reload_ticks` is `SECONDS / 2`). Charge one round per `ammo_every_ticks` of firing, the countdown on the occupant dictionary without `Farm.touch`, defaulting when an old save has no such key
- Mark `ammo_every_ticks` `# LEVER: ticks, 1-4 seconds worth`; `check_defences` refuses one on an entry without `ammo` or shorter than its `reload_ticks`
- New asserts go in `headless_v1`. An old assert that encoded a bug (`_task_0035_ammunition`, `_task_0043_flame`, `_task_0044_mortar` are where to look) is rewritten in place with a comment pointing at 0116
- Run `python tools/autoplay.py` before and after (its policies build mortars); SIM moves only if the determinism scenario touches these towers (it builds gun towers, which use no ammunition, and walls) - say which. DATA moves only if a table value changes; a `# LEVER` comment moves nothing

  - done when: `_task_0116_ammo` in `headless_v1`: an unarmed mortar shell landing on a walker takes `Ammo.weak_damage` of the mortar's damage off it (40 -> 12 at `EMPTY_DAMAGE_PERCENT` 30)
  - done when: With 'long barrels' a flame tower's cone hits a walker at range + 1; with 'true sights' (`tower_damage_percent` 120) the cone deals `Towers.damage_of` - assert it on the level-3 flame row (damage 5 -> 6), because level one's 3 rounds back to 3 in integer arithmetic
  - done when: A flame tower firing for 10 s on a full pool spends 5 rounds (10 s / `ammo_every_ticks`), not 20
  - done when: The journal says which of the three suspicions were real, with the autoplay table before and after

### 0118 - One road into the waves

Waits on 0112.  Likely files: `src/core/phases.gd, src/core/sim.gd, src/tools/night_road.gd (new), src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd, src/tools/shot.gd, src/tools/autoplay.gd, src/tools/determinism.gd, src/tools/make_goldens.gd, src/tools/perf_check.gd, src/tools/play_nights.gd, src/tools/art_showcase.gd, src/tools/capture_dawn.gd`.

About sixty-five places in the tests and tools start a night the same way: `begin_preparation`, then wait out `PREPARATION_TICKS`. Phase 10 changes how the build step ends twice (0136's START, 0137's dawn). Put the road into the waves in one place first, so those tasks change it once.

- A refactor: both hashes stay where they are and no test changes what it asserts
- One core entry starts the waves: `Phases.start_waves(state)`, PREPARATION to NIGHT, refusing any other phase with `push_error` like the other transitions; `Sim._tick_preparation`'s timer calls it. 0136's START intent and 0128's 30 s pass-out step will be its other callers
- Nothing in `src/tools/` or `src/ui/` calls `Phases.begin_night` directly any more (`art_showcase.gd` and `capture_dawn.gd` do today); `_task_0006_phases`' refused-transition check (`not Phases.begin_night(guard)`, ~l.2089) asks `start_waves` instead, or stays as an allowed exception
- A shared tool/test helper, e.g. `src/tools/night_road.gd` (`class_name NightRoad`, static): into the build step (`begin_preparation`); through it (the rest of the build step, `PREPARATION_TICKS - phase_tick`: on a fresh one exactly today's `Sim.advance(state, GameData.PREPARATION_TICKS)`, so the ticks are identical); both together; the night runner (step until the phase leaves NIGHT, with a cap - autoplay's 40000 loop); and the park (today's `_park_the_waves`)
- The park is where 0137 will also hold back dawn: say so in its doc comment, and add no state key for it now (any new key moves SIM)
- Route every site through it: `headless_check`'s `_scheduled_night`, `_fresh_night`, `_night_falls`, `_a_run_at_night`, `_to_the_next_night`, `_armed_prep`, `_defended_night` and the inline ones; the 19 lines in `input_check`; anything 0113-0117 put in the v1 suites; `shot.gd` (its `PREPARATION_TICKS + 1` too), `autoplay.gd`, `make_goldens.gd`, `perf_check.gd`, `play_nights.gd`. `determinism.gd` folds the state into SIM every `SAMPLE_EVERY` ticks through `_advance_sampling`: its build step must keep folding at the same ticks (the road tells it how many ticks are left, or takes the stepper), or SIM moves
- Leave the asserts whose subject is the timer itself (`_task_0006_phases`, 'then the night begins' after `PREPARATION_TICKS - 1`), each with a comment that 0136 rewrites it
- A brand-new `class_name` is invisible to `--script` runs until `--import` refreshes the cache: run verify, not the scripts by hand

  - done when: `_task_0118_road` in `headless_v1` reads the code lines (comments skipped) of `src/tools/*.gd` and `src/ui/*.gd`: `PREPARATION_TICKS` appears only in the road and in an allow-list of timer asserts named in the assert, and `Phases.begin_night(` nowhere outside `src/core/` but its allowed exceptions (the assert's own needles excluded)
  - done when: `Phases.start_waves` from DAY or NIGHT returns false and changes nothing - asserted
  - done when: `python tools/autoplay.py` prints the same table as before the refactor, and `python tools/perf.py` stays within tolerance

### 0120 - One road for art that has not arrived

Waits on 0112.  Likely files: `src/ui/placeholder_art.gd (new), src/ui/art_placement.gd, src/ui/house_view.gd, src/ui/pixel_effects.gd, src/ui/player_view.gd, src/ui/player_art.gd, src/ui/world_view.gd, src/ui/README.md, tools/placeholders.py (new), tools/verify.py, src/tools/headless_v1.gd`.

From here on code tasks put new things on screen long before Codex has drawn them. Give them one road: a stand-in with the real pack's canvas and pivot, found through the lookup the views already use, so the leaf that brings the real art for a new thing only deletes its entry and no view code changes.

- A registry, e.g. `src/ui/placeholder_art.gd`: for each runtime path drawn before its pack is integrated, the pack id (`Axxx`), canvas, pivot, frames, seconds, loop and draw scale, taken from the Deliverables table of `implementation/backlog/packs/Axxx-<slug>.md`; where a pack has a `Spec after` task, the entry names the task that settles its geometry
- One lookup: views read geometry straight from `RasterArt.FRAMES` today (`art_placement.gd`, `house_view.gd`, `pixel_effects.gd`, `player_view.gd`, `world_view.gd`). Put one function in front of it that answers from `RasterArt.FRAMES` first and the registry second, and move those call sites onto it
- Player poses too: `PlayerArt.pose` errors on a name missing from `PlayerFrames.COUNT` (generated by `import_art.py`, never edited by hand), so a stand-in pose (0129's sleeping farmer) gets its frame count, seconds and texture path from the registry when `PlayerFrames` has no such name
- A stand-in is never a hand-painted PNG: an existing texture (reused, tinted or scaled), an ASCII map in `tools/sprite_maps.py` built by `tools/gen_sprites.py` and owned `ascii` in `assets/art_source/ownership.json`, or a code-drawn shape - at the canvas and pivot the real art will have, so placement and y-sorting do not move when it arrives
- A leaf's whole view work for a new thing is deleting the registry entry when the raster outputs land at the same paths
- Record the stand-ins that exist today, so the tool lists them from the start: A006's `run_<dir>_0..7` (stand-in: the walk frames at `PlayerArt.RUN_FRAME_SECONDS`) and the `<verb>_<dir>_0..3` names A007 (till, plant, water, harvest), A008 (chop, mine, collect, carry) and A009 (craft, trade, repair) will deliver (stand-in: the legacy west strip, east mirrored). These replace art already in the game under other names, so nothing asks for them yet: their leaves (0122-0125) rename the poses in `PlayerArt` and delete the entries; this task leaves `PlayerArt.pose` naming `walk_<dir>` and `<verb>` as today. The legacy strips are 48x48/(24,44) at draw 1.0 - the same screen box as the contract's 96x96/(48,88) at 0.5; record the stand-in's own geometry and note the final one
- `python tools/placeholders.py` prints which packs are still on stand-ins; `--check`, wired into `tools/verify.py`, fails on an entry naming a pack that does not exist or is already `integrated` (read through `implementation/backlog/assets.py`'s own loader), or a path that is also raster-owned. 0290's visual gate reads it
- Document the road (registry, lookup, how to add and delete an entry) at the top of the registry and in `src/ui/README.md`: the `## Art` paragraph gen_backlog adds to every dressed prompt sends the agent to task 0120's road. View only: neither hash moves

  - done when: `python tools/placeholders.py` lists A006, A007, A008 and A009, and `--check` fails on a scratch entry naming `A999` (then removed)
  - done when: `_task_0120_placeholders` in `headless_v1`: every entry resolves through the lookup to a texture whose size and pivot match the entry; the player road answers a registered name (`run_south`: 8 frames, frame 0 is the walk's texture) the way `PlayerFrames` answers a real one; and no file in `src/ui/` other than the lookup reads `RasterArt.FRAMES` directly
  - done when: `python tools/shot.py 0120` taken and opened: nothing on screen moved, the farmer included

### 0121 - A controller for every action

Waits on 0112.  Likely files: `project.godot, src/app/input_actions.gd, src/ui/main.gd, src/ui/options_controls.gd, src/ui/pause_menu.gd, src/ui/title_screen.gd, src/ui/studio_intro.gd, assets/locale/strings.csv, src/tools/input_v1.gd, src/tools/headless_v1.gd`.

The plan promises a night played on a controller, and `project.godot` has not one joypad binding: only the pause menu, the title and the ident read raw pad buttons. Bind every action now, before phase 10's cursor and hotbar are built on top of them.

- A pad event for every action in `InputActions.ACTIONS`, in `project.godot`: `move_*` on the left stick and the d-pad; face, shoulder, trigger and Start/Back buttons for run, interact, cancel, build, place/remove/upgrade, inventory, night (0127's GO TO BED), ability, speed, skip_night, pause, tech, stats, log. Where there are more actions than buttons (the six seed slots), decide, write the layout in the journal and name any action left without a pad event on purpose in the assert below, with its reason
- Analog walking: `main.gd` writes `intent.move` as `int(Input.get_axis(...))`, which truncates a half-tilted stick to 0. Turn the stick into -1/0/1 through the action's deadzone, so a stick walks exactly like a key
- `InputActions.label_of` names pad buttons and axes from the strings table: new `ACT_PAD_*` rows (A, B, X, Y, LB, RB, LT, RT, Start, Back, d-pad and stick directions) in en and pt_BR. Hints and the controls screen show the pad's name when the last input came from a pad - a view-only flag in `InputActions`
- Rebinding keeps the devices apart: today `apply()` replaces all of an action's events with the one saved, so a rebound key would drop the pad button. Save one binding per device kind (`as_text`/`from_text` learn `joy:<button>` and `axis:<axis>:<sign>`, `is_bindable` accepts pad events), read old single `key:`/`mouse:` values as keyboard ones, and apply the clash rule within a device kind
- `pause_menu.gd`, `title_screen.gd` and `studio_intro.gd` read actions rather than raw `JOY_BUTTON_*`; menus and panels move focus on the d-pad/stick and accept/cancel on the face buttons through the `ui_*` actions
- Keep `_task_0095_controls`' sync check (project.godot `[input]` against `ACTIONS`) passing. Tutorial lines that name a key in their text (`TUT_CHOP`, `TUT_BUILD`, `TUT_NIGHT`) are 0141's and 0195's; a deadzone option is 0292's
- Cases go in `input_v1` with synthetic events (`Input.parse_input_event` with `InputEventJoypadButton` and `InputEventJoypadMotion`). Input and view only: neither hash moves (a stick walks exactly like a key, so the intents a keyboard writes are unchanged)

  - done when: `_case_0121_pad` in `input_v1`: synthetic pad events walk the farmer on the stick and on the d-pad, chop a tree, open and leave build mode, press the night button and open and close the pause menu - each asserted through the state or the scene
  - done when: Rebinding interact to another key keeps its pad button, and rebinding its pad button keeps the key - asserted, then reset
  - done when: `_task_0121_pad` in `headless_v1`: every action in `ACTIONS` has a joypad event in `project.godot` except the ones the assert names with a reason, every `ACT_PAD_*` key `label_of` can return is in the strings table, and no code line in `src/ui/` names a `JOY_` constant
  - done when: `python tools/i18n_check.py` passes; `python tools/shot.py 0121 options_controls` opened: the pad labels fit

### 0114 - Untouched means the house the night started with

Waits on 0112, 0113.  Likely files: `src/core/rewards.gd, src/core/tech.gd, src/core/sim.gd, src/core/enemies.gd, src/ui/night_hud.gd, src/ui/result_screen.gd, src/tools/play_nights.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd, src/tools/input_check.gd`.

With 'stout timbers' the house starts the night at 140, yet four rules still measure it against 100: it can lose 40 and still pay the untouched bonus, and the skip refusal and the danger bar read the wrong share. Every 'how whole is the house' question is asked of the house the night started with.

- Route through `Phases.house_full(state)`: the 'the house untouched' line in `rewards.gd` (`house_hp >= GameData.HOUSE_HP`), `Tech._earned` `&"house untouched"`, the percentage `Sim.why_not_skip` compares with `SKIP_MIN_HOUSE_PERCENT`, and `Enemies.house_fraction`
- The view reads the same number: the night HUD house bar, its text and its `HOUSE_DANGER_PERCENT` pulse (`night_hud.gd`, `full := maxi(GameData.HOUSE_HP, 1)`), the result screen's `RES_HOUSE` line, and `play_nights.gd`'s report
- If the tree can change between the night and its result screen, `Rewards.settle` records the full value in the payout and the screen prints that instead of recomputing it - check and say which
- `GameData.HOUSE_HP` outside `game_data.gd` is left only in `Phases.house_full` and `Farm.initial` (a new run's house, before any tree); 0113 (a dependency) has already taken it out of `repair.gd`. `_task_0114_untouched` in `headless_v1` reads the code lines of `src/core/` and `src/ui/` as text and keeps it so, the way `_task_0095_controls` scans for raw keys
- Update `input_check`'s house-bar case (~l.3350, it reads `str(GameData.HOUSE_HP)`) only if it now fails; its no-tree house is still 100
- No new number: 0191's house tiers build on `house_full`. The determinism scenario owns no tech, so the comparisons give the same answers and SIM should not move - but a new key in the payout (above) is hashed and moves it if the scenario's night settles; if SIM moves, say which and accept it with both numbers. DATA does not move

  - done when: `_task_0114_untouched`: with 'stout timbers', a night ending at 120 of 140 pays no 'the house untouched' money and earns no 'house untouched' tech; one ending at 140 earns both
  - done when: `Sim.why_not_skip` with 'stout timbers' allows a skip at 75 of 140 (53 %) and refuses at 65 of 140 with `[&"WHY_HOUSE_LOW", 46]`
  - done when: `_case_0114_house_bar` in `input_v1`: a 140 house reads `140/140` on the night HUD with no danger pulse

### 0119 - Tests and tools build in the build step

Waits on 0118.  Likely files: `src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd, src/tools/autoplay.gd, src/tools/determinism.gd, src/tools/shot.gd, src/tools/make_goldens.gd, src/tools/perf_check.gd, src/tools/play_nights.gd, src/tools/tower_showcase.gd, src/tools/barrier_showcase.gd, src/tools/effect_showcase.gd, src/tools/enemy_showcase.gd, src/tools/giant_showcase.gd`.

0132 will forbid defences by day. Before it does, move every defence the tests and tools put down into the build step, where they are allowed today, so that rule change is a rule change and not a hundred broken set-ups.

- Every set-up `Building.place` of a defence (an id in `GameData.DEFENCES`) happens in PREPARATION, after the road's 'into the build step' and before the waves: `_arm_the_farm`/`_defended_night` and the rest of `headless_check`'s ~62 place sites, `input_check`'s ~10, the v1 suites' groups from 0113-0118, `shot.gd`'s scenarios, `determinism.gd` `_set_the_farm_going`, `make_goldens.gd`, `perf_check.gd`, `play_nights.gd`. The same for every set-up `Building.upgrade` and `Building.sell` of a defence (~11 in `headless_check`): 0132 makes them follow the same rule
- The art gates verify runs place real defences after setting `phase` to DAY: `tower_showcase.gd`, `barrier_showcase.gd`, `effect_showcase.gd`, `enemy_showcase.gd`, `giant_showcase.gd`. They set PREPARATION around the placement, upgrade and sale instead, and their `show_art.py ... --check` rows still pass (`art_showcase.gd`'s stations are buildings and stay by day)
- Production buildings (`GameData.BUILDINGS`: press, generator, kitchen...) stay by day: decision #4 keeps them a day job
- `Autoplay`: `_a_day` still gathers, crafts, buys tech and puts up production buildings; a new build step between `begin_preparation` and the waves places, upgrades and repairs defences off the same plan cursor (`_wants`, `_room_for`, `_next_step`)
- `_task_0068_balance` asserts 'builds what its plan names first' straight after `_a_day`: rewrite it to look after the build step
- Leave the asserts whose subject is the day-placement rule itself - e.g. `_task_0022`'s 'built by day', `_task_0047`'s night barricade, the tutorial's day `build` step in `_task_0041` - with a comment at each pointing at 0132
- In `input_check`, a defence placed through the real build mode goes down after the night button; if build mode cannot open in PREPARATION, that is a bug to fix here and say so
- Only SIM may move, because the determinism scenario's towers and walls now go down in PREPARATION: accept it and write both numbers and why in the journal. DATA does not move

  - done when: With a scratch edit to `Building.allowed_in_phase` and `why_not_upgrade` refusing every `DEFENCES` id by day (reverted before the end), a full `python tools/verify.py` fails only on the day-rule asserts this task leaves for 0132, in `headless_check` and `input_check` - listed in the journal; the v1 suites, the art showcases, autoplay and the tools pass
  - done when: `python tools/autoplay.py` runs, and the journal has the nights held per policy before and after
  - done when: `python tools/shot.py 0119` taken and opened: `wave` and `refused` still show their towers and walls

### 0122 - Art: the farmer's run

Waits on 0120.  Likely files: `assets/art_source/player-fhd/, assets/art_source/manifest.json, assets/art_source/ownership.json, src/ui/player_art.gd, src/ui/placeholder_art.gd, src/tools/art_showcase.gd, src/tools/headless_check.gd, implementation/fhd-player/pilots/2026-10-04/palette-variants/promote_blue_walk.py, tools/verify.py, src/tools/shot.gd`.

Running is the walk played faster. Put in the eight-direction run Codex drew for A006 at the approved 32px detail, so holding run looks like running.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A006` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A006-PROMPT.txt` handoff (under `implementation/backlog/deliveries/`); check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/player-fhd/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`. The farmer's checks are `art_showcase.gd --locomotion` and the FHD player sources check (`promote_blue_walk.py --check`), which knows only walk and idle: extend it, or give the run its own promoter with a `--check` wired into `tools/verify.py`
- Runtime names `run_<dir>_0..7` for the eight directions of `PlayerArt.HEADINGS`: 80x80, pivot (40,72), `draw_scale` 0.5, `exact-source` inside the 12-colour blue garment ramp; `01.png` is frame 0, seconds and loop from the pack's contract, mirrors exactly as the handoff says (never flip a baked mirror again)
- `PlayerArt.pose` plays `run_<direction>` while running instead of `walk_<direction>` at `RUN_FRAME_SECONDS` (0120 left it naming the walk), its seconds from `PlayerFrames.SECONDS`; retire `RUN_FRAME_SECONDS` if nothing else reads it. Rewrite what pinned the stand-in: `_task_0073_player_art`'s running pose (~l.13300, 'runs its eight walking poses at a faster pace') and `art_showcase.gd`'s `_locomotion` (~l.1245-1290: the expected name and the seconds check)
- Delete A006's entry from the 0120 placeholder registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A006 integrated`.

  - done when: `python tools/show_art.py --locomotion --check` and the FHD player sources check pass with the run in them; `python tools/import_art.py --check` passes
  - done when: `python tools/placeholders.py` no longer lists A006
  - done when: FHD captures (`python tools/shot.py 0122 --fhd`, with the farmer running; add a scenario if none shows it) by day and in the dark, in `implementation/shots/0122/`, opened: feet on the ground line, body as tall as the walk, no blue drift
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0123 - Art: the farmer tilling, planting, watering and harvesting

Waits on 0120.  Likely files: `assets/art_source/player-fhd/, assets/art_source/manifest.json, assets/art_source/ownership.json, src/ui/player_art.gd, src/ui/placeholder_art.gd, src/tools/art_showcase.gd, src/tools/headless_check.gd, src/tools/shot.gd`.

The field verbs still play the older, stockier 48x48 farmer next to the 32px walk. Put in A007's till, plant, water and harvest, drawn facing south, north and west, so the farmer is one person whatever he is doing.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A007` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A007-PROMPT.txt` handoff (under `implementation/backlog/deliveries/`); check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/player-fhd/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend `art_showcase.gd --work` (and the FHD player sources check if the pack is exact-source) for the new strips
- Runtime names `<verb>_<dir>_0..3` for till, plant, water and harvest x south, north, west - anticipation, contact, follow-through, recovery - at the canvas, pivot and draw scale the pack's contract states; east is west mirrored at runtime
- `PlayerArt.pose` picks a verb's strip by facing (today `VERBS` maps a verb to one west strip, drawn for every facing), `flip` only for `Player.EAST`; one code path for every verb, with verbs not yet converted keeping their one legacy strip, which 0124 and 0125 reuse if this lands first. The contact frame still meets the rules' completion (`player_work.gd`)
- The tool in hand is not tiered by art: keep the pack's fixed head ramp as delivered and record which colours it is (manifest metadata or a constant beside `PlayerArt`) so 0173 can tint it per tier; this task draws it untinted
- Retire the legacy `till_*`, `plant_*`, `water_*`, `harvest_*` 48x48 outputs from the manifest and `ownership.json`, and their `PlayerArt.SECONDS` rows; rewrite `_task_0073_player_art` (its verb loops, ~l.13253-13276, and 'a verb is drawn even while a direction is held') and `art_showcase.gd`'s `--work` checks (`_work_frame` and `_work_cycles`, ~l.1491-1530, which pin `PlayerFrames.FEET`/`CANVAS` 48x48 and `pose(...)["name"] == verb` for north and south); delete A007's registry entry
- Set the pack to integrated: `python implementation/backlog/assets.py set A007 integrated`.

  - done when: `python tools/show_art.py --work --check` passes with the four verbs in three directions; `python tools/import_art.py --check` passes
  - done when: `python tools/placeholders.py` no longer lists A007
  - done when: FHD captures (`python tools/shot.py 0123 --fhd`; add a scenario that holds the farmer mid-verb if none does) of each verb facing south, north, west and east, by day and in the dark, in `implementation/shots/0123/`, opened: feet planted, the same body height as the walk
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0124 - Art: the farmer chopping, mining, collecting and carrying

Waits on 0120.  Likely files: `assets/art_source/player-fhd/, assets/art_source/manifest.json, assets/art_source/ownership.json, src/ui/player_art.gd, src/ui/placeholder_art.gd, src/tools/art_showcase.gd, src/tools/headless_check.gd, src/tools/shot.gd`.

Chopping and mining are what a first day is made of, and they still play the old 48x48 farmer. Put in A008's chop, mine, collect and carry in the 32px body.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A008` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A008-PROMPT.txt` handoff (under `implementation/backlog/deliveries/`); check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/player-fhd/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend `art_showcase.gd --work` for the new strips
- Runtime names `<verb>_<dir>_0..3` for chop, mine, collect and carry x south, north, west, east mirrored at runtime, at the pack's canvas, pivot and draw scale. `carry` is a view cue (`PlayerArt.COSMETIC`), not a core verb, and maps the same way
- If 0123 has not yet made `PlayerArt.pose` choose a strip by facing, do it here as the one path for every verb. The axe and pickaxe heads keep the pack's fixed ramp, recorded for 0173's tint, drawn untinted
- Retire the legacy `chop_*`, `mine_*`, `collect_*`, `carry_*` 48x48 outputs and their `SECONDS` rows; update `_task_0073_player_art` and the `--work` checks for the new names; delete A008's registry entry
- Set the pack to integrated: `python implementation/backlog/assets.py set A008 integrated`.

  - done when: `python tools/show_art.py --work --check` and `python tools/import_art.py --check` pass
  - done when: `python tools/placeholders.py` no longer lists A008
  - done when: FHD captures (`python tools/shot.py 0124 --fhd`, with an earlier leaf's mid-verb scenario or a new one) of each verb in four facings, by day and in the dark, in `implementation/shots/0124/`, opened: the axe meets the tree and the pick meets the rock on the contact frame
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0125 - Art: the farmer crafting, trading and repairing

Waits on 0120.  Likely files: `assets/art_source/player-fhd/, assets/art_source/manifest.json, assets/art_source/ownership.json, src/ui/player_art.gd, src/ui/placeholder_art.gd, src/tools/art_showcase.gd, src/tools/headless_check.gd, src/tools/shot.gd`.

The last three legacy strips: A009's craft, trade and repair in the 32px body. Repair becomes a day job in 1.0 - the house, the barns and the stations, mended by the farmer while defences are mended by cursor at night.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A009` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A009-PROMPT.txt` handoff (under `implementation/backlog/deliveries/`); check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/player-fhd/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend `art_showcase.gd --work` for the new strips
- Runtime names `<verb>_<dir>_0..3` for craft, trade and repair x south, north, west, east mirrored at runtime, at the pack's canvas, pivot and draw scale; if no earlier leaf has made `PlayerArt.pose` choose a strip by facing, do it here
- The `repair` verb plays this strip wherever the rules still offer it (by day today, and at night until 0129/0134 move night repair to the cursor); the hammer head keeps the pack's fixed ramp for 0173
- Retire the legacy `craft_*`, `trade_*`, `repair_*` 48x48 outputs and their `SECONDS` rows; update `_task_0073_player_art` and the `--work` checks; delete A009's registry entry. After this no 48x48 work strip is left except fish/reel (A024)
- Set the pack to integrated: `python implementation/backlog/assets.py set A009 integrated`.

  - done when: `python tools/show_art.py --work --check` and `python tools/import_art.py --check` pass
  - done when: `python tools/placeholders.py` no longer lists A009
  - done when: FHD captures (`python tools/shot.py 0125 --fhd`, with an earlier leaf's mid-verb scenario or a new one) of craft at the workshop, trade at the stall and repair on the house, by day and in the dark, in `implementation/shots/0125/`, opened
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0126 - The clock: 06:00 to 02:00

Waits on 0118.  Likely files: `src/core/phases.gd, src/core/game_data.gd, src/ui/day_hud.gd, src/ui/world_view.gd, assets/locale/strings.csv, src/tools/headless_v1.gd`.

The day gets an hour. Today's `DAY_TICKS` is mapped onto a clock that runs from 06:00 to 02:00, dusk falls at 18:00, and the light and the HUD read the hour, so every later task can speak in times of day.

- Clock levers in `game_data.gd`: `DAY_START_MINUTE := 6 * 60` (`# LEVER`, 05:00-08:00), `DAY_END_MINUTE := 26 * 60` (02:00 the next morning, `# LEVER`, 24:00-27:00) and `DUSK_MINUTE := 18 * 60` (`# LEVER`, 16:00-20:00). `DUSK_AT_TICK` becomes a constant derived from them, so none of its callers change
- Integer helpers in `Phases`: `clock_minute(state)` (minutes since midnight of the day that began: 360 at `day_tick` 0, 1560 at `DAY_TICKS`), `tick_at_minute(minute)` (the inverse, for tests and tools), and `is_dusk` reading the dusk minute. Outside DAY they answer for the moment the day ended. Until 0128 the clock keeps counting past 02:00 rather than clamping
- `GameData.validate()` (through a `check_clock(start, dusk, end, day_ticks)` that takes its numbers as arguments, like `check_tutorial(steps)`, so a test can feed it a bad clock; it replaces today's `DUSK_AT_TICK > DAY_TICKS` line): start < dusk < end, and `DAY_TICKS` is a whole number of ticks per game minute (6 today, 12-15 after 0166), so the clock never shows a minute twice or skips one
- `DHUD_DAY` (today `DAY %d   %d:%02d%s`, elapsed m:ss) shows the hour as 24-hour HH:MM in both languages (`assets/locale/strings.csv`), wrapping after midnight (01:30, never 25:30); keep `DHUD_DUSK` read or delete its row, so `tools/i18n_check.py` finds no unused key. 0140 gives the clock its final look
- `WorldView._daylight_now` and `_ramp_now` read the hour: dawn to noon, noon to dusk at 18:00, the dusk light deepening until 02:00. The night ramp does not change
- No rule changes: `day_percent` and `overtime_percent` keep their meaning (overtime now starts at 18:00), and the real length of the day is 0166's
- SIM must not move. DATA moves on purpose - dusk goes from 192 s to 144 s of the 240 s day (22:00 to 18:00 on the new clock) and the clock levers join the `time` row of `digest()`; write both numbers in PROGRESS

  - done when: `_task_0126_clock` in `src/tools/headless_v1.gd` asserts 06:00 at tick 0, 16:00 at `DAY_TICKS / 2`, 18:00 at `DUSK_AT_TICK`, 02:00 at `DAY_TICKS`, `tick_at_minute(clock_minute(t)) == t` on minute boundaries, and that `check_clock` refuses a dusk after the end of the day and a day that is not a whole number of ticks per minute
  - done when: `python tools/shot.py 0126 noon dusk` opened: the HUD reads HH:MM and the evening light starts at 18:00, not later

### 0127 - Going to bed starts the night

Waits on 0126.  Likely files: `src/core/phases.gd, src/core/house.gd, src/core/sim.gd, src/core/player.gd, src/ui/day_hud.gd, src/ui/house_view.gd, src/ui/title_screen.gd, src/ui/player_work.gd, src/tools/shot.gd, src/tools/art_showcase.gd, src/tools/house_check.gd, assets/locale/strings.csv, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Going to bed is the reality switch. The bed in the farmhouse and the night button both put the farmer to sleep, and sleeping is what starts the build step - the plan's section 12, 'when he sleeps, the farm switches reality'.

- One road: the `begin_night` intent edge becomes `sleep` in `Player.initial()`, `Sim._tick_day`, the day HUD (`day_hud.gd` ~285), the `night` action, the title backdrop (`title_screen.gd` ~231), `player_work.gd` (~40, which reads it), `shot.gd` (~317, ~443), `art_showcase.gd` (~1692), `house_check.gd` (~168) and every test (grep `"begin_night"`; `Phases.begin_night` the transition keeps its name). `intent` is in `State.TABLES`, so reconcile drops the old field and fills the new one: no `State.VERSION` bump, and the goldens still load
- `Phases.go_to_bed(state)` (DAY only; refuses and says so otherwise) is what the intent and the bed call; it runs `begin_preparation`, and **`begin_preparation` is what sets** a new `asleep` field of `house_visit` (a TABLES structure), so every road into the build step - the bed, the button, 0128's pass-out and 0118's `NightRoad` used by the tests and tools - leaves him asleep, and 0129's rule holds everywhere. **Asleep is not `House.inside`**: `begin_preparation` still calls `House.leave`, so `Building.why_not`, `Building.set_active` and the world view keep working. Add `House.asleep(state)`; `begin_day` clears the flag until 0138 wakes him in bed
- The bed gets a verb: indoors, interact on a floor cell next to the bed's `HOUSE_FURNITURE` rectangle writes the same `sleep` intent (in `House.tick`), with a `HOUSE_BED_HINT` line ('%s: go to bed', en and pt_BR, beside `HOUSE_ENTER_HINT`) in the house view. Keep it out of `Interact.DAY_ONLY`: a verb on that list needs a `Sfx.VERB_SOUNDS` entry (`_task_0084_day_sounds`); if it goes there anyway, map it to the nearest existing sound until 0281 gives it its own
- The day HUD's `NightButton` keeps its node name and becomes GO TO BED / IR DORMIR (`DHUD_TO_NIGHT`, `DHUD_NIGHT_WAITING` reworded); pressed anywhere on the farm, the farmer goes home and sleeps behind a fade, with no walking. The `night` action keeps its id (saved bindings are keyed by it) and `ACT_NIGHT` reads 'Go to bed'. 0140 owns the button's look and reminders
- Sleeping early skips the rest of the day. Decide what the skipped hours do and write why in the journal. This prompt recommends that they are neither lived nor credited: crafting queues, regrowth, livestock and the generator keep their progress and resume at 06:00 (no lost work), and nothing is produced for hours nobody lived (no exploit). That is what the night button does today, so the recommended choice needs no new code - only the decision, the journal line and the assert
- Rewrite the tests this task owns: `_task_0021_night_intent` (the sleep intent gets the build step, is consumed, is refused twice, and dusk never presses it), `_task_0111_house` ('defence starts outside' becomes 'the night starts asleep, not inside'; a house visit still cannot bypass the night), `_case_0111_farm_house` (~1956, 'starting night inside returns outside for defence'), every `NightButton` site in input_check (clicks ~1066-4993, requires ~1060-6355), the text case ~6355 ('GO TO BED' / 'IR DORMIR') and the intent at ~6452
- SIM moves on purpose (an intent field is renamed and `house_visit` gains a field, and both are hashed): record the old and new numbers. DATA does not move

  - done when: `_task_0127_bed` in `headless_v1.gd`: the bed and the intent both land in PREPARATION with `asleep` true and `inside` false; both are refused in PREPARATION, NIGHT and RESULT; the early-sleep rule the journal chose holds (e.g. a queue started at 09:00 and slept on keeps its progress and is not finished overnight)
  - done when: `_case_0127_bed` in `input_v1.gd`: walk into the house, stand by the bed, press interact - the build step begins; clicking GO TO BED from the far field does the same
  - done when: `python tools/shot.py 0127 house_interior dusk` opened, also with `--pt_BR`: the bed hint and the GO TO BED button read right and fit

### 0128 - Passing out at 02:00

Waits on 0127.  Likely files: `src/core/sim.gd, src/core/phases.gd, src/core/house.gd, src/core/game_data.gd, src/core/events.gd, src/ui/title_screen.gd, src/ui/log_panel.gd, src/tools/autoplay.gd, assets/locale/strings.csv, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd`.

The day finally ends. A farmer still awake at 02:00 collapses where he stands and the night begins anyway, with only a thirty-second build step: staying up late is allowed, and it costs preparation, not the run.

- In `Sim._tick_day`, on the tick `day_tick` reaches `DAY_TICKS` (02:00), `Phases.pass_out(state)`: whatever he was doing stops (his action, a fishing cast), `house_visit.asleep` and a new `house_visit.passed_out` are set, and `begin_preparation` runs - indoors or out. A panel that stops the clock also stops 02:00 from arriving, as today
- `PASS_OUT_PREPARATION_TICKS := 30 * SECONDS` (`# LEVER`, 15-60 seconds worth): after a pass-out the build step ends itself after this many ticks, through 0118's `Phases.start_waves`; an ordinary bedtime keeps today's `PREPARATION_TICKS` until 0136 removes it (the build step's `phase_tick` is the counter; no new key). `validate()` checks it is positive and below `Sim.MOST_TICKS_IN_A_NIGHT`, and it joins the `time` row of `digest()`
- The clock clamps at 02:00, and `overtime_percent` now runs 0-100 from dusk to 02:00 and never past it
- A `passed_out` event: a new `Events.KINDS` entry, a severity in `log_panel.gd` and a `LOG_PASSED_OUT` line in both languages, so the log says why the build step is short; add its sample to `_task_0090_log` (headless_check), which fails on a kind without one. The fade from where he fell is the transition's; the collapse itself is A001's (0129 registers it, 0143 integrates it)
- Anything that spends a whole `DAY_TICKS` by day now passes out into a night. `Autoplay._a_day` spends exactly that and then calls the road into the build step, which would find it already there: make it stop short of 02:00 and go to bed (0142 rewrites the loop properly). Check the long day advances in the suites too - `_task_0002_tick_and_rng`'s 10000 ticks, `_task_0005_guards`' 20000-tick replay, `_task_0030_fishing`'s idle `DAY_TICKS`, `_task_0038_idle`, `_mine_for_a_day` - and either keep them inside the day or accept the night on purpose; report the suite times
- Rewrite `_task_0039_clock`: 'the night never starts itself' becomes 'at 02:00 he passes out and the night starts itself'. The stubborn-player block keeps its point - ignoring the clock costs nothing beyond the short build step (house, money, wood and the planted crop are what they were at 02:00)
- The title backdrop (`title_screen.gd`) stops writing the sleep intent at dusk: it starts its clock shortly before 02:00 and lets the pass-out bring the night. Update `_case_0091_title`, which compares `backdrop_tick()` with `DUSK_AT_TICK` (~5439)
- SIM moves on purpose: `house_visit` gains `passed_out` (hashed like every state key), and the determinism scenario's second day (about 12700 ticks after `begin_day`) now runs past 02:00 into a pass-out night. Record both numbers. DATA moves (a new lever in `digest()`)

  - done when: `_task_0128_pass_out` in `headless_v1.gd` (write `day_tick` near the end rather than playing the day): still DAY at `DAY_TICKS - 1`; PREPARATION with `asleep` and `passed_out` at `DAY_TICKS`; NIGHT after exactly `PASS_OUT_PREPARATION_TICKS`; a farmer indoors passes out too; going to bed at 01:59 is an ordinary night
  - done when: The rewritten `_task_0039_clock`, `_task_0090_log` and `_case_0091_title` pass, and `python tools/autoplay.py` still plays its nights
  - done when: `python tools/shot.py 0128 --title` opened: the backdrop farm still reaches the night

### 0129 - He stays in bed all night

Waits on 0127, 0120, 0128.  Likely files: `src/core/player.gd, src/core/ability.gd, src/core/building.gd, src/ui/main.gd, src/ui/night_hud.gd, src/ui/player_view.gd, src/ui/house_view.gd, src/ui/world_view.gd, src/ui/placeholder_art.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Nobody walks at night. The farmer is in bed from the moment he sleeps until the morning, and the two things the night used him for - the flare and the repair - keep working without him until the cursor takes them over.

- `Player.tick` returns at once while `House.asleep` (consuming the `interact` and `cancel` edges): no movement, no verbs, no turn in PREPARATION or NIGHT. `main.gd` writes `intent.move = [0, 0]` and no highlight outside DAY, which frees the move axes for 0130's camera
- Interim flare until 0135: `Ability.use` centres on `Farm.house_centre(state)` instead of `Player.cell`; `_task_0054_ability`'s and `_case_0054_ability`'s (~3140, 'recorded where the player is standing') 'goes off at the player' becomes the house, for now
- Interim repair until 0134: a new edge intent `repair_cell` (`[-1, -1]` when idle; a new field of `intent`, which is in TABLES, so reconcile fills it) is consumed in `Building.tick` in PREPARATION and NIGHT and calls `Repair.apply_all` on that cell; the night HUD's REPAIR button writes the house's cell and is enabled while `Repair.can_mend` allows it. No new `X.tick` in `sim.gd`, so `PerfNames` is untouched
- Rewrite `_task_0022_reality`'s 'the player walks his defences at night' as 'he stays in bed all night' (600 ticks of move and interact change nothing about him)
- Every test that has the farmer walk or use a verb in PREPARATION or NIGHT now fails - a scratch run of both suites lists them. Known ones: `_task_0053_repair` and `_case_0053_repair` mend a wall at night with the held key (move those night mends onto `repair_cell`; 0134 then takes the defences' day verb away), and `_case_0056_night_hud`'s REPAIR block (~3395-3420, 'facing a broken wall') now mends a damaged house
- View: at night the farm shows nobody on the porch; the farmhouse windows stay lit (`lighting.gd` lights them already) and a Zzz drifts up from the house - a view cue, not a `Reactions` kind, so the hash never sees it
- Register the four A001 animations in 0120's placeholder registry under the names the pack will deliver - get into bed, the sleep loop, wake and stretch, pass out on the farm - with stand-ins (the idle frame turned or tinted is enough), and the Zzz for A002. The switch opens with a short interior beat of him getting into bed and asleep (view only: the rules are already in PREPARATION), the pass-out plays where he fell, and 0138 plays the wake
- SIM moves on purpose: `intent` gains `repair_cell`, and every state key is hashed (and more if the determinism scenario walks or flares at night - say which). Record both numbers. DATA does not move

  - done when: `_task_0129_asleep` in `headless_v1.gd`: in PREPARATION and in NIGHT, 600 ticks of move and interact leave his position, facing and action unchanged; a flare lands on the house centre; `repair_cell` on a damaged house mends it, charges what `Repair.cost_at` says, and changes nothing when the ledger cannot pay
  - done when: `_case_0129_asleep` in `input_v1.gd`: holding D at night does not move `Player.position`; clicking `RepairButton` mends a damaged house
  - done when: `python tools/shot.py 0129 dusk wave` and `python tools/shot.py 0129 --switch` opened: the bed beat, nobody on the porch at night, the windows lit, the Zzz visible

### 0140 - The day HUD: the hour and bedtime

Waits on 0126, 0127, 0128.  Likely files: `src/ui/day_hud.gd, src/core/game_data.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/input_v1.gd`.

The day HUD tells the time and says when it is time for bed: an HH:MM clock, a GO TO BED button that looks like the way into the night, a reminder from 22:00 and a warning before the 02:00 pass-out.

- The HH:MM clock (0126's format) gets its final place and look, tinted from dusk; it reads the `Phases` clock helpers and nothing else
- The GO TO BED button (`NightButton`) is dressed with the UI kit and lights up from the reminder hour
- `BEDTIME_REMINDER_MINUTE := 22 * 60` and `PASS_OUT_WARNING_MINUTE := 25 * 60 + 30` (01:30) as `# LEVER`s with ranges; `validate()`: dusk <= reminder < warning < `DAY_END_MINUTE`. They are view thresholds, not balance, so they stay out of `digest()` and neither hash moves (0112's coverage assert reads only Dictionary and Array tables)
- From 22:00 a quiet 'time for bed' line naming the GO TO BED key (the `night` action through `InputActions.label_of`, so a pad player reads 0121's glyph); from 01:30 a warning in the warn colour with the minutes left before he passes out (`DHUD_BEDTIME`, `DHUD_PASS_OUT_SOON`, both languages, inside `tools/i18n_check.py`'s widths)
- A `bedtime` scenario in `shot.gd` (the farm at 22:30) beside `noon` and `dusk`

  - done when: `_case_0140_bedtime` in `input_v1.gd`: no reminder at 21:59, the reminder at 22:00, the warning at 01:30; clicking GO TO BED at 23:00 starts the night
  - done when: `python tools/shot.py 0140 noon dusk bedtime` opened, also with `--pt_BR`

### 0130 - The night camera

Waits on 0129, 0121.  Likely files: `src/ui/main.gd, src/ui/world_view.gd, src/core/game_data.gd, project.godot, src/app/input_actions.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/input_v1.gd`.

At night the camera belongs to the player, not to the farmer: it pans over the whole farm with the keys, the screen edge or the right stick, so the guardian can look wherever the horde is.

- From PREPARATION until the day begins, `main.gd` stops calling `follow_player` and the world camera pans: with the move axes (WASD, the arrows, and the left stick 0121 bound to them), with the mouse inside an edge band of the window (only while the window has focus and the pointer is in it), and with the right stick
- The right stick gets actions of its own: `pan_left`, `pan_right`, `pan_up`, `pan_down` in `project.godot` and `InputActions.ACTIONS` (`ACT_GROUP_NIGHT`, `ACT_PAN_*` strings in both languages), rebindable, with the sync and clash checks passing
- Pan speed and edge width are `# LEVER`s in `game_data.gd` - view feel, not balance, so they stay out of `digest()`. Speed is in real seconds whatever 1x/2x/4x is set, and nothing pans while the pause menu is up
- Clamped by `WorldView._camera_bounds`, no zoom. The night opens with the camera on the house; RESULT leaves it where it is; when the day begins it goes back to the farmer
- `shot.gd` gains a camera hook that a night scenario can set (rewrite the comment that says the camera cannot be set); `dusk`, `wave` and `result` use it
- View only: neither hash moves

  - done when: `_case_0130_night_camera` in `input_v1.gd`: holding D at night moves the camera right by about speed x time and leaves the farmer where he is; panning past the farm edge stops at the bound; a synthetic right-stick motion pans; after the morning the camera is back on the farmer
  - done when: `python tools/shot.py 0130 wave` opened: the camera is where the scenario put it, not on the porch

### 0143 - Art: going to bed, sleeping, waking, passing out

Waits on 0129, 0128.  Likely files: `assets/art_source/player-fhd/, assets/art_source/manifest.json, assets/art_source/ownership.json, src/ui/player_frames.gd, src/ui/raster_art.gd, src/ui/placeholder_art.gd, src/ui/house_view.gd, src/ui/player_view.gd, tools/verify.py`.

The farmer's night in his own art - getting into bed, the sleep loop, waking and stretching, passing out on the farm - from Codex pack A001, replacing 0129's stand-ins.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A001` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A001-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/player-fhd/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`. The farmer has no `check_*_art.py`: its gates are a hash-checking promoter with a `--check` mode wired into `tools/verify.py` (like `implementation/fhd-player/pilots/2026-10-04/palette-variants/promote_blue_walk.py`) and the `show_art.py` showcases
- Runtime: the canvas, pivot and `draw_scale` the pack's contract states, one per animation; the get-in, sleep and wake strips play in `house_view.gd` sitting exactly on the bed (`FURNITURE_OFFSETS` for the bed), the pass-out in `player_view.gd` where he fell, over the shared shadow; the one-shots stay one-shots and the sleep loop loops
- Delete A001's entries from 0120's placeholder registry: the raster outputs land under the names 0129 registered, so no view code changes (`python tools/placeholders.py --check` fails on an entry left for an integrated pack). Extend the `--house-visit` and `--work` showcases with the four animations
- Set the pack to integrated: `python implementation/backlog/assets.py set A001 integrated`.

  - done when: `python tools/show_art.py --house-visit --check`, `python tools/show_art.py --work --check` and the farmer's promoter check pass; `python tools/import_art.py --check` passes; `python tools/placeholders.py` no longer lists A001
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game - going to bed, asleep, waking, a pass-out - opened and looked at, in `implementation/shots/0143/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0144 - Art: the farmer's reactions and Zzz

Waits on 0129.  Likely files: `assets/art_source/player-fhd/, assets/art_source/manifest.json, assets/art_source/ownership.json, src/ui/raster_art.gd, src/ui/placeholder_art.gd, src/ui/player_view.gd, src/ui/world_view.gd, src/ui/house_view.gd`.

The farmer's reactions at the 32px detail of his new body, and the Zzz that rises from the farmhouse at night, from Codex pack A002.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A002` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A002-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/player-fhd/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; the gates are the `--reactions` showcase and the importer's bubble checks
- Runtime: `react_bang`, `react_question`, `react_note` and `react_heart` keep their names (the legacy 48x48 frames are retired) and the Zzz takes the name 0129 registered; every frame carries a `bubble_xywh` covering every glyph pixel and no body pixel (`validate_bubble` in `import_art.py`)
- The Zzz replaces 0129's stand-in over the farmhouse at night and over him in bed indoors by deleting A002's entry from 0120's placeholder registry; `Reactions.KINDS` is untouched, because the Zzz is a view cue
- Set the pack to integrated: `python implementation/backlog/assets.py set A002 integrated`.

  - done when: `python tools/show_art.py --reactions --check` passes and shows the Zzz; `python tools/import_art.py --check` passes; `python tools/placeholders.py` no longer lists A002
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game - a reaction by day, the Zzz at night - opened and looked at, in `implementation/shots/0144/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0131 - The guardian's cursor

Waits on 0130, 0121, 0120.  Likely files: `src/ui/guardian_cursor.gd (new), src/ui/guardian_view.gd (new), src/ui/main.gd, src/ui/world_view.gd, src/ui/build_mode.gd, src/ui/tooltip.gd, src/ui/describe.gd, src/ui/lighting.gd, src/ui/placeholder_art.gd, src/app/input_actions.gd, project.godot, assets/locale/strings.csv, src/tools/headless_v1.gd, src/tools/input_v1.gd, implementation/backlog/packs/`.

The player's hand at night: a cell cursor that the mouse or the pad drives, that says what is under it, and that every night action points at - held by the porch scarecrow, who wakes up to be the guardian.

- A cell cursor in PREPARATION and NIGHT only. With the mouse it is the cell under the pointer (`WorldView.screen_to_cell`); with a pad the dpad and the left stick step it one cell per press with a hold-repeat (delay and rate are view levers) and the camera follows it near the edge. The last device used decides, as 0121's glyphs do, so the keyboard keeps panning (0130) while a pad steps
- It writes the levels the rules read - `build_cell` now, `ability_cell` from 0135 - and BuildMode's ghost and its `Pathing.route_if_blocked` preview follow the cursor instead of the raw pointer
- A tooltip of what is under it through `tooltip.gd` and `Describe`: a structure (name, HP against its levelled maximum, level), an enemy (kind, HP) or empty ground, with strings in both languages
- Seven highlight states, all registered now in 0120's placeholder registry so later tasks only switch them on: neutral, can place, blocked, upgrade, sell, repair, aim - a code-drawn outline with a 2-frame pulse until A004 is integrated by 0146. This task uses neutral, can place and blocked
- Any new pad action (a confirm or back for the cursor, if 0121 left `place` and `remove` without a pad button) goes into `project.godot` and `InputActions.ACTIONS` with `ACT_*` strings and is rebindable on the controls page; the clash check passes
- The porch guardian: a view-only prop at a fixed offset from `House.porch`, on a cell nothing can ever be built on (the house's own footprint beside the door is one) - not an occupant and not in the state, so the hash cannot see it. States: day (still), wake (plays at the reality switch), night (idle, the eyes lit as emission points `lighting.gd` reads) and point; placeholder until A003 is integrated by 0145. This task registers all four and plays the first three; 0133 makes it point when a defence goes down
- Settle A003's and A004's geometry from what this task drew: canvas, pivot, frames per state, seconds per frame, emission points
- View only: neither hash moves

  - done when: `_case_0131_cursor` in `input_v1.gd`: a synthetic mouse move puts the cursor on that cell; synthetic dpad presses step it one cell each and repeat when held; a placement at the cursor in PREPARATION lands on that cell; there is no cursor by day
  - done when: `_task_0131_guardian` in `headless_v1.gd`: the guardian's cell is never buildable (`Farm.buildable` false) on a new farm
  - done when: The Deliverables tables of `implementation/backlog/packs/A003-guardian.md` and `implementation/backlog/packs/A004-cursor.md` state the final geometry this task settled
  - done when: `python tools/shot.py 0131 dusk wave` and `--fhd` captures opened: the cursor reads over dark ground, the tooltip does not cover the HUD, the guardian stands by the porch with its eyes lit at night

### 0132 - Defences go down only at night

Waits on 0131, 0119.  Likely files: `src/core/building.gd, src/core/game_data.gd, src/core/phases.gd, src/core/tutorial.gd, src/core/sim.gd, src/ui/build_mode.gd, assets/locale/strings.csv, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd`.

The plan's decision 4: defences are placed, upgraded and sold only at night, by cursor, and production buildings only by day. The day earns and the night spends.

- `Building.allowed_in_phase`: a `DEFENCES` id only in PREPARATION and NIGHT, a `BUILDINGS` id only in DAY. `why_not` answers `WHY_ONLY_AT_NIGHT` for a defence by day (the string exists) and `WHY_NOT_AT_NIGHT` for a building after dark; `why_not_upgrade` and `sell` follow the same rule; `catalogue()` keeps following `allowed_in_phase`. The plan (4.3) lets upgrades go on during the waves, so `why_not_upgrade`'s `WHY_MID_NIGHT` refusal goes: rewrite `_task_0064_tower_levels` (~11931), and delete the `WHY_MID_NIGHT` row if nothing reads it any more (`tools/i18n_check.py` fails on an unused key)
- `placeable_at_night` goes: drop it from the barricade and drop the `check_defences` rule that tied it to a lifetime and a nightly limit. The barricade keeps `lifetime_ticks` and `per_night_limit` as its own identity (cheap, temporary, limited). Section 13's bug must not come back in the build step, which has no clock after 0136: a barricade placed in PREPARATION counts against tonight's limit (`Building.forget_tonight` moves from `begin_night` to `begin_preparation`) and its lifetime starts with the waves, not when it went down
- At night upgrade and sell go through the cursor: BuildMode's `upgrade` and `remove` write `build_upgrade` and `build_sell` at the cursor cell, and the cursor shows its upgrade and sell states (0131's registry)
- By day `B` lists only production buildings; at night the palette lists only defences (0133 turns it into the hotbar)
- The tutorial's `build` step moves to the night: it follows `night` in `TUTORIAL`, `Tutorial.tick` also runs on its beat in `_tick_preparation`, and `TUT_BUILD` says it happens at night, in both languages. 0141 writes the rest of the night's steps
- Rewrite `_task_0047_barricades` ('only the barricade goes down at night' becomes 'every defence goes down at night and none by day; buildings only by day'), `_task_0022_reality`'s 'built by day' wording and `_task_0041_tutorial`'s build step; any input_check case still placing a defence by day moves to the build step (0119 should already have moved them)
- A rule change: if SIM moves, record both numbers and why (0119 moved the determinism scenario's placements into PREPARATION, so it may not). DATA moves (the barricade and the tutorial)

  - done when: `_task_0132_night_build` in `headless_v1.gd`: for every `DEFENCES` id, `can_place` is false by day with the night refusal and true in PREPARATION and NIGHT on a clear cell; the reverse for every `BUILDINGS` id; upgrade and sell follow, and a tower upgrades mid-wave; the barricade still expires and still has its nightly limit, and one placed in PREPARATION counts against that limit and still stands for `lifetime_ticks` after the waves begin
  - done when: `python tools/shot.py 0132 refused` and a day build-mode capture opened: by day the list holds buildings only, at night defences only

### 0135 - The flare goes where you aim it

Waits on 0131.  Likely files: `src/core/ability.gd, src/core/player.gd, src/ui/main.gd, src/ui/guardian_cursor.gd, src/ui/world_view.gd, src/ui/night_hud.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

The flare goes off where the player aims it, not where somebody is standing. It is the night's one power today and the first of the plan's aimed powers.

- A level intent `ability_cell` (`[-1, -1]` is nowhere), written every frame from the cursor like `build_cell`; a new field of `intent`, filled in old saves by reconcile
- `Ability.use` centres on `ability_cell`. Nowhere or off the farm is refused and spends nothing - no cooldown, no `flares` count. 0129's interim house centre goes
- Aiming: while the flare is ready, holding the ability key or arming the FLARE button shows the radius around the cursor (`ABILITY.radius_tiles`, a Chebyshev square, the way `Ability.use` measures it) and the cursor's aim state. The key fires on press at the cursor; the armed button fires on the next confirm; `cancel` disarms. The pad uses the same actions through 0121's bindings
- Final `_task_0054_ability` and `_case_0054_ability`: the flare lands on the aimed cell; rewrite the flare half of 0129's `_task_0129_asleep` (it asserted the interim house centre)
- SIM moves on purpose: `intent` gains `ability_cell`, and every state key is hashed (more if the determinism scenario fires a flare - say which). Record both numbers. DATA does not move

  - done when: `_task_0135_aimed_flare` in `headless_v1.gd`: with one zombie by the aimed cell and one by the house, only the first is hit and slowed; a flare at nowhere is refused and keeps its charge
  - done when: `_case_0135_flare_aim` in `input_v1.gd`: moving the cursor and pressing the ability key flares that cell; arming the button and clicking flares the clicked cell
  - done when: A capture of the aiming preview, opened: the square matches what the flare hits

### 0146 - Art: the guardian's cursor

Waits on 0131.  Likely files: `assets/art_source/ui/, assets/art_source/manifest.json, assets/art_source/ownership.json, src/ui/raster_art.gd, src/ui/placeholder_art.gd, src/ui/guardian_cursor.gd, tools/check_ui_art.py, tools/show_art.py`.

The cursor's seven states in drawn pixels, from Codex pack A004, replacing 0131's code-drawn outline.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A004` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A004-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded lists of `tools/check_ui_art.py` and the `--ui` showcase
- Runtime: neutral, can place, blocked, upgrade, sell, repair and aim as one-cell 16x16 frames with a 2-frame pulse each, under the names 0131 registered; no text; readable over the night ramp on grass, soil and a wall
- Replace 0131's placeholder by deleting A004's entries from 0120's placeholder registry, so the states 0132, 0134 and 0135 switched on all show the new art
- Set the pack to integrated: `python implementation/backlog/assets.py set A004 integrated`.

  - done when: `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass; `python tools/import_art.py --check` passes; `python tools/placeholders.py` no longer lists A004
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game - the cursor in each state over dark ground - opened and looked at, in `implementation/shots/0146/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0133 - The hotbar of defences

Waits on 0132.  Likely files: `src/ui/hotbar.gd (new), src/ui/build_mode.gd, src/ui/night_hud.gd, src/ui/day_hud.gd, src/ui/tooltip.gd, src/ui/guardian_view.gd, src/ui/placeholder_art.gd, project.godot, src/app/input_actions.gd, assets/locale/strings.csv, src/tools/input_v1.gd`.

The night's shop window: a hotbar of every defence with its price, picked with a number key, a click or a bumper instead of a text list, so what the day earned is visible as walls and towers.

- In PREPARATION and NIGHT a hotbar along the bottom replaces BuildMode's text palette: one slot per id of `Building.catalogue(state)`, in that order, with its icon and price - the kit count when a kit is held, else `Building.cost_of`, greyed with what is short when `Building.affordable` says no, and the barricade's `left_tonight`. By day `B` keeps the text list of buildings
- Built from the catalogue, not a list: phase 13's six new defences appear with no edit here, and more slots than fit page or scroll
- Selection goes through `Building.select`, the road the palette rows use today: a click on a slot; `slot_1`..`slot_8` (add `slot_7` and `slot_8` - slots 1-6 are the seed keys by day (`DayHud.SEED_ACTIONS`) and mean hotbar slots at night, when the seed strip ignores them; `ACT_SLOT_*` stop saying 'SEED' in both languages); and `hotbar_prev`/`hotbar_next` on two pad buttons 0121's layout left free (the bumpers if they are) and a key pair, wrapping. New actions go into `project.godot` and `InputActions.ACTIONS` with `ACT_*` strings, rebindable, with the clash check passing. `cancel` clears the selection and the cursor goes back to inspecting
- Each slot's tooltip shows name, cost, HP, range and damage read from `GameData` (never copied) through `tooltip.gd`
- Icons through the placeholder road - the structure's own sprite scaled down is enough - until A005 is integrated by 0147
- The porch guardian (0131) plays its point state when a defence goes down, spotted by the view the way `sfx.gd` and `particles.gd` compare this frame's occupants with the last - no new `Events` kind, which would move SIM
- View only: neither hash moves. The night HUD's bottom-right controls stay clickable (0139 settles the final layout)

  - done when: `_case_0133_hotbar` in `input_v1.gd`: `slot_2` selects the second defence, clicking a slot selects it, a bumper cycles and wraps, a placement at the cursor uses the selection, an unaffordable slot shows its shortfall, `slot_2` at night leaves the selected seed alone, and the guardian is in its point state after the placement
  - done when: `python tools/shot.py 0133 wave refused` and `--fhd` captures opened, also with `--pt_BR`: prices legible, nothing overlapping the night HUD

### 0136 - The build step waits for START

Waits on 0118, 0132, 0128.  Likely files: `src/core/sim.gd, src/core/phases.gd, src/core/game_data.gd, src/core/player.gd, src/ui/night_hud.gd, project.godot, src/app/input_actions.gd, assets/locale/strings.csv, src/tools/night_road.gd, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

The build step has no clock. The night waits while the player builds and starts when they press START - except after a pass-out, when the horde is already at the gate and gives thirty seconds.

- `Sim._tick_preparation` no longer starts the night by itself: a new edge intent `start_waves` (consumed by the tick, ignored outside PREPARATION) calls 0118's `Phases.start_waves`; after a pass-out the night also starts by itself at `PASS_OUT_PREPARATION_TICKS` (0128), and that timer is the only one left
- `PREPARATION_TICKS` leaves `game_data.gd` and `digest()`; the day clock stays stopped through the build step
- A START button on the night HUD (`StartButton`, `NHUD_START` 'START' / 'COMEÇAR') and a `start_waves` action in `project.godot` and `InputActions.ACTIONS`, with a pad button (0121) and a default key that is not the GO TO BED key, so a double press cannot skip the build step; `ACT_START` in both languages. After a pass-out the button counts down (`NHUD_START_IN`)
- 0118's road (the `NightRoad` helper, or whatever 0118 named it) now writes `start_waves` instead of advancing `PREPARATION_TICKS`, so autoplay, determinism, shot, perf_check, play_nights and make_goldens change nowhere else. A loop that waits the build step out without naming the constant would now spin for ever - `shot.gd`'s trailer (~322, `while ... == Phases.PREPARATION`) is one: route it through the road too
- Rewrite `_task_0006_phases` ('preparation ends itself' becomes 'preparation waits for START') and every assert 0118 left on the timer with a comment pointing here; input cases that waited out the build step use the road. 0118's `_task_0118_road` text scan allowed `PREPARATION_TICKS` in the road: it now allows it nowhere. Check 0128's `_task_0128_pass_out` ordinary-bedtime half still holds
- SIM moves on purpose (`intent` gains `start_waves`, and the determinism scenario's build step is one tick instead of 600): record both numbers. DATA moves (`PREPARATION_TICKS` leaves `digest()`)

  - done when: `_task_0136_start` in `headless_v1.gd`: two minutes of ticks in PREPARATION (past the old 20 s and the 30 s pass-out timer) stay in PREPARATION; `start_waves` begins the night on the next tick; `start_waves` by day or at night changes nothing; after a pass-out the night begins at exactly `PASS_OUT_PREPARATION_TICKS`, or sooner on START
  - done when: `_case_0136_start` in `input_v1.gd`: clicking `StartButton` and pressing the START key each begin the waves
  - done when: A capture of the build step with START on screen, opened

### 0134 - Repairing by cursor

Waits on 0131, 0113, 0133.  Likely files: `src/core/interact.gd, src/core/building.gd, src/core/repair.gd, src/ui/guardian_cursor.gd, src/ui/night_hud.gd, src/ui/build_mode.gd, assets/locale/strings.csv, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Repairs at night are made by pointing, not by walking. A damaged defence or the house is mended by selecting it with the cursor, paid as today, and defences are mended no other way.

- At night, confirming the cursor on a damaged structure or the house (an occupied cell, or nothing selected in the hotbar) writes 0129's `repair_cell` at the cursor; any part of a multi-cell structure mends its anchor (`Building.anchor_of`). Mending is `Repair.apply_all`: as far as the ledger covers, at today's price (`Repair.cost_at`, the house at `HOUSE_REPAIR_PERCENT`), up to 0113's real maximum
- The cursor shows its repair state over anything `Repair.can_mend` allows, and the tooltip adds what a full repair costs and how much can be afforded (`Repair.max_affordable`)
- Defences lose the farmer's repair verb: `Interact._offered` offers `repair` only for the house, production buildings and stations, by day. A damaged defence by day offers nothing and waits for the night. Gate it in `_offered`, not by adding `repair` to `Interact.DAY_ONLY`: every verb there needs a `Sfx.VERB_SOUNDS` entry (`_task_0084_day_sounds`) and there is no repair sound; if it must go there, map it to the nearest existing sound until 0281
- There is no farmer, so there is no per-HP work time any more: write in the journal what that does to a siege (a scripted wall under attack, mended every second, against today's held key) and whether a lever will be needed
- The interim REPAIR button of 0129 leaves the night HUD (0139 lays out what is there instead), and with it its string: delete the `NHUD_REPAIR` row, or `tools/i18n_check.py` fails on an unused key. Update what names `RepairButton`: `_case_0056_night_hud` (~3355, ~3407), `_case_0081_theme`'s size loop (~4403) and the RepairButton half of 0129's `_case_0129_asleep`, which now mends through the cursor
- Rewrite `_task_0053_repair` and `_case_0053_repair` where they mend a defence with the farmer's verb by day; the house by day keeps the verb
- A rule change: SIM moves if the determinism scenario repairs a defence by day - say which

  - done when: `_task_0134_cursor_repair` in `headless_v1.gd`: a damaged gun tower mended through `repair_cell` at night costs exactly `Repair.cost_at`; it is refused, changing nothing, when the ledger cannot pay; a damaged wall by day offers the farmer no verb; the house by day still does
  - done when: `_case_0134_repair` in `input_v1.gd`: confirming the cursor on a damaged wall at night mends it, with the mouse and with a synthetic pad press; no `RepairButton` exists any more and `python tools/i18n_check.py` passes
  - done when: A capture of the repair cursor and its tooltip, opened

### 0137 - The night ends at 06:00

Waits on 0136.  Likely files: `src/core/sim.gd, src/core/phases.gd, src/core/waves.gd, src/core/game_data.gd, src/core/events.gd, src/ui/night_hud.gd, src/ui/log_panel.gd, assets/locale/strings.csv, src/tools/determinism.gd, src/tools/night_road.gd, src/tools/nights.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, tools/nights.py`.

The night has an end you know in advance: 06:00. A house still standing at dawn is a won night and whatever is left walks off into the light; killing everything sooner still wins.

- `NIGHT_TICKS := 240 * SECONDS` (`# LEVER`, 180-300 seconds worth: the plan's three to five real minutes) is the waves' length from `begin_night` to dawn, the same after a 21:00 bedtime and after a pass-out. `validate()`: below `Sim.MOST_TICKS_IN_A_NIGHT`
- `begin_night` writes the dawn tick into the state (e.g. `wave.dawn_at`, a TABLES field whose `initial()` is `NIGHT_TICKS`, so an old save gets a whole night) and `Phases.ticks_to_dawn(state)` reads it. The park of 0118's `NightRoad` (today's `_park_the_waves`) parks dawn too (`dawn_at` out of reach), so parked nights still never end
- In `Sim._tick_night`, after `Combat.tick`: still NIGHT and `night_tick >= dawn_at` -> `Rewards.settle(state, true)` and `Phases.enter_result(state, true)` with the survivors still on the farm; `begin_day`'s `Enemies.withdraw` and `EnemyRetreats` walk them off. A `dawn` event (a new `Events.KINDS` entry with a severity in `log_panel.gd` and a sample in `_task_0090_log`) with `LOG_DAWN` ('dawn - %d walked off', en and pt_BR). The house at 0 still loses and `_test_for_the_end` still wins early
- Interim until 0153: dawn does not end a night while a boss is on the farm (`Combat.boss_here`), so night 10 still ends only with the Giant or the house down, and the run can never end with the Giant standing
- `check_nights`: every night's schedule (the opening, each wave's members x `SPAWN_INTERVAL_TICKS`, the gaps) ends at least a margin `# LEVER` before `NIGHT_TICKS`; a headless assert samples the endless curve (nights 11-40, a few seeds) against the same rule, from the schedule functions and without playing a night; `tools/nights.py` (through `src/tools/nights.gd`) prints each night's schedule against the night
- The night HUD shows the time left to dawn as a countdown (`NHUD_DAWN`), never a wall clock - after a pass-out a 22:00-06:00 mapping would lie - holding at 0:00 while a boss keeps the night going. Skip and 1x/2x/4x simply run to dawn
- Owns `_task_0027_the_loop` ('ends by itself' becomes 'ends at dawn or when everything is dead'), `_task_0055_speed` (skip runs to dawn) and the `Sim.skip_night` in input_check's `_case_0082_shots` (~4461). `determinism.gd` stops calling `enter_result` directly and fights until the night ends itself: SIM moves on purpose (that, and `wave` gains `dawn_at`), record both numbers. DATA moves too: `NIGHT_TICKS` and the margin join the `time` row of `digest()`. A bounty only for kills is 0219's

  - done when: `_task_0137_dawn` in `headless_v1.gd` (write a near `dawn_at` into the test's state rather than playing 240 s, so the group stays a few seconds): a night whose horde cannot reach the house ends at exactly `dawn_at` with `survived` true, and the survivors are gone after `begin_day`; killing everything ends it sooner; a house at 0 before dawn loses; `check_nights` refuses a schedule longer than the night
  - done when: `Sim.skip_night` from mid-night takes at most the ticks left to dawn and lands in RESULT
  - done when: `python tools/nights.py` shows all ten nights inside the night with their margins; the numbers are in the journal
  - done when: `python tools/shot.py 0137 wave` opened: the dawn countdown is on screen

### 0145 - Art: the porch guardian

Waits on 0131, 0133.  Likely files: `assets/art_source/guardian/, assets/art_source/manifest.json, assets/art_source/ownership.json, src/ui/raster_art.gd, src/ui/placeholder_art.gd, src/ui/guardian_view.gd, src/ui/lighting.gd, tools/check_prop_art.py, tools/show_art.py, tools/verify.py`.

The porch scarecrow that becomes the guardian at night, from Codex pack A003, replacing 0131's placeholder.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A003` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A003-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/guardian/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`. It is a new family: extend `tools/check_prop_art.py`'s `NAMES` or add a `tools/check_guardian_art.py` wired into `tools/verify.py`, with a showcase
- Runtime: the day, wake, night and point states with the canvas, pivot and timings 0131 wrote into the pack's Deliverables table, at draw scale 1.0 (`ArtPlacement`'s 2x list is not extended); the eyes' light points become emission metadata, like `light_xy`, that `lighting.gd` reads - nothing else on the scarecrow emits
- Replace 0131's placeholder by deleting A003's entries from 0120's placeholder registry (runtime names `guardian_<anim>_<i>`, as 0131 registered them); the wake still plays at the reality switch and the point (0133) when something is placed
- Set the pack to integrated: `python implementation/backlog/assets.py set A003 integrated`.

  - done when: The guardian's checker and showcase pass; `python tools/import_art.py --check` passes; `python tools/placeholders.py` no longer lists A003
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game - still by day, awake with its eyes lit at night, pointing at a placement - opened and looked at, in `implementation/shots/0145/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0138 - Waking up: the morning report

Waits on 0137.  Likely files: `src/core/phases.gd, src/core/house.gd, src/ui/result_screen.gd, src/ui/house_view.gd, src/ui/main.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/autoplay.gd, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd, implementation/backlog/packs/A057-morning-report.md`.

Every night, won or lost, closes on a morning report, and confirming it starts the day with the farmer getting out of bed at 06:00.

- `begin_day` wakes him in bed: `House.wake(state)` puts him inside on the floor cell beside the bed - `inside` true, `asleep` and `passed_out` false, `outside_pos` the porch - so he walks out of the door into the day, and the clock reads 06:00. The wake animation 0129 registered plays (A001 stand-in until 0143)
- Tests and tools that walk the farmer outside after a night step him out with `House.leave` or a helper (the determinism scenario's second day, `Autoplay._a_day`, the suites' `_to_the_next_night`-style helpers); list the ones touched in the journal. The autoplayer keeps working
- `result_screen.gd` becomes the morning report: a heading with the day, what came in (the `Rewards` lines), what was lost (stock taken on a loss, structures lost), how many walked off at dawn, a line when the night began with a pass-out, and a leftovers line that says nothing is on the farm yet (phase 13's bones and moon stones fill it). Confirming is the same `confirm_result` intent. The ending and endless branches stay as they are (0160 reworks them)
- An optional header, a sunrise over the farmhouse, through the placeholder road (a code-drawn band is enough) until A057 is integrated by 0289; if the owner declines A057 the band stays
- `main._bank_if_a_night_ended` banks every night's end, won or lost (key it on `day` or `last_result`, not `nights_won`), without `Stats.fold` counting a night twice
- Strings in both languages, and the report fits 480x270 in both; a row nothing prints any more leaves strings.csv. The input cases that read `ResultScreen` keep passing: `_case_0027_the_loop` (~1303), `_case_0070_endless` (~3616) and `_case_0082_shots`' crowding check (~4466). SIM moves on purpose (where `begin_day` leaves the farmer): record both numbers

  - done when: `_task_0138_morning` in `headless_v1.gd`: after a won and after a lost night, `confirm_result` leaves him inside beside the bed, awake, at `day_tick` 0 and 06:00; a state saved and loaded in RESULT confirms into the same
  - done when: `_case_0138_morning` in `input_v1.gd`: the report shows its lines; confirming brings up the house view; a lost night writes the run save (the saved `day` matches)
  - done when: The Deliverables table of `implementation/backlog/packs/A057-morning-report.md` states the final geometry this task settled
  - done when: `python tools/shot.py 0138 result` opened, also with `--pt_BR`: nothing clipped or overlapping

### 0139 - The night HUD for the guardian

Waits on 0133, 0134, 0135, 0136, 0137.  Likely files: `src/ui/night_hud.gd, src/ui/day_hud.gd, src/ui/hotbar.gd, src/ui/ui_kit.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/input_v1.gd`.

One night HUD built for the guardian rather than for a farmer in the yard: the time to dawn, the house, the wave, START, speed, skip, the flare and the hotbar, all reachable by mouse and by pad.

- Top strip: the night, wave x/y, the dawn countdown (0137) and the house bar against `Phases.house_full` (the boss bar stays where it is). Bottom: the hotbar (0133). Bottom right: START in the build step; speed, skip and the flare with its charge during the waves
- A mode hint line says what a confirm does now - place, upgrade, sell, repair or aim - with the key or the pad glyph from 0121, following the cursor's state
- Skip becomes a button whose tooltip is its refusal (`Sim.why_not_skip`), and the day HUD's `SkipLine` read-out goes. The farmer-centric REPAIR button is gone (0134). The day HUD's `NightButton` belongs to 0127 and 0140 and is not touched here
- Every control writes an intent or asks the driver, as today; on a pad each one is reachable by focus or by its own action
- Icons through the placeholder road until A005 is integrated by 0147
- Rewrite `_case_0056_night_hud` (and `_task_0056_night_hud` where it reads the old layout) and the `SkipLine` read in `_case_0055_speed` (~3178); remove strings nothing reads any more (`DHUD_SKIP` and `DHUD_SKIP_NO`; 0134 already took `NHUD_REPAIR`) so `tools/i18n_check.py` stays clean
- View only: neither hash moves

  - done when: `_case_0139_night_hud` in `input_v1.gd`: START is up in the build step and starts the waves; speed cycles 1/2/4; skip is refused under `SKIP_MIN_HOUSE_PERCENT` with its reason and allowed above it; the flare shows its charge; no `RepairButton` exists; the hint changes with what is under the cursor
  - done when: `python tools/shot.py 0139 dusk wave` and `--fhd` captures opened, also with `--pt_BR`: no two labels on top of each other and nothing over the hotbar

### 0141 - Teaching the new night

Waits on 0139, 0140.  Likely files: `src/core/game_data.gd, src/core/tutorial.gd, src/core/sim.gd, src/ui/tutorial_prompt.gd, src/tools/perf_names.gd, assets/locale/strings.csv, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Day one teaches the new night - go to bed, build with the cursor, press START, hold until dawn - by watching the state and never gating anything.

- `TUTORIAL` has seven steps today (chop, plant, water, sell, craft, then 0132's night and build) and `MAX_TUTORIAL_LINES := 7` with a 3-9 range, so seven plus three does not fit: the `night` step becomes the bed step (`TUT_NIGHT` - 'N, or the button' - is replaced by `TUT_BED` and its row leaves strings.csv), START and dawn follow the night `build` step, and the lever goes to 9 - or two day steps merge; say which. `check_tutorial` still passes
- `Tutorial._happened` arms that read the state only: asleep seen, a defence placed in a build step, NIGHT reached, a night that ended at dawn or by a win
- `Tutorial.tick` runs on its beat in NIGHT too (0132 added PREPARATION; never indoors). `PerfNames.NIGHT` gains `Tutorial`: `_task_0102_budget` only compares the union of the two lists, so it would not notice a night system the benchmark does not time. `points_at` aims each step at something real: the bed (in the house view), a cell between the house and the spawn, the START button, the dawn countdown
- `TUT_BED`, `TUT_BUILD` (rewritten), `TUT_START` and `TUT_DAWN` in both languages, inside the widths `tools/i18n_check.py` measures - practical lines, not a description of the reality switch
- Rewrite `_task_0041_tutorial` and `_case_0041_tutorial` for the new steps
- DATA moves (`TUTORIAL`); SIM moves only if the tutorial state differs in the determinism scenario - say which

  - done when: `_task_0141_tutorial` in `headless_v1.gd` (jump `day_tick` and `dawn_at` rather than playing whole spans): a scripted first day and night completes every step in order; ignoring the prompts reaches the same night with the same state apart from `tutorial`
  - done when: `_case_0141_tutorial` in `input_v1.gd`: the bed line shows on day one after the day steps, the START line in the build step
  - done when: Captures of the bed, START and dawn prompts, opened

### 0142 - The autoplayer sleeps too

Waits on 0137, 0132, 0138.  Likely files: `src/tools/autoplay.gd, src/tools/autoplay_run.gd, src/tools/nights.gd, src/tools/play_nights.gd, tools/autoplay.py, tools/nights.py, tools/balance.py, tools/play_nights.py, implementation/BALANCE.md, src/tools/headless_check.gd`.

The autoplayer plays the game as it now is - a day, bed, building by cursor, START, the night to dawn - and keeps playing after a loss, so the balance tools measure the real loop again.

- `Autoplay.play`, per night: `_a_day` (gathering, crafting and production buildings by day only, starting from 0138's wake in bed); the `sleep` intent at a policy hour or when the day's plan is done, never passing out by accident (0128 only made it stop short of 02:00); the policy's defences in PREPARATION through the intent road (`build_cell` with `build_place`, `build_upgrade`, `repair_cell`); `start_waves`; ticks until RESULT, capped at `NIGHT_TICKS` plus a margin; then `confirm_result`
- It carries on after a loss instead of stopping; the per-night report adds how the night ended (dawn, everything dead, house down), the house left and how many walked off
- Policies keep their lists; nothing is placed by day (it would be refused)
- `tools/autoplay.py`, `tools/nights.py`, `tools/balance.py` and `tools/play_nights.py` still run; `balance.py` still restores `game_data.gd` and still refuses a dirty tree
- `_task_0067_autoplay` and `_task_0068_balance` are rewritten to the new loop and kept inside the suite's time (one day and one night per policy); report the group times
- A note in `implementation/BALANCE.md`: survival per night for the four policies over the same seeds before and after the new loop, and what changed
- Tools only: neither hash moves

  - done when: `_task_0067_autoplay` and `_task_0068_balance` pass, with their times in the journal
  - done when: `python tools/autoplay.py` plays ten nights for every policy and prints the table; the numbers are in the journal and in BALANCE.md
  - done when: `python tools/balance.py` with a short sweep finishes and leaves the git tree clean

### 0147 - Art: the night hotbar and HUD icons

Waits on 0133, 0139.  Likely files: `assets/art_source/ui/, assets/art_source/manifest.json, assets/art_source/ownership.json, src/ui/raster_art.gd, src/ui/placeholder_art.gd, src/ui/hotbar.gd, src/ui/night_hud.gd, tools/check_ui_art.py, tools/show_art.py`.

The icons of the night - the eight defences, the flare, START, speed and the moon of the dawn countdown - from Codex pack A005, replacing the hotbar's and the night HUD's placeholders.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A005` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A005-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded lists of `tools/check_ui_art.py` and the `--ui` showcase
- Runtime: one raw source each, cut into a 16x16 `icon_<id>` and a 10x10 `hud_<id>` (visible at most 14 and 8 px) for `gun_tower`, `auto_crossbow`, `flame_tower`, `mortar`, `mine`, `fence`, `wall`, `barricade`, the flare, START, speed and the dawn moon
- The hotbar (0133) takes the 16x16 cuts and the night HUD (0139) the 10x10 ones, replacing their placeholders by deleting A005's entries from 0120's placeholder registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A005 integrated`.

  - done when: `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass; `python tools/import_art.py --check` passes; `python tools/placeholders.py` no longer lists A005
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game - the hotbar and the night HUD in the build step and mid-wave - opened and looked at, in `implementation/shots/0147/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0289 - Art: the morning report

Waits on 0138.  Likely files: `assets/art_source/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_ui_art.py, src/tools/ui_art_showcase.gd, src/ui/placeholder_art.gd, src/ui/result_screen.gd`.

A small sunrise over the farmhouse heads 0138's morning report. Optional: if the owner declines the pack, the header 0138 drew becomes the shipped look and this task closes with a note.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A057` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- The one exception, because A057 is optional: if its status is `blocked` with the owner's decline in the note, do not wait. Delete A057's entries from 0120's placeholder registry (`src/ui/placeholder_art.gd`) and draw 0138's code-drawn band directly in `result_screen.gd`, so it is the final look and no longer a stand-in (or drop the header if it only made sense as art), quote the decline in the journal and close with `python tools/task.py done 0289`. `task.py next` never offers a task whose pack is not approved, so this path is run by hand or by 0290
- Use only the folder named in the pack's `CLAUDE-A057-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/<family>/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_<family>_art.py`, `ArtPlacement` if needed).
- Family `ui`: one header at the canvas and pivot 0138 settled in A057's Deliverables table, drawn by `result_screen.gd` above the report through the lookup it already uses, replacing 0138's stand-in (delete A057's registry entries in `src/ui/placeholder_art.gd` once the raster lands at the same path); no text in it (the report's words stay strings), checked in its own section of `tools/check_ui_art.py` and shown in `ui_art_showcase.gd`
- Set the pack to integrated: `python implementation/backlog/assets.py set A057 integrated`.

  - done when: `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass with the header counted
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures of the morning report after a won and after a lost night, and of the farm around it by day and by night, opened and looked at, in `implementation/shots/0289/`
  - done when: The sim and data hashes are unchanged (art never moves them)
  - done when: On the decline path instead: `python tools/placeholders.py` no longer lists A057, a capture of the morning report shows the band drawn directly, and the journal quotes the owner's words

### 0148 - Checkpoint: is the night better with him asleep?

Waits on 0137, 0138, 0139, 0140, 0141, 0142.  Likely files: `implementation/PROGRESS.md, implementation/shots/0148/, implementation/prompts/`.

**The plan's Phase 1 test.** Play the new night - the farmer asleep, the cursor, START, dawn - with a mouse and with a pad, and answer honestly whether it is better than the MVP's night. Every later phase waits on the answer.

- Play at least three whole days and nights by hand with mouse and keyboard and at least one with only a pad (a real one if attached; say honestly if it was synthetic): bed, cursor building, START, a repair, a flare, an upgrade and a sale by cursor, speed and skip, dawn, the morning report - and one night that follows a pass-out
- Run the autoplayer for every policy over ten nights and note how the nights end: at dawn, with everything dead, or with the house down
- FHD captures of one night from START to dawn - the build step with the cursor and the hotbar, the first wave, a repair, the flare aimed, the walk-off at dawn, the morning report - in `implementation/shots/0148/`, opened and looked at
- Answer the plan's question in the journal, 'is the night better with him asleep?', against the MVP's night: what is better, what is worse, what is missing, and what is slow or fiddly (the camera, the cursor, the pad)
- Fix here only what is small and inside this phase's rules; anything bigger becomes an edit to a later prompt or a note for the phase it belongs to
- Every later phase depends on this task. If the answer is no, run `python tools/task.py blocked 0148 "<the reason>"` and edit the later prompts that must change before any content is produced; never tick or untick a box by hand

  - done when: The journal has the answer, the nights played (device, how each ended, house left), the autoplayer's numbers, and every later prompt edited and why
  - done when: The captures in `implementation/shots/0148/` exist and were opened
  - done when: Either the task is done on a yes, or it is blocked with the reason and the later prompts are edited

### 0149 - The calendar: four seasons of fourteen days

Waits on 0148.  Likely files: `src/core/calendar.gd (new), src/core/game_data.gd, src/ui/day_hud.gd, src/ui/names.gd, assets/locale/strings.csv, src/tools/headless_v1.gd, src/tools/input_v1.gd, src/tools/input_check.gd`.

The farm learns what day of the year it is. Every rule of this phase hangs off one small set of pure helpers, and the player sees 'SPRING 3' beside the clock - before a single rule reads it.

- `src/core/calendar.gd` (`class_name Calendar`, node-free, static): `date(state)` - the calendar day, which is `state["day"]` until 0153 adds the boss hold, and the one place that knows it - plus pure `year_of(date)`, `season_of(date)` (0-3), `day_of_season(date)` (1-14) and `year_days()`. Each pure helper takes an optional season length, so a test can prove a seven-day season without editing the lever
- `GameData.SEASON_DAYS := 14  # LEVER: days a season, 7-28` and `SEASONS: Array` of the ids `spring`, `summer`, `autumn`, `winter` (names, not a lever); `validate()` gains `check_calendar` (four seasons, a season of at least two days), and both go into `digest()` (0112's coverage assert)
- No new State key and no rule reads the calendar yet: day 1 is Spring 1 of Year 1, day 14 Spring 14, day 15 Summer 1, day 56 Winter 14, day 57 Spring 1 of Year 2
- The day HUD shows the date beside 0126's HH:MM clock: `SPRING 3`, and `SPRING 3  YEAR 2` from the second year on. It takes the place of the day count in the clock line (`DAY %d` in `DHUD_DAY` / `DHUD_DAY_FIRST`, as 0126 and 0140 left them): one number for the day, not two. Rewrite in place the input_check cases that read `DAY 1` (`_case_0021_day_hud`, `_case_0039_clock`) and drop any row nothing reads any more. Season names go through `Names.KEYS` (`spring` -> `SEASON_SPRING`, ...) so `tools/i18n_check.py` sees literal keys
- `assets/locale/strings.csv` rows, both languages: `SEASON_SPRING` SPRING / PRIMAVERA, `SEASON_SUMMER` SUMMER / VERÃO, `SEASON_AUTUMN` AUTUMN / OUTONO, `SEASON_WINTER` WINTER / INVERNO, `DHUD_DATE` `%s %d` / `%s %d`, `DHUD_DATE_YEAR` `%s %d  YEAR %d` / `%s %d  ANO %d`; the width is the label's real width, measured
- The night HUD keeps its night number for now: `night` is not the date until 0151, and 0158 names the date there
- Hashes: SIM must not move. DATA moves once, because the calendar levers enter `digest()` - both numbers in the journal

  - done when: `_task_0149_calendar` in `src/tools/headless_v1.gd` asserts the five mappings above, a seven-day season through the optional argument, `year_days() == 56`, and that a state's hash is the same before and after asking every helper
  - done when: `_case_0149_date` in `src/tools/input_v1.gd` reads `SPRING 3` on day 3 and `SUMMER 1` on day 15 from the day HUD, in English and in Portuguese (`PRIMAVERA 3`, `VERÃO 1`)
  - done when: `python tools/shot.py 0149 noon dusk --fhd` and the same with `--pt_BR`, opened: the date sits by the clock and nothing overlaps

### 0173 - Five tools, three tiers

Waits on 0148, 0126.  Likely files: `src/core/tool_tiers.gd (new), src/core/state.gd, src/core/game_data.gd, src/core/crafting.gd, src/core/phases.gd, src/ui/workshop_panel.gd, src/ui/player_work.gd, src/ui/names.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Hoe, watering can, axe, pickaxe and rod, each in three tiers bought at the workshop with money and ore: the first thing day money buys that makes every later day better (plan section 3.7).

- `TOOLS` in `game_data.gd`: hoe, can, axe and pickaxe at basic/iron/gold, the rod at bamboo/fibre/iron, as tiers 0/1/2 of one ladder; each tier's cost (money + ore) and the effect fields 0174, 0175, 0180 and 0181 read, all `# LEVER`
- The tiers held and any pending upgrade live in a `tools` dictionary (keys from code: `State.TABLES`, through a new `initial()` - e.g. `src/core/tool_tiers.gd` - and one `_adopt` line), all tier 0 in a new game. **Tools are not resources**: `Rewards._loss` iterates `RESOURCES` and must never take one
- An upgrade is a workshop recipe whose output names a tool tier: a new branch in `Crafting._deliver` (and in `check_recipes`, which accepts only resources and defences today) records it as pending, and `Phases.begin_day` hands it over - ready the next morning. The tool keeps its old tier until then, so no day is spent without a can
- This task ships tier 1 for all five (iron hoe, can, axe and pickaxe; fibre rod) and the rod's tier 2 (iron). The gold costs arrive with 0176; until then gold is listed and refused with a reason
- Rebalance the tech nodes that did a tool's job: 'sharp tools' (`gather_percent`) and 'full cans' (`water_can_bonus`) keep their ids, get smaller numbers or a new role, and their `note` and `TECHNOTE_*` rows change in both languages; arithmetic in the journal. `_task_0063_tech_tree` asserts 'sharp tools' makes chopping quicker: keep that true or rewrite it in place
- The tool in the farmer's hand is not tiered by art (decision): the work frames keep one fixed head ramp and `player_work.gd` tints it per tier, view only. Tool icons in the workshop panel and the inventory use the placeholder road until A019 is integrated by 0202
- Names and strings for every tool and tier, and a `Names.KEYS` entry with a `REC_*` row for every upgrade recipe (every `RECIPES` id needs one), in both languages; `validate()` checks every tier cost names a real resource; `TOOLS` goes into `digest()`
- DATA moves (TOOLS, TECH_TREE). SIM moves on purpose: the new `tools` key is in the state and `State.hash_of` folds every key - record both

  - done when: `_task_0173_tools` in `src/tools/headless_v1.gd`: an iron axe queued with the money and iron is still basic that evening and iron the next morning; a lost night takes 25% of the iron and no tool
  - done when: `_case_0173_upgrade` in `src/tools/input_v1.gd`: open the workshop and order an upgrade with the keyboard and with the mouse; it shows as pending
  - done when: A new `tool_upgrades` scenario: `python tools/shot.py 0173 tool_upgrades --fhd` shows the upgrade list and the farmer chopping with a tinted iron head; opened and looked at

### 0191 - The house in three tiers

Waits on 0148, 0114.  Likely files: `src/core/phases.gd, src/core/house.gd, src/core/repair.gd, src/core/interact.gd, src/core/game_data.gd, src/ui/house_view.gd, src/ui/world_view.gd, src/ui/sfx.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Money buys a stronger house - tiers I, II and III, each more hit points and cheaper repairs - because the house is what keeps the sleeping farmer safe (plan section 3.8).

- `HOUSE_TIERS` (`# LEVER`s): a price in money (and materials if wanted), an `hp_bonus` and a repair discount per tier, bought by day; tier I is the house a new game has. `validate()` checks it (bonuses never fall from one tier to the next, the discount within 0-100) and it goes into `digest()`
- The tier is a top-level `house_tier` int: reconcile fills it for old saves (no version bump), but the state hash folds it. `Phases.house_full` adds the tier's HP, so every reader 0114 routed through it follows; the house repair in `Repair` applies the discount and composes with what 0113 decided for 'a full larder' on the house
- **There is no storage limit today** and section 3.8's 'more room to keep things' is not invented here; say so in the journal
- Pick one input path for buying (the house's door, the stall, or a tab in the workshop panel) and test it; the new tier holds from the next night. A new verb goes in `DAY_ONLY` and `all_verbs` with an `Sfx.VERB_SOUNDS` entry (borrow `sfx/trade` until 0281), or `_task_0084_day_sounds` fails. The tier names and the buying row are `strings.csv` rows in both languages, through literal keys
- Same 6x4 footprint and pivot; tiers II and III draw as today's house with a code-drawn mark through the placeholder road until A035 is integrated by 0217
- DATA moves; SIM moves on purpose (the `house_tier` key) - record both

  - done when: `_task_0191_house` in `src/tools/headless_v1.gd`: tier II raises `house_full` by its bonus with and without 'stout timbers'; a house repair costs the discounted price; the untouched-house bonus (0114) reads the new full
  - done when: `_case_0191_house` in `src/tools/input_v1.gd`: buy tier II by day
  - done when: A new `house_tiers` scenario: `python tools/shot.py 0191 house_tiers --fhd` shows tiers I to III; opened and looked at
  - done when: the Deliverables table of `implementation/backlog/packs/A035-house-tiers.md` states the final geometry this task settled

### 0150 - Nights looked up by the calendar

Waits on 0149.  Likely files: `src/core/waves.gd, src/core/endless.gd, src/core/run.gd, src/core/tech.gd, src/core/rewards.gd, src/core/game_data.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd`.

Before the night number changes meaning, every question about which night is which goes through one lookup, and nothing in the rules asks `MVP_NIGHTS` any more. A port: the same ten nights, the same Endless past them, the same hashes.

- Split the lookup in two in `src/core/waves.gd`: `Waves.plain_night(night, seed)` is the record as written - the authored row for days `1..Waves.authored_count()` (today's ten, `NIGHTS.size()`), `Endless.night(seed, day)` after them, defined for every day of every year - and `Waves.night_of(night, seed)` is the record the night actually fights: `plain_night` plus the calendar's rules. There are none yet; 0152-0154 add theirs there and nowhere else. With no rule, `night_of` hands back the authored row itself, not a copy
- Every pure question keeps going through `night_of` (`table`, `size_of`, `kinds_of`, `spawns_of`, `reward_of`, `summary_of`, `delay_before`, `tonight`); tests of the authored curve and of the endless curve (`_task_0059`, `_task_0060`, and `_task_0070`'s 'it grows', 'deals out every body it promised' and 'both sides') read `plain_night`, so the Full Moon, boss and calm rules of 0152-0154 do not fight them. No new record format: 0270 owns that
- Core readers of `MVP_NIGHTS` ask a named question instead: `Endless.is_generated`, `step_of` and `_size` use `Waves.authored_count()`, and `_size`'s base is the last authored night's plain size (through `plain_night`, not `Waves.size_of`), so a calendar rule on that date never moves the whole curve; `Run.is_over`, `is_final_night` and `go_endless` use a new `Run.final_night()` (the last authored night in this task; 0151 makes it the year's last day, 0160 the winter boss); `Tech.total_available()` and `least_available()` count `Run.final_night()` nights
- `Rewards._lines` and `_money_from` scale with `state["night"]`, which becomes the calendar day in 0151: read it through one helper (e.g. `Rewards.night_step(state)`) so 0219 and 0278 retune a 56-night year in one place; nights 1-10 pay exactly what they pay today
- `check_nights`' `nights.size() != MVP_NIGHTS` rule becomes: at least one authored night and no more than `Calendar.year_days()`
- The other test reads of `MVP_NIGHTS` that only mean 'the authored nights' become `Waves.authored_count()` as a plain rename: `_task_0003_game_data` ('ten nights'), `_a_full_farm` (for `_task_0038_idle`), `_task_0058_giant` and `_task_0068_balance`. `MVP_NIGHTS` then survives only for `_task_0066_run_end` and input_check's `_case_0070_endless` (both about the run's end, which 0151 changes), the tools (`autoplay.gd`, `nights.gd`, `play_nights.gd`, `perf_check.gd`) and its line in `digest()`; its comment says 0151 deletes it
- Rewrite `_task_0059`, `_task_0060`, `_task_0061`, `_task_0062` and `_task_0070` in `src/tools/headless_check.gd` over the lookup and the named questions: `_ten_of` becomes one copy per authored night, 'the Giant on night ten' becomes 'on the last authored night', the endless asserts compare `plain_night` with `Endless.night` and read 'past the authored nights'. Keep what each asserted and its run time
- Hashes: SIM and DATA both stay where they are. If either moves, find out why before going on

  - done when: `grep -rn MVP_NIGHTS src/core` finds only its declaration and the `digest()` line
  - done when: The five rewritten groups pass, and the journal has one line per group on what changed in it
  - done when: `python tools/nights.py 20` prints the same twenty lines as before the change (diff the two outputs; the result goes in the journal)
  - done when: `_task_0150_lookup` in `src/tools/headless_v1.gd`: every day 1-112 resolves to a non-empty record for seeds 0 and 424242; `night_of(1)` is the same object as `GameData.NIGHTS[0]` (`is_same`); `Tech.least_available()` is `tech_points` x `Run.final_night()`, and `Run.final_night()` equals `Waves.authored_count()` - the one line 0151 changes to `Calendar.year_days()`

### 0159 - Seasons on screen

Waits on 0149.  Likely files: `src/ui/season_view.gd (new), src/ui/season_remap.gdshader (new), src/ui/ambient_motion.gdshader, tools/palette.py, tools/gen_sprites.py, src/ui/palette_data.gd (generated), src/ui/world_view.gd, src/ui/particles.gd, src/ui/placeholder_art.gd, src/tools/shot.gd, src/tools/input_v1.gd, src/tools/headless_v1.gd`.

The same farm through the year: today's green in spring, warmer in summer, ochre and rust in autumn, snow in winter - all of it in the view, with not one rule touched.

- A palette remap shader (`src/ui/season_remap.gdshader`) on the terrain, edge and prop layers: each season maps the grass and foliage palette entries onto other palette entries (spring is today's art, summer warmer, autumn ochre and rust). The tables live in `tools/palette.py` and reach `PaletteData` through `python tools/gen_sprites.py` (its `palette_gd()` writes only `COLOURS` and `RAMPS` today: extend it); a uniform switches the season, and the terrain - drawn once - is never redrawn for it. A CanvasItem has one material and the trees already carry `ambient_motion.gdshader` for the wind: put the remap inside that shader (or a shared include) for them
- Winter stand-in until A012 and A013 are integrated by 0163 and 0164: the remap turns grass and foliage to the palette's pale colours (`bone`, `bone_dark`, `moon`, `stone_light`). No new `COLOURS` entry: the raster importer maps sources onto that palette, so a new colour could change imported art. Register the winter paths the seasonal lookup asks for (`terrain/<name>_winter`, `props/tree_<season>`, the caps) in 0120's registry under A012 and A013, resolving to the base frame, so `python tools/placeholders.py` lists both packs until 0163 and 0164 delete the entries
- Hooks so those leaves only add frames: a seasonal lookup (e.g. `SeasonView.frame_for(name, season)`) returns `<name>_<season>` when the art lookup of 0120 has it and the base name otherwise; a seasonal terrain atlas, when one exists, is swapped onto the terrain `TileMapLayer`'s tile set; the remap leaves alone a raster frame that already carries its season, and still remaps a registered stand-in
- Snowfall in winter in `src/ui/particles.gd`, honouring `a11y/particle_density` and the `video/max_particles` cap
- Snow on roofs by a code mask: in winter the top rows of the house's, the stations' and the stall's opaque roof pixels draw in `bone`/`moon` (the occupant sprites in `world_view.gd`; `house_view.gd` is the interior and has no roof). No new art: if the shots fail, say so in the journal and propose a pack rather than drawing one
- The season comes from `Calendar.season_of(Calendar.date(state))` and changes on the morning of a season's first day, behind 0138's wake-up, never mid-frame
- New shot scenarios `season_summer`, `season_autumn`, `season_winter` and `season_winter_night`: a date in each season, framed like `noon`
- View only: nothing in `src/core/` changes, and SIM and DATA must not move

  - done when: `_case_0159_seasons` in `src/tools/input_v1.gd`: the remap's season and the snowfall follow the date (off in spring, on in winter), and the terrain layer is not redrawn when the season changes
  - done when: `python tools/gen_sprites.py --check` (or a `_task_0159_palette` group in `src/tools/headless_v1.gd`) checks that every grass or foliage colour used by `terrain/` and the trees has a mapping in every season: it passes, and a scratch table missing one mapping makes it fail (tried, reverted, said so in the journal)
  - done when: `python tools/shot.py 0159 noon season_summer season_autumn season_winter season_winter_night --fhd`, opened against `docs/reference-sheet.png`: each season reads at a glance and the night ramp still works over it

### 0175 - The axe and the pickaxe by tier

Waits on 0173.  Likely files: `src/core/interact.gd, src/core/gathering.gd, src/core/game_data.gd, src/ui/main.gd, assets/locale/strings.csv, src/tools/headless_v1.gd`.

The axe and the pickaxe save time by tier, and the hardest things on the farm - hardwood stumps and gold - want the iron ones.

- Fewer swings by tier: the tool's tier scales the swing in `Interact.ticks_for` or the `hits` `Gathering.strike` counts - pick one, keep it integer, and make it compose with 'sharp tools' (`gather_percent`) rather than replace it
- A `GATHERING` entry may name a `min_tier`; below it the cell still shows its verb but the work is refused with a reason in both languages ('needs an iron axe'), never a swing that silently does nothing - through the `Interact` reason road 0171 opened (a `Building.why_not`-shaped array that `Names.refusal` words), or open it here if 0171 has not landed
- The real gates arrive with their nodes - hardwood stumps (0177) want an iron axe, gold (0176) an iron pickaxe - so test the rule here with a rigged entry
- `validate()` checks `min_tier` against the `TOOLS` ladder; `check_iron` and `check_reachable` still pass
- DATA moves; SIM only if the scenario gathers with an upgraded tool

  - done when: `_task_0175_swings` in `src/tools/headless_v1.gd`: an iron axe fells a tree in fewer ticks than a basic one, by the percent the lever claims; a rigged `min_tier` node refuses a basic pickaxe and yields to an iron one
  - done when: The refusal fits its control in both languages (`tools/i18n_check.py`)

### 0217 - Art: the house in three tiers

Waits on 0191.  Likely files: `assets/art_source/buildings/, assets/art_source/manifest.json, tools/check_house_art.py, src/ui/art_placement.gd, src/ui/house_view.gd`.

House tiers I, II and III get their approved exteriors, whole and hurt; tier III reads as a small fortified farmhouse.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A035` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A035-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/buildings/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_house_art.py`, which hard-codes `house`/`house_hurt` and their window points today - extend it per tier).
- Runtime names: `house`, `house_hurt`, `house_2`, `house_2_hurt`, `house_3`, `house_3_hurt` with their slices (`house_<c>_<r>`, `house_2_<c>_<r>`...), `windows_xy`, `window_rects_xywh`, `light_xy` and `smoke_xy` on the same 6x4 footprint as today's house. The pack draws them at full density (128x128, pivot (64,120): today's 64x64 at 2.0), so take `house` out of `ArtPlacement.visual_scale`'s 2.0 list - it matches every file whose name starts `house_`, the tiers too - unless 0191 wrote a different density into the pack
- Replace 0191's code-marked stand-ins and flip A035's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A035 integrated`.

  - done when: `python tools/check_house_art.py` and `python tools/show_art.py --house --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0217/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0151 - The night is the calendar day

Waits on 0150.  Likely files: `src/core/phases.gd, src/core/run.gd, src/core/state.gd, src/core/tech.gd, src/core/endless.gd, src/app/save.gd, src/core/game_data.gd, src/app/playtest.gd, src/tools/nights.gd, tools/nights.py, tools/verify.py, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/autoplay.gd, src/tools/play_nights.gd, src/tools/perf_check.gd, tools/goldens/`.

The meaning change. The night fought at the end of a day is that day's night in the calendar, so difficulty follows the calendar, a lost night is never fought again, and the year has fifty-six of them.

- `Phases.begin_night` sets `night = Calendar.date(state)` instead of `nights_won + 1`; `enter_result` still moves `day` every time and `nights_won` only on a win - a count now, not an index. Fix every reader that means 'the next night is nights_won + 1': `src/app/playtest.gd` (~l.221), the `perf_check.gd` and `play_nights.gd` fixtures, and test fixtures that set `nights_won` to pick a night (`_a_run_at_night`, `_task_0070_endless`'s 'night 25 is playable'), which now set `day`
- `Run.final_night()` becomes `Calendar.year_days()` (update `_task_0150_lookup`'s line that pins it to `Waves.authored_count()`). `Run.is_over` is 'the year's last night has been won', read from a stable fact (`Tech.already_paid(state, Run.final_night())` or equivalent), never from a count of wins, and `go_endless` opens on that same fact (0160 reworks the door). `Tech.total_available()` now counts a year (56 x 4 = 224 at best) and the whole tree costs 45, so `_task_0063_tech_tree`'s 'the tree costs more than the best run earns' fails: give `total_available`/`least_available` an optional night count and keep that assert on the first `Waves.authored_count()` nights, commented that 0220 re-prices the tree against the year
- `State.VERSION` 5 with `Save.migrations()[4]`: `day` is kept and becomes the date (no v4 save ever held a day back); a night in progress keeps its `night` until it ends and the calendar takes over at the next `begin_night`; `nights_paid` keeps its entries unchanged (an old night number is below the date, a date the calendar has left behind, so none can pay twice) and gains nothing - padding it with lost dates would make `already_paid(56)` lie to `Run.is_over`; `endless` becomes false (the year carries the run on; 0160 offers it again) except on an endless save already past `year_days()`, which stays endless so it is not 'over' on load (0291 settles those shapes). Saves can be written in any phase (the pause menu's save and quit): handle all four
- Test the step on a real v4 save: if `tools/goldens/run-v4.sav` does not exist, make it from the MVP commit `bea89a88` in a `git worktree` outside the repository (`--import`, `src/tools/make_goldens.gd` with `GODOT` set, copy back only the v4 goldens, remove the worktree); after the bump write `run-v5*.sav` from this build. Never name a key `moon_phase` (the newer golden's dropped key)
- Delete `MVP_NIGHTS` everywhere (code, tools, tests, `digest()`): after 0150 it is left in `_task_0066`, input_check's `_case_0070_endless`, `autoplay.gd`, `nights.gd`, `play_nights.gd` and `perf_check.gd`. The autoplayer's and `play_nights`' night counts become explicit arguments (default: the first ten calendar nights, so `implementation/BALANCE.md` keeps its meaning)
- Rewrite `_task_0065` (a lost night is not fought again: losing day 3's night leads to night 4 on day 4, and `nights_won` holds), `_task_0066` (not over mid-year, not ended by a loss, over once the year's last night is won - by a fixture on that date, not by playing 56 nights - then carrying on and the profile) and `_case_0070_endless` (the ending offers PLAY ON after a fixture wins date 56, and the next night is 57). The in-suite played run is at most three nights
- The whole-year assertion moves to a tool: `python tools/nights.py --check` resolves every date 1..`year_days()` for seeds 0 and 424242 and exits 1 on an empty record or any `check_nights` error; `tools/verify.py` runs it as a gate (through `check_script()` on `src/tools/nights.gd` with `verify.GODOT` - `tools/nights.py` has its own hard-coded `GODOT` default). If a generated night breaks 0137's night-length rule, fix the generator's pacing (an `ENDLESS` lever, DATA moving on purpose), not the check
- Hashes: SIM moves (the version is in the state) and DATA moves (`MVP_NIGHTS` leaves the digest), both on purpose - both numbers in the journal. The night HUD keeps printing `NIGHT %d`, now the date's number; naming the date there (`SPRING 3`) moved to 0158, whose captures show it

  - done when: `_task_0065`, `_task_0066`, `_task_0063_tech_tree` and `_case_0070_endless` rewritten as above and passing; `grep -rn MVP_NIGHTS src` and `grep -n MVP_NIGHTS tools/*.py` find nothing (the prompts in `tools/backlog/` may still name it)
  - done when: `python tools/nights.py --check` passes and prints 56 nights; a deliberately broken record makes it exit 1 (tried, reverted, said so in the journal)
  - done when: `_task_0151_migration` in `src/tools/headless_v1.gd` steps a v4 state in DAY, PREPARATION, NIGHT and RESULT up to v5, brings each to its next night through 0118's road and the sleep intent (never by playing a day out) and asserts the night number, the paid list and that no date pays twice; an endless v4 state past day 56 stays endless and a non-endless one there is not over either; every golden (v1, v4, v5) loads and plays

### 0163 - Art: winter ground

Waits on 0159.  Likely files: `assets/art_source/terrain/, assets/art_source/crops/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_terrain_art.py, tools/check_crop_art.py, tools/gen_sprites.py, src/ui/world_view.gd, src/ui/season_view.gd, src/ui/placeholder_art.gd`.

Winter gets real snow on the ground: the approved snowy grass, path, soil, tilled ground, edges and shores replace the remapped stand-in of 0159.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A012` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A012-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/terrain/` (and `crops/` for the tilled tiles), manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_terrain_art.py`, `tools/check_crop_art.py`, `ArtPlacement` if needed).
- Runtime names: `terrain/<name>_winter` for `grass`, `grass_b`-`grass_d`, `path` and `soil`, the winter `edge_*`/`shore_*` sides and corners, and `crops/tilled_winter` / `tilled_wet_winter` - 16x16, opaque, seamless, the same set as today's (the wet tile still at least 20 RGB darker, `check_crop_art.py`). The 256x80 atlas is ASCII-owned and built by `tools/gen_sprites.py` from the raster recipes (and asserted against it): build the winter atlas there the way the handoff says (new rows or a second atlas) and let 0159's hook swap it in
- Winter's ground stops going through 0159's remap (the remap stays for anything this pack does not cover); delete the stand-in entries from `src/ui/placeholder_art.gd`, so `python tools/placeholders.py` no longer lists A012
- Set the pack to integrated: `python implementation/backlog/assets.py set A012 integrated`.

  - done when: `python tools/check_terrain_art.py`, `python tools/check_crop_art.py` and `python tools/show_art.py --check` pass, and `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night in the real game - `python tools/shot.py 0163 season_winter season_winter_night --fhd` - in `implementation/shots/0163/`, opened and looked at: no seam, edge or shore breaks the snow
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0152 - Full Moon nights

Waits on 0151.  Likely files: `src/core/calendar.gd, src/core/waves.gd, src/core/rewards.gd, src/core/game_data.gd, tools/palette.py, src/ui/palette_data.gd (generated), src/ui/world_view.gd, src/ui/day_hud.gd, src/ui/result_screen.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Days 7 and 14 of every season are Full Moon nights: a bigger horde, double the pay, and a night you can see further into. The player sees one coming days ahead.

- `FULL_MOON_DAYS: Array = [7, 14]  # LEVER: days of the season`, `FULL_MOON_HORDE_PERCENT := 150  # LEVER: percent of the night's count, 120-200` and `FULL_MOON_REWARD_PERCENT := 200  # LEVER: percent of the night's pay, 150-300`; `check_calendar` refuses a Full Moon day outside the season and a percent under 100; all go into `digest()`
- `Calendar.is_full_moon(date)` and `days_to_full_moon(date)` (0 on the night itself), pure
- In `Waves.night_of`, over `plain_night`: a Full Moon date's record has each non-boss wave's count scaled by `FULL_MOON_HORDE_PERCENT` (integer arithmetic, never below the plain count), boss rows untouched, and carries `"full_moon": true` - the flag 0158's forecast reads. Authored and generated nights alike, and no RNG. A scaled record must still fit 0137's night length (`python tools/nights.py --check` resolves Full Moons too): if one does not, the Full Moon record tightens its own pacing (its gaps first), never the check
- `Waves.tonight()` is asked every frame by the night HUD: cache a record a rule changed the way generated ones are cached (`wave.tonight`), and only then, so night 1 stays the authored row and nothing new enters its state
- `Rewards`: a won Full Moon night pays `FULL_MOON_REWARD_PERCENT` of its money and materials, itemised as its own line for the morning report. Essence is not doubled here (0219 reads this helper for that) and moon stones are 0221's
- View only, a brighter night ramp: a `full_moon` entry in `tools/palette.py` `RAMPS` with the five fields `night` has (tint, lift, saturation, warm_keep, warm_edge), which `python tools/gen_sprites.py` writes into `PaletteData` as `FULL_MOON_TINT`, `_LIFT`, `_SATURATION`, ... (never edit `palette_data.gd`); `WorldView._night_ramp()` (static today) picks them when tonight is a Full Moon, and it still reads as night
- The day HUD's date line gains `FULL MOON IN 4 DAYS` / `FULL MOON TONIGHT` (plan section 9) through `I18n.plural`: `DHUD_FULL_MOON_IN.one`/`.other` (FULL MOON IN %d DAY(S) / LUA CHEIA EM %d DIA(S)), `DHUD_FULL_MOON_TONIGHT` (FULL MOON TONIGHT / LUA CHEIA HOJE), and the morning report's `RES_FULL_MOON` (FULL MOON BONUS / BÔNUS DE LUA CHEIA - no 'double', since the percent is a lever)
- `_task_0060`'s 'every curve climbs' and `_task_0070`'s 'it grows' keep reading `plain_night` (0150); if anything else in the suites assumed day 7 or 14 is a plain night, point it at the plain record
- Hashes: DATA moves (new levers). SIM should not, because the determinism night is day 1 - if it moves, explain it

  - done when: `_task_0152_full_moon` in `src/tools/headless_v1.gd`: days 7, 14, 21 and 56 are Full Moons and 6, 8 and 15 are not; a Full Moon record sends the lever's percent of its plain record per wave with the boss count unchanged; a won Full Moon night's money and materials are the lever's percent of what the same state would be paid with the flag off (same kills), with the difference on its own line; `Waves.tonight` hands back the same record over 100 ticks; `python tools/nights.py --check` still passes
  - done when: `_case_0152_moon_line` in `src/tools/input_v1.gd` reads the line on day 3 (`FULL MOON IN 4 DAYS`), day 6 (`... IN 1 DAY`) and day 7 (`FULL MOON TONIGHT`), in both languages
  - done when: A new shot scenario `full_moon` (the `wave` scene on day 7): `python tools/shot.py 0152 wave full_moon --fhd`, opened side by side - brighter, and still night

### 0153 - Boss nights repeat until the boss falls

Waits on 0151, 0137.  Likely files: `src/core/waves.gd, src/core/phases.gd, src/core/calendar.gd, src/core/rewards.gd, src/core/sim.gd, src/core/game_data.gd, src/ui/result_screen.gd, src/ui/night_hud.gd, assets/locale/strings.csv, src/tools/perf_check.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/shot.gd`.

Day 14 of every season is the season's boss night, and the season does not end until that boss is down. A boss alive at dawn walks off with the rest and is back the next night - without the loss penalty, and without the farm losing a day of crops and animals.

- `SEASON_BOSSES: Array = [&"giant", &"giant", &"giant", &"giant"]` (one per season; 0253-0255 put in the Harvester, the Scarecrow King and the Winter Lord); `check_calendar` requires each to be an `is_boss` enemy; in `digest()`
- `Calendar.is_boss_night(date)` is the season's last day. In `Waves.night_of`: a boss date's record gets one row of the season's boss, third from last like `Endless._put_the_giants_in`, from spawn 0 (the east, open in every season - 0157); every other date loses its `is_boss` rows (today's night 10 loses its Giant; Endless's every-fifth-night Giants stop reaching the calendar, and the `giant_every` levers stay for 0279 to decide)
- `Waves.boss_fell(state)`: every `is_boss` body in tonight's record was killed (from `killed_by_kind`). `Waves.tick` raises `boss_arrived` from `is_boss`, not from `&"giant"`
- 0137's interim goes (dawn waiting while `Combat.boss_here`, the night HUD's dawn countdown holding at 0:00, and the `_task_0137_dawn` assert of it, rewritten in place in `headless_v1` as the escape below). At dawn (`dawn_at`) on a boss night, boss alive and house standing: a third outcome, escaped, through `Rewards.settle` and `Phases.enter_result` - the boss and the survivors walk off as on any dawn, no `_loss`, no night pay or technology, `nights_won` unchanged. The house falling is a loss as on any night. The season holds whenever the boss did not fall, however the night ended
- The hold is a counter, not a frozen `day`: `day` still moves every night (the stall restocks on it, the report and stats count it, every day system runs) and a new Phases key `days_held` grows by one; `Calendar.date(state)` becomes `day - days_held`, so the date stays on 14 and tonight is the boss again. A new top-level int only: reconcile fills 0 for old saves, no version bump
- `nights_paid` is keyed by the date, so a repeated boss night pays its technology once, when the boss falls
- The morning report says it: `RES_BOSS_ESCAPED` (%s GOT AWAY - IT COMES BACK TONIGHT / %s FUGIU - VOLTA HOJE À NOITE), the boss named through `Names.of`
- Whatever assumed the Giant on night 10 looks for the boss on Spring 14: `_task_0058_giant` (`Waves.table(...)` of the last night), the 'one new thing a night' asserts of `_task_0059`/`_task_0060` and `_task_0070_endless`'s Giant counts if any still read `night_of` rather than `plain_night`, and `perf_check.gd`'s worst case (0275 later makes it the winter boss night)
- Hashes: SIM moves on purpose (a new key, the boss rows); DATA moves (a new table) - both in the journal

  - done when: `_task_0153_boss_nights` in `src/tools/headless_v1.gd`: for dates 1-112 and two seeds, `is_boss` rows appear only on dates 14, 28, 42, 56, 70, 84, 98 and 112, once each, with the season's boss; `python tools/nights.py --check` still passes with the boss rows in
  - done when: The same group, from Spring 14 fixtures started through 0118's `NightRoad` (its park, with dawn brought close rather than played out): boss alive at dawn -> no stock taken, `nights_won` unchanged, `day` +1, the date still 14, the stall restocked, tonight's record the boss night again; boss killed -> the next date is 15; house down with the boss alive -> the loss and the hold; house down after the boss fell -> the loss and no hold
  - done when: `boss_arrived` is raised for the Giant through `is_boss`, and `src/core/waves.gd` no longer names `&"giant"`
  - done when: A `boss_escaped` shot scenario: `python tools/shot.py 0153 boss_escaped --fhd`, opened - the morning report names the boss and says it comes back

### 0156 - The 1.0 farm map

Waits on 0151.  Likely files: `src/core/game_data.gd (FARM_MAP, MAP_LEGEND, checks), src/core/farm.gd, src/core/interact.gd, src/core/pathing.gd, src/app/save.gd, src/core/state.gd, src/ui/world_view.gd, src/ui/placeholder_art.gd, tools/goldens/, src/tools/shot.gd, src/tools/headless_v1.gd`.

Every change the 1.0 farm needs on its map, made once so a save migrates once: ground for the new attack sides, the new ore, the big hardwood stumps, ponds with names, and room kept for the coop, the barn and the shipping bin.

- Spawn ground for the sides 0157 opens: a clear band of walkable cells near the north, west and south edges, away from the farmstead and about as far from the house by path as the east band (measure with `Pathing.distance`; the numbers go in the journal), with nothing on it that regrows
- Nodes under their final ids, so 0176 and 0177 change data only: copper, coal and gold nodes (e.g. `copper_ore`, `coal_seam`, `gold_ore`; gold deeper in the rock face) and 2x2 hardwood stumps (`hardwood_stump`, one thing over four cells with an `anchor`, as a building's footprint is kept); new `MAP_LEGEND` characters. Until those tasks give them `GATHERING` rows they are inert, impassable obstacles with no verb: check that `Interact`, `Pathing._through`, `Farm` and `Save._widen` accept an occupant with no table row
- Ponds by name: one anchor cell per water body in a `PONDS` table (the north-west pond, the forest pond, the south-east lake) and `Farm.pond_of(state, cell)` by flood fill over the state's own terrain, cheap enough to ask once per cast, so 0179 keys species by pond; no occupants
- Room kept clear in a `MAP_SITES` table: the coop and the barn near the workshop and the animals (room for footprints up to 7x4; 0183 decides the real ones) and the shipping bin by the porch (0189)
- `check_map`, `check_livestock` and `validate()` stay clean; `check_reachable` (which walks only `GATHERING` ids today) also covers the new node ids that have no row yet, so each can be stood beside; a new check that every spawn band cell is walkable map ground. `PONDS` and `MAP_SITES` go into `digest()`
- `State.VERSION` + 1 (6 after 0151's 5) with a step in `Save.migrations()` in the style of `_expand_farm_v1..3`: the new nodes, stumps and cleared bands laid onto a save only where its cell is empty map ground - never over a plot, a building, the house or anything the player placed; map trees and rocks leave the bands and sites only if they are untouched map props; path caches reset and `grid_version` bumped. Write `run-v6*.sav` after the bump (0151's `run-v5*.sav` is this step's input)
- The new nodes and the stump are drawn through 0120's placeholder road (tinted `ore`, `seam` and `stump` frames, the stump scaled over its 2x2) until A021 is integrated by 0204
- Hashes: SIM and DATA both move (the map is in `digest()` and in the state) - both numbers in the journal

  - done when: `_task_0156_map_v1` in `src/tools/headless_v1.gd`: `GameData.validate()` is clean; every spawn band cell is walkable and `Pathing.reachable` on a new farm; each new node id is on the map; `Farm.pond_of` names three ponds and nothing on land
  - done when: The v5 golden steps up to v6 with every plot and every player-placed occupant where it was, the new nodes only on cells that were empty, and plays 600 ticks; every golden loads
  - done when: New shot scenarios standing at the north band, the new ore and a stump: `python tools/shot.py 0156 <them> --fhd`, opened

### 0154 - The calm night after a boss

Waits on 0153.  Likely files: `src/core/calendar.gd, src/core/waves.gd, src/core/rewards.gd, src/core/game_data.gd, src/ui/day_hud.gd, src/ui/result_screen.gd, src/tools/nights.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

After a boss falls the horde regroups: the first night of the next season sends nothing, the farmer sleeps through it, and something is waiting on the porch in the morning. Spring 1 of Year 1 is still the tutorial's night 1.

- `Calendar.is_calm(date)`: the first day of a season, except the first day of the game. With 0153's hold the calendar reaches a new season only once its boss has fallen, so this is a pure function of the date and the forecast cannot be wrong about it - in every year, Spring 1 of Year 2 included
- `Waves.night_of` returns a calm record for those dates: `{note, opening_ticks: 0, waves: [], calm: true}`. `check_nights` refuses an empty wave list unless the record says calm; `Waves.summary_of` and `tools/nights.py --check` print and accept it as calm
- The night still happens and takes no special road: the build step opens as on any night (decision #4: the only time defences go down), START - or 0128's 30 s after passing out - starts a night with nothing in it, and `Waves.begin`'s empty table wins it on the first tick
- A calm night pays only the gift: `CALM_NIGHT_GIFT: Dictionary = {WOOD: 20, STONE: 20, FOOD: 10}  # LEVER: units each, 0-60` - no night money, materials or technology, since nothing was defended; `nights_paid` still records the date; `validate()` allows only known resources and never money or `tech`; in `digest()`
- The day HUD's date line says `CALM NIGHT` on a calm date (`DHUD_CALM_TONIGHT`: CALM NIGHT / NOITE CALMA); the morning report says `RES_CALM_NIGHT` (A CALM NIGHT - THE HORDE REGROUPED / NOITE CALMA - A HORDA SE REAGRUPOU) and `RES_GIFT` (A GIFT ON THE PORCH / UM PRESENTE NA VARANDA); 0158's forecast reads the record's flag
- Anything in the suites or tools that reads dates 15, 29, 43 or 57 through `night_of` and expects a fight (a size, a kind, a side) reads `plain_night` instead, or skips calm dates; 0137's night-length sample and `tools/nights.py` accept a calm record
- Hashes: SIM should not move (day 1 is not calm); DATA moves (the gift lever)

  - done when: `_task_0154_calm` in `src/tools/headless_v1.gd`: dates 15, 29, 43 and 57 are calm and 1, 14 and 16 are not; a calm night ends won on its first tick after START with no entity spawned; it pays exactly `CALM_NIGHT_GIFT` and no technology
  - done when: `_case_0154_calm` in `src/tools/input_v1.gd`: to bed on Summer 1, START, and the morning report shows the calm and the gift - once by keyboard, once by pad
  - done when: A `calm_morning` shot scenario: `python tools/shot.py 0154 calm_morning --fhd` and `--pt_BR`, opened

### 0155 - Losing a night when the calendar moves on

Waits on 0151, 0153.  Likely files: `src/core/rewards.gd, src/core/farming.gd, src/core/pathing.gd, src/core/phases.gd, src/core/run.gd, src/core/game_data.gd, src/ui/world_view.gd, src/ui/placeholder_art.gd, src/ui/result_screen.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd`.

Losing costs what the plan says and nothing more: the calendar moves on, the horde takes a quarter of the stock, tramples the crops it walked through, and what it broke stays broken. Only a boss night comes back.

- The calendar moving on after a loss is 0151's rule; assert it here beside 0153's exception: an ordinary lost night is never fought again, a lost boss night is
- Stock loss stays `Rewards._loss` (`DEFEAT_LOSS_PERCENT`, money and technology kept by the `DEFEAT_KEEPS_*` levers): no change, an assert
- Trampling, new and deterministic: when the house falls, every plot on the horde's routes loses its crop. The routes are cells, never randomness - from each spawn region tonight used (`Waves.spawns_of`), follow the flow field (`Pathing.step_from`) from every spawn cell to the house, add every cell an enemy stands on when the house falls, widen by `TRAMPLE_REACH := 0  # LEVER: tiles either side of a route, 0-2` (in `digest()`; `validate()` refuses one outside 0-2), and walk the cells sorted
- A trampled plot (`plots`, RUN_DATA) stays tilled, loses its crop and growth, and keeps a `trampled` marker naming the crop for the view until something is planted there; `Farming` treats it as empty tilled ground. No migration: a missing marker means nothing was trampled
- Destroyed defences stay destroyed (the rubble is swept, nothing refunded): an assert, not a change
- The morning report lists it: `RES_TRAMPLED.one`/`.other` (%d CROP TRAMPLED / %d CROPS TRAMPLED; %d PLANTA PISOTEADA / %d PLANTAS PISOTEADAS)
- Find and remove what still says the same night comes back (doc comments in `phases.gd` and `run.gd`, any tutorial or report text); 0153's boss hold is the only repeat left. `_task_0065` is 0151's and is not touched here
- The trampled crop is drawn through 0120's placeholder road (`src/ui/placeholder_art.gd`: the crop's first stage frame, flattened and darkened in code) until A014 is integrated by 0197
- Hashes: SIM moves only if the determinism night is lost (it is not); DATA moves (the lever)

  - done when: `_task_0155_losing` in `src/tools/headless_v1.gd`: a lost night on day 5 leads to night 6 and a lost Spring 14 with the boss alive to Spring 14 again; a quarter of each stock is taken as before; on a farm planted across and beside the east route, every plot on the route cells (worked out in the test the same way) is trampled and none off them; a won night tramples nothing; a wall destroyed that night is still gone the next morning
  - done when: Two copies of the same state lose the same night and trample the same cells
  - done when: A `trampled` shot scenario (the morning after a loss, by the field): `python tools/shot.py 0155 trampled --fhd`, opened - trampled plots read as damaged, the rest as untouched

### 0157 - A new side every season

Waits on 0156, 0115.  Likely files: `src/core/game_data.gd (SPAWNS, SPAWN_SIDES, SIDES_BY_SEASON, check_nights), src/core/calendar.gd, src/core/endless.gd, src/core/enemies.gd, src/ui/build_mode.gd, src/ui/world_view.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/shot.gd`.

The farm is surrounded one side at a time: spring comes from the east, summer adds the south-east, autumn the north, and in winter they come from everywhere.

- `SPAWNS` gains regions on 0156's ground - 2 north, 3 west, 4 south - each a line of border cells like the east one; a parallel `SPAWN_SIDES: Array` names them `east`, `south_east`, `north`, `west`, `south` (the forecast's words); indices 0 and 1 do not move
- `SIDES_BY_SEASON: Array  # LEVER`: spring `[0]`, summer `[0, 1]`, autumn `[0, 1, 2]`, winter all five; `Calendar.open_sides(date)`; validated (every index a real region, each season a superset of the one before); both new tables in `digest()`
- Generated nights deal their sides from the date's open sides only: `Endless._lay_out` alternates through them instead of through every region. 0153's boss row already comes from the east. Rewrite in place `_task_0070_endless`'s 'both sides, always' (nights 11, 13, 20, 25, 33 against `SPAWNS.size()`) as 'every side open on that date'
- `check_nights` gains the rule that a record names only sides open in its season; it knows a record's date from its index (`validate()` passes `NIGHTS`, 0151's `nights.py --check` the resolved year). Today's ten break it in spring (nights 2-10 use the south-east): exempt them with an explicit, commented allowance that 0271 deletes when it remaps them, and record the deviation in the journal
- Every new region has walkable, reachable cells on a new farm (`Enemies.spawn_cells`), and 0115's rule holds for each: building over a region never silently loses a wave member
- The flow field is swept from the house, so more regions should add no sweep: measure with `python tools/perf.py` (path_refresh inside `PATH_BUDGET_US` and the 40% tolerance) and put the numbers in the journal
- The build step's route preview (`Pathing.route_if_blocked`, `WorldView.show_route`) shows a route from every side open tonight
- Hashes: DATA moves (new tables). SIM should not - day 1 comes from the east as before - and if it does, explain it

  - done when: `_task_0157_sides` in `src/tools/headless_v1.gd`: the open sides of Spring 1, Summer 1, Autumn 1 and Winter 1 are the table's; for dates 11-56 and two seeds every generated wave comes from an open side; every region has spawn cells on a fresh farm
  - done when: 0115's guarantee holds for regions 2-4, whichever fix 0115 chose: each region built over as far as the rules allow, a small hand-made record of a few walkers from it accounts for every member (killed, alive or waiting) and ends in bounded ticks - a few seconds for the three
  - done when: A `winter_build` shot scenario: `python tools/shot.py 0157 winter_build --fhd`, opened - a route from each of the five sides

### 0164 - Art: trees through the seasons

Waits on 0159, 0156.  Likely files: `assets/art_source/props/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_prop_art.py, src/ui/world_view.gd, src/ui/season_view.gd, src/ui/placeholder_art.gd`.

Blossom in spring, colour in autumn, bare branches under snow in winter: the approved seasonal trees and snow caps replace the remapped stand-ins of 0159.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A013` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A013-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/props/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_prop_art.py`, `ArtPlacement` if needed).
- Runtime names: `props/tree_spring`, `tree_autumn` and `tree_winter`, and the same for `tree_b` - 40x48, pivot (20,44), sharing canvas, pivot, scale and palette with the base tree (`variant_of` rules); summer is today's tree. The tree wind motion (`tree_wind_showcase.gd`) still applies
- Generic 16x16 snow caps drawn over each stump, rock, seam and ore node in winter, and over 0156's new nodes and stumps (one per 2x2 cell); the caps are an overlay in the view, never a change to the occupant. 0159's lookup finds the seasonal frames, and the remap leaves them alone
- Delete the stand-in entries from `src/ui/placeholder_art.gd`; `python tools/placeholders.py` no longer lists A013
- Set the pack to integrated: `python implementation/backlog/assets.py set A013 integrated`.

  - done when: `python tools/check_prop_art.py` and `python tools/show_art.py --check` pass, and `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night in the real game - `python tools/shot.py 0164 noon season_autumn season_winter season_winter_night --fhd` - in `implementation/shots/0164/`, opened and looked at: the trees change with the season and every cap sits on its node
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0165 - Crops grow by days

Waits on 0149, 0151, 0156.  Likely files: `src/core/farming.gd, src/core/phases.gd, src/core/sim.gd, src/core/game_data.gd, src/app/save.gd, src/core/state.gd, src/ui/day_hud.gd, src/ui/describe.gd, src/ui/shop_panel.gd, assets/locale/strings.csv, src/tools/perf_names.gd, src/tools/perf_check.gd, tools/perf_baseline.txt, src/tools/make_goldens.gd, tools/goldens/, src/tools/autoplay.gd, src/tools/art_showcase.gd, src/tools/effect_showcase.gd, src/tools/house_check.gd, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd`.

Crops grow by days, the way the plan and Stardew have it: each morning a plot that was watered the day before moves one day along. A field becomes something you plan a week around, not a minute.

- `CROPS` entries trade `growth_ticks` for `growth_days` (`# LEVER`, plan section 3.1: carrot 3, wheat 4, corn 8; the other nine crops are 0168's). `stages` stays 4 and `Farming.stage()` maps days onto it in integer arithmetic
- The credit: `Farming.dry_out()` (called by `Phases.begin_preparation`) first records which planted plots were watered, then dries them; `Phases.begin_day` calls a new `Farming.morning(state)` that adds one day to each recorded plot and raises `crop_ready`. One credit per morning, so a boss night that repeats (0153) still grows the field and a farmer who passed out (0128) is credited like one who went to bed
- Dry is not dead: an unwatered plot waits a day and loses nothing (`TUT_WATER` - 'come up sooner watered' - is rewritten to say so, both languages). `WATER_GROWTH_BONUS` and the `soak` bank go, nothing grows per tick any more: take `Farming.tick` out of `Sim._tick_day` and `Farming` out of `PerfNames.DAY` (`_task_0102_budget` compares the two), its arm out of `perf_check.gd`'s `_tick_one`, and the `day_farming` row out of `tools/perf_baseline.txt` (`python tools/perf.py --accept`)
- `value_per_day`, `harvests_per_day`, `seconds_to_grow` and `GameData._crop_offer`/`check_crops` work in days: harvests per season of 0149's season length, value per harvest as today; the seed strip (`DHUD_SEED_ROW` and its `DHUD_SEED_HEADING` 'TIME /DAY', `day_hud.gd`), the stall's seed rows (`SHOP_SEED_ROW`, `shop_panel.gd`) and the tooltip (`DESC_GROWS_IN`, `describe.gd`) say days, in both languages
- A saved plot's `growth` changes units: `State.VERSION` 7 (after 0156's 6) with a step in `Save.migrations()` that turns tick growth into whole days (rounded down, a ready crop stays ready - the step carries the old `growth_ticks` per crop as literals, the table no longer has them) and drops `soak`, plus `run-v7*.sav` through `src/tools/make_goldens.gd`; every older golden still loads
- Rewrite `_task_0028_crops` and `_task_0029_watering` (headless_check) and `_case_0028_seeds`/`_case_0029_watering` (input_check) to the new rule, and every other reader of tick growth: `_task_0018_wheat`, `_task_0020_shop` and `_task_0039_clock` (growth paused by a panel, a crop ripe after a day), `_task_0038_idle` (`_a_busy_day` asserts 'the crops grew' within one idle day), `_task_0109_reactions` ('a crop coming ready nearby puts a note up' within 12000 day ticks - `crop_ready` now fires at the morning credit, with him waking indoors: decide what the note means now), `_case_0040_shop` (its seed labels print `seconds_to_grow`), `art_showcase.gd` (it calls `Farming.tick`; `show_art.py --check` runs in verify), `effect_showcase.gd`, `house_check.gd`, the autoplayer's field plan - grep `growth`, `is_ready` and `Farming.tick` for the rest
- Tests credit mornings by calling `Farming.morning` or `Phases.begin_day`, never by advancing whole days of ticks - a day is about to become some sixteen thousand of them (0166)
- SIM moves on purpose (the determinism scenario plants crops) and DATA moves (the CROPS table); record both numbers

  - done when: `_task_0165_days` in `src/tools/headless_v1.gd`: a watered and an unwatered carrot planted together are a day apart after one morning; a carrot watered three days running is ready on the third morning; passing out credits the field like going to bed
  - done when: The migration turns a golden's half-grown plot into the matching whole days, asserted
  - done when: `python tools/shot.py 0165 noon --fhd` shows the field at several stages (the `noon` scenario gives its plots growth days directly - a first morning is all stage 0); opened and looked at

### 0176 - Copper, coal and gold

Waits on 0175, 0156.  Likely files: `src/core/game_data.gd, src/core/gathering.gd, src/core/interact.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd`.

The quarry gets copper and coal - for sprinklers, tools and the generator - and gold from autumn for the top tier (plan section 3.3).

- The copper, coal and gold nodes 0156 put on `FARM_MAP` under their final ids (e.g. `copper_ore`, `coal_seam`, `gold_ore`; its journal names them and the legend characters) become `GATHERING` entries with swings, yield and `regrow_ticks` (`# LEVER`), dearer than stone on the dials the way `check_iron` holds iron, and `Interact.OCCUPANT_VERBS` entries (`mine`, so `Sfx.VERB_SOUNDS` already covers them); gold has `min_tier` 1 (an iron pickaxe, 0175)
- Gold from autumn: a gold node offers no verb before the first autumn, through 0149's calendar helpers; say whether it stays open in winter
- `COPPER`, `COAL` and `GOLD` in `RESOURCES`, `SELL_PRICE`, the materials group, `Names.KEYS` and `ITEM_*` rows in both languages (0169's check wants all four)
- Coal is fuel (plan section 3.3): the generator may burn it instead of oil - decide and say so; 0193 uses coal for spring gunpowder
- The gold tier's costs for the hoe, can, axe and pickaxe (money + gold, `# LEVER`), so 0173's refused tier opens
- Nodes keep 0156's stand-ins on the placeholder road (tinted `ore` for copper and gold, `seam` for coal; 16x16, pivot (8,14)) and icons are tinted stand-ins until A021 (0204) and A020 (0203) are integrated
- DATA moves. SIM moves on purpose: three new resources are new keys in `held`/`gained`, which the state hash folds - record both

  - done when: `_task_0176_ores` in `src/tools/headless_v1.gd`: each new node yields its resource and regrows; gold refuses before autumn and with a basic pickaxe and yields after; a gold hoe can be ordered and arrives the next morning
  - done when: A new `quarry` scenario: `python tools/shot.py 0176 quarry --fhd` shows the quarry with the new nodes by day and by night; opened and looked at

### 0177 - Hardwood

Waits on 0175, 0156.  Likely files: `src/core/game_data.gd, src/core/gathering.gd, src/core/interact.gd, src/core/farm.gd, src/ui/world_view.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd`.

Big stumps give hardwood to an iron axe: a reason to upgrade early, and the stuff of the strong wall (0231).

- The 2x2 stumps 0156 put on the map (`hardwood_stump`, or the id its journal names) become a `GATHERING` node with `min_tier` 1 (iron axe), more swings than a tree, a `HARDWOOD` yield and a `regrow_ticks` (`# LEVER`) - nothing on the farm is exhausted for good - and an `Interact.OCCUPANT_VERBS` entry (`chop`). One occupant over four cells with an anchor, like the stations: a swing at any of its cells strikes it. `Gathering.strike`, `Farm.remove`/`restore` and the regrowth in `Gathering.tick` all work one cell at a time today: the stump leaves all four cells when it falls and comes back only when all four are clear (the anchor's entry in `regrowing`), asserted
- A chipped look after the first swing, until it falls (view, from `Gathering.swings_left`)
- `HARDWOOD` in `RESOURCES`, `SELL_PRICE`, the materials group, names and strings in both languages; its icon is a tinted stand-in until A020 is integrated by 0203
- Its use is 0231's strong wall; here it only sells, and the journal says so. DATA moves; SIM moves on purpose (a new resource in `held`/`gained`) - record both
- `check_reachable`: every stump has a cell to stand on beside it; the flow field treats it like a tree
- A scaled stand-in of today's `stump` at 32x32 through the placeholder road until A021 is integrated by 0204

  - done when: `_task_0177_hardwood` in `src/tools/headless_v1.gd`: a basic axe is refused at a big stump; an iron axe fells it in the swings, for the hardwood, the levers say, from any of its four cells; it is back on all four after `regrow_ticks`, and not while one of them is built on
  - done when: A new `hardwood` scenario: `python tools/shot.py 0177 hardwood --fhd` shows a whole and a chipped stump beside a tree; opened and looked at
  - done when: the Deliverables table of `implementation/backlog/packs/A021-ore-hardwood.md` states the final geometry this task settled (the node canvas and variants, the stump's canvas, pivot and states)

### 0183 - The coop and the barn

Waits on 0126, 0156.  Likely files: `src/core/game_data.gd, src/core/livestock.gd, src/core/building.gd, src/core/interact.gd, src/core/state.gd, src/ui/world_view.gd, src/ui/transition.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Animals get homes: a coop and a barn, built by day, that hold them, shelter them at night and - from 0184 - make them worth feeding (plan section 3.4).

- Coop and barn are `BUILDINGS` entries (hp, cost in wood, stone and money, `size`, an animal `capacity`, all `# LEVER`), built by day on 0156's `MAP_SITES` (room for up to 7x4) or anywhere buildable, with `Names.KEYS` entries and `BLD_*` rows in both languages. Decide the footprints and capacities here
- Animals live in their building: a record per building of who lives there (kind, produce waiting, ticks left), inside `livestock` or under a new key listed in `State.RUN_DATA`; `Livestock` produces for housed animals and the `collect` verb (already in `Sfx.VERB_SOUNDS`) moves from the animal to the building's door
- The map's cow and chickens move in: until a coop or barn exists they stand where `FARM_MAP` put them and behave as today; the first one built takes the loose animals of its kind in (removed as occupants, one `Farm.touch`). A save with loose animals keeps working
- `check_livestock` is reworked: every kind names the building it lives in, and the map or the stall (0190) is its source - 'every animal stands on the map' stops being a rule
- Buying animals is 0190's; here the map or a test supplies them
- Housed animals stand by their building by day (view only; wandering is 0185's) and are hidden at night; the buildings draw as scaled station stand-ins at their footprint through the placeholder road until A030 is integrated by 0212
- Update the animal parts of `_task_0034_cooking` and `_case_0034_livestock` if they rely on loose animals. DATA moves; SIM moves if the state gains a key or a station, or the scenario builds one - say which

  - done when: `_task_0183_barns` in `src/tools/headless_v1.gd`: building a coop moves the map's chickens in and their produce still comes; a full coop refuses another chicken; a barn holds its capacity
  - done when: `_case_0183_barn` in `src/tools/input_v1.gd`: place a coop by day and collect at its door
  - done when: A new `coop_barn` scenario: `python tools/shot.py 0183 coop_barn --fhd` shows the coop and the barn with their animals by day; opened and looked at
  - done when: the Deliverables table of `implementation/backlog/packs/A030-coop-barn.md` states the footprints, capacities and door/window points this task settled

### 0189 - The shipping bin

Waits on 0148, 0138, 0156.  Likely files: `src/core/shipping.gd (new), src/core/interact.gd, src/core/phases.gd, src/core/state.gd, src/core/farm.gd, src/core/game_data.gd, src/app/save.gd, src/ui/shop_panel.gd, src/ui/result_screen.gd, src/ui/sfx.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/make_goldens.gd, tools/goldens/, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

A shipping bin like Stardew's: drop things in at any hour of the day and be paid the next morning, so selling no longer waits on the stall's hours (plan section 3.6).

- The bin is an occupant with a `ship` verb in `Interact.OCCUPANT_VERBS` (and `DAY_ONLY`, `all_verbs`, and an `Sfx.VERB_SOUNDS` entry - borrow `sfx/sell` until 0281 - or `_task_0084_day_sounds` fails), on the bin site 0156 kept clear by the porch (`MAP_SITES`)
- Fixture or building - decide and say why. A fixture (`Farm.FIXTURES`, never sold or wrecked) laid by `FARM_MAP` reaches new farms only: old saves need a `State.VERSION` bump with a step that places it on the site when that cell is empty, in the style of 0156's, and a golden at the new version. A cheap day building needs no bump
- What waits is a `shipping` dictionary in the state (resource -> count; keys come from play: `State.RUN_DATA`); putting a stack in takes it out of `held` at once
- The morning report (0138's, shown in RESULT before `begin_day`) prints what the bin will pay, worked out with `Shop.paid_for` (the sell price and the `sell_percent` bonus) from what waits; the money lands at `Phases.begin_day` and the bin empties. The line and the ledger agree, asserted
- A panel to choose what goes in, reusing the stall's sell rows (`shop_panel.gd`); decide whether it stops the clock like the stall (`open_panel`) and say why; keyboard, mouse and pad. `ship` opens a panel, so it joins `Interact.ONE_SHOT` beside `trade` - a repeating verb reopens its panel on the tick after it closes
- Decide what a lost night does to the bin (the horde takes 25% of the stock): what is in the bin is sold, not stock, or it is taken - write it down and assert it
- Names and strings in both languages; the bin draws through the placeholder road until A033 is integrated by 0215
- DATA moves; SIM moves on purpose (the `shipping` key, and the bin if it is on the map) - record both

  - done when: `_task_0189_bin` in `src/tools/headless_v1.gd`: ten carrots shipped by day leave `held` at once and are paid the next morning at the sell price with the tech bonus; the report line names the total
  - done when: `_case_0189_bin` in `src/tools/input_v1.gd`: open the bin, put one stack in with the keyboard and one with the mouse, close it
  - done when: A new `shipping_bin` scenario: `python tools/shot.py 0189 shipping_bin --fhd` shows the bin and the morning line; opened and looked at
  - done when: the Deliverables table of `implementation/backlog/packs/A033-shipping-bin.md` states the final geometry this task settled

### 0158 - The forecast

Waits on 0151, 0152, 0153, 0154, 0157.  Likely files: `src/core/forecast.gd (new), src/ui/forecast_panel.gd (new), src/ui/day_hud.gd, src/ui/night_hud.gd, src/ui/names.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

At dusk the farmer learns what is coming: from which sides, how many and of what kind, and whether it is a Full Moon, a boss or a calm night. The forecast is never wrong, because it is the night.

- `src/core/forecast.gd` (`class_name Forecast`): `Forecast.of(seed, date)` returns `{date, season, day_of_season, full_moon, boss, calm, sides, waves, kinds, count, event}`, pure, built only from `Waves.night_of(date, seed)` - the record the night will fight, flags included - and `Calendar`; `Forecast.tonight(state)` asks it for `Calendar.date(state)`
- Never the run's stream: it reads `state["seed"]`, never `state["rng"]`, and anything random in it comes from a fresh `(seed, date)` stream like `Endless._stream_for`
- `event` is an empty slot (`&""`) that 0256 fills from `(seed, date)`; the panel draws nothing for it until then
- `src/ui/forecast_panel.gd`: shown in the day HUD from 18:00 (0126's dusk, `Phases.is_dusk`) and on the night HUD in the build step, hidden at noon and once the waves start. It shows the date, the season and moon marks, the sides in words, the waves, and one head and count per kind; a calm night says so and nothing else
- Strings in both languages, widths measured: `FCAST_TITLE` (TONIGHT / ESTA NOITE), `FCAST_FROM` (from the %s / pelo %s), `SIDE_EAST`, `SIDE_SOUTH_EAST`, `SIDE_NORTH`, `SIDE_WEST`, `SIDE_SOUTH` (EAST / LESTE, SOUTH-EAST / SUDESTE, NORTH / NORTE, WEST / OESTE, SOUTH / SUL), `FCAST_EVERY_SIDE` (from every side / por todos os lados), `FCAST_WAVES.one`/`.other` (%d WAVE / %d WAVES; %d ONDA / %d ONDAS), `FCAST_FULL_MOON` (FULL MOON / LUA CHEIA), `FCAST_BOSS` (%s IS COMING / %s ESTÁ VINDO), `FCAST_CALM` (A CALM NIGHT / NOITE CALMA). 0157's side ids get literal `Names.KEYS` entries (`east` -> `SIDE_EAST`, ...) so the panel names a side with `Names.of` and `tools/i18n_check.py` sees the keys; kinds through `Names.of` and the plural enemy keys
- Stand-ins through 0120's placeholder road until A010 is integrated by 0161 and A011 by 0162: each enemy's first walk frame cropped into a 16x16 head box, and code-drawn moon, boss and season marks at 16x16 and 10x10
- No new input path: the panel is information, and showing it all day is an option of 0292's
- Moved here from 0151: the night HUD's top strip (0139) names the date beside its night label with 0149's helper and `DHUD_DATE`/`DHUD_DATE_YEAR` (`SPRING 3`), through the waves too, so the plan's 'season, night and wave' is on screen
- Pure functions and view only: SIM and DATA must not move

  - done when: `_task_0158_forecast` in `src/tools/headless_v1.gd`: for a plain, a Full Moon and a calm date, the forecast's kinds, count and sides equal what the night sends (count `Enemies.spawn` through a parked run that only steps until every wave is out, keeping the group to a few seconds), and a boss date names the season's boss; 1000 calls to `Forecast.tonight` leave `state["rng"]` and the state hash unchanged
  - done when: `_case_0158_panel` in `src/tools/input_v1.gd`: hidden at noon, shown at 18:00 and in the build step, hidden once START is pressed
  - done when: `forecast_dusk` and `forecast_build` shot scenarios: `python tools/shot.py 0158 forecast_dusk forecast_build --fhd` and with `--pt_BR`, opened - every line fits, the night HUD names the date, and the heads read as the enemies

### 0160 - The end of the year

Waits on 0153, 0151, 0154.  Likely files: `src/core/run.gd, src/ui/result_screen.gd, src/ui/credits_roll.gd (new), src/ui/main.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

When the winter boss - for now the Giant - falls on Winter 14, the year is over: an ending, the credits, and the choice to carry on into a Year 2 that does not end.

- `Run.is_over` is 'the year's last boss has fallen and the run is not endless': with 0153's hold the date passes `Calendar.year_days()` only then. A lost or escaped Winter 14 is not an ending; a Winter 14 lost after its boss fell is
- The morning report's ending branch (0138's screen, today's `_build_the_ending`): `YOU SURVIVED A YEAR` with what `Run.summary` already holds (days lived, nights won, bosses down, killed, structures lost, the build that won), then two choices
- Carry on: `Run.go_endless` (only once the year is beaten); the farmer wakes on Year 2 Spring 1 - 0154's calm night - and the nights keep coming through the lookup from today's Endless until 0279 makes later years heavier
- A new farm: the run is recorded (`Run.record`: `runs_won` counts the year; `best_night` keeps its meaning, any change to it is 0291's) and a new run starts, as `_record_and_restart` does today
- A credits roll before the choices (`src/ui/credits_roll.gd`): lines from `CRED_*` strings, skippable with confirm or cancel on keyboard, mouse and pad
- Strings in both languages replace the MVP's: `RES_NEW_FARM` (A NEW FARM / UMA FAZENDA NOVA), `RES_PLAY_ON` (CARRY ON INTO YEAR %d / SEGUIR PARA O ANO %d), `RES_RUN_LINE` without 'the Giant', `END_TITLE` (YOU SURVIVED A YEAR / VOCÊ SOBREVIVEU UM ANO); remove the rows nothing reads any more
- Keep the node names `ContinueButton` and `PlayOnButton`, and rewrite in place what reads the old ending as 0151 left it: input_check's `_case_0070_endless` (the credits now come first), `_task_0066_run_end`'s over/carry-on asserts and `_task_0070_endless`'s `go_endless` refusals, against the new `Run.is_over`
- Hashes: SIM must not move (the determinism run never reaches Winter 14) and DATA does not

  - done when: `_task_0160_year_end` in `src/tools/headless_v1.gd`, from a Winter 14 fixture (date 56, started through 0118's road, never by playing the year): boss down -> `Run.is_over` and the result says so; boss escaped -> not over, the date still 56; carried on -> not over, and the next night is date 57, Year 2 Spring 1, calm; `Run.record` counts the year in `runs_won`
  - done when: `_case_0160_ending` in `src/tools/input_v1.gd`: the ending shows, the credits skip by keyboard and by pad, CARRY ON returns to the farm on Year 2 Spring 1, and A NEW FARM starts day 1 of a new run
  - done when: A `year_end` shot scenario: `python tools/shot.py 0160 year_end --fhd` and with `--pt_BR`, opened - nothing overflows

### 0166 - A day of eight to ten minutes

Waits on 0165.  Likely files: `src/core/game_data.gd, src/core/phases.gd, src/tools/autoplay.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd, tools/balance.py, implementation/BALANCE.md`.

The day becomes eight to ten real minutes, so the 80x65 farm has time in it: crossing it already takes 28 seconds, and the plan's spring day (its appendix) does not fit in four minutes.

- `DAY_TICKS` spans 0126's 1200 game minutes (06:00-02:00) at a whole number of ticks per minute, which 0126's `validate()` rule demands: 12-15 a minute is 14400-18000 ticks, 8-10 real minutes (`# LEVER`). Recommended 14 (16800 ticks, 9 min 20 s) - nine minutes flat is 13.5 a minute and is refused. 0126 already derives `DUSK_AT_TICK` from `DUSK_MINUTE`: check it still lands on 18:00
- Re-express every per-tick producer against the longer day, with the arithmetic in the journal: `RECIPES` ticks (a kit still takes about a walk across the farm), `LIVESTOCK.every_ticks`, `GATHERING.regrow_ticks` (a node still gives about twice a day), the `FISHING` bite range, the generator's `fuel_every_ticks` and the `DAILY_STOCK` sizes. Nothing may double its daily output by accident
- Nothing in core or ui may hard-code a tick count for an hour of the clock: the bedtime reminders (0140) and pass-out (0128) read 0126's helpers, and so will 0190's stall hours - grep for `SECONDS` multiples compared with `day_tick`
- Re-time the suites: no headless group or input case may advance a whole day or a whole morning of ticks. Today's are `_task_0006_phases` and `_task_0021_night_intent` (to dusk), `_task_0030_fishing`, `_task_0031_iron` (`_mine_for_a_day`), `_task_0038_idle` (`_a_busy_day`), `_task_0039_clock`, `_task_0065_defeat`, `_task_0067_autoplay`, `_task_0068_balance`, `_case_0039_clock`, `_case_0091_title` and any v1 group that does (grep `DAY_TICKS`, `DUSK_AT_TICK`, `tick_at_minute`): give them a shorter road - a rigged `day_tick`, a direct morning call - and record each suite's time before and after
- `Autoplay._a_day` (as 0142 left it) spends the new day; 0142 already plays one day and one night per policy in `_task_0067`/`_task_0068`, so keep them inside the budget by an earlier policy bedtime in the suite or fewer policies there, never by shortening the lever. `tools/autoplay.py` and `tools/balance.py` still run
- A saved `day_tick` keeps its meaning (ticks since 06:00) and only reads earlier on the longer clock, and producer timers count down as before: no `State.VERSION` bump - say so in the journal
- DATA moves on purpose (time and producer levers). SIM moves on purpose too: the determinism scenario's kits, animals and clock run on the re-expressed levers. Record both, and add a BALANCE.md note on what one day yields now

  - done when: `_task_0166_long_day` in `src/tools/headless_v1.gd`: `DAY_TICKS` maps onto 06:00-02:00, dusk reads 18:00, and each producer's yield per day (computed from the tables, not simulated) is inside the range the journal claims
  - done when: headless_check, input_check and both v1 suites finish at least 20 s under `SCRIPT_TIMEOUT_S`, with the times in the journal
  - done when: A short `tools/autoplay.py` run plays a full day and night, and the journal records the money that day made

### 0167 - Any grass can be tilled

Waits on 0165.  Likely files: `src/core/farming.gd, src/core/interact.gd, src/core/game_data.gd, src/core/tutorial.gd, src/ui/world_view.gd, src/ui/placeholder_art.gd, src/tools/autoplay.gd, src/tools/determinism.gd, src/tools/make_goldens.gd, src/tools/perf_check.gd, src/tools/house_check.gd, src/tools/shot.gd, src/core/player.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd, implementation/backlog/packs/A014-crop-ground.md`.

Any grass can be tilled, as in Stardew, so the 60 beds become the starter garden rather than the whole of farming - and ground becomes a choice between field and fortress (plan section 5: space has two uses).

- `Interact._offered` sends GRASS as well as SOIL to `Farming.verb_at`, which offers `till` on bare grass and works on any plot whatever the ground under it. **The terrain byte never changes**: `world_view` draws terrain once, so tilled grass is a plot over grass, drawn by `_refresh_plots`
- Only bare grass and soil take the hoe; path, floor, water, rock and any occupied cell offer nothing. A lawn that offers `till` everywhere changes `Player.target`, whose fallback is the cell he stands on: standing on grass and facing nothing would till under his feet, and every press on open ground now does something. Decide (e.g. grass offers `till` only as the faced cell, never as the fallback), assert it, and grep the input cases that press interact on open grass
- Untended ground goes back: an empty tilled plot on grass left for `TILLED_GRASS_FADES_DAYS` mornings (`# LEVER`, 1-7) returns to grass in `Farming.morning`; soil beds never fade. The plot remembers the morning it was last worked (plots are `RUN_DATA`: read the new field with a default, reconcile never fills it)
- Path cost: decide whether tilled grass costs like SOIL in the flow field. Recommended: it keeps the grass cost, because a field that changed the route on every hoe stroke would call `Farm.touch` and rebuild every field (`path_refresh` ~7.9 ms). The journal says which and why
- Add `Farming.field_cells(state)` (soil beds plus tilled grass, index order) and move every user that means 'the field' off `Farm.cells_of(SOIL)`: `tutorial.gd` (three sites), `autoplay.gd`, `determinism.gd`, `make_goldens.gd`, `perf_check.gd`, `house_check.gd` and the headless/input helpers. With no grass tilled it returns exactly today's cells, so that alone moves no hash
- Edges of tilled grass: decide the scheme (N1/E2/S4/W8 masks like the barriers, or a plain border) and draw it through the placeholder road with today's `tilled`/`tilled_wet` sprites until A014 is integrated by 0197
- DATA moves (the lever goes into `digest()`, and `validate()` holds it to 1-7). SIM moves only if the scenario's soil plots change shape: write the new plot field only on tilled grass (soil beds never fade) and it stays - say which

  - done when: `_task_0167_till_grass` in `src/tools/headless_v1.gd` (mornings by `Farming.morning`, never a day of ticks): the hoe on grass makes a plot and leaves the terrain byte alone; an empty tilled grass plot is gone after the fade mornings and a planted one is not; a path cell refuses the hoe
  - done when: `_case_0167_till_grass` in `src/tools/input_v1.gd`: the farmer walks onto open grass, holds interact, and a plot appears
  - done when: A new `till_grass` scenario: `python tools/shot.py 0167 till_grass --fhd` shows tilled grass beside the beds by day and by night; opened and looked at
  - done when: the Deliverables table of `implementation/backlog/packs/A014-crop-ground.md` states the final geometry this task settled (edge masks, canvas, pivot), and the pack's text names 0171, not 0170, as the owner of the withered crop

### 0168 - Nine new crops

Waits on 0165.  Likely files: `src/core/game_data.gd, src/ui/names.gd, assets/locale/strings.csv, src/ui/day_hud.gd, src/ui/shop_panel.gd, src/ui/placeholder_art.gd, src/tools/shot.gd, src/tools/input_check.gd, src/tools/headless_v1.gd`.

The plan's twelve crops exist as data: potato, garlic, strawberry, pepper, sunflower, melon, pumpkin, grape and beet join carrot, corn and wheat, each with the role section 3.1 gives it.

- Data only: nine `CROPS` entries with `growth_days`, `seed_cost`, `yield` and `stages` from the plan's table (potato 5, garlic 4, strawberry 8, pepper 5, sunflower 7, melon 10, pumpkin 10, grape 8, beet 6 days), plus `RESOURCES`, `SELL_PRICE` and the existing `crops` group of `RESOURCE_GROUPS`, every number a `# LEVER`
- Seasons are 0170's and regrowth 0172's: add neither field here
- Ids are the plain crop names; the defences that share a crop word keep their own ids (`garlic_braid`, `catapult`, `decoy`)
- `Names.KEYS` and `ITEM_POTATO`..`ITEM_BEET` rows in `assets/locale/strings.csv` (key,width,en,pt_BR: batata, alho, morango, pimenta, girassol, melancia, abóbora, uva, beterraba); `tools/i18n_check.py` clean
- `check_crops` keeps 'no crop dominates on money, visits and seed cost at once' across all twelve: seed costs that rise with value per day are enough. Put the table in the journal; 0170 may narrow the comparison to one season
- Twelve rows overflow the `DayHud` seed strip and its six `SEED_ACTIONS`, and the stall's seed rows (`shop_panel.gd`, which `_case_0040_shop` reads one by one). Until 0170 filters them by season, keep both legible (page them, or six rows around the selection - view only) and capture them
- Every new crop draws through the placeholder road: a tinted stand-in of an existing crop's four stages at the final canvas (the art contract's 16x16, pivot (8,14); sunflower and the grape trellis very tall at 16x32, pivot (8,30)) until A015/A016/A017 are integrated by 0198/0199/0200
- DATA moves (the tables). SIM moves on purpose: nine new keys in `held`/`gained`, which `State.hash_of` folds, and the determinism scenario sows `Farming.seeds()` in sorted order, so its field changes. Record both

  - done when: `_task_0168_crops` in `src/tools/headless_v1.gd`: all twelve validate, each has a price, a group and a name in both languages, and each reaches its ready stage in its plan days of watered mornings
  - done when: A new `twelve_crops` scenario: `python tools/shot.py 0168 twelve_crops --fhd` shows every crop at its four stages; opened and looked at
  - done when: the Deliverables tables of `implementation/backlog/packs/A015-spring-crops.md`, `A016-summer-crops.md` and `A017-autumn-crops.md` state the final geometry this task settled (canvas, pivot, stages, which crops are tall)

### 0178 - Sprinklers

Waits on 0176, 0165.  Likely files: `src/core/game_data.gd, src/core/farming.gd, src/core/phases.gd, src/core/pathing.gd, src/core/building.gd, src/ui/names.gd, src/ui/particles.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Sprinklers automate the chore: copper, iron and gold ones water the plots around them every morning, so a big field stops costing the whole morning.

- Three tiers (copper, iron, gold) as `BUILDINGS` entries or one id with levels - decide - with costs in their metal plus money, hp and a 1x1 size, built by day like every production building; recipes or a direct cost, with `check_recipes` and `check_buildings` still honest
- Each morning, after 0165's growth credit, every sprinkler marks the plots of its pattern watered for the new day (four neighbours, 3x3, 5x5 - `# LEVER`), in sorted cell order; they dry at night like any other plot
- **Never a wall.** `Pathing._through` makes anything without a `path_cost` impassable, so a row of sprinklers would fence the farm. Make them walkable for the flow field like a trap (a declared flag `_through` reads) and not prey - `is_prey` counts any `BUILDINGS` entry with no `path_cost` today, so it reads the same flag - and say whether the farmer walks over them
- A cell with a sprinkler is not a plot: tilling and planting skip it, and a sprinkler cannot go on a planted plot
- The spray is code particles (view only); the body draws through the placeholder road until A018 is integrated by 0201
- `BLD_*`/`REC_*` names and strings in both languages. DATA moves; SIM moves if the state's shape changes (a new station in `selected_recipe`) or the scenario places one - say which

  - done when: `_task_0178_sprinklers` in `src/tools/headless_v1.gd`: a copper sprinkler waters its four neighbours on a morning and they grow the next; the flow field crosses its cell at ground cost; a breaker does not hunt it
  - done when: `_case_0178_sprinkler` in `src/tools/input_v1.gd`: place one by day from the build list
  - done when: A new `sprinklers` scenario: `python tools/shot.py 0178 sprinklers --fhd` shows the three tiers spraying; opened and looked at
  - done when: the Deliverables table of `implementation/backlog/packs/A018-sprinklers.md` states the final geometry this task settled

### 0179 - Fish by pond, season and hour

Waits on 0126, 0149, 0156, 0165.  Likely files: `src/core/fishing.gd, src/core/game_data.gd, src/core/crafting.gd, src/app/save.gd, src/core/state.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/make_goldens.gd, tools/goldens/, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd`.

The one pond becomes three with about twelve species, each with its place, season, hours and rarity, so fishing asks where and when as well as whether (plan section 3.2).

- `FISH_SPECIES` in `game_data.gd`: about twelve species (carp, perch, catfish, tilapia; trout, pike, eel; dorado, salmon, sturgeon; two more to fill the seasons) with ponds (the ids of 0156's `PONDS` table, found from a cell by `Farm.pond_of`; use 0156's names, not the plan's), seasons, hours (0126's `Phases.clock_minute`), a rarity weight and a value, all `# LEVER`, in `digest()`. Legendaries are 0182's
- `Fishing.begin` draws the species at the cast from the run RNG, among those the pond, the season and the hour allow, weighted by rarity; the bite-delay draw stays. `Fishing.reel` gives that species and `last_catch` names it. SIM moves on purpose (the draw, the new resources, the version) and DATA moves (`FISH_SPECIES`, `FISHING`, the recipes): record both
- Each species is a resource: `RESOURCES`, `SELL_PRICE`, a fish group, `Names.KEYS`, `ITEM_*` rows in both languages
- **Recipes that took `fish` accept any species**, as a rule: a recipe input may name the fish group, and `Crafting` pays it from the species held in a fixed order (cheapest first, then by name). `check_recipes`, `check_chain` (value it at the cheapest member) and `Crafting.missing` understand it; `press_fish_oil` and `cook_fish` use it
- The old `fish` resource goes: bump `State.VERSION` by one (8, after 0165's 7) with a migration that moves `fish` in `held` (and `gained`) into the commonest species, plus a golden at the new version - reconcile alone would drop it. Every other reader follows (`GameData.FISH` - a dozen uses in `headless_check.gd` and four in `input_check.gd`, e.g. the press and kitchen groups -, `SELL_PRICE`, the larder group, `Names.KEYS`/`ITEM_FISH` - `tools/i18n_check.py` flags an unused key); the `fish` verb keeps its id
- `FISHING.common_yield`/`rare_yield` give way to the table; `check_fishing` is rewritten: every species names real ponds, seasons and hours, and every pond has a catch in every season at every hour of the day
- Rewrite `_task_0030_fishing` and `_case_0030_fishing` (the triple 'rare' fish is gone)
- Icons draw as tinted `icon_fish` stand-ins through the placeholder road until A022 is integrated by 0205

  - done when: `_task_0179_species` in `src/tools/headless_v1.gd`: the same seed casts the same species; a summer species never bites in spring; two of 0156's ponds yield different sets; `cook_fish` takes the cheapest species held
  - done when: A migrated golden's old fish arrive as the commonest species, asserted
  - done when: the Deliverables table of `implementation/backlog/packs/A022-fish-icons.md` states the final species list and sizes this task settled

### 0186 - Barns at night

Waits on 0183, 0137.  Likely files: `src/core/farm.gd, src/core/livestock.gd, src/core/repair.gd, src/core/pathing.gd, src/core/run.gd, src/core/crafting.gd, src/core/interact.gd, src/core/game_data.gd, src/ui/world_view.gd, src/ui/placeholder_art.gd, src/tools/shot.gd, src/tools/headless_v1.gd`.

At night the animals sleep inside and the barn becomes something to defend: breakers go for it, and a wrecked barn stands useless until it is mended. No animal ever dies.

- Animals sleep in their building at night (the view hides them; livestock already ticks only by day)
- Breakers hunt coops and barns: `Pathing.is_prey` counts a `BUILDINGS` entry with no `path_cost` already - assert it
- A wrecked-but-standing state: an entry that declares it (e.g. `wrecks: true` on coop and barn) is not removed by `Farm.damage` at 0 HP; it stays an occupant marked wrecked, still impassable, no longer prey (`Pathing.prey_cells` already skips 0 HP), with no rubble; decide whether `Run.lost_a_structure` counts it and assert that. The hunt field is cached on `grid_version` and only `Farm.remove` bumps it today: wrecking (and mending back above 0) must `Farm.touch`, or breakers stand at a 0-HP barn all night - the bug `prey_cells`' own comment records
- A wrecked building produces nothing and offers only `repair` (by day, by the farmer, as 0134 left it); any HP above 0 brings it back; its animals stay inside, alive, throughout
- `Crafting.forget_cell` and `Livestock`'s cache must not forget a wrecked building's residents or queue
- Hurt and wrecked looks are tints of the stand-in through the placeholder road until A030 is integrated by 0212
- DATA moves (the new flag); SIM moves only if the scenario has a barn at night - say so

  - done when: `_task_0186_barns_night` in `src/tools/headless_v1.gd` (a short night with breakers set down beside the barn, mornings by `Phases.begin_day`): breakers reach a barn and wreck it, then leave it for other prey; it stands, produces nothing the next day, keeps every animal, and works again after a day repair
  - done when: A new `barn_night` scenario: `python tools/shot.py 0186 barn_night --fhd` shows a hurt and a wrecked barn at night and the next morning; opened and looked at

### 0204 - Art: copper, coal, gold and hardwood

Waits on 0176, 0177.  Likely files: `assets/art_source/props/, assets/art_source/manifest.json, tools/check_prop_art.py, src/ui/world_view.gd, src/ui/art_placement.gd`.

The new quarry nodes and the big hardwood stumps get their approved art in the world.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A021` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A021-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/props/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_prop_art.NAMES`; `ArtPlacement` if the 2x2 stump needs it).
- Runtime names: copper, coal and gold nodes at 16x16, pivot (8,14), each with a `_b` variant through `WorldView.PROP_VARIANTS`/`_prop_variant` like `ore`/`ore_b`; the 2x2 stump whole and chipped at the 32x32 canvas and pivot 0177 settled, placed at the bottom centre of its footprint
- Replace the stand-ins of 0176 and 0177 and flip A021's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A021 integrated`.

  - done when: `python tools/check_prop_art.py` and `python tools/show_art.py --props --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0204/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0215 - Art: the shipping bin

Waits on 0189.  Likely files: `assets/art_source/props/, assets/art_source/manifest.json, tools/check_prop_art.py`.

The shipping bin of 0189 gets its approved art, lid and all.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A033` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A033-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/props/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_prop_art.NAMES`).
- Runtime names: the closed bin and its lid-opening strip (2-3 frames, one-shot) at the canvas and pivot 0189 settled; the view plays the lid when the bin's panel opens (view only)
- Replace 0189's stand-in and flip A033's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A033 integrated`.

  - done when: `python tools/check_prop_art.py` and `python tools/show_art.py --props --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0215/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0161 - Art: seasons and moons

Waits on 0158.  Likely files: `assets/art_source/ui/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_ui_art.py, src/ui/raster_art.gd (generated), src/ui/placeholder_art.gd, src/ui/forecast_panel.gd`.

The approved season, moon, boss-night and calm-night icons take the place of the forecast's code-drawn marks.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A010` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A010-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_ui_art.py`, `ArtPlacement` if needed).
- Runtime names: `ui/icon_<id>` 16x16 pivot (8,8) and `ui/hud_<id>` 10x10 pivot (5,5) for `spring`, `summer`, `autumn`, `winter`, `full_moon`, `boss_night` and `calm_night`, both cut from one source crop like the resource icons, binary alpha, no text. `tools/check_ui_art.py` is hard-coded to the fifteen resource icons of task 0018: give it a calendar family with the same clipping and size rules
- Replace 0158's code-drawn marks in the forecast panel by deleting their entries from `src/ui/placeholder_art.gd`; `python tools/placeholders.py` no longer lists A010
- Set the pack to integrated: `python implementation/backlog/assets.py set A010 integrated`.

  - done when: `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass, and `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the icons in the real game - `python tools/shot.py 0161 forecast_dusk forecast_build --fhd` - in `implementation/shots/0161/`, opened and looked at
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0162 - Art: forecast heads

Waits on 0158.  Likely files: `assets/art_source/ui/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_ui_art.py, src/ui/raster_art.gd (generated), src/ui/placeholder_art.gd, src/ui/forecast_panel.gd`.

The forecast names what is coming with the enemies' own faces: the approved heads of the walker, runner, tank, breaker and Giant replace the cropped walk frames.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A011` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A011-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_ui_art.py`, `ArtPlacement` if needed).
- Runtime names: `ui/head_<kind>` 16x16, pivot (8,8), for `walker`, `runner`, `tank`, `breaker` and `giant`, binary alpha, matching each enemy's sprite. `tools/check_ui_art.py` gains a heads family that requires a head for each of these five; later enemies bring theirs in their own packs and add themselves to the list
- Replace 0158's cropped walk-frame heads by deleting their entries from `src/ui/placeholder_art.gd`; the panel asks for `ui/head_<kind>` and nothing else changes; `python tools/placeholders.py` no longer lists A011
- Set the pack to integrated: `python implementation/backlog/assets.py set A011 integrated`.

  - done when: `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass, and `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the heads in the real game - `python tools/shot.py 0162 forecast_dusk forecast_build --fhd`, with the scenarios moved to a date whose forecast lists all five kinds (Spring 14 does while it is Endless-generated with the Giant's row; check it on the day) - in `implementation/shots/0162/`, opened and looked at
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0169 - An inventory for many things

Waits on 0168.  Likely files: `src/ui/inventory_panel.gd, src/core/inventory.gd, src/core/game_data.gd, src/ui/day_hud.gd, src/ui/names.gd, src/app/input_actions.gd, project.godot, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Task 0036's inventory was a list for fifteen things and 1.0 has about seventy. Groups become pages a player flips with a key, a click or the pad, and the HUD's six numbers become a choice.

- `RESOURCE_GROUPS` grows to the categories of plan section 8 (materials, crops, seeds, fish, animal goods, artisan goods, ammunition, night leftovers, the farm). A group may be declared before its members exist; an empty group is not drawn
- `inventory_panel.gd` shows one group per page with tabs (keyboard, mouse and pad through `InputActions`: a new page action goes into `InputActions.ACTIONS` and `project.godot` with a pad binding and its `ACT_*` row, or reuse an existing one - say which), amount and sale price per row, and fits 480x270 with seventy items in all; `ROW_HEIGHT` decides how many rows a page holds. Each tab is named by a literal key (`INV_GROUP_*` rows, en and pt_BR, looked up through a literal table so `tools/i18n_check.py` sees them). `_case_0036_inventory` expects every resource's `inv_<id>` row on screen at once and `_task_0036_inventory` the reference sheet's groups: rewrite both in place for pages
- `DayHud.SHOWN` stays six numbers in two rows; which six is a decision written in the journal (wood, stone, iron and food, plus the two that matter most in 1.0). The bar never grows
- **From here on a resource is not done until it is complete**: `GameData.validate()` (an extended `check_groups` or a new check) refuses a `RESOURCES` id with no `SELL_PRICE` (money, energy and tech excepted) or no group (nothing new may fall into `GROUP_OTHER`), and headless asserts each id has a `Names.KEYS` entry and an `ITEM_*` row in both languages. Every later task that adds a resource adds all four
- An item with no `ui/icon_<id>` draws a placeholder through the placeholder road (0120), so no row is ever blank
- View only: SIM unchanged; DATA moves for the groups table

  - done when: `_task_0169_inventory` in `src/tools/headless_v1.gd`: the new check fails by name on a rigged table with an unpriced and with an ungrouped resource; every real resource has a price, a group, a `Names.KEYS` entry and an `ITEM_*` row in both languages
  - done when: `_case_0169_inventory` in `src/tools/input_v1.gd`: open the inventory, flip every page with the keyboard, the mouse and a synthetic pad event, close it
  - done when: A new `inventory_full` scenario (every item held): `python tools/shot.py 0169 inventory_full --fhd` shows each page with no labels on top of each other; opened and looked at

### 0172 - Crops that grow back

Waits on 0168.  Likely files: `src/core/farming.gd, src/core/game_data.gd, src/ui/world_view.gd, src/ui/placeholder_art.gd, src/tools/shot.gd, src/tools/headless_v1.gd`.

Strawberry, corn, pepper and grape grow back after picking, so planting them early in their season is a choice that pays all season long.

- `CROPS` gains `regrow_days` (`# LEVER`) for strawberry 4, corn 4, pepper 3 and grape 3 (plan section 3.1)
- `Farming._harvest` on a regrowing crop leaves the plant in a regrowing state, `regrow_days` short of ready, instead of an empty plot; watering and the morning credit work as for any crop, and the hoe clears it
- `Farming.stage()` reports a distinct regrowing stage the view draws as `<crop>_regrow`; until A015/A016/A017 are integrated by 0198/0199/0200 it is the stage-2 sprite tinted, through the placeholder road
- `value_per_day` and `check_crops` count regrowth: harvests in a season are one plus the whole regrowths left in it. Put the table in the journal so the four do not dominate the rest
- The season-change withering of 0171 takes regrowing plants too; if 0171 has landed, assert it
- The new plot field is read with a default (plots are `RUN_DATA`); if it changes what a saved `growth` means, bump `State.VERSION` and migrate
- DATA moves; SIM only if the scenario harvests a regrowing crop

  - done when: `_task_0172_regrow` in `src/tools/headless_v1.gd` (mornings by `Phases.begin_day`): a strawberry harvested when ready is ready again `regrow_days` watered mornings later without replanting; a carrot leaves an empty plot
  - done when: A new `regrowing` scenario: `python tools/shot.py 0172 regrowing --fhd` shows a regrowing strawberry beside a ripe one; opened and looked at

### 0174 - The can and the hoe by tier

Waits on 0173, 0167.  Likely files: `src/core/farming.gd, src/core/player.gd, src/core/game_data.gd, src/ui/day_hud.gd, src/ui/world_view.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

The can and the hoe earn their tiers: one tile, then three, then five at a stroke, which turns watering a big field from a chore into a walk.

- The can's and the hoe's tiers carry an area (`# LEVER`: 1, 3 and 5 tiles, plan section 3.7): the faced tile and the ones beside it across the facing. Pick the shape, draw it, write it down
- `Farming._water` and `Player._do_instant` water every tile of the area that offers `water`, one unit of the can per tile, in a fixed order; a can short of water waters what it holds
- A better hoe tills the area through `Farming._till` in one action of the hoe's time, skipping cells 0167 refuses
- Decide whether the can's tier also raises its capacity (a per-tier `# LEVER` added in `Farming.can_capacity`), and fix the known bug: `day_hud.gd` prints the can against `GameData.WATER_CAN_CAPACITY` instead of `Farming.can_capacity(state)`, so 'full cans' never showed
- The highlight shows every cell the next press will touch (view only, `world_view.gd`)
- DATA moves; SIM moves only if the scenario uses an upgraded tool (it should not)

  - done when: `_task_0174_area` in `src/tools/headless_v1.gd`: an iron can waters three dry plots in one press and spends three; a gold hoe (its tier written into the state - gold cannot be ordered before 0176) tills five grass cells and skips a path cell among them; the HUD's capacity equals `Farming.can_capacity` with 'full cans' bought
  - done when: `_case_0174_area` in `src/tools/input_v1.gd`: holding interact along a row with an iron can waters it in a third of the steps
  - done when: A new `can_area` scenario: `python tools/shot.py 0174 can_area --fhd` shows the area highlight; opened and looked at

### 0180 - The fishing minigame

Waits on 0179, 0121, 0173.  Likely files: `src/core/fishing.gd, src/core/game_data.gd, src/core/sim.gd, src/ui/fishing_bar.gd (new), src/ui/main.gd, src/app/input_actions.gd, src/app/settings.gd, project.godot, src/ui/player_work.gd, src/ui/sfx.gd, src/tools/perf_names.gd, src/tools/perf_check.gd, src/tools/determinism.gd, src/tools/autoplay.gd, src/tools/art_showcase.gd, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

A bite opens a simple timing bar: a marker runs, and you press as it crosses the green - simpler than Stardew's bar and as good on a pad as on a mouse.

- In core, after the bite the line enters a bar stage: the marker is a pure function of the ticks since the bite (a triangle sweep, speed per species); the zone's place comes from the cast's draw and its width from the species and the rod tier (`# LEVER`s in `FISH_SPECIES` and `TOOLS`, which `check_fishing` bounds). No RNG after the cast
- Presses are intents (the `interact` edge or a dedicated one), judged against the marker on the tick they are consumed; 1-3 hits by species land the fish; misses allowed and how long the bar runs are `# LEVER`s, and running out loses the fish and nothing else
- If the bar adds or retires a verb, `_task_0084_day_sounds` still passes: every `Interact.DAY_ONLY` verb keeps an `Sfx.VERB_SOUNDS` entry (borrow `sfx/reel` until 0282 gives the bar its sounds) and `water` stays the only instant verb. A new `X.tick(state)` call in `sim.gd` joins `PerfNames.DAY` and `perf_check.gd`
- Keyboard, mouse and pad write the same intent: a new action in `InputActions.ACTIONS` and `project.godot` with a pad binding, kept in sync by the existing check
- An assist (wider zone, slower marker) is a rule, so it lives in the state: a run flag written through an intent from a Settings key, never read by core from `Settings` (a top-level key, or a field of a dictionary listed in `State.TABLES` - say which). The Options row is 0292's
- The view draws the bar, marker, zone and hit/miss flash through the placeholder road until A023 is integrated by 0206, and the farmer on today's `fish`/`reel` strips until A024 is integrated by 0207
- Settle the art: the bar's piece sizes into A023, and the farmer's poses and timings (cast, wait, strike, reel loop, show the catch) into A024
- SIM moves on purpose and DATA moves (the bar levers): record both. Rewrite whatever still reels in one press: what is left of `_task_0030_fishing`/`_case_0030_fishing`, the determinism scenario's cast, the autoplayer's fishing and the showcases that cast and reel (`art_showcase.gd`, `effect_showcase.gd` - `show_art.py --check` runs in verify)

  - done when: `_task_0180_minigame` in `src/tools/headless_v1.gd`: a press on a tick inside the zone counts and one tick outside does not; a three-hit species needs three; the assist widens the zone; a replay with the same presses lands the same fish
  - done when: `_case_0180_minigame` in `src/tools/input_v1.gd`: land a fish with the keyboard, with the mouse and with a synthetic pad button
  - done when: A new `fishing_bar` scenario: `python tools/shot.py 0180 fishing_bar --fhd` shows the bar mid-catch; opened and looked at
  - done when: the Deliverables table of `implementation/backlog/packs/A023-fishing-gear.md` states the final geometry this task settled, and so does `A024-farmer-fishing.md` for the poses and timings - that pack file does not exist yet: if it is still missing, write the settled poses into the journal under an `A024` heading for its author, create no pack, and say so

### 0181 - Rods and bait

Waits on 0179, 0173, 0167.  Likely files: `src/core/fishing.gd, src/core/farming.gd, src/core/game_data.gd, src/ui/day_hud.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

The rod's tiers change what bites: fibre brings bites sooner and rare fish more often, iron adds a bait slot and is the only rod a legendary takes.

- Rod effects read from `TOOLS` (`# LEVER`s): the fibre rod shortens the bite range and raises rare weights; the iron rod opens a bait slot and is the gate 0182 checks
- Worms: tilling (`Farming._till`) finds a `WORM` one time in `WORM_IN` (`# LEVER`, in `digest()`), drawn from the run RNG - SIM moves on purpose (the determinism scenario tills) and the journal records it
- A fish-scrap bait recipe (a `RECIPES` entry, so a `Names.KEYS` entry and a `REC_*` row): a common fish into several `BAIT` at the workshop or the kitchen - decide. Bait has a sale price like every resource since 0169, and the recipe passes `check_chain`
- With the iron rod, a held bait is spent at the cast and shortens the wait or raises rarity (`# LEVER`s); which bait is on is a choice the HUD shows, kept in the state (say where; a nested dictionary goes in `State.TABLES`); no bait means no effect, not a refusal
- `WORM` and `BAIT` with prices, a group, names and strings in both languages. Zombie bait is 0225's, not here
- Icons through the placeholder road until A023 is integrated by 0206. DATA moves (`WORM_IN`, the rod levers, the recipe) and SIM moves on purpose (the worm draw, the bait choice): record both

  - done when: `_task_0181_rods` in `src/tools/headless_v1.gd`: on a fixed seed the fibre rod's mean wait is shorter than bamboo's by what the levers say; bait is spent at an iron-rod cast and not at a bamboo one; tilling finds worms at the rate claimed
  - done when: `_case_0181_bait` in `src/tools/input_v1.gd`: choose a bait and cast with it

### 0184 - Feeding, eggs and milk

Waits on 0183, 0168.  Likely files: `src/core/livestock.gd, src/core/farming.gd, src/core/phases.gd, src/core/game_data.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd`.

Animals are fed and give what they are kept for: chickens lay eggs, cows give milk, and both eat hay made from the wheat's straw - one more use for wheat.

- Harvesting wheat also gives `STRAW` (`# LEVER` per harvest); a recipe at a station you choose turns straw into `HAY`, the feed (both exist: the plan makes hay from straw, and straw is also 0224's decoy material). The peddler's hay outside autumn is 0193's
- A daily feed debit at `Phases.begin_day`: each housed animal eats `feed_per_day` hay (`# LEVER`); one not fed gives nothing that day, and never dies or sickens. Decide and assert what day 1 (no `begin_day` before it) and the map's loose animals (no coop or barn yet) count as - 'unfed' would silence `_task_0034_cooking`, `_case_0034_livestock`, `_task_0038_idle` ('the animals produced', `_a_busy_day`) and the determinism scenario's animals; rewrite in place what the decision and the new products break
- Products: chickens give `EGG`, cows give `MILK` (`LIVESTOCK.produces`, the rate and `holds` as `# LEVER`s)
- Decide what happens to `MEAT` and write it in the journal: keep the resource and `cook_roast`, and say how meat is still had (the stall stocks it, an animal gives it now and then...). `check_livestock`'s 'nothing produces meat' rule follows the decision. A saved animal's waiting produce is a count and comes out as the new product: say so (no version bump)
- `STRAW`, `HAY`, `EGG` and `MILK` with prices, groups, names and strings in both languages, and a `Names.KEYS` entry with a `REC_*` row for each new recipe; recipes that took meat adjusted so `check_chain` passes
- Icons through the placeholder road until A029 (0211) and, for hay and straw, A020 (0203) are integrated
- SIM moves (four new resources in `held`/`gained`, and the scenario's animals produce differently); DATA moves

  - done when: `_task_0184_feed` in `src/tools/headless_v1.gd` (mornings by `Phases.begin_day`, produce by advancing `every_ticks`, never a whole day of ticks): a fed coop gives eggs the next day, an unfed one gives none and every chicken is still there; a wheat harvest gives the straw the lever says
  - done when: The journal states the meat decision and `check_livestock` enforces it (a rigged table without a meat source fails)

### 0201 - Art: sprinklers

Waits on 0178.  Likely files: `assets/art_source/props/, assets/art_source/ui/, assets/art_source/manifest.json, tools/check_prop_art.py, tools/check_ui_art.py`.

The copper, iron and gold sprinklers of 0178 get their approved bodies and icons; the spray stays code particles.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A018` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A018-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/props` and `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_prop_art.NAMES`, `tools/check_ui_art.py`).
- Runtime names for each tier's idle and spray-body frames at the 16x16 canvas and pivot 0178 settled, and an icon (16x16 + 10x10) per tier for the build list
- Replace 0178's stand-ins and flip A018's placeholder-registry entries to raster; the particle spray is unchanged
- Set the pack to integrated: `python implementation/backlog/assets.py set A018 integrated`.

  - done when: `python tools/check_prop_art.py`, `python tools/check_ui_art.py`, `python tools/show_art.py --props --check` and `--ui --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0201/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0212 - Art: the coop and the barn

Waits on 0186.  Likely files: `assets/art_source/buildings/, assets/art_source/manifest.json, tools/check_station_art.py, src/ui/art_placement.gd`.

The coop and the barn get their approved art - whole, hurt and wrecked-but-standing - in place of 0183's stand-ins.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A030` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A030-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/buildings/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_station_art.FAMILY` or a buildings checker wired into `tools/verify.py`).
- Runtime names: `<id>`, `<id>_hurt` and the wrecked state 0186 added, at the footprints 0183 settled, with door/window light points on opaque pixels; full density - they do **not** join `ArtPlacement.visual_scale`'s 2.0 list
- Replace the stand-ins of 0183 and 0186 and flip A030's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A030 integrated`.

  - done when: `python tools/check_station_art.py` and `python tools/show_art.py --stations --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0212/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0170 - Crops keep to their seasons

Waits on 0168, 0149, 0169.  Likely files: `src/core/game_data.gd, src/core/farming.gd, src/core/shop.gd, src/ui/day_hud.gd, src/ui/shop_panel.gd, src/ui/describe.gd, src/ui/title_screen.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/autoplay.gd, src/tools/determinism.gd, src/tools/make_goldens.gd, src/tools/perf_check.gd, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Each crop keeps to its season, so spring, summer and autumn fields look and pay differently, and seeds become packets bought at the stall (plan sections 3.1 and 3.6). Which packets the stall puts out in which season is 0190's, with the peddler.

- `CROPS` gains `seasons` (`# LEVER`): carrot, potato, garlic, strawberry in spring; corn, pepper, sunflower, melon in summer; wheat, pumpkin, grape, beet in autumn. No crop lists winter. The season is `GameData.SEASONS[Calendar.season_of(Calendar.date(state))]` (0149; `season_of` returns 0-3). `check_crops` refuses a crop with no season, an unknown one or winter, and may narrow 'no crop dominates' to crops sharing a season (0168 left it open) - say which. What a change of season does to a planted field, winter included, is 0171's
- Seeds become items, as the plan's stall and the seed packets of A015-A017 expect: a `<crop>_seed` resource per crop with a price, the seeds group, a `Names.KEYS` entry and an `ITEM_<CROP>_SEED` row in both languages (0169's check wants all four). `Farming._plant` spends one packet of the selected crop instead of `seed_cost` in money (its own comment names it as the one function this changes); `selected_seed` still holds a crop id; `STARTING_RESOURCES` gives a few spring packets so day 1 still plants. An old save holds no packets and buys them: no `State.VERSION` bump - say so
- The price: `Shop.buy_price` is `ceil(SELL_PRICE * BUY_MARKUP)`, so a packet costs either `seed_cost` through a branch there or a packet `SELL_PRICE` the markup turns into about the seed cost - decide. `check_crops` balances on what a packet really costs, and `check_stall`'s buy-and-sell-back loss still holds
- The stall sells every packet all year for now: they join today's flat `DAILY_STOCK`, so `Shop.buyable()` lists them and the buy rows show them with no new UI; the `SHOP_SEEDS` rows of `shop_panel.gd` stop meaning 'pay at the furrow' (fold them into the buy rows or keep them as the seed picker - say which). **Moved to 0190:** the seasonal stock (this season's packets only, none in winter), because 0190 reworks `Shop.buyable`/`restock` for the peddler anyway
- Only in-season crops can be chosen: a `Farming.in_season(state)` list feeds the seed strip (with the packets held), `select_seed_at` and the six `SEED_ACTIONS`; `select_seed` refuses an off-season crop. `Farming.initial()` picks `seeds()[0]`, which after 0168 is `beet` (autumn): a new game selects the first spring crop, and a selection that falls out of season moves to the first in-season crop (none in winter). Packet icons draw through the placeholder road (the crop's icon, tinted) until A015/A016/A017 are integrated by 0198/0199/0200
- Move what plants (grep `Farming.act`, `select_seed`, `Farming.seeds()` and `seed_cost` in the suites and tools): wheat and corn sown on day 1 - Spring 1 - are now refused (`_task_0018_wheat`, `_task_0028_crops`, `_task_0029_watering`, `_case_0028_seeds`); fields sown round-robin over every crop run out of season and of packets (`_a_busy_day`, `_a_full_farm`, `_task_0109_reactions`, `_task_0111_house`, `determinism.gd`, `make_goldens.gd`, `perf_check.gd`, `shot.gd`, `title_screen.gd`'s backdrop); the autoplayer plants corn and must buy packets. Give the suites one shared helper (in the helper script 0112 made) that sets a date in a crop's season and hands over packets, and route them through it; `_case_0040_shop`'s seed rows follow the stall's change
- Correct `TUT_PLANT`, `DESC_SEED_COST` (`describe.gd`) and any line that says seeds are paid at the furrow, in both languages
- SIM and DATA move on purpose (twelve packet resources in `held`/`gained`, the starting packets, the planting rule); record both

  - done when: `_task_0170_seasons` in `src/tools/headless_v1.gd`: planting spends one packet and no money, and with no packet plants nothing; an off-season crop can be neither selected nor planted, and a summer date offers only summer crops; a new game selects a spring crop; the stall sells a carrot packet at the price the journal states
  - done when: `_case_0170_seeds` in `src/tools/input_v1.gd`: buy potato packets at the stall, pick them on a slot key, plant one
  - done when: New `spring_field` and `summer_field` scenarios: `python tools/shot.py 0170 spring_field summer_field --fhd`; opened and looked at

### 0182 - Legendary fish and the fish book

Waits on 0181.  Likely files: `src/core/fishing.gd, src/core/game_data.gd, src/core/stats.gd, src/core/state.gd, src/ui/fish_book.gd (new), src/ui/inventory_panel.gd, src/ui/names.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Four legendary fish, one a season, each with its own conditions, and a fish book with a page per species - the first collection that makes a player come back.

- Four legendaries in `FISH_SPECIES` - the Old Catfish, the Golden Queen, the Ghost Pike and the Ice Sturgeon (ids `old_catfish`, `golden_queen`, `ghost_pike`, `ice_sturgeon`, as A022 names them), one per season - each with a pond, hours and a condition (`# LEVER`s, bounded by `check_fishing`), catchable only on the iron rod and with the hardest bar of 0180
- Decide whether a legendary can be caught once per run; if so the draw skips it once the book has it
- The book: a `fish_book` dictionary in the state (keys come from play: `State.RUN_DATA`), species -> times caught and the first day; folded into the profile through `Stats` so it outlives the run
- A book view (an inventory tab or its own panel) with a page per species, unknown ones as silhouettes with a hint, and a collection count (n of every species, legendaries included); portraits through the placeholder road until A022's are integrated by 0205, the tab icon until A023's by 0206
- Names and strings for the legendaries and the book in both languages; every hint fits its control (`tools/i18n_check.py`)
- SIM moves (new draws, four new resources and the `fish_book` key); DATA moves

  - done when: `_task_0182_legendary` in `src/tools/headless_v1.gd`: the spring legendary never bites on the bamboo or fibre rod and does under its conditions on the iron rod; a catch writes the book and the profile
  - done when: `_case_0182_book` in `src/tools/input_v1.gd`: open the book and turn pages with the keyboard, the mouse and the pad
  - done when: A new `fish_book` scenario: `python tools/shot.py 0182 fish_book --fhd` shows a page and the count; opened and looked at

### 0185 - Sheep, pigs and the dog

Waits on 0184.  Likely files: `src/core/livestock.gd, src/core/game_data.gd, src/core/interact.gd, src/core/phases.gd, src/core/state.gd, src/ui/animal_view.gd (new), src/ui/world_view.gd, src/ui/transition.gd, src/ui/sfx.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

The barn fills out: sheep give wool, pigs dig truffles, and a dog follows the farmer by day - the farm feels alive between the chores.

- Sheep live in the barn, eat hay and give `WOOL` (`# LEVER`s)
- Pigs find truffles: each morning a housed pig marks dig spots on open grass near its barn (a `RUN_DATA` cell -> item record, deterministic - run RNG or a `(seed, day)` stream, decide; SIM moves); the farmer collects `TRUFFLE` by day with a verb in `Interact`; a spot never sits on a plot, a path or an occupied cell, and is gone at night. A spot is on open grass, where 0167 offers `till`: the spot's verb wins there. A new verb goes in `DAY_ONLY`, `all_verbs` and an `Interact.complete` arm with an `Sfx.VERB_SOUNDS` entry (borrow `sfx/collect` until 0281), or `_task_0084_day_sounds` fails
- The dog is a pet from day 1 that follows the farmer by day and sleeps by the porch at night. **View only**: no state key, no occupant, nothing in `src/core/`, so the hash cannot see it; petting it is a view-only gesture (a heart). Its night power is 0233's
- View-only wander, eat and sleep states for every animal (cow, chicken, sheep, pig, dog) near its building, in `src/ui/animal_view.gd`, never touching the state; at night `transition.gd`'s `DAY_ONLY` (today cow and chicken: add sheep and pig) hides them as it does today
- `WOOL` and `TRUFFLE` with prices, groups, names and strings in both languages; `check_livestock` covers sheep and pig. SIM moves on purpose (new resources, the dig-spot key); DATA moves
- Stand-ins through the placeholder road (tinted cow/chicken for sheep and pig, a small one for the dog, tinted icons and a code-drawn dig spot) until A026 (0209), A027 (0210), A028 (0245), the tend pose A025 (0208) and the icons and dig spot of A029 (0211) are integrated
- Settle the art: scales against the 32px farmer, states and frame counts into A025, A026 and A027

  - done when: `_task_0185_animals` in `src/tools/headless_v1.gd` (mornings by `Phases.begin_day`, never a whole day of ticks): a sheep gives wool; a pig's dig spot can be collected and is never on a plot or a path; a text scan finds no dog in `src/core/`, so the hash cannot depend on it
  - done when: `_case_0185_truffle` in `src/tools/input_v1.gd`: walk to a dig spot and collect a truffle
  - done when: A new `barnyard` scenario: `python tools/shot.py 0185 barnyard --fhd` shows the barnyard with every animal and the dog following; opened and looked at
  - done when: the Deliverables tables of `implementation/backlog/packs/A026-farm-animals.md` and `A027-cow-chicken.md` state the scales, states and frames this task settled, and so does `A025-farmer-care.md` for the tend and pet poses - that pack file does not exist yet: if it is still missing, write the settled poses into the journal under an `A025` heading for its author, create no pack, and say so

### 0187 - Days in a barrel: the keg and the preserves jar

Waits on 0184, 0168, 0149, 0186.  Likely files: `src/core/crafting.gd, src/core/game_data.gd, src/core/phases.gd, src/ui/workshop_panel.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

The first artisan machines: a keg and a preserves jar that turn fruit into wine, juice, jelly and pickles over days - the road for a player who wants to farm money (plan section 3.5).

- A per-day recipe credit: a `RECIPES` entry may say `days` (`# LEVER`) instead of `ticks`; `Crafting` credits such a job one day each morning (from `Phases.begin_day`), not per tick, and the panel shows days left (a new string in both languages: `WORK_MAKING` prints seconds). `check_recipes` accepts exactly one of `ticks` and `days`
- Keg and preserves jar are `BUILDINGS` entries built by day (size, hp, cost as `# LEVER`s; 0188 writes the final sizes into A031). The keg makes wine from grapes and juice from other fruit; the jar makes jelly from fruit and pickles from vegetables - choose which crops
- `WINE`, `JUICE`, `JELLY` and `PICKLES` with prices, an artisan group, names and strings in both languages; every recipe passes `check_chain` with a margin worth the days
- Breakers already hunt every building with no `path_cost` (`Pathing.is_prey`), machines included: decide whether a machine at 0 HP takes 0186's wrecked-but-standing state (then 0188 adds `<id>_wreck` rows to A031) or turns to rubble like today's stations, and assert it
- Machines and goods draw through the placeholder road until A031 (0213) and A032 (0214) are integrated
- `Names.KEYS` with `BLD_*`/`REC_*` rows for the machines and every recipe, both languages. DATA moves; SIM moves on purpose (four resources in `held`/`gained`, two stations in `selected_recipe`) - record both

  - done when: `_task_0187_keg` in `src/tools/headless_v1.gd` (mornings by `Phases.begin_day`): grapes in a keg are wine after the recipe's mornings and not one before; a day spent elsewhere still counts; every new recipe has a positive chain margin
  - done when: `_case_0187_keg` in `src/tools/input_v1.gd`: queue wine at a keg from its panel

### 0203 - Art: material icons

Waits on 0176, 0177, 0184.  Likely files: `assets/art_source/ui/, assets/art_source/manifest.json, tools/check_ui_art.py`.

Copper, coal, gold, hardwood, hay and straw get their approved icons in the inventory, the HUD and the panels.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A020` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A020-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_ui_art.py`).
- Runtime names `ui/icon_<id>` (16x16) and `ui/hud_<id>` (10x10) cut from one source, for the ids 0176, 0177 and 0184 gave copper, coal, gold, hardwood, hay and straw
- Replace their stand-ins and flip A020's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A020 integrated`.

  - done when: `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0203/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0207 - Art: the farmer fishing

Waits on 0180.  Likely files: `assets/art_source/player-fhd/, assets/art_source/manifest.json, src/ui/player_work.gd, src/ui/player_frames.gd`.

The farmer casts, waits, strikes, reels and shows the catch at the 32px detail, replacing the legacy fish and reel strips (0180's poses).

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A024` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A024-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/player-fhd/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (the work-verb list `player_work.gd` and the showcase read).
- Runtime names and timings: cast, wait, strike, reel (loop) and show the catch (2) for S, N and W, with E mirrored at runtime (not baked), on the art contract's work canvas (48x48, pivot (24,44), draw scale 0.5); if a farmer work leaf (0123-0125) has landed, reuse its `PlayerArt.pose` work-strip path; the poses follow 0180's bar stages
- Retire the legacy 48x48 `fish`/`reel` strips from the manifest and `ownership.json` once nothing reads them, and flip A024's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A024 integrated`.

  - done when: `python tools/show_art.py --work --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0207/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0292 - Options for the new controls

Waits on 0131, 0180, 0158.  Likely files: `src/app/settings.gd, src/app/input_actions.gd, src/ui/options_controls.gd, src/ui/options_game.gd, src/ui/guardian_cursor.gd, src/ui/main.gd, src/ui/world_view.gd, src/ui/forecast_panel.gd, src/ui/day_hud.gd, assets/locale/strings.csv, src/tools/input_v1.gd, src/tools/headless_v1.gd`.

The guardian's cursor, the night camera and the fishing bar each get the knob a player reaches for: how fast the cursor moves, whether the screen edge pans, how far a stick must tilt, a kinder fishing bar, and a forecast that stays up all day.

- Five keys in `Settings.DEFAULTS` (`src/app/settings.gd`), each in its page's `resets` and with a row: `controls/cursor_speed` (percent of the repeat rate 0131 shipped, steps 50/75/100/150/200), `controls/edge_pan` (on), `controls/pad_deadzone` (0.10-0.50 in 0.05 steps, default what 0121 shipped - `project.godot` has 0.2 on the move actions today), `gameplay/fishing_assist` and `gameplay/forecast_all_day` (both off). A key 0130, 0131 or 0180 already made is reused, never doubled
- Cursor speed, edge pan and deadzone are input preferences, not rules: 0131's hold-repeat in `guardian_cursor.gd` scales its rate by cursor speed, 0130's edge-band pan in `main.gd`/`world_view.gd` runs only with edge pan on, and `InputActions` applies the deadzone with `InputMap.action_set_deadzone` to the move, pan and cursor actions (0121, 0130, 0131). Their step lists sit with their rows on the options pages, the way `OptionsA11y.ROWS` and `Video.FPS_CAPS` keep theirs - preferences, not balance, so not in `game_data.gd`, and neither hash moves for them
- Fishing assist: 0180 shipped it as a rule - a run flag written through an intent from its Settings key, the zone wider and the marker slower, never read by core from `Settings` - and left only the row. Reuse 0180's key (rename nothing) and its levers. If 0180 left a gap (core reading `Settings`, a strength with no `# LEVER` in `GameData.FISHING`, a view-side widening that changes catches), fix it here and say so: a new lever moves DATA and a rule fix moves SIM, on purpose, both numbers in the journal; otherwise neither hash moves
- Forecast all day is view only: 0158's panel (`src/ui/forecast_panel.gd`, shown by `day_hud.gd`) shows from 06:00 instead of 18:00 and still hides once START is pressed. The forecast is a pure function of (seed, date), so seeing it at breakfast can never change the night
- Rows where a player looks for them: cursor speed, edge pan and deadzone under a heading on the controls page (`OptionsControls`), fishing assist and the forecast on the game page (`OptionsGame`). Both pages still work by keyboard, mouse and pad, and RESET puts the new keys back
- Applied live and kept: a change made with a night up behind the options moves the cursor and the camera at once, the way `SimDriver` hears `gameplay/night_speed` through `Settings.changed`, and every value survives a restart through `settings.cfg`. New keys alone need no `Settings.VERSION` bump
- Strings in `assets/locale/strings.csv` with real widths, under each page's prefix (`CTL_CURSOR_SPEED`, `CTL_EDGE_PAN`, `CTL_DEADZONE`, a `CTL_*` heading, `GAME_FISHING_ASSIST`, `GAME_FORECAST_ALL_DAY`), toggles reusing `OPT_ON`/`OPT_OFF`: e.g. CURSOR SPEED / VELOCIDADE DO CURSOR, EDGE PAN / ROLAR PELA BORDA, STICK DEADZONE / ZONA MORTA DO ANALÓGICO, FISHING ASSIST / PESCA ASSISTIDA, FORECAST ALL DAY / PREVISÃO O DIA TODO

  - done when: `_case_0292_options` in `src/tools/input_v1.gd` steps each new row by keyboard and by pad, finds the value in `Settings` and in a reloaded `settings.cfg`, and RESET puts it back
  - done when: the same case at night: with edge pan on, a pointer held in 0130's edge band for a second moves the camera, and with it off it does not (a synthetic mouse motion into the band, or the edge-pan helper 0130's pan reads if the headless window cannot hold focus); a stick tilt under the deadzone moves no cursor and one over it does; a held d-pad at 200 crosses about twice the cells it crosses at 100
  - done when: the same case by day: with forecast all day on, the panel is up at 08:00, and with it off it is hidden at noon as `_case_0158_panel` expects; with fishing assist on, the next cast carries 0180's assist flag, and with it off it does not
  - done when: `_task_0292_options` in `src/tools/headless_v1.gd`: no file in `src/core/` names `Settings`; `Forecast.tonight` gives the same record at 08:00 as at 18:00
  - done when: the controls and game pages captured at 1920x1080 in both languages (`$GODOT --path . --position -4000,-4000 --script res://src/tools/capture_menus.gd -- --out=res://implementation/shots/0292/`, then again with `--pt_BR`) and opened: no label runs off its row and no two rows overlap

### 0171 - Winter: nothing grows outside

Waits on 0170, 0159.  Likely files: `src/core/farming.gd, src/core/interact.gd, src/core/game_data.gd, src/ui/day_hud.gd, src/ui/main.gd, src/ui/world_view.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd`.

When a season ends its crops wither, and in winter nothing grows outside - yet the day still matters: the pond, the quarry, the workshop and the barn carry it while the farm lives on autumn's stock.

- The change of season, moved here from 0170 so one task owns what a season boundary does to the field: on the first morning of a season `Farming.morning` withers every planted crop whose `seasons` does not list the new one (regrowing plants too, once 0172 has them). The plot loses its crop and growth and keeps a `withered` marker naming the crop for the view, like 0155's `trampled`: `Farming` treats it as empty tilled ground and planting clears the marker (no new verb, so no new sound). No crop lists winter, so Winter 1 withers what autumn left in the ground: write that in the journal
- A withered crop draws through the placeholder road (the crop's stage-2 frame, greyed in code) until A014's withered crop is integrated by 0197
- `Farming.morning` credits no growth outdoors in a season named by `NO_GROWTH_SEASONS` (`# LEVER`, winter; in `digest()`; `validate()` refuses a name not in `GameData.SEASONS`), so a crop that is in the ground in winter anyway (a test, an old save) never grows
- Planting in winter is refused with a reason the highlight can show (a `WHY_*` key in both languages), never a silent nothing; tilling still works. Interact has no refusal road today: give it a reason array of the shape `Building.why_not` returns, which `Names.refusal` already turns into words (0175 reuses it for tool tiers)
- The seed strip says that nothing grows in winter instead of showing an empty list (a `DHUD_*` string in both languages)
- Assert the rest of a winter day still runs - a check, not a new rule: fishing (winter species once 0179 has them), mining and regrowth, crafting queues and animals all produce
- No greenhouse: plan section 3.1 puts it after 1.0
- Winter's look is 0159's; this task adds only the withered stand-in and the HUD line. DATA moves; SIM does not unless the determinism scenario crosses a season - say which

  - done when: `_task_0171_winter` in `src/tools/headless_v1.gd`: a corn plot withers on the first morning of autumn and a wheat plot sown that morning does not; every planted crop withers on Winter 1; a watered plot gains no day on a winter morning; a seam, a press queue and a cow still produce on a winter day (direct calls or a short run)
  - done when: New `withered` (the first morning of autumn by a summer field) and `winter_day` scenarios: `python tools/shot.py 0171 withered winter_day --fhd` shows the withered stand-ins and the HUD line; opened and looked at

### 0188 - The dairy, the loom and the mill

Waits on 0187, 0185.  Likely files: `src/core/game_data.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd`.

The dairy, the loom and the mill: milk into cheese and butter, wool into cloth and sandbags, wheat into flour and beet into sugar.

- Dairy, loom and mill as `BUILDINGS` built by day; recipes (`ticks` or `days`, `# LEVER`s): cheese and butter from milk; cloth from wool and sandbags from cloth plus a filler you choose; flour from wheat and sugar from beet
- `CHEESE`, `BUTTER`, `CLOTH`, `SANDBAG`, `FLOUR` and `SUGAR` with prices, groups, names and strings in both languages, and `BLD_*`/`REC_*` rows for the machines and every recipe; every value passes `check_chain`. If 0187's jelly should take sugar, add it now
- Sandbags are a material here: their night use is 0231's. Bread is 0192's (the kitchen, from flour)
- Settle the art: the five machines' footprints, states (idle, active, hurt, and wreck if 0187 said so) and light/smoke points into A031; the eleven goods into A032 (bread included)
- Stand-ins through the placeholder road until A031 (0213) and A032 (0214) are integrated
- DATA moves; SIM moves on purpose (six resources in `held`/`gained`, three stations in `selected_recipe`) - record both

  - done when: `_task_0188_mills` in `src/tools/headless_v1.gd`: every new recipe runs and `check_chain` holds for each
  - done when: A new `machines` scenario: `python tools/shot.py 0188 machines --fhd` shows the five machines idle and working; opened and looked at
  - done when: the Deliverables tables of `implementation/backlog/packs/A031-machines.md` and `A032-artisan-goods.md` state the final geometry and item list this task settled

### 0190 - The peddler and his hours

Waits on 0126, 0170, 0183, 0185, 0173.  Likely files: `src/core/shop.gd, src/core/interact.gd, src/core/game_data.gd, src/core/livestock.gd, src/ui/shop_panel.gd, src/ui/world_view.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/autoplay.gd, src/tools/determinism.gd, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

The stall gets a peddler who keeps hours, 08:00 to 17:00, whose seed packets change with the season (plan section 3.6), and who sells what the farm cannot make for itself: animals and tool upgrades.

- `trade` is offered only from `STALL_OPENS` to `STALL_CLOSES` (`# LEVER`s in game minutes, 08:00 and 17:00, read through 0126's `Phases.clock_minute`; in `digest()`; `validate()` keeps them in order inside 0126's day); outside them the stall shows a closed state and the verb is refused with a reason in both languages. Gate the verb, not `Shop.buy`/`sell`: an open panel stops the clock, so the stall never closes under the player
- **Moved here from 0170:** the stock becomes seasonal. A per-season stock table (`# LEVER`, in `digest()`) puts out this season's packets only (0170 left all twelve in the flat `DAILY_STOCK`; none in winter) beside the materials; `Shop._fresh_stock`/`restock` read the date's season and `Shop.buyable()` takes the state (move its callers: `shop_panel.gd`, the autoplayer, the suites). `check_stall` covers every season. 0193 adds straw and hay before autumn
- Animals and upgrades: chickens, cows, sheep and pigs, delivered into a coop or barn with room (refused, money kept, without one), and 0173's tool upgrades at the same money + ore price through the same order path, so the rule exists once. Neither is a resource: `Shop.buy`, the stall's stock and `check_stall` (resources only today) get a branch, and `check_stall` gives each animal a price with no buy-and-sell-back profit. The four animals get `Names.KEYS` entries and `ANIMAL_*` rows in both languages (the stall lists them by name)
- Move what trades through the verb before 08:00 to opening hours: `_task_0020_shop`, `_task_0040_shop`, `_case_0020_shop`, `_case_0040_shop`, the autoplayer - grep the suites and `shot.gd` for `trade` and `Shop.open`. The determinism scenario calls `Shop.open` at `day_tick` 1500, before 08:00 on 0166's clock: leave `Shop.open` ungated or accept the SIM move, and say which
- The peddler stands at the stall in open hours, walking in and out at the edges (view only), through the placeholder road; the closed stall is a dimmed stand-in until A034 is integrated by 0216
- DATA moves; SIM moves on purpose (the stall's stock in the state turns seasonal and gains animals and upgrades) - record both

  - done when: `_task_0190_peddler` in `src/tools/headless_v1.gd` (hours by a rigged `day_tick`): trade is refused at 07:59 and at 17:00 and offered at 08:00; a spring stall stocks only spring packets, a summer one only summer's and a winter one none; a cow bought with a barn arrives in it, and without one is refused with the money kept
  - done when: `_case_0190_peddler` in `src/tools/input_v1.gd`: buy a chicken in hours; the closed stall refuses
  - done when: A new `peddler` scenario: `python tools/shot.py 0190 peddler --fhd` shows the stall open with the peddler and closed at dusk; opened and looked at
  - done when: the Deliverables table of `implementation/backlog/packs/A034-peddler.md` states the final geometry and states this task settled

### 0198 - Art: spring crops

Waits on 0170, 0172.  Likely files: `assets/art_source/crops/, assets/art_source/ui/, assets/art_source/manifest.json, tools/check_crop_art.py, tools/check_ui_art.py`.

Potato, garlic and strawberry, and the spring seed packets, get their approved art in place of 0168's tinted stand-ins.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A015` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A015-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/crops` and `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_crop_art.KINDS`; `tools/check_ui_art.py`, which counts only task 0018's icons today - give it the new family rather than breaking that count).
- Runtime names: `<crop>_0..3` for potato, garlic and strawberry (16x16, pivot (8,14)), strawberry's regrowing stage under the name 0172 draws, and `ui/icon_<id>` (16x16) with `ui/hud_<id>` (10x10) cut from one source for the produce and the carrot, potato, garlic and strawberry seed packets (ids from 0170)
- Replace the stand-ins of 0168, 0170 and 0172 and flip A015's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A015 integrated`.

  - done when: `python tools/check_crop_art.py`, `python tools/check_ui_art.py`, `python tools/show_art.py --crops --check` and `--ui --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0198/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0199 - Art: summer crops

Waits on 0170, 0172.  Likely files: `assets/art_source/crops/, assets/art_source/ui/, assets/art_source/manifest.json, tools/check_crop_art.py, tools/check_ui_art.py`.

Pepper, sunflower and melon, corn's regrowing stage and the summer seed packets get their approved art.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A016` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A016-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/crops` and `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_crop_art.KINDS`, `tools/check_ui_art.py`).
- Runtime names: `<crop>_0..3` for pepper and melon (16x16, pivot (8,14)) and the tall sunflower at the canvas and pivot 0168 settled, pepper's and corn's regrowing stages, icons (16x16 + 10x10 from one source) for the produce and the corn, pepper, sunflower and melon seed packets
- Replace the stand-ins of 0168, 0170 and 0172 and flip A016's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A016 integrated`.

  - done when: `python tools/check_crop_art.py`, `python tools/check_ui_art.py`, `python tools/show_art.py --crops --check` and `--ui --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0199/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0200 - Art: autumn crops

Waits on 0170, 0172.  Likely files: `assets/art_source/crops/, assets/art_source/ui/, assets/art_source/manifest.json, tools/check_crop_art.py, tools/check_ui_art.py`.

Pumpkin, the grape on its trellis and beet, and the autumn seed packets, get their approved art.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A017` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A017-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/crops` and `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_crop_art.KINDS`, `tools/check_ui_art.py`).
- Runtime names: `<crop>_0..3` for pumpkin and beet (16x16, pivot (8,14)) and the tall grape trellis at the canvas and pivot 0168 settled with its regrowing stage, icons (16x16 + 10x10 from one source) for the produce and the wheat, pumpkin, grape and beet seed packets
- Replace the stand-ins of 0168, 0170 and 0172 and flip A017's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A017 integrated`.

  - done when: `python tools/check_crop_art.py`, `python tools/check_ui_art.py`, `python tools/show_art.py --crops --check` and `--ui --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0200/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0205 - Art: fish

Waits on 0182.  Likely files: `assets/art_source/ui/, assets/art_source/manifest.json, tools/check_ui_art.py, src/ui/fish_book.gd`.

Every species and the four legendaries get their icons and fish-book portraits.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A022` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A022-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_ui_art.py`, plus the 32x32 portraits as a family of their own).
- Runtime names: `ui/icon_<species>` (16x16) and `ui/hud_<species>` (10x10) from one source per species, for the list 0179 and 0182 settled, and a 32x32 book portrait each
- Replace the stand-ins in the inventory, the catch line and the fish book, and flip A022's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A022 integrated`.

  - done when: `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0205/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0206 - Art: fishing gear and the minigame

Waits on 0180, 0181, 0182.  Likely files: `assets/art_source/ui/, assets/art_source/effects/, assets/art_source/manifest.json, tools/check_ui_art.py, src/ui/fishing_bar.gd`.

The bobber, the bait icons, the pieces of the fishing bar and the fish-book tab get their approved art.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A023` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A023-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui` and `assets/art_source/effects/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_ui_art.py`; `tools/check_effect_art.py` if the bobber goes in as an effect).
- Runtime names: the 8x8 bobber (float and the 2-3 frame bite dip) replacing the float the view draws today; worm and bait icons (16x16 + 10x10); the bar's frame, marker, sweet zone and hit/miss flash at the sizes 0180 settled; the book tab icon (0182)
- Replace the stand-ins of 0180, 0181 and 0182 and flip A023's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A023 integrated`.

  - done when: `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0206/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0208 - Art: the farmer tending animals

Waits on 0184, 0185.  Likely files: `assets/art_source/player-fhd/, assets/art_source/manifest.json, src/ui/player_work.gd`.

The farmer milks, shears and feeds with a proper pose, and pets the dog, at the 32px detail.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A025` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A025-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/player-fhd/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (the work-verb list `player_work.gd` and the showcase read).
- Runtime names: a tend-animal pose (4 frames) for S, N and W with E mirrored at runtime, played for `collect` at a coop or barn and the truffle dig of 0185; pet the dog (2-4 frames) for 0185's view-only gesture; canvas, pivot and `draw_scale` as 0185 wrote into the pack
- Replace the stand-in poses and flip A025's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A025 integrated`.

  - done when: `python tools/show_art.py --work --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0208/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0209 - Art: sheep and pigs

Waits on 0185.  Likely files: `assets/art_source/props/, assets/art_source/manifest.json, tools/check_prop_art.py, src/ui/animal_view.gd`.

Sheep and pigs get their approved art and the view states 0185 gave them.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A026` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A026-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/props/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_prop_art.NAMES`, where the cow and the chicken live today, or a new animals checker wired into `tools/verify.py` if the pack says so).
- Runtime names: idle (2), walk side-on (4, mirrored at runtime), eat (2-3) and sleep (1-2) for both, and the pig's dig (3), at the scale 0185 settled against the 32px farmer; 0185's wander/eat/sleep view states play them
- Replace the tinted stand-ins and flip A026's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A026 integrated`.

  - done when: `python tools/check_prop_art.py` and `python tools/show_art.py --props --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0209/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0210 - Art: the cow and the chicken redrawn

Waits on 0185.  Likely files: `assets/art_source/props/, assets/art_source/manifest.json, tools/check_prop_art.py, src/ui/world_view.gd, src/ui/animal_view.gd`.

Today's 24x24 cow and chicken are redrawn at the farmer's scale with idle, walk, eat and sleep.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A027` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A027-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/props/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_prop_art.NAMES`, which names `cow` and `chicken` today).
- Runtime names: idle, walk (side-on, mirrored at runtime), eat and sleep for the cow and the chicken at the canvas and pivot 0185 settled; drop the cow and chicken from the `AMBIENT_MOTION` shader's `species` parameter in `world_view.gd` if the frames replace that sway, and keep `transition.gd`'s `DAY_ONLY` finding them
- Retire the old 24x24 `props/cow` and `props/chicken` once nothing reads them, and flip A027's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A027 integrated`.

  - done when: `python tools/check_prop_art.py` and `python tools/show_art.py --props --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0210/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0211 - Art: animal goods

Waits on 0185.  Likely files: `assets/art_source/ui/, assets/art_source/props/, assets/art_source/manifest.json, tools/check_ui_art.py, tools/check_prop_art.py`.

Egg, milk, wool and truffle get their icons, and the pig's dig spot its look in the world.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A029` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A029-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui` and `assets/art_source/props/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_ui_art.py`, `check_prop_art.NAMES`).
- Runtime names: `ui/icon_<id>` (16x16) and `ui/hud_<id>` (10x10) from one source for the ids 0184 and 0185 gave egg, milk, wool and truffle, and the 16x16 dig spot drawn where 0185 marks one
- Replace their stand-ins and flip A029's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A029 integrated`.

  - done when: `python tools/check_ui_art.py`, `python tools/check_prop_art.py` and `python tools/show_art.py --ui --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0211/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0192 - Cooking with the new harvest

Waits on 0188, 0184.  Likely files: `src/core/game_data.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/headless_v1.gd`.

The kitchen cooks the new harvest - potato, egg, milk and bread - into the food that mends the house at night, and spring gets a meal without wheat.

- Kitchen recipes with potato, egg, milk and flour, and `BREAD` baked from flour (price, group, names and strings in both languages; a tinted icon until A032 is integrated by 0214), each recipe with a `Names.KEYS` entry and a `REC_*` row; the better recipes give `FOOD` in bigger batches (`# LEVER`s)
- A spring meal without wheat: potato and carrot into food, so the house can be mended in spring - today `cook_meal` needs wheat, an autumn crop
- Every recipe passes `check_chain`: cooked is always worth more than its inputs
- Keep the ids `cook_meal`, `cook_fish` and `cook_roast` (tests and saves name them) unless the journal says why one goes
- DATA moves; SIM moves on purpose (`BREAD` in `held`/`gained`, and the kitchen's default selection if a new recipe sorts first) - record both

  - done when: `_task_0192_kitchen` in `src/tools/headless_v1.gd`: from spring stock alone (carrot, potato, fish) the kitchen makes food; bread needs flour; every kitchen recipe has a positive chain margin
  - done when: The journal lists every kitchen recipe with its margin

### 0197 - Art: trampled crops and tilled ground

Waits on 0167, 0155, 0171.  Likely files: `assets/art_source/crops/, assets/art_source/manifest.json, tools/check_crop_art.py, src/ui/world_view.gd`.

The trampled crop of 0155, the withered crop of 0171 and the tilled-grass edges of 0167 get their approved art in place of their stand-ins.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A014` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A014-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/crops/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_crop_art.py`, which checks `tilled`/`tilled_wet` today).
- Runtime names: the trampled and withered crops (16x16, pivot (8,14)) and the edge pieces under the mask names 0167 wrote into the pack's table; ground pieces keep the soil conventions (pivot (8,16), wet at least 20 RGB darker)
- Replace the stand-ins in `world_view.gd`'s plot drawing left by 0155, 0167 and 0171, and flip A014's placeholder-registry entries to raster so 0120's check stops listing it
- Set the pack to integrated: `python implementation/backlog/assets.py set A014 integrated`.

  - done when: `python tools/check_crop_art.py` and `python tools/show_art.py --crops --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0197/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0202 - Art: tool icons

Waits on 0173, 0176, 0190.  Likely files: `assets/art_source/ui/, assets/art_source/manifest.json, tools/check_ui_art.py, src/ui/workshop_panel.gd`.

Fifteen tool icons - four tools in three tiers and the three rods - replace 0173's stand-ins wherever a tool is shown.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A019` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A019-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_ui_art.py`, which counts only task 0018's icons today - give it the new family).
- Runtime names `ui/icon_<tool>_<tier>` (16x16, pivot (8,8)) and `ui/hud_<tool>_<tier>` (10x10, pivot (5,5)) cut from one source, for hoe, can, axe and pickaxe at basic/iron/gold and the rod at bamboo/fibre/iron, as 0173 named the tiers
- Replace the stand-ins in the workshop panel, the inventory and the stall (0190) and flip A019's placeholder-registry entries to raster. The tool in the farmer's hand stays code-tinted
- Set the pack to integrated: `python implementation/backlog/assets.py set A019 integrated`.

  - done when: `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0202/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0213 - Art: the artisan machines

Waits on 0188.  Likely files: `assets/art_source/buildings/, assets/art_source/props/, assets/art_source/manifest.json, tools/check_station_art.py`.

The keg, the preserves jar, the dairy, the loom and the mill get their approved art, idle and working.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A031` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A031-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/buildings/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_station_art.FAMILY`).
- Runtime names: `<id>`, `<id>_active` and `<id>_hurt` (and the wreck if 0187 chose it) for the five, at the sizes 0188 settled, with `light_xy`/`smoke_xy` on opaque active pixels; full density, not in `ArtPlacement.visual_scale`'s 2.0 list
- Replace the stand-ins of 0187 and 0188 and flip A031's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A031 integrated`.

  - done when: `python tools/check_station_art.py` and `python tools/show_art.py --stations --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0213/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0216 - Art: the peddler

Waits on 0190.  Likely files: `assets/art_source/npc/, assets/art_source/props/, assets/art_source/manifest.json, tools/check_station_art.py, tools/check_npc_art.py (new), tools/verify.py`.

The peddler at the stall and the stall's closed state get their approved art.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A034` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A034-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/npc` and `assets/art_source/props/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_station_art.FAMILY` for the closed stall; a new `tools/check_npc_art.py` wired into `tools/verify.py` for the peddler, saying why in the journal).
- Runtime names: idle (2-4), talk/wave (2-4) and the walk in/out side cycle (4-8, mirrored at runtime) at the farmer's scale and the pivot 0190 settled; the closed stall matches today's `shop` (32x40, pivot (16,36))
- Replace 0190's stand-ins and flip A034's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A034 integrated`.

  - done when: `python tools/check_station_art.py`, `python tools/check_npc_art.py` and `python tools/show_art.py --stations --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0216/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0193 - Every season can make what it needs

Waits on 0170, 0176, 0188, 0190, 0192.  Likely files: `src/core/game_data.gd, src/core/shop.gd, src/ui/names.gd, assets/locale/strings.csv, src/tools/headless_v1.gd`.

No defence, round, repair meal or feed may depend on a crop whose season has not come yet: every season can make what it needs.

- `check_seasonal_supply(...)` in `GameData.validate()`, taking its tables as arguments like `check_chain(recipes, prices)` so a test can hand it a broken one: for each season S, everything unlocked in S - defence kits, ammunition, repair food, animal feed - is makeable from the crops of seasons up to S plus fish, ore, wood, stone and what the stall sells in S (0190's seasonal stock table); it walks the recipe graph
- What 'unlocked in S' means: a `season` field on `DEFENCES` entries, default spring. Plan section 5 puts the flamethrower in summer and the mortar in autumn, but moving them is 0234's (with the new defences), so today's eight stay spring here
- Fix the known breaks: gunpowder in spring (a recipe from coal and oil pressed from fish by `press_fish_oil`, since corn is summer), a meal in spring (0192's, checked here), straw and hay sold by the peddler before autumn (rows in 0190's seasonal stock)
- Pepper and sunflower get their plan roles: pepper makes incendiary rounds at a better yield than wood (a recipe, not a new ammunition rule), and sunflower is pressed into oil
- Every new recipe passes `check_chain` and `check_ammo` and has a `Names.KEYS` entry and a `REC_*` row in both languages
- DATA moves; SIM moves if the stall's stock or a station's default recipe (both in the state) changes - say which

  - done when: `_task_0193_supply` in `src/tools/headless_v1.gd`: the real tables pass for all four seasons; taking out the coal gunpowder recipe makes spring fail by name
  - done when: The journal lists, season by season, the route to each kit, round, meal and feed

### 0214 - Art: artisan goods

Waits on 0188, 0192.  Likely files: `assets/art_source/ui/, assets/art_source/manifest.json, tools/check_ui_art.py`.

Wine, juice, jelly, pickles, cheese, butter, cloth, sandbags, flour, bread and sugar get their approved icons.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A032` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A032-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_ui_art.py`).
- Runtime names: `ui/icon_<id>` (16x16) and `ui/hud_<id>` (10x10) from one source for the eleven ids 0187, 0188 and 0192 gave them
- Replace their stand-ins and flip A032's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A032 integrated`.

  - done when: `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0214/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0194 - The day's economy

Waits on 0193, 0189, 0171, 0172, 0174, 0177, 0178, 0180, 0182, 0186, 0191.  Likely files: `src/core/game_data.gd, tools/balance.py, src/tools/autoplay.gd, implementation/BALANCE.md, src/tools/headless_v1.gd`.

The day's money is tuned on purpose: a price for every item, and targets per season so that a good day buys about one new defence (plan section 5's rule of thumb).

- One reviewed price table for every item: `SELL_PRICE`, seed and animal prices, upgrade and building costs; `check_stall` and `check_chain` pass
- Money-per-day targets by season, as `# LEVER`s or a table the check reads: a well-worked day at the start of each season buys about one new defence
- `tools/balance.py` gains sweeps of day strategies - crops, fishing, mining, animals, artisan goods - over a spring and a summer day, headless and outside the suite; it still refuses a dirty tree and restores `game_data.gd`
- A BALANCE.md section with money per strategy per season against the target, and every lever moved
- No single strategy wins every season: the day has several ways to earn, which is what 0196 asks
- DATA moves on purpose (the target table goes into `digest()`); SIM moves if a price or a stock the determinism scenario meets changes - record both

  - done when: `_task_0194_economy` in `src/tools/headless_v1.gd`: a computed (not simulated) day of each strategy lands inside its season's target band
  - done when: A `tools/balance.py` run writes the BALANCE.md section, and the journal quotes its numbers

### 0195 - Teaching the new day

Waits on 0194.  Likely files: `src/core/game_data.gd, src/ui/tips.gd (new, e.g.), src/ui/tutorial_prompt.gd, src/ui/main.gd, src/app/save.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

The new day explains itself once: tilling grass, the seasons, the shipping bin, the fishing bar and the animals each get one tip, at the moment they first matter.

- Tips, not day-one lines: `MAX_TUTORIAL_LINES` still caps the first day. A tip fires from the state (the first stand on open grass with the hoe, the first morning of a new season, the first stand by the bin, the first bite, the first animal bought) and is remembered in the profile so it never shows twice
- Tips live in the view: `src/ui/` reads the state for the trigger and the profile (`Save.read_profile`/`write_profile`) for what was shown, through a pure `due(state, profile)` the headless group can call. No rule in `src/core/` reads them (their table may sit in `game_data.gd` beside `TUTORIAL`, as data), so SIM must not move; they never gate or pause anything. The day-one lines remember themselves in the `gameplay/tutorial_seen` Settings key (`tutorial_prompt.gd`): say why the tips use the profile instead, or use Settings too
- `check_tutorial` (or a new check) covers the tip table in `game_data.gd`: unique, short, naming a string key that exists. List it in `digest()` (DATA moves) or exempt it in `_task_0112_digest` as view text - say which
- Strings in both languages, each fitting its control (`tools/i18n_check.py`); a tip sits on the thing it describes (`tutorial_prompt.gd`)
- The guided Spring 1-7 is 0293's, not here

  - done when: `_task_0195_tips` in `src/tools/headless_v1.gd`: each tip fires once on its trigger and never again with the profile flag set
  - done when: `_case_0195_tips` in `src/tools/input_v1.gd`: a tip appears on the first bite and is dismissed
  - done when: A new `tips` scenario: `python tools/shot.py 0195 tips --fhd` shows two tips in place; opened and looked at

### 0196 - Checkpoint: is the day good on its own?

Waits on 0194, 0195.  Likely files: `implementation/PROGRESS.md, implementation/shots/0196/, src/tools/autoplay.gd, implementation/prompts/`.

**The plan's Phase 3 checkpoint.** A spring day and a summer day earn money in different ways, and the day is fun even without thinking about the night. Phase 13 and everything after it waits on this answer.

- Play a spring day and a summer day in the real game, and run the autoplayer through the same days; compare where the money came from
- FHD captures of both days at morning, noon and dusk in `implementation/shots/0196/`, opened and looked at
- Answer honestly in the journal: is the day fun even without thinking about the night? What drags, what is busywork, what is missing
- If the answer changes the plan, edit the later prompts (0197 on) before they run, and say which
- If the answer is no, mark this task blocked with the reason, so phase 13 does not start on a day that does not work
- Change no rule here, so neither hash moves: fixes go into later prompts or new tasks

  - done when: The journal says, with numbers, how a spring day and a summer day each made their money - and that they differ
  - done when: The journal answers the question in one paragraph a reader could disagree with
  - done when: The captures are in `implementation/shots/0196/` and the journal says what each one shows

### 0293 - The first week, taught

Waits on 0195, 0141, 0158, 0180.  Likely files: `src/core/game_data.gd, src/core/tutorial.gd, src/ui/tutorial_prompt.gd, src/app/settings.gd, tools/goldens/, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

A stranger learns 1.0 the way they learned the MVP's first day - one short line, on the thing it is about, gone when it is done - but spread over Spring 1 to 7, so the first morning is not a lecture and the forecast, the bin and the rod arrive when they first matter.

- Start from what 0141 and 0195 left in `GameData.TUTORIAL` and write the week down as data: each step gains the Spring date it may first show (e.g. `from_day`, read against `Calendar.date`), in the order a week happens - day 1 chop, plant, water, the bed, the cursor, START and dawn; the bin and the stall once there is something to sell; the forecast at 18:00 of the first night with something new in it; the rod and the minigame mid-week; the season and the Full Moon by day 7. Where a 0195 tip already teaches a lesson (the bin, the first bite, a new season), the week takes it over or leaves it to the tip - one line per lesson, never both. The schedule is the task's to justify in the journal
- It still watches and never gates (the `Tutorial` header): `Tutorial.tick` keeps checking every step, a step done early by a player who found it alone is done, and `current()` and `points_at()` only offer steps whose day has come. Keep 0141's assert that ignoring the prompts reaches the same night with the same state apart from `tutorial` - one day and night in the suite, never Spring 1-7
- Every step finishes on something the state shows: the forecast step is done when the night it forecast begins, not when a panel was looked at - the rules cannot see the screen
- Short, per day: `check_tutorial` counts the week's lines per day against a new `# LEVER` `MAX_TUTORIAL_LINES_PER_DAY` (3-7, start at 5) and the week against `MAX_TUTORIAL_LINES`, whose comment and range are raised only as far as the week needs, with the reason in the journal (0195's tips keep their own check and do not count per day). `MAX_TUTORIAL_LINE_LENGTH` is unchanged, and no line describes the switch of reality - the bed and the fade show it
- Never twice, but the new lessons still reach a returning player: `gameplay/tutorial_seen` is one bool, so whoever finished the 0.1 day one would never see the bed or the cursor. Unless 0141 or 0195 already changed it, make it the list of step ids seen, with a `Settings.VERSION` bump whose `Settings._migrate` turns `true` into the 0.1 steps. The bump gets its golden: a 0.1 `settings.cfg` fixture in `tools/goldens/` (e.g. `settings-v1.cfg`, in the format `git show bea89a88:src/app/settings.gd` saves, with a non-default language, volumes, a rebind and `tutorial_seen` true) - the fixture goes in even if 0141 or 0195 already changed the key
- Each line sits on its thing through `tutorial_prompt.gd`: the bed, the cursor's cell, the START button, the forecast panel, the bin, the pond. At night the line follows the camera, not the sleeping farmer
- Rewrite in place what assumed every step shows on day one: `_task_0041_tutorial` in `headless_check.gd`, 0141's `_task_0141_tutorial`/`_case_0141_tutorial` and 0195's tip groups in `headless_v1.gd`/`input_v1.gd`
- Every line is a `TUT_*` row in both languages with a real width. `TUTORIAL` is in `GameData.digest()`, so DATA moves on purpose; SIM moves only if the done list in the determinism scenario changes - say which, both numbers in the journal
- What the loop cannot know - whether a stranger reads them - becomes a question in 0295's tester note, not a guess here

  - done when: `check_tutorial` passes, and the journal has the week as a table: day, steps, lines
  - done when: `_task_0293_first_week` in `src/tools/headless_v1.gd`: a scripted player that only does what `Tutorial.current()` and `points_at()` ask gets from Spring 1 at 06:00 to Spring 2's morning with the house standing and every day-1 step done (going to bed early, so the group stays a few seconds); no step is offered before its day
  - done when: the same group: the 0.1 `settings.cfg` fixture loads with its language, volumes and rebind kept, every key it lacks at its `Settings.DEFAULTS` value, and its `tutorial_seen` of `true` migrated to the 0.1 step ids, so only the new steps are offered
  - done when: 1920x1080 captures of the bed line, the cursor line at night and the forecast line at dusk, in both languages (new scenarios such as `tut_bed`, `tut_cursor`, `tut_forecast`: `python tools/shot.py 0293 tut_bed tut_cursor tut_forecast --fhd` and again with `--pt_BR`), opened: each line is on its thing and nothing on screen covers it

### 0218 - Room for more fields and more bodies

Waits on 0196.  Likely files: `src/core/pathing.gd, src/core/entities.gd, src/core/towers.gd, src/tools/perf_check.gd, tools/perf.py, tools/perf_baseline.txt, src/tools/headless_v1.gd`.

Nothing changes for the player. The decoy, the bait, the digger and the rat swarm are coming, and today every wall placed re-sweeps every path field and every tower scans every zombie; make room before adding to either, with the game playing exactly as it does now.

- A named-field registry in `Pathing`, in code (a const table and one accessor such as `Pathing.field(state, name)`): a field is registered with its seeds, its cost rule and the state keys it is stored under, and is built on first request for the current `grid_version`, never on a rebuild nobody asked for. Today's three (`flow`, `flow_open`, `flow_hunt` and their `*_cost` arrays, under `flow_version`) keep being built eagerly in `refresh` exactly as now, because those keys are folded into SIM. The registry is for 0224's lure field and 0250's digger field, which add their own storage keys (and move SIM) then
- `Entities.ids` stops sorting on every call, on the strength of an asserted invariant: ids are handed out ascending and never reused (`next_entity_id`), so the table's own order is already ascending - assert it after spawns, kills, `Enemies.withdraw` and a save round trip (if a loaded table does not keep the order, sort it once where the save is read, e.g. `State.reconcile`). No static cache shared between states
- A spatial bucket for `Towers._acquire`, built once per `Towers.tick` as a local (never stored in the state) from the entity cells, so a tower looks only at the buckets its reach touches. It must pick exactly what the full scan picks for every `TARGETING` mode, ties to the lowest id included; `acquire_for` keeps working for the tests
- Both hashes unchanged is the bar. `State.hash_of` folds every state key, caches included, so nothing here may add a key to a new game's state. If that proves impossible, prove play identical (kills, house HP and every entity cell at fixed ticks of one seeded night, before and after) and record both numbers in `implementation/PROGRESS.md`
- A swarm scenario in `src/tools/perf_check.gd`: a few hundred walkers (the rat swarm's stand-in until 0248) against the worst case's towers, with its own `PERF` lines (e.g. `swarm_tick`, `swarm_towers`, `swarm_enemies`) and a `COUNT` of bodies. `PerfNames` is unchanged: no system is added
- The swarm must sit inside `TICK_BUDGET_US` (8333 us), and `tools/perf.py` holds only `night_tick`, `day_tick` and `path_refresh` to a budget today: add `swarm_tick` to that list so the bar is enforced. If it does not fit, write down what it would take rather than shrinking the swarm
- Accept the new baseline with `python tools/perf.py --accept` and say in the journal why each number moved

  - done when: `_task_0218_perf_ground` in `src/tools/headless_v1.gd` asserts the bucketed acquire equals the full scan over a seeded crowd for all four targeting modes, `Entities.ids` is ascending after spawns, kills and a save round trip, and a registered field is not built until it is asked for
  - done when: `python tools/perf.py --report` shows `night_towers` below its baseline at the start of this task (1028 us when this was written) on the old worst case, and `python tools/perf.py` passes with `swarm_tick` inside the tick budget
  - done when: The journal has the perf table before and after

### 0219 - Essence

Waits on 0196, 0137, 0152.  Likely files: `src/core/rewards.gd, src/core/tech.gd, src/core/game_data.gd, src/ui/night_hud.gd, src/ui/result_screen.gd, src/ui/tech_panel.gd, assets/locale/strings.csv, implementation/BALANCE.md, src/tools/headless_check.gd, src/tools/headless_v1.gd`.

The night stops paying like a day. It hands over essence - today's technology points under a new name - for holding the farm, and a smaller purse, so money is what the day earns and the night spends (plan section 4.6).

- Keep the id `tech` (`GameData.TECH`, `Rewards._is_tech`, the saves): only the words change, so no `State.VERSION` bump. `ITEM_TECH` becomes essence / essência and every line that names the currency follows (`DESC_TECH_COST`, `TECH_HELD`'s 'points', any result or HUD line); the tree itself may stay the technology tree (`TECH_TITLE`)
- Earn rules as LEVERs in `GameData.REWARDS` and `TECH_BONUSES`: a night won pays `tech_points`; the three bonuses stay (house untouched measured against `Phases.house_full`, as 0114 left it); a Full Moon night (`Calendar.is_full_moon`, 0152) multiplies the night's essence by a percent LEVER (100-300), its own line in `Tech.would_pay`; `GameData.validate()` refuses a percent under 100. `nights_paid` still stops a night paying twice
- The night's money shrinks: `base_money`, `money_per_night` and the material handout (`resources`, `resources_per_night`), read through 0150's `Rewards.night_step`, come down to numbers argued against 0194's money-per-day targets in `implementation/BALANCE.md`; the journal says what a spring night paid before and after
- The bounty is paid for kills only. `Rewards._money_from` already reads `killed_by_kind`; assert that survivors who walk off at dawn (0137, `Enemies.withdraw`) pay nothing and are not counted as killed
- Essence on screen: the night HUD shows what is held (plan section 9) and the morning report of 0138 has a '+N essence' line itemised from the lines `Tech.would_pay` gave inside `Rewards.settle`, kept in `payout` for the screen - after `Tech.award` the night is paid and `would_pay` answers empty. The icon is the existing tech icon through the placeholder road until A036 is integrated by 0235
- Asserts that pin night money or technology (`_task_0061`, `_task_0062`, `_task_0068` and whatever 0150 left of them) are rewritten in place in `src/tools/headless_check.gd` to read the LEVERs rather than literals; `tools/i18n_check.py` is clean in both languages
- SIM and DATA both move on purpose (the payout and the REWARDS table): record the old and the new numbers in `implementation/PROGRESS.md`

  - done when: `_task_0219_essence` in `src/tools/headless_v1.gd` asserts a won night pays `tech_points` plus each bonus earned, a Full Moon night pays the multiplied amount, a replayed night pays no essence, and a dawn win with survivors pays bounty for the kills only
  - done when: `python tools/shot.py 0219` captures of the night HUD and the morning report say essence, opened and looked at
  - done when: The BALANCE.md section sets a spring night's money and essence beside a spring day's money

### 0223 - Defences sleep under tarps

Waits on 0196, 0132, 0120.  Likely files: `src/ui/world_view.gd, src/ui/transition.gd, src/ui/placeholder_art.gd, src/tools/shot.gd, src/tools/headless_v1.gd, implementation/backlog/packs/A044-tarps.md`.

By day the defences sleep under tarps and the farm looks like a farm; when the night comes the covers come off with the wake the transition already plays (plan section 5).

- View only: no rule reads a tarp, and both hashes stay where they are
- In the DAY phase every defence of a tarp family is drawn covered; during the switch into the night the tarps come off with the wake pass in `transition.gd` (`WAKES` kept - the generator still wakes, without a tarp) and go back on when the day begins
- Decide which families get tarps and why: probably the towers and the other standing one-cell defences, not barriers, mines or traps (a covered wall is still a wall, a covered mine is a lie). Drive the unveil from one list in the view so a later defence joins by being listed; 0234 lists the families of 0224-0231, which leave the list alone
- A hurt or wrecked defence shows its state by day - through the tarp or instead of it, decide - so the morning never hides damage
- Drawn through the placeholder road of 0120: a code-drawn or tinted cover per footprint (32x48 towers, 16x32, 16x24) with two unveil frames, until A044 is integrated by 0243
- Write the chosen families and footprints into the Deliverables table of `implementation/backlog/packs/A044-tarps.md`; 0234 settles the final list

  - done when: `_task_0223_tarps` in `src/tools/headless_v1.gd` asserts every id in the view's tarp list is a `DEFENCES` id and nothing in `src/core/` mentions a tarp
  - done when: `python tools/shot.py 0223` captures of the same towers by day (covered), at dusk and at night (uncovered), opened and looked at

### 0227 - The pumpkin catapult

Waits on 0196, 0132, 0168.  Likely files: `src/core/game_data.gd, src/core/towers.gd, src/core/ammo.gd, src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd`.

A lobbed splash that burns pumpkins instead of gunpowder, so an autumn harvest becomes an autumn defence (plan section 5).

- Id `catapult` (never `pumpkin`, which is the crop): `shape` splash, `aim` ballistic with `flight_ticks`, `ammo` {pumpkin: 1}, a cost in wood and pumpkins, `season` autumn (0193's field - pumpkins are autumn's, so `check_seasonal_supply` fails it as spring). Not a cheaper mortar: shorter reach, no gunpowder, a reason of its own - the journal says when it is the better buy
- It has `damage`, so `_task_0085_night_sounds` wants a `Sfx.TOWER_SOUNDS` entry: borrow `sfx/mortar` until 0283 gives it a thunk
- `check_ammo` refuses ammunition no recipe makes. Allow what a crop yields (the `CROPS` table) as well as recipe outputs, or add a recipe - decide, and keep the rule's intent: a tower must be able to fire a proper shot
- An empty pumpkin pool gives the weak shot every tower has (`Ammo.weak_damage`, `Ammo.weak_reload`), never a silent catapult
- `TOWER_LEVELS` 1-3 for `catapult`, gated on the same tree nodes as the other towers (`true sights`, `oiled works`)
- `Names.KEYS` `DEF_CATAPULT`, a `Describe.defence` line, strings in both languages; drawn through the placeholder road (a tinted 32x48 tower per level and state, an 8x8 pumpkin shot, a 4-frame splat) until A039 is integrated by 0238
- DATA moves (a row, its levels, the ammunition rule); SIM moves only if a state key appears or the scenario builds one - record both numbers

  - done when: `_task_0227_catapult` in `src/tools/headless_v1.gd` asserts a pumpkin lands where it was aimed with the splash falloff the LEVER claims, an empty pool still fires weakly, and levels 1-3 read through `Building.entry_at`
  - done when: The Deliverables table of `implementation/backlog/packs/A039-catapult.md` states the final geometry this task settled (levels, states, muzzle points, the shot, the splat)
  - done when: `python tools/shot.py 0227` captures of a volley landing, opened and looked at

### 0230 - The electric fence

Waits on 0196, 0132, 0176.  Likely files: `src/core/game_data.gd, src/core/enemies.gd, src/ui/world_view.gd, src/ui/placeholder_art.gd, src/ui/names.gd, src/ui/describe.gd, assets/locale/strings.csv, src/tools/headless_v1.gd`.

A barrier like the wooden fence, except whatever bites it is thrown back stunned for a moment - a winter answer that needs the generator running (plan section 5).

- Id `electric_fence`: a barrier (`path_cost` and `hp` LEVERs, within `WIDEST_STEP` by `check_pathing`) with an `energy_draw`, a cost in copper (0176), with wood if it needs a frame, and `season` winter (0193's field). The shock is a stun, not `damage`, so no `Sfx.TOWER_SOUNDS` entry (`_task_0085_night_sounds` wants one exactly when a defence has `damage`; 0283 adds the zap)
- Stun in `Enemies._gnaw`: an enemy biting an electric fence is stunned for a LEVER of ticks (1-3 s) - a generic entity counter (any source may set it) read at the top of `Enemies._walk`, so a stunned enemy neither moves nor bites; 0233's farm bell writes the same counter. The bite still lands; decide whether bosses get a shorter stun or none. `check_defences` refuses a stun of zero ticks
- Needs power, degraded never dead: on a short farm the stun is scaled down by `Power.percent`, never to zero
- Joins like the fence: `WorldView.barrier_mask` joins only `wall` and `fence` today - add the electric fence (decide whether it meets a wooden one) and the placeholder road's `connected` flag, so the joins draw before the art arrives
- `Names.KEYS` `DEF_ELECTRIC_FENCE`, a `Describe.defence` line, strings in both languages; drawn through the placeholder road (fence-style modules for the 16 masks, whole/hurt, a wreck, a 3-frame zap) until A042 is integrated by 0241
- DATA moves (a new row); SIM moves only if the scenario meets one or a state key appears - record both numbers

  - done when: `_task_0230_electric_fence` in `src/tools/headless_v1.gd` asserts a walker that bites it stands still for the stun and then bites again, a short farm shortens the stun without removing it, and the field prices it like a barrier
  - done when: The Deliverables table of `implementation/backlog/packs/A042-electric-fence.md` states the final geometry this task settled
  - done when: `python tools/shot.py 0230` captures of a joined run of electric fence, opened and looked at

### 0232 - Powers as a list

Waits on 0196, 0135.  Likely files: `src/core/ability.gd, src/ui/night_hud.gd, src/ui/main.gd, src/ui/world_view.gd, src/ui/pixel_effects.gd, src/tools/effect_showcase.gd, src/tools/perf_check.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Nothing changes for the player. The one flare becomes the first entry of a list of powers, each with its own cooldown and aim cell, so 0233 can add three without a second copy of the cooldown and aiming code.

- `Ability` takes a power id: `ready(state, id)`, `cooldown_left(state, id)`, `charge_percent(state, id)` and `use(state, id, cell)` with the aim cell from 0135's `ability_cell` intent. The flare is the only power and behaves exactly as it does now
- Hashes unchanged is the bar. `state["ability"]` is in `State.TABLES` and folded into SIM, so the flare keeps its keys (`cooldown`, `flare`, `flare_ticks`, `flares`) and no new state key appears until 0233 adds a power; `intent.ability` stays the flare's edge for the same reason; `GameData.ABILITY` stays byte-identical so DATA does not move
- If a key truly has to move, prove play identical (a scripted night with two aimed flares, before and after) and record both numbers in `implementation/PROGRESS.md`
- `Ability.recharge` and `Ability.put_out` work over every power; the `flare_percent` tree bonus stays the flare's
- Every caller moves to the new signatures - today `main.gd`, `night_hud.gd`, `world_view.gd`, `pixel_effects.gd`, `effect_showcase.gd`, `perf_check.gd`, `_task_0054` as 0135 left it and the input cases (grep `Ability.` for whatever 0135-0142 added: the shot scenarios, the autoplayer) - and no flare-only path is left

  - done when: `_task_0232_powers_list` in `src/tools/headless_v1.gd` asserts the flare's cooldown, aim and damage through the new API match the numbers before the refactor, and an unknown power id is refused without touching the state
  - done when: `_case_0135_flare_aim` in `src/tools/input_v1.gd` passes with nothing changed but its calls moved to the new API

### 0246 - Bosses in general

Waits on 0153, 0196.  Likely files: `src/core/combat.gd, src/ui/night_hud.gd, src/ui/log_panel.gd, src/ui/enemy_motion.gd, src/ui/enemy_deaths.gd, src/ui/pixel_effects.gd, src/ui/world_view.gd, src/ui/sfx.gd, assets/locale/strings.csv, tools/check_giant_art.py, tools/show_art.py, src/tools/giant_showcase.gd, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Three more bosses are coming, and everything that knows about a boss today knows about the Giant by name. Make the bar, the counters, the arrival line, the sounds and the art checks work for anything with `is_boss`, so 0253-0255 are a data entry and a behaviour each.

- `Combat.boss_here` stays the lowest-id boss on the farm; add `Combat.bosses_here(state)` (sorted ids) and `Combat.full_hp(state, id)` (the table's `hp` today), so the boss bar (`NightHud._refresh_boss` reads `ENEMIES[kind]["hp"]` today) reads a body's full health from the one place 0257's elites will change; `Describe.enemy` describes a kind and keeps the table's number
- Per-boss counters without a new State key: `Combat.bosses_down_of(state, kind)` reads `killed_by_kind_all_run` (RUN_DATA) for `is_boss` kinds; `bosses_down` stays the run total `Run` reports. Raising `boss_arrived` for any `is_boss` is 0153's, not this task's
- The night HUD's boss bar (`NightHud._refresh_boss`, or wherever 0139 moved it) names whichever boss is up, adds `x2` when more than one is alive (Endless already sends two Giants) and keeps the wind-up flash for any boss with `telegraph_ticks`
- A boss intro line: `LOG_BOSS` ('the giant is coming') becomes one literal key per boss in a const map in the view (`BOSS_INTRO_GIANT` first; key,width,en,pt_BR rows in `assets/locale/strings.csv`), shown as a banner on `boss_arrived` and as the log line; delete the `LOG_BOSS` row, since `tools/i18n_check.py` fails on unused keys
- View hard-codes on the Giant's id become boss-generic where the art follows the Giant's pose names (`EnemyMotion.TRACKED` and `_giant_pose`, the five death frames in `EnemyDeaths`, the impact offset in `PixelEffects`, the `giant_windup_` test in `WorldView`): a boss with no authored poses falls back to the ordinary path, and the Giant draws exactly as before. `Sfx` too: `_watch_bodies` announces any `is_boss` on arrival with no position, `nearest_by_kind` leaves every boss out and `_ducks` ducks for any boss voice - so 0253-0255 borrow `sfx/roar_giant` in `ENEMY_SOUNDS` until 0284 voices them
- `tools/check_giant_art.py` becomes table-driven (family -> motion counts, canvas, pivot, generation task; only the Giant today) and its exact `migrated_enemies() == {five}` becomes a subset check, so a new enemy family cannot fail it; `giant_showcase.gd` takes the family and `tools/show_art.py` routes a new `--boss=<family>` to it (`--giant` unchanged) for the leaves 0266-0268
- Rewrite `_task_0058_giant`'s 'the only boss in the table' and 'outlasts every other enemy' asserts as every boss against every non-boss (hp, armour, walking `ticks_per_tile`), because 0247-0255 add both kinds
- Hashes unchanged: helpers, view and tests only

  - done when: `_task_0246_bosses` in `src/tools/headless_v1.gd`: two Giants on the farm give `bosses_here` both ids in order; killing one moves `bosses_down_of(state, &"giant")` and `bosses_down` by one each; every `is_boss` entry has an intro key in the map and in the strings table
  - done when: `_case_0246_boss_bar` in `src/tools/input_v1.gd`: a spawned Giant raises the bar and the banner, `Sfx.nearest_by_kind()` has no entry for it, and the bar goes when it dies
  - done when: `python tools/check_giant_art.py` and `python tools/show_art.py --giant --check` pass and report the Giant as before
  - done when: `python tools/shot.py 0246 boss` (a new scenario: a Giant winding up) opened and looked at: bar, name and banner overlap neither the hotbar nor the time to dawn

### 0281 - The new day's sounds

Waits on 0196.  Likely files: `tools/gen_sfx.py, assets/sfx/, src/ui/sfx.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Going to bed, waking up, the shipping bin, the peddler, the machines and the new ores each make their own noise, so the longer day of 1.0 sounds as varied as it plays. View only: neither hash moves. (The animal calls are 0286's and the dog's bark 0283's - moved there so this fits one invocation.)

- New recipes in `tools/gen_sfx.py`, built from the same `Noise` and primitives (no `random`): bed (under the blanket), wake (a stretch at 06:00), pass-out (a thud at 02:00), the morning payout coins, the peddler's stall bell, and the tool upgrade (an anvil ring when it is ordered, a bright ting when it is delivered next morning)
- And the farm's: one working sound per artisan machine (0187's keg and jar, 0188's dairy, loom and mill) and copper, coal and gold variants of `mine` for 0176's nodes. No animal voices here: 0286 writes the calls heard near the coop and the barn and 0283 the dog's bark for its power
- Furniture and moments: everything played per action keeps the rule `_task_0084_day_sounds` enforces (a peak of at most 0.6 - rendered at `SOFT_PEAK` - under 0.6 s, and quieter and shorter than the bite, so the bite stays the loudest and longest day sound). Bed, wake, pass-out, the morning coins, the stall bell and a delivered tool happen once or twice a day: give them their own list and peak in `gen_sfx.py` (e.g. `MOMENT_SOUNDS`, below `ALARM_PEAK`, joined into `SOUNDS`) and teach that group the named exception rather than loosening its rule
- `Sfx` hears them from the state and `src/core/` never calls `Audio` nor gains a key for a sound: bed and pass-out on the phase leaving DAY with 0127's `House.asleep` and 0128's `house_visit.passed_out`, wake on 0138's morning, the payout as ONE coins sound when 0189's bin is paid at `begin_day` (never one per coin, never the night's reward; `_watch_money` resets outside DAY and swallows that rise, so read the bin emptying), the stall bell when 0190's `STALL_OPENS` and `STALL_CLOSES` pass, at the stall's cell, the anvil when 0173's pending upgrade appears and the ting when it is handed over
- A per-target table in `src/ui/sfx.gd` (e.g. `TARGET_SOUNDS`, occupant id -> sound) consulted before `VERB_SOUNDS` with the cell the action already carries: copper, coal and gold nodes sound like their ore and each machine like itself when a job goes in; a target absent from it falls back to the verb's sound
- Walk `Interact.DAY_ONLY` against `Sfx.VERB_SOUNDS`: every verb 0165-0195 added (0189's `ship` - the bin's lid and drop -, 0185's truffle dig, whatever else the list holds now) was mapped to a borrowed file to keep `_task_0084_day_sounds` green; each gets its own recipe, and two verbs share a file only where the journal says why
- Every new file is reached by the checks: the per-target table goes into the `wanted` list of `_task_0084_day_sounds` (so the furniture rule measures it), the moment list into the `heard` set its 'nothing in the folder is unreached' assert builds but not into the furniture loop - that assert fails on a WAV nothing asks for
- The numbers live in `gen_sfx.py` and `sfx.gd`, not in `game_data.gd` - the `Sfx.GROAN_EVERY_SECONDS` reasoning: a noise changes no rule and must not move the data hash

  - done when: `_task_0281_day_sounds` in `src/tools/headless_v1.gd`: every new id is a file, per-action sounds keep the furniture rule, the moment list is named and stays under the alarm, and ore and machine targets resolve to their own sound while an unknown target falls back to the verb's
  - done when: `_case_0281_day_moments` in `src/tools/input_v1.gd`, reading `Audio.last_played()` and `Audio.plays_of()`: going to bed plays the bed sound once, mining a copper node plays the copper variant and not `sfx/mine`, and a morning with items in the bin plays the coins exactly once
  - done when: `_task_0084_day_sounds` and `_task_0085_night_sounds` pass; `python tools/gen_sfx.py --report` lengths and peaks of every new sound are in the journal

### 0282 - The sounds of the fishing minigame

Waits on 0180, 0182, 0196.  Likely files: `tools/gen_sfx.py, tools/gen_music.py, assets/sfx/, assets/music/, src/ui/sfx.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

The minigame of 0180 can be played by ear as well as by eye: a tick from the bar, a hit, a miss, the catch, and a fanfare when one of 0182's legendaries comes out of the water. View only: neither hash moves, and no state key is added to be heard.

- Recipes in `tools/gen_sfx.py` for tick, hit, miss and catch. All four are furniture (at most `SOFT_PEAK`, shorter than the bite), so `_task_0084_day_sounds` still finds the bite the loudest and longest day sound: the bite opens the window, these only follow it
- The tick marks the marker turning at an end of the bar or entering the zone (pick one and say why), never every frame
- `Sfx` reads hit, miss and catch off 0180's minigame state the way `_watch_fishing` reads `Fishing.is_biting`: a hit or a miss is the edge the press intent left in the state, the catch is the cast ending with a species landed. An assisted hit (0180's option) sounds like any other hit
- The legendary fanfare is music, not furniture: a short cue in `tools/gen_music.py` beside `sting` (Music bus, at most `STING_PEAK`, a `PIECES` entry so `--check` knows it) built on `MOTIF`, so the year's tune answers the catch. `Sfx` asks `Audio.play` for it when the species landed is one of 0182's legendaries, and the ordinary catch is skipped then
- Decide what becomes of `sfx/reel` (the MVP's one-press reel): kept as the line coming in under the minigame, or retired with its recipe and its `VERB_SOUNDS` entry - never left as a file nothing plays. `reel` is in `Interact.DAY_ONLY` today and `_task_0084_day_sounds` wants a sound for every verb there, so retire it only if 0180 took the verb out of that list
- Extend what `_task_0084_day_sounds` collects so every new file in `assets/sfx/` is reached; `python tools/gen_sfx.py --check` and `python tools/gen_music.py --check` are clean

  - done when: `_task_0282_fishing_sounds` in `src/tools/headless_v1.gd`: the four files exist and keep the furniture rule against the bite; the fanfare is in `assets/music/`, under five seconds and at most `STING_PEAK`, and its recipe reads `MOTIF`
  - done when: `_case_0282_fishing_sounds` in `src/tools/input_v1.gd`: a minigame driven through intents plays the hit for a press in the zone, the miss for one outside it and the catch on landing; a crafted legendary bite landed plays the fanfare and not the catch (`Audio.last_played()`)
  - done when: `gen_sfx.py --report` and `gen_music.py --report` numbers for the new sounds are in the journal

### 0220 - The technology tree by season

Waits on 0219, 0149.  Likely files: `src/core/game_data.gd, src/core/tech.gd, src/core/calendar.gd, src/ui/tech_panel.gd, src/ui/names.gd, assets/locale/strings.csv, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Each season opens a new floor of the tree, so summer's essence buys something spring could not and the tree grows with the year instead of being finished in the first fortnight (plan section 7).

- `TECH_TREE` rows gain a `season` (0 spring to 3 winter, the calendar of 0149). Today's twelve nodes are spring's floor; summer, autumn and winter each add one node per branch (production, defence, survival) - nine new nodes with notes
- The gate is the seasons the run has reached, not the season it is in: a winter node stays available in Year 2's spring. Put that question in one pure helper beside 0149's, e.g. `Calendar.season_reached(state, season)` (every season from Year 2 on) - 0233 and 0234 reuse it. `Tech.why_not_buy` refuses an unreached season with a new key (e.g. `WHY_NOT_YET_SEASON` and the season name, a `strings.csv` row in both languages), checked before the price
- Every new node gives a number a system already reads, or a new `Tech.bonus` key read by the one system that owns it. `Tech.bonus` returns the first owned node that gives a key, so a later tier improving an existing key needs a rule (best value wins, or a key of its own): decide, write it in `tech.gd` and assert it
- Price it the way task 0063 did: every node reachable in a year, not all of them, against `Tech.total_available()` over the calendar (0150); the arithmetic goes in the journal
- Leave the powers to 0233, which adds one survival node per season from summer; nothing here gives a power
- `tech_panel.gd` pages the tree by season (keyboard, mouse and pad), greys an unreached season with its reason and still fits 480x270. `Names.KEYS`, `Names.NOTES` and `TECH_*`/`TECHNOTE_*` rows in `assets/locale/strings.csv` for every new node, in both languages
- A `GameData.validate()` rule: every `season` is 0-3, `needs` never points at a later season, and each branch has a node in every season. DATA moves on purpose (the tree is in `GameData.digest()`): record it. SIM must not move - no state key is added and the determinism scenario buys nothing

  - done when: `_task_0220_tree_seasons` in `src/tools/headless_v1.gd` asserts a summer node is refused in spring with the season reason, is buyable once summer is reached and still in Year 2's spring, and the stacking rule for a repeated bonus key holds
  - done when: `_case_0220_tree_pages` in `src/tools/input_v1.gd` pages to summer and buys a node with the keyboard and with the pad
  - done when: `python tools/shot.py 0220` captures of the tree in spring and in autumn, opened and looked at: no node cut off, no two labels on top of each other

### 0221 - What the night leaves behind

Waits on 0219, 0152.  Likely files: `src/core/combat.gd, src/core/loot.gd (new), src/core/phases.gd, src/core/player.gd, src/core/state.gd, src/core/game_data.gd, src/core/tech.gd, src/ui/names.gd, src/ui/world_view.gd, src/ui/result_screen.gd, assets/locale/strings.csv, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

The night leaves something for the morning: bones where zombies fell and, after a Full Moon, moon stones along the road the horde came by - picked up on the morning round and worth money, essence or fertiliser (plan sections 3.3 and 4.6).

- Loot is a RUN_DATA dictionary (cell index -> {item: count}) listed in `State.RUN_DATA` and adopted through an `initial()` (a small `src/core/loot.gd`). It is not an occupant - nothing walks round it or builds on it - and it survives `Farm.clear_rubble` at `begin_day`. Never name a key `moon_phase`
- Bones drop in `Combat._kill` on the cell the enemy died on: a per-kind count in `ENEMIES` (`bones`, LEVER 0-6, the Giant more; a row without `bones` drops none, so the enemies of phase 14 opt in), piled per cell up to a cap LEVER, no RNG. Survivors that walk off at dawn drop nothing. A pile on a cell the farmer cannot stand on (a wall, water) goes to the nearest walkable cell by a fixed rule - decide and assert
- Moon stones: the morning after a Full Moon night (0152), a LEVER number (2-8) lies on cells of the horde's route - e.g. every Kth cell of the flow field from tonight's spawn regions toward the house - chosen deterministically or from a fresh `(seed, day)` stream like `Endless._stream_for`, never the run stream
- Picked up by day only, when the farmer steps onto the cell in `Player.tick` (no verb, no tool); the pile goes into the ledger and the cell is cleared. Uncollected loot stays, or fades after a LEVER of days - decide and say so
- `bones` and `moon_stone` are resources: `RESOURCES`, `SELL_PRICE`, a leftovers group in `RESOURCE_GROUPS`, `Names.KEYS` (`ITEM_BONES`, `ITEM_MOON_STONE`) and both languages. Moon stones sell at the stall or trade for essence by day at a LEVER rate through one core function (e.g. `Tech.trade_moon_stones`), offered where an input path already exists - a button in the tech panel, or a station recipe through the workshop panel if `check_chain` can value essence (a recipe needs its `REC_*` key). Every new constant goes into `GameData.digest()` (0112's coverage assert) and `validate()` refuses a cap, a stone count or a rate of zero
- The morning report's leftovers line (0138) says what is lying on the farm: N bones, M moon stones to collect
- Drawn through the placeholder road until A036 is integrated by 0235: a code-drawn bone pile and a moon stone with a 2-frame shimmer (the glow is code, view only)
- SIM moves on purpose (drops in `_kill`, a new state key) and DATA moves (new resources and prices): record both

  - done when: `_task_0221_night_loot` in `src/tools/headless_v1.gd` asserts a killed walker leaves its bones on its cell, the pile survives `begin_day`, stepping on it by day collects it and at night does not, a Full Moon morning lays its stones on the same cells for the same seed, and a traded stone pays the essence LEVER
  - done when: `_case_0221_collect` in `src/tools/input_v1.gd` walks the farmer over a bone pile and sees the count rise, then trades a moon stone for essence through the panel that offers it
  - done when: `python tools/shot.py 0221` morning captures show the piles on the road, opened and looked at

### 0224 - The scarecrow decoy

Waits on 0218, 0132.  Likely files: `src/core/game_data.gd, src/core/pathing.gd, src/core/enemies.gd, src/ui/names.gd, src/ui/describe.gd, assets/locale/strings.csv, src/tools/perf_check.gd, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

A straw figure that pulls nearby zombies off their road and takes their blows while the towers work - the first defence that changes where the horde goes without walling it in.

- Id `decoy` (not `scarecrow`, which is the porch guardian, and no crop id). A `DEFENCES` row: a cost in straw (the resource 0184 and 0193 brought in) and wood, a high `hp` LEVER (100-250), a `lure_tiles` LEVER (3-8), no `reload_ticks` (it is not a tower) and no `path_cost`, so breakers already hunt it as prey. Its `season` (0193's field on `DEFENCES`) is summer, per the plan's table, so `check_seasonal_supply` judges it right; 0234 does the gating. No `damage` either, so no `Sfx.TOWER_SOUNDS` entry: `_task_0085_night_sounds` wants a sound exactly when a defence has `damage`
- The lure rule: a lure field registered in 0218's `Pathing` registry, swept from decoy cells and built only while a decoy stands. An enemy whose `ENEMIES` row says it can be lured (a new flag: walker and runner yes, bosses never; decide the tank and the breaker) and is within `lure_tiles` of a decoy by the lure field walks down that field instead of its own, and bites the decoy through `Enemies._gnaw` when it is the next cell
- When the decoy falls the lured go back to their own field the same tick. Two decoys: the nearer by the field wins, ties by `Grid.STEPS`
- `GameData.validate()`: a lure has `lure_tiles` > 0 and hit points (`check_defences`); no boss is lurable (`check_enemies`)
- Perf: a farm without decoys pays nothing for the lure field; with four decoys the rebuild stays inside `PATH_BUDGET_US`. Add decoys to perf_check's swarm scenario
- `Names.KEYS` `DEF_DECOY`, a `Describe.defence` line for the lure (a `DESC_*` key), strings in both languages; placed by cursor at night like every defence (0132)
- Drawn through the placeholder road (a code-drawn straw figure at 16x32, whole/hurt/wreck) until A037 is integrated by 0236; the hit sway is view only
- DATA moves (a new row and the lurable flags). SIM moves on purpose too if the lure field's storage keys are in a new game's state, because `State.hash_of` folds every key, cached fields included: record both numbers and why

  - done when: `_task_0224_decoy` in `src/tools/headless_v1.gd` asserts a walker within `lure_tiles` walks to the decoy and bites it while one beyond walks on to the house, a runner is lured, the Giant is not, and the lured return to the road the tick the decoy falls
  - done when: `_case_0224_decoy` in `src/tools/input_v1.gd` places a decoy with the cursor at night
  - done when: `python tools/perf.py` passes with decoys in the swarm, and a `shot.gd` scenario of a lured crowd, captured with `python tools/shot.py 0224`, is opened and looked at

### 0226 - The beehive

Waits on 0218, 0132, 0168.  Likely files: `src/core/game_data.gd, src/core/towers.gd, src/core/combat.gd, src/core/phases.gd, src/core/building.gd, src/core/state.gd, src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/headless_v1.gd`.

Bees sting what comes near and keep stinging, and the hive is as strong as the sunflowers around it - a defence that asks for a field to be planted beside it (plan section 5).

- Id `beehive`: a `DEFENCES` row with `reload_ticks` (so `Towers` collects it), a short `range`, a cost in wood and sunflowers, `season` summer (0193's field), and a sting - damage over time refreshed, never stacked, the way `Combat.set_alight` works. Either generalise `burning` to carry a damage type (fire must stay fire for 0256's rain; an entry saved without a type reads as fire, so no version bump) or add a sibling RUN_DATA table ticked in sorted id order in `Combat.tick`; decide and say which
- The row has a `damage` (the sting's per-hit number), so `_task_0085_night_sounds` wants a `Sfx.TOWER_SOUNDS` entry: map `beehive` to the nearest generated sound (e.g. `sfx/flame`) until 0283 gives it a buzz
- Strength from sunflowers, worked out once at `Phases.begin_night` and written on the occupant (no `Farm.touch`): growing sunflower plots within N tiles (`Farming.crop_on`, LEVER 2-4) raise the sting; when too few grow - autumn and winter - the hive takes sunflowers from the stock instead (LEVER per hive per night). Decide the curve and write it in the journal; a hive with neither still stings, weakly
- `TOWER_LEVELS` 1-2 for `beehive`. `Building.why_not_upgrade` only checks `TOP_TOWER_LEVEL`, so a family with fewer rows can be upgraded past its last one: refuse that, for every family
- `check_defences` accepts a sting (damage and ticks above zero) and refuses a sting with either at zero; the sunflower radius and per-night stock LEVERs are checked above zero too
- `Names.KEYS` `DEF_BEEHIVE`, a `Describe.defence` line (the sting, the sunflowers), strings in both languages; drawn through the placeholder road (a tinted 32x48 tower per level and state, an 8x8 bee swarm) until A038 is integrated by 0237
- SIM and DATA move on purpose: record both

  - done when: `_task_0226_beehive` in `src/tools/headless_v1.gd` asserts the sting refreshes rather than stacks, a hive among growing sunflowers outdoes one without, a hive with stocked sunflowers takes them at `begin_night`, and a two-level family refuses a third upgrade
  - done when: The Deliverables table of `implementation/backlog/packs/A038-beehive.md` states the final geometry this task settled (levels 1-2, the states, the swarm)
  - done when: `python tools/shot.py 0226` captures of a hive at work beside a sunflower bed at night, opened and looked at

### 0228 - The garlic braid

Waits on 0218, 0132, 0168.  Likely files: `src/core/game_data.gd, src/core/pathing.gd, src/core/enemies.gd, src/core/phases.gd, src/ui/names.gd, src/ui/describe.gd, assets/locale/strings.csv, src/tools/perf_check.gd, src/tools/headless_v1.gd`.

Hung on a post, it makes the ground around it somewhere zombies would rather walk round, and slows the ones that come through anyway (plan sections 3.1 and 5).

- Id `garlic_braid` (never `garlic`, the crop), paid in garlic and a little wood, `season` autumn (0193's field, per the plan's table). Walkable like a trap through the `walkable` flag 0225 puts on `DEFENCES` (add it here if 0225 has not landed): `Pathing._through` gives it the ground's cost and `Pathing.is_prey` leaves it out (today a defence with no `path_cost` is prey); it is not `one_shot`, so `Traps` never sees it. No `damage`, so no `Sfx.TOWER_SOUNDS` entry
- Repelling is a cost: cells within N tiles (LEVER 1-3) cost a LEVER more in `Pathing._entry_costs`, in the shared and the open field, never more than one braid's worth however many overlap. Every step stays within `WIDEST_STEP` (32): extend `check_pathing` to add the garlic extra to the worst terrain and the worst `path_cost`
- Slowing: inside the area an enemy walks at a percent of its speed (LEVER) in `Enemies._walk`, worked out like `Ability.slowed_ticks`; with a flare too, the stronger of the two applies, not both. Build the area as a per-cell array with the field (the pass over the occupants is already there) so `_walk` reads one entry, never a search per zombie per tick
- It wears out: full strength the first night, wilted (a LEVER share) the second, spent after - kept on the occupant, moved on at `Phases.begin_night`. The strength is part of the path costs, so a night that changes any braid bumps the grid once (`Farm.touch`) and the fields rebuild; the no-touch rule is for per-tick status. A spent braid does nothing and stays until sold, or goes (decide). The states match A040: fresh, wilted, spent
- Perf: the area cost is part of `_entry_costs`, so measure `path_refresh` with ten braids; it stays inside `PATH_BUDGET_US`
- `Names.KEYS` `DEF_GARLIC_BRAID`, a `Describe.defence` line, strings in both languages; drawn through the placeholder road (16x24, fresh/wilted/spent) until A040 is integrated by 0239
- SIM and DATA: record both

  - done when: `_task_0228_garlic` in `src/tools/headless_v1.gd` asserts a route with a cheap way round avoids the braid, a crowd forced through walks at the LEVER's speed, the braid wilts and is spent on the nights it says (driven through `Phases.begin_night`, not whole played nights), and `GameData.validate()` refuses a garlic extra that would pass `WIDEST_STEP`
  - done when: The Deliverables table of `implementation/backlog/packs/A040-garlic-braid.md` states the final geometry this task settled
  - done when: `python tools/shot.py 0228` captures of the route bending round a braid (0130's camera hook), opened and looked at

### 0238 - Art: the pumpkin catapult

Waits on 0227.  Likely files: `assets/art_source/defences/, assets/art_source/effects/, assets/art_source/manifest.json, tools/check_tower_art.py, tools/check_effect_art.py, tools/import_art.py`.

The approved catapult, its pumpkin and its splat replace the stand-ins 0227 left.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A039` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A039-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/defences/` and `assets/art_source/effects/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_tower_art.py` `FAMILIES`, `check_effect_art.py`, `ArtPlacement` if needed).
- `buildings/catapult`, `catapult_2` and `catapult_3` x the four states at 32x48 with `muzzle_xy`/`muzzles_xy` on opaque pixels; the `tower` metadata in `import_art.py` for this pack; the per-family checks 0237 made in `check_tower_art.py` (if 0237 has not landed, make them here), with `gen_sprites.migrated_towers()` still the four legacy families
- The pumpkin shot (8x8) drawn where the view draws a mortar shell, and the splat (4 frames, one-shot) as an effect family in `check_effect_art.py` - its own checked block, leaving task 0017's count of 25 frames alone
- Retire 0227's stand-ins from 0120's placeholder registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A039 integrated`.

  - done when: The family checks (`check_tower_art.py`, `check_effect_art.py`) and the showcase (`python tools/show_art.py --towers --check` and `python tools/show_art.py --effects --check`) pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of each level firing and a pumpkin landing in the real game, opened and looked at, in `implementation/shots/0238/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0241 - Art: the electric fence

Waits on 0230.  Likely files: `assets/art_source/defences/, assets/art_source/effects/, assets/art_source/manifest.json, tools/check_barrier_art.py, tools/check_effect_art.py`.

The approved electric fence, joined on all sixteen masks, and its zap replace the stand-ins 0230 left.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A042` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A042-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/defences/` and `assets/art_source/effects/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_barrier_art.py`, `check_effect_art.py`, `ArtPlacement` if needed).
- Source modules `buildings/modules/electric_fence_{post,horizontal,vertical}` (and `_hurt`) composed into `electric_fence_join_<mask>` for the 16 N1/E2/S4/W8 masks and `_hurt`, plus `_wreck`, at 16x32 / (8,28) like the fence. `check_barrier_art.py` checks `('wall', 'fence')` and 84 entries of task 0014: add the family and its count
- `WorldView.connected_barrier` reads the `connected` flag the importer writes from `join_mask`, so the joined art replaces 0230's placeholder joins with no view change - check it. The zap (3 frames, one-shot) is an effect family played when the stun lands, its own checked block in `check_effect_art.py` beside task 0017's 25 frames
- Retire 0230's stand-ins from 0120's placeholder registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A042 integrated`.

  - done when: The family checks (`check_barrier_art.py`, `check_effect_art.py`) and the showcase (`python tools/show_art.py --barriers --check` and `python tools/show_art.py --effects --check`) pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of a joined run of electric fence zapping a biter in the real game, opened and looked at, in `implementation/shots/0241/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0247 - The spitter

Waits on 0218, 0132.  Likely files: `src/core/enemies.gd, src/core/game_data.gd, src/ui/world_view.gd, src/ui/describe.gd, src/ui/names.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd`.

The first enemy that hurts what you built without touching it: it stops at range and spits at a tower. A tower line in the open becomes something to cover, not only something to build.

- `ENEMIES.spitter` with `# LEVER`s: hp, `ticks_per_tile`, damage to the house, reward, `spit_range` (tiles, 3-5), `spit_damage` (to a structure), `spit_every_ticks`, `spit_tiles_per_second`; `check_enemies` refuses a spit range of zero or one that reaches as far as the gun tower's base `range` (5), so a tower can always answer it. Keep it inside `_task_0051_tank`'s non-boss bounds (less hp and armour than the tank, faster than it) and `_task_0058_giant`'s
- In `Enemies._walk`: with a tower (a DEFENCES entry with `reload_ticks`) within `spit_range` - Chebyshev, nearest first, ties by the lower cell index - it stands and spits; with none it walks the flow field and bites like a walker
- Enemy projectiles are new and kept apart from the towers' `projectiles`, which `Combat.incoming` and `worth_shooting` read: a top-level `enemy_shots` Array (only Dictionaries need a TABLES/RUN_DATA line), integer positions, aimed at a cell when fired, landing through `Farm.damage` after its flight
- Advance them inside `Enemies.tick` so `PerfNames.NIGHT` stays true; if a new `X.tick` goes into `Sim._tick_night` instead, add it to `src/tools/perf_names.gd` and `perf_check.gd` in this task
- `Enemies.withdraw` clears `enemy_shots` at dawn; a spit landing on an empty cell does nothing; a tower it destroys leaves rubble and a `structure_lost` event like a bite
- Names.KEYS `spitter`, rows `ENEMY_SPITTER` and `ENEMY_SPITTER.other` (spitter/spitters, cuspidor/cuspidores) and a `Describe.enemy` line `DESC_SPITS` ('spits at towers from %d tiles' / 'cospe nas torres a %d ladrilhos'); `Sfx.ENEMY_SOUNDS.spitter` borrows the nearest generated voice (`sfx/groan_walker`) so `_task_0085_night_sounds` passes, until 0284 gives it its own
- On screen through 0120's placeholder road: the spitter at 64x48 pivot (32,44), the spit in flight (8x8) and a code-drawn splat, plus its forecast head - placeholders until A046 is integrated by 0260
- The first kind past the MVP's five breaks the art groups that count `ENEMIES`: rewrite in place `_task_0074_zombie_art` (`kinds.size() == 5`, a file per pose, the silhouette and biggest-Giant tests) and `_task_0088_juice` (a death body per kind) to check the kinds with raster art, leaving stand-ins to 0120's `_task_0120_placeholders`; `_case_0074_zombie_art` in `input_check.gd` counts a stand-in through 0120's lookup as drawn. If `_task_0059_wave_data` still wants every `ENEMIES` kind in the authored nights, exempt the kinds no night sends yet in one named list (0270-0274 put them in the year). Later enemy tasks only add to what this leaves
- Hashes: DATA moves (a new ENEMIES entry); SIM moves once, because the state gains `enemy_shots` - nothing else in the determinism scenario may change, and the journal says so

  - done when: `_task_0247_spitter` in `src/tools/headless_v1.gd`: with a gun tower inside `spit_range` it stops and lands `spit_damage` every `spit_every_ticks` (measured); with none it walks to the house; two runs of one seed land the same spits on the same ticks; nothing is left in `enemy_shots` after dawn
  - done when: The same group: a tower whose reach covers it kills it before losing the tower, and a tower that cannot reach it is worn down - print both numbers
  - done when: `python tools/shot.py 0247 spitter` (a new scenario: a spitter working on a tower line) opened and looked at; the rewritten `_task_0074_zombie_art`, `_task_0088_juice` and `_case_0074_zombie_art` pass with the spitter on its stand-in
  - done when: the Deliverables table of `implementation/backlog/packs/A046-spitter.md` states the final geometry this task settled

### 0248 - The rat swarm

Waits on 0218, 0132.  Likely files: `src/core/game_data.gd, src/core/waves.gd, src/core/enemies.gd, src/tools/perf_check.gd, tools/perf_baseline.txt, src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd`.

A crowd of small fast bodies that a single-target tower wastes shots on and a mine or a flame cone eats. It is also the perf case the groundwork of 0218 was built for.

- `ENEMIES.rat` with `# LEVER`s: hp 2-6, `ticks_per_tile` 10-14, damage 1-2, reward 1, armour 0, `cluster` (rats per spawn, 4-10; `check_enemies` refuses a `cluster` below 1); a swarm must not out-earn a day - check the night's bounty against 0219's levers
- `check_enemies` wants every `ignores_structures` kind faster than the fastest kind that stops for walls (the runner, 9 ticks a tile): a rat that stops for walls at 9 or less would fail the runner, so keep it at 10-14 or make it go round like one - decide, and never weaken the check to pass
- Clusters: a wave record still counts bodies, so the forecast and `Waves.size_of` stay true; `Waves.tick` releases up to `cluster` per `SPAWN_INTERVAL_TICKS`, the first on a cell from the run RNG as today (`Enemies.spawn`) and the rest through `Entities.spawn` on that cell's walkable, reachable neighbours in `Enemies.NEIGHBOURS` order (four of them), then back round onto the same cells - bodies may share a cell, as they already can - with no extra draws
- Mines and fire are the answer by construction: a gun tower overkills a rat, a mine's splash and the flamethrower cone take many. Put the cost per rat killed for the gun tower, the crossbow, the mine and the flamethrower in the journal
- Perf through 0218's caches: 0218's swarm scenario in `src/tools/perf_check.gd` swaps its walker stand-ins for rats (a few hundred alive); its `swarm_tick`, `swarm_towers` and `swarm_enemies` lines stay inside `TICK_BUDGET_US` (8333 us); a moved baseline is accepted (`python tools/perf.py --accept`) only with the journal saying why
- Names.KEYS `rat`, `ENEMY_RAT`/`ENEMY_RAT.other` (rat/rats, rato/ratos), and `DESC_SWARMS` ('comes %d at a time' / 'chega %d de cada vez') in `Describe.enemy`; `Sfx.ENEMY_SOUNDS.rat` borrows `sfx/groan_runner` until 0284
- Drawn through 0120's placeholder road at the pack's small canvas (~24x16), forecast head included - placeholders until A047 is integrated by 0261
- Hashes: DATA moves; SIM should not (no rats in the determinism night) - if it does, find out why before accepting

  - done when: `_task_0248_rats` in `src/tools/headless_v1.gd`: one wave member releases `cluster` rats on adjacent cells on one tick, the bodies sent match `Waves.size_of`, and a mine under the cluster kills more rats per unit of cost than a gun tower in the same lane
  - done when: `python tools/perf.py --report` prints the swarm lines with rats inside `TICK_BUDGET_US` and every other line inside its tolerance
  - done when: `python tools/shot.py 0248 rats` (a new scenario) opened and looked at: a cluster reads as a crowd, not a smear
  - done when: the Deliverables table of `implementation/backlog/packs/A047-rats.md` states the final geometry this task settled

### 0251 - The frost zombie

Waits on 0218.  Likely files: `src/core/combat.gd, src/core/towers.gd, src/core/enemies.gd, src/core/game_data.gd, src/ui/world_view.gd, src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd`.

An enemy whose death is the attack: it bursts into ice and the towers near it reload slowly for a while. Killing it right under the line now costs something.

- `ENEMIES.frost_zombie` with `# LEVER`s (hp, `ticks_per_tile`, damage, reward, armour; inside `_task_0051_tank`'s non-boss bounds) plus `chill_tiles` (radius, 1-3), `chill_ticks` and `chill_reload_percent` (reload speed while chilled, 25-75: fifty is twice as slow); `check_enemies` refuses a chill field of zero or a percent outside 1-99
- The hook is `Combat._kill`: every tower within `chill_tiles` (Chebyshev, from `Towers`' cached tower cells, sorted) gets a countdown on its occupant dictionary (`tower["chill"]`) - never through `Farm.touch`, so `grid_version` and every field stay put
- Refreshed, never stacked (the `Combat.set_alight` rule); `Towers.tick` and `_cool_down` count it down; while it lasts the reload set after a shot is scaled by `chill_reload_percent` in integers
- No chill outlives the night: cleared in `Enemies.withdraw`, which `Phases.begin_day` already calls; a save made mid-night keeps it, since occupants are RUN_DATA
- `Towers.chill_left(state, cell)` for the view and for the Winter Lord, whose freeze (0255) sits beside this chill
- Names.KEYS `frost_zombie`, `ENEMY_FROST_ZOMBIE`/`.other` (frost zombie/frost zombies, zumbi de gelo/zumbis de gelo); `DESC_CHILLS` ('slows towers when it dies' / 'deixa as torres lentas ao morrer'); `Sfx.ENEMY_SOUNDS.frost_zombie` borrows `sfx/groan_tank` until 0284
- On screen through 0120's placeholder road: the zombie, a code-drawn ice burst on death, a frost tint on chilled towers (view only) and its forecast head, until A050 is integrated by 0264
- Hashes: DATA moves; SIM should not

  - done when: `_task_0251_frost` in `src/tools/headless_v1.gd`: one killed beside two towers makes their next reload `chill_reload_percent` slower for exactly `chill_ticks`, a tower outside `chill_tiles` is untouched, `grid_version` does not move, and the chill is gone the next morning
  - done when: Two deaths beside one tower refresh rather than stack - asserted on the reload number
  - done when: `python tools/shot.py 0251 frost` (a new scenario) opened and looked at: a chilled tower is visibly different
  - done when: the Deliverables table of `implementation/backlog/packs/A050-frost-zombie.md` states the final geometry this task settled

### 0285 - Music for four seasons

Waits on 0160, 0282.  Likely files: `tools/gen_music.py, assets/music/, src/ui/music.gd, src/app/audio.gd, src/ui/main.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

The two MVP pieces become a year: a day piece per season on the shared motif, a winter night, a boss track and the credits, each crossfading on the moment it belongs to. View only: neither hash moves.

- `tools/gen_music.py` adds day pieces for summer, autumn and winter beside today's `farm`, which becomes spring (keep its id or rename it and every reader in the same pass), a winter night beside `night`, a boss track and the credits. All read `MOTIF` at the one `BPM = 75` - a crossfade between two tempos is a stumble, as the module says - and each season gets its own scale, register and density
- Every looping piece gets the seam the module already builds (`snap()`, `wrapped()` tails) and runs longer than 15 s. The credits play once, as long as 0160's roll; they and the cues (`sting` and 0282's fanfare; 0286 adds its event stingers to the same list later) are named as not-loops rather than excused from the seam check in bulk. `Audio.play_music` loops whatever it plays (`_looping` sets the shared stream's loop mode), so the credits need a play-once road in `src/app/audio.gd`
- `Music.piece_for` stays static and askable and gains what it now needs: the season (0149's calendar) and whether tonight is a boss night (0153). Day plays that season's piece; the build step, the night and the morning report play the night piece (the winter one in winter); a boss night plays the boss track; a menu keeps the spring piece behind `audio/music_in_menus`
- Crossfades use the one length there is (`fade_seconds()`, the transition's): the season turns on the first morning of the new season, the boss track arrives with a boss night's build step and leaves at dawn, the credits take over on 0160's ending screen. Decide whether `layer_for`'s urgent layer plays over the boss track, and say why
- Size: a 96 s piece is about 4.2 MB of WAV in the repository and about 0.85 MB of QOA in the pack, and `tools/release.py` holds the Web pack to `PACK_BUDGET` (3.5 MB gzipped, 2.31 MB at task 0100). Measure before and after, prefer shorter loops for the new pieces, and if the budget must move, move it on purpose with both numbers in the journal. Time matters too: `tools/verify.py` runs `gen_music.py --check`, which renders every piece (about 13 s for today's four) - put its time before and after in the journal
- Rewrite `_task_0086_music` in `headless_check.gd` for the new `piece_for` and the new list: its seam, motif and one-tempo checks cover every looping piece

  - done when: `_task_0285_season_music` in `src/tools/headless_v1.gd`: `piece_for` answers right for each season and phase, a boss night, and a menu with the setting off and on; every looping piece's `_loop_seam` ratio is at most 1.0 and its length over 15 s; every arrangement reads `MOTIF`
  - done when: `_case_0285_season_music` in `src/tools/input_v1.gd`: a real run moved to a summer morning is playing the summer piece once the fade is over (`Audio.music_playing()`), and a boss night's build step the boss track
  - done when: The Web pack size before and after (`python tools/release.py`, or why it could not be measured) and `python tools/gen_music.py --report` lengths and seams are in the journal

### 0222 - Bone meal

Waits on 0221, 0165.  Likely files: `src/core/game_data.gd, src/core/farming.gd, src/core/interact.gd, src/ui/day_hud.gd, src/ui/sfx.gd, src/ui/names.gd, src/ui/world_view.gd, assets/locale/strings.csv, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Bones go back into the ground: ground into bone meal, they give a plot one day of growth for free, once - the night paying for the day.

- A recipe (e.g. `grind_bone_meal`, at the workshop or 0188's mill) turns bones into `bone_meal`, a new resource with a price, a group, `Names.KEYS` (`ITEM_BONE_MEAL`, its `REC_*`) and both languages; `check_chain` holds (bone meal is worth more than its bones)
- Fertilising: with bone meal selected in the day HUD's strip beside the seeds (keyboard, mouse and pad), interact on a tilled plot spends one and marks the plot `fertilised` - a new field on the plot in `state["plots"]` (RUN_DATA), read with a default so old saves' plots need no migration and no `State.VERSION` bump. If it is a new verb (e.g. `fertilise` in `Farming.verb_at`), it goes in `Interact.DAY_ONLY` and `DEFAULT_TICKS`, and `Sfx.VERB_SOUNDS` maps it to the nearest generated sound (`sfx/plant`) so `_task_0084_day_sounds` stays green until 0281 gives it its own
- The rule: at the next morning's growth credit (0165) a fertilised plot grows one extra day, once, and the mark clears. Decide and assert whether it must also have been watered; it never gets round a regrowth (0172) or winter (0171) rule
- A fertilised plot not yet planted keeps the mark until it is; harvesting clears it
- The soil marker is drawn through the placeholder road (a tinted tilled tile, dry and wet) until A036 is integrated by 0235
- SIM and DATA move on purpose: record both

  - done when: `_task_0222_bone_meal` in `src/tools/headless_v1.gd` asserts two plots of one crop planted together, one of them fertilised, finish exactly one day apart, and a second morning grants nothing extra - driving 0165's morning credit directly rather than simulating whole days, which the 120 s suite budget cannot afford
  - done when: `_case_0222_fertilise` in `src/tools/input_v1.gd` selects bone meal and fertilises a plot with the keyboard
  - done when: The Deliverables table of `implementation/backlog/packs/A036-night-loot.md` states the final geometry this task settled (the pickups, the fertilised soil, the four icons)
  - done when: `python tools/shot.py 0222` captures of a fertilised plot dry and wet, opened and looked at

### 0225 - Zombie bait

Waits on 0224, 0179.  Likely files: `src/core/game_data.gd, src/core/pathing.gd, src/core/enemies.gd, src/core/building.gd, src/ui/names.gd, src/ui/describe.gd, assets/locale/strings.csv, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Rotten fish made by day and thrown down at night: for a few seconds the whole crowd around it turns toward it - the pond paying into the night (plan section 3.2).

- Id `zombie_bait`: a recipe at the kitchen (or the press) turns fish into a bait kit, through 0179's rule that a recipe taking `fish` accepts any species; the kit's inputs equal the `DEFENCES` cost, as `check_recipes` demands. 0179's fish group is understood by `Crafting`, not by `Resources.pay`: either the bait goes down from a kit only (the ledger road refused with a reason) or its `cost` names a real resource - decide. Its `season` (0193's field) is summer, as 0234's table says
- It reuses 0224's lure rule and lurable flags, with a wider `lure_tiles` LEVER (6-14). Decide how one lure field honours two reaches (each source seeded with its own head start, or the bait as a second registered field) and keep 'the nearer by the field wins'
- Walkable like a mine: a `walkable` flag on the `DEFENCES` row that `Pathing._through` (the ground's cost) and `Pathing.is_prey` (left out) both read, so nothing breaks through it and breakers do not hunt it. 0228's garlic braid uses the same flag - if 0228 landed first, reuse it. `check_defences` refuses a walkable row with a `path_cost`
- Consumed: it lasts `lifetime_ticks` (LEVER, 5-20 s) and goes when that runs out or when a LEVER number of zombies have reached it, whichever is first; it leaves no rubble
- A per-night limit LEVER like the barricade's, read through `Building.left_tonight` - which today adds the tree's `barricade_bonus` to every `per_night_limit`: make that the barricade's alone, or decide the bait shares it, and assert which
- `Names.KEYS` (`DEF_ZOMBIE_BAIT`, its `REC_*`), a `Describe.defence` line, strings in both languages; no `damage`, so no `Sfx.TOWER_SOUNDS` entry; drawn through the placeholder road (a 16x16 fish on the ground and its icon) until A037 is integrated by 0236
- DATA moves (a row and a recipe); SIM moves only if a state key is added or the determinism scenario meets a bait - record which

  - done when: `_task_0225_bait` in `src/tools/headless_v1.gd` asserts a crowd beyond any decoy's reach turns toward the bait, the bait goes at its lifetime or its arrival count, and the crowd is back on its road the same tick
  - done when: `_case_0225_bait` in `src/tools/input_v1.gd` makes a bait by day and places it with the cursor at night
  - done when: The Deliverables table of `implementation/backlog/packs/A037-decoy.md` states the final geometry this task settled (decoy states and sway frames, the bait on the ground, its icon)

### 0229 - The searchlight

Waits on 0196, 0132, 0226.  Likely files: `src/core/light.gd (new), src/core/game_data.gd, src/core/towers.gd, src/core/ability.gd, src/core/combat.gd, src/ui/lighting.gd, src/ui/names.gd, src/ui/describe.gd, assets/locale/strings.csv, src/tools/headless_check.gd, src/tools/headless_v1.gd`.

A powered lamp that lights the ground around it and lets the towers in its light see a tile further - and the moment light becomes a rule that the wraith and the fog will read (plan section 5).

- Id `searchlight`: a `DEFENCES` row with no `reload_ticks` (it does not shoot) and no `damage` (so no `Sfx.TOWER_SOUNDS` entry), an `energy_draw`, a `light_tiles` LEVER (3-6), a cost in iron and copper (0176) and `season` winter (0193's field). Breakers hunt it like anything built. `check_defences` refuses a light with `light_tiles` of zero; a new constant (the porch radius, the reach bonus) goes into `GameData.digest()`
- Light is a core rule in one place (e.g. `src/core/light.gd`): `Light.is_lit(state, cell)` is true on searchlight cells, in the flare's area while it burns (`Ability.flare_at`), on the cells of burning enemies (`Combat.is_burning`) and on the porch (a LEVER radius round the house door). 0252 and 0256 read it; `lighting.gd` may draw from it, never the other way round
- Searchlight cells are cached against `grid_version`, like `Towers._towers` (new state keys: SIM moves; a Dictionary cache goes in `State.TABLES` or `RUN_DATA`); the flare and the fires are asked fresh. `Light` is asked, never ticked - if it grows a `tick`, it goes in `PerfNames` and `perf_check`
- A tower standing in light reaches +1 (LEVER): `Towers.reach_of` learns the tower's cell (or `_acquire` passes it) - move every caller: `_acquire` (0218's bucketed version), `acquire_for`, the old asserts that call `reach_of` in `headless_check.gd`, and any range drawing the view gained (0131's cursor)
- Needs power, degraded never dead like the rest of `Power`: on a short farm the light shrinks (e.g. by a tile) instead of going out; decide and assert
- `TOWER_LEVELS` 1-2 for `searchlight` (a wider light), refused past its last row by 0226's fix to `Building.why_not_upgrade`
- `Names.KEYS` `DEF_SEARCHLIGHT`, a `Describe.defence` line, strings in both languages; drawn through the placeholder road (32x48 per level and state, a `light_xy` point) with the beam in code, until A041 is integrated by 0240
- SIM and DATA: record both

  - done when: `_task_0229_light` in `src/tools/headless_v1.gd` asserts the lit cells of each source (a searchlight, the flare, a burning zombie, the porch), a gun tower in light acquiring one tile further than one in the dark, a short farm shrinking the light, and the cache rebuilding when a searchlight goes up or comes down
  - done when: The Deliverables table of `implementation/backlog/packs/A041-searchlight.md` states the final geometry this task settled
  - done when: `python tools/shot.py 0229` captures of a lit and an unlit tower line at night, opened and looked at

### 0231 - Hardwood walls and sandbags

Waits on 0196, 0177, 0188, 0132, 0226.  Likely files: `src/core/game_data.gd, src/core/building.gd, src/core/pathing.gd, src/core/repair.gd, src/ui/world_view.gd, src/ui/names.gd, src/ui/describe.gd, assets/locale/strings.csv, src/tools/headless_v1.gd`.

Two more ways to hold a line: the stone wall upgraded with hardwood into something a breaker has to work at, and sandbags from the loom as a cheap barrier that soaks more than a fence (plan sections 3.3 and 3.5).

- A `TOWER_LEVELS` row for `wall`: level 2 paid in hardwood (0177), more `hp` and `path_cost`, upgraded by cursor like a tower (0226's fix refuses a third level). `Building.entry_at` already lays a level over any id, but the field does not read it: `Pathing._through` prices an occupant from `Building.entry_of` (the base row), so `_entry_costs` must price a levelled occupant from its levelled entry, and `check_pathing` must read `TOWER_LEVELS`' `path_cost` too, so the level stays within `WIDEST_STEP`
- Sandbags: 0188 planned `SANDBAG` as a material (read what it actually made). A material means the barrier gets its own id (e.g. `sandbag_wall`) paid in sandbags, because `Names.KEYS` is keyed by id; if 0188 made a kit instead, it becomes the `DEFENCES` row that kit places. Its `hp` and `path_cost` LEVERs sit between the fence and the wall, and its `season` (0193's field) is decided here and confirmed by 0234. Neither has `damage`, so no `Sfx.TOWER_SOUNDS` entry
- A level-2 wall mends to its levelled HP (0113) and costs what that level is made of - assert it
- Joins: `WorldView.barrier_mask` decides who meets whom - a hardwood wall joins stone walls, sandbags join sandbags (decide whether they meet walls) - and `_barrier_name` learns the wall's level
- `Names.KEYS` and strings in both languages for the new id and the upgrade; drawn through the placeholder road (level-2 wall modules for the 16 masks, whole/hurt/wreck; the sandbag pieces) until A043 is integrated by 0242
- DATA moves (a level row, a new barrier). SIM must not move for the determinism scenario's level-1 walls; if pricing levelled occupants moves it, say why - record both numbers

  - done when: `_task_0231_strong_walls` in `src/tools/headless_v1.gd` asserts a level-2 wall takes the LEVER's longer to chew through and costs the field its levelled `path_cost`, a third upgrade is refused, sandbags sit between fence and wall on hit points and path cost, and repair restores the level-2 maximum
  - done when: The Deliverables table of `implementation/backlog/packs/A043-strong-walls.md` states the final geometry this task settled (and whether sandbags are modules or one piece)
  - done when: `python tools/shot.py 0231` captures of a mixed line - stone, hardwood, sandbags - opened and looked at

### 0233 - Three new powers

Waits on 0232, 0185, 0220, 0230.  Likely files: `src/core/ability.gd, src/core/game_data.gd, src/core/enemies.gd, src/core/repair.gd, src/ui/night_hud.gd, src/ui/names.gd, src/app/input_actions.gd, project.godot, assets/locale/strings.csv, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Three more buttons for a night going wrong: the farm bell stops every zombie for two seconds, the dog runs out and bites one, and an emergency repair puts a structure back on its feet - each aimed with the cursor, each with its wait (plan section 4.4).

- Power ids `farm_bell`, `call_dog` and `emergency_repair` (not `dog`, the animal of 0185), every number a LEVER in a `GameData` table beside `ABILITY`, listed in `GameData.digest()` (0112's coverage assert) and checked by `validate()` (a cooldown above zero, a node that gives each power). Their state goes inside `state["ability"]` (`State.TABLES`, so reconcile fills old saves)
- The bell stops every zombie on the farm for 2 s (1-4) through 0230's entity stun counter; decide whether bosses stop, for less or not at all
- The dog bites the enemy nearest the aimed cell within a radius, for a LEVER damage, after a delay worked out from its distance to the house - no RNG; its run and bite are view only
- The repair restores 30% (LEVER 15-50) of the aimed structure's levelled maximum (0113), free, through one `Repair` function that `apply` also uses for the cap; decide whether the house counts. A destroyed structure is rubble and cannot be aimed at
- Own cooldowns (LEVERs), recharged at `begin_night` like the flare. Unlocked by the tree, one per season from summer: three survival rows in `TECH_TREE` with 0220's `season` gate (summer the bell, autumn the dog, winter the repair), each giving its power, priced with 0220's arithmetic (redo it in the journal with the three added); a locked power shows greyed with its node, never hidden
- Aimed with the cursor through 0232's API; an input action per power in `InputActions.ACTIONS` and `project.godot` with pad bindings (0121's sync check) and `ACT_*` strings in both languages, rebindable
- The night dog is 0185's stand-in through the placeholder road until A028 is integrated by 0245; the power icons are placeholders until A045 is integrated by 0244
- `Names.KEYS`/`NOTES` for the new nodes, `POWER_*` names and notes, strings in both languages; the night HUD shows each power's charge or lock
- SIM and DATA move on purpose: record both

  - done when: `_task_0233_powers` in `src/tools/headless_v1.gd` asserts the bell holds every walker for exactly its ticks, the dog's bite lands on the enemy nearest the aimed cell after the computed delay, the repair restores the LEVER share of a levelled tower, and each power is refused before its node is bought
  - done when: `_case_0233_powers` in `src/tools/input_v1.gd` aims and fires each power with the mouse and with the pad
  - done when: The Deliverables table of `implementation/backlog/packs/A028-dog.md` states the final geometry this task settled (the night run and bite, the scale against the farmer)

### 0237 - Art: the beehive

Waits on 0226.  Likely files: `assets/art_source/defences/, assets/art_source/effects/, assets/art_source/manifest.json, tools/check_tower_art.py, tools/check_effect_art.py, tools/import_art.py`.

The approved beehive and its bees replace the stand-ins 0226 left.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A038` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A038-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/defences/` and `assets/art_source/effects/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_tower_art.py` `FAMILIES`, `check_effect_art.py`, `ArtPlacement` if needed).
- `buildings/beehive` and `beehive_2` x {'', `_hurt`, `_fire`, `_wreck`} at 32x48, pivot (16,44), one scale per level. `check_tower_art.py` loops levels 1-3 for every family, accepts only `generation_task` 0013 and demands a `muzzle_xy` on every non-wreck state: make the level count and the metadata point per family (the hive's own point, where the swarm leaves, or none - as the pack's contract says) and accept the pack. Keep `gen_sprites.migrated_towers()` to the four legacy families (the checker compares it with `FAMILIES`). `import_art.py` writes `"tower": true` only for 0013 - extend it
- The bee swarm (8x8, 3 frames) loops while a hive stings: a looping effect, which `check_effect_art.py` (one-shots only) has to be taught deliberately
- Retire 0226's stand-ins from 0120's placeholder registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A038 integrated`.

  - done when: The family checks (`check_tower_art.py`, `check_effect_art.py`) and the showcase (`python tools/show_art.py --towers --check` and `python tools/show_art.py --effects --check`) pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of a hive at each level stinging a crowd in the real game, opened and looked at, in `implementation/shots/0237/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0239 - Art: the garlic braid

Waits on 0228.  Likely files: `assets/art_source/defences/, assets/art_source/manifest.json, tools/check_barrier_art.py, tools/verify.py`.

The approved garlic braid, fresh, wilted and spent, replaces the stand-in 0228 left.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A040` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A040-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/defences/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_barrier_art.py`, `ArtPlacement` if needed).
- `buildings/garlic_braid`, `_wilted` and `_spent` at 16x24 on the barricade's ground pivot; the wear state 0228 keeps on the occupant picks the frame
- Extend `check_barrier_art.py`'s single-piece checks (or a family checker wired into `tools/verify.py`) for the three states
- Retire 0228's stand-in from 0120's placeholder registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A040 integrated`.

  - done when: The family checks (`check_barrier_art.py`) and the showcase (`python tools/show_art.py --barriers --check`) pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of braids fresh, wilted and spent beside a route in the real game, opened and looked at, in `implementation/shots/0239/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0260 - Art: the spitter

Waits on 0247, 0246.  Likely files: `assets/art_source/enemies/spitter/, assets/art_source/effects/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_enemy_art.py, tools/gen_sprites.py, tools/check_effect_art.py, src/ui/enemy_motion.gd`.

The spitter as Codex drew it, in place of 0247's stand-in: its walk, the spit, the splat and its forecast head.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A046` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A046-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/enemies/spitter/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`gen_sprites.migrated_enemies()`, `check_enemy_art.FAMILIES` and its pinned generation task `'0015'`, the effect checker's pinned 0017 set, `EnemyMotion.FAMILIES`/`TRACKED`) with a block for this pack rather than loosening the old counts.
- Runtime names as the ordinary enemies at 64x48 pivot (32,44): `enemies/spitter`, `spitter_walk_0..3` (0.125 s, loop), `spitter_attack_0..2` (the spit), `spitter_death_0..3`, with the `_walk_b`/`_attack`/`_death` aliases; the spit (8x8, 2 frames) and the splat (3) in the effects family; the 16x16 forecast head where 0158 put the others
- Replace 0247's placeholders in 0120's registry (the leaf flips ownership to raster) and drive the attack pose from the real spit, not a bite.
- Set the pack to integrated: `python implementation/backlog/assets.py set A046 integrated`.

  - done when: `python tools/check_enemy_art.py`, `python tools/check_effect_art.py` and `python tools/show_art.py --enemies --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures in the real game by day (its head in the dusk forecast) and by night (spitting at a tower), opened and looked at, in `implementation/shots/0260/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0261 - Art: the rat swarm

Waits on 0248, 0246.  Likely files: `assets/art_source/enemies/rat/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_enemy_art.py, tools/gen_sprites.py, src/ui/enemy_motion.gd, src/ui/enemy_deaths.gd`.

The rats as Codex drew them, in place of 0248's stand-in: small enough to read as a swarm and still read as rats.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A047` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A047-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/enemies/rat/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`gen_sprites.migrated_enemies()`, `check_enemy_art.FAMILIES`, `EnemyMotion.FAMILIES`/`TRACKED`).
- The rat is not 64x48: `check_enemy_art.py` takes canvas, pivot, contact row and motion counts per family (rat: walk 4, attack 3 from the pack's bite, death 3, at the canvas 0248 settled, ~24x16) instead of asserting `[64,48]` for everyone, and `EnemyDeaths` plays three death frames for it
- Runtime names `enemies/rat`, `rat_walk_0..3`, `rat_attack_0..2`, `rat_death_0..2` with the usual aliases, and the forecast head; replace 0248's placeholders in 0120's registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A047 integrated`.

  - done when: `python tools/check_enemy_art.py` and `python tools/show_art.py --enemies --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures in the real game by day (the head in the dusk forecast) and by night (a cluster crossing a mine), opened and looked at, in `implementation/shots/0261/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0264 - Art: the frost zombie

Waits on 0251, 0246.  Likely files: `assets/art_source/enemies/frost_zombie/, assets/art_source/effects/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_enemy_art.py, tools/gen_sprites.py, tools/check_effect_art.py, src/ui/enemy_motion.gd`.

The frost zombie as Codex drew it, in place of 0251's stand-in, with the ice shattering when it dies.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A050` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A050-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/enemies/frost_zombie/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`gen_sprites.migrated_enemies()`, `check_enemy_art.FAMILIES`, the effect checker's pinned set, `EnemyMotion.FAMILIES`/`TRACKED`).
- At 64x48 pivot (32,44): `frost_zombie_walk_0..3`, `_attack_0..2`, `_death_0..3` with the usual aliases; the ice-shatter burst (4 frames, one-shot) in the effects family, played where 0251's code burst was; the forecast head
- Replace 0251's placeholders in 0120's registry; the frost tint on chilled towers stays code
- Set the pack to integrated: `python implementation/backlog/assets.py set A050 integrated`.

  - done when: `python tools/check_enemy_art.py`, `python tools/check_effect_art.py` and `python tools/show_art.py --enemies --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures in the real game by day (the head in the dusk forecast) and by night (a shatter beside a tower), opened and looked at, in `implementation/shots/0264/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0234 - The arsenal grows with the seasons

Waits on 0224, 0225, 0226, 0227, 0228, 0229, 0230, 0231, 0149, 0220, 0223.  Likely files: `src/core/game_data.gd, src/core/building.gd, src/ui/hotbar.gd, src/ui/build_mode.gd, src/ui/night_hud.gd, src/ui/world_view.gd, src/ui/transition.gd, assets/locale/strings.csv, implementation/BALANCE.md, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

The arsenal arrives with the calendar - spring's six, then summer's, autumn's and winter's - and every defence costs money as well as materials, so the day's purse is what the night is built with (plan sections 2, 5 and 7).

- The `season` field 0193 put on `DEFENCES` (default spring; 0224-0231 set their own) becomes a rule, per the plan's table: spring the gun tower, crossbow, mine, fence, barricade and wall; summer the flamethrower, decoy, beehive and bait; autumn the mortar, catapult and garlic braid; winter the searchlight and electric fence. Confirm the hardwood wall level and the sandbags and say why. Gated through 0220's `Calendar.season_reached` (Year 2 keeps all), refused in `Building.why_not` with 0220's season key, shown greyed in the hotbar with its season; `validate()` refuses a `season` outside 0-3
- Moving the flamethrower and the mortar out of spring is a rule change: every test, tool and showcase that builds them on day 1 (perf_check's worst case, `_task_0043`, `_task_0044`, the tower groups, `tower_showcase`, the autoplayer) gets a test helper that sets the calendar - never a switch in core
- Money in the cost (plan sections 1 and 7): each `cost` gains a money share (LEVERs). A kit pays the materials in advance and placing it still charges the money: `check_recipes` compares the kit's inputs with the cost less its money, `Building.affordable` and `why_not` ask for the money even when a kit is held (today a kit alone says yes), `Building.place` takes the money either way, and refunds follow `refund_for_cost`
- The hotbar of 0133 already pages or scrolls: give it a fixed order, by season then by cost, and group or page it by season if that reads better - decide; keyboard, mouse and pad still reach every slot
- 0223's tarp list and `transition.gd`'s `WAKES` take the new families; every new defence has its hotbar icon through the placeholder road until A045 is integrated by 0244
- Prices argued against 0194's money per day: at the start of a season a good day buys about one new defence (plan section 5) - a table in `implementation/BALANCE.md`
- SIM and DATA move on purpose: record both

  - done when: `_task_0234_arsenal` in `src/tools/headless_v1.gd` asserts each defence is refused before its season with the season reason and placeable after, Year 2's spring keeps winter's defences, a placed kit still charges its money, and `GameData.validate()` refuses a kit whose inputs drift from the materials
  - done when: `_case_0234_hotbar_pages` in `src/tools/input_v1.gd` pages the hotbar and places an autumn defence in autumn
  - done when: The Deliverables tables of `implementation/backlog/packs/A044-tarps.md` and `implementation/backlog/packs/A045-power-weapon-icons.md` state the final geometry this task settled (the tarp families and footprints, the icon list)
  - done when: `python tools/shot.py 0234` captures of the hotbar in spring and in winter, opened and looked at

### 0235 - Art: bones, moon stones and essence

Waits on 0221, 0222, 0219.  Likely files: `assets/art_source/props/, assets/art_source/crops/, assets/art_source/ui/, assets/art_source/manifest.json, tools/check_prop_art.py, tools/check_crop_art.py, tools/check_ui_art.py`.

The approved bones, moon stones, fertilised soil and night-loot icons go into the game in place of the stand-ins 0219, 0221 and 0222 left - essence's icon included.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A036` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A036-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/props/`, `assets/art_source/crops/` and `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_prop_art.py` `NAMES`, `check_crop_art.py`'s soil names, `check_ui_art.py`, `ArtPlacement` if needed).
- Runtime names: the bone pile and the moon stone as 16x16 props on a ground pivot (the stone's 2-frame shimmer an animation, its glow left in code); the fertilised ground dry and wet beside `tilled`/`tilled_wet` (the wet one at least 20 RGB darker, as `check_crop_art.py` holds soil to); `icon_`/`hud_` for `bones`, `bone_meal` and `moon_stone`, and the essence art as `ui/icon_tech` and `ui/hud_tech`, since the id stays `tech`
- `check_ui_art.py` counts the resource icons by `generation_task` (15 plans, 30 entries today, `tech` among them): extend it to the pack's entries rather than loosening the count, and move `tech` out of task 0018's set on purpose (the plan list and the count, with the reason) since the essence icon replaces it
- Retire the stand-ins of 0219, 0221 and 0222 from 0120's placeholder registry, so its check no longer lists A036
- Set the pack to integrated: `python implementation/backlog/assets.py set A036 integrated`.

  - done when: The family checks (`check_prop_art.py`, `check_crop_art.py`, `check_ui_art.py`) and the showcase (`python tools/show_art.py --props --check`, `python tools/show_art.py --crops --check` and `python tools/show_art.py --ui --check`) pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of bone piles, a moon stone, a fertilised plot and the essence counter in the real game, opened and looked at, in `implementation/shots/0235/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0236 - Art: the scarecrow decoy and zombie bait

Waits on 0224, 0225.  Likely files: `assets/art_source/defences/, assets/art_source/ui/, assets/art_source/manifest.json, tools/check_barrier_art.py, tools/check_ui_art.py, tools/verify.py`.

The approved straw decoy and rotten-fish bait replace the stand-ins 0224 and 0225 left.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A037` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A037-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/defences/` and `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_barrier_art.py`, `check_ui_art.py`, `ArtPlacement` if needed).
- Runtime names follow the one-cell pieces: `buildings/decoy`, `_hurt` and `_wreck` at 16x32 on the ground pivot, the hit sway (2-3 frames) as a short one-shot the view plays when it is struck; the bait on the ground at 16x16 like the mine; `icon_`/`hud_` for the bait kit
- `check_barrier_art.py` counts task 0014's 84 entries and checks the mine's single pieces: extend it for the pack's entries, or add a `check_decoy_art.py` wired into `tools/verify.py` if the shape does not fit
- Retire the stand-ins of 0224 and 0225 from 0120's placeholder registry; if 0223/0234 gave the decoy a tarp, check it still unveils
- Set the pack to integrated: `python implementation/backlog/assets.py set A037 integrated`.

  - done when: The family checks (`check_barrier_art.py`, `check_ui_art.py`) and the showcase (`python tools/show_art.py --barriers --check` and `python tools/show_art.py --ui --check`) pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of a decoy whole, hurt and struck, and a bait on the ground in the real game, opened and looked at, in `implementation/shots/0236/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0240 - Art: the searchlight

Waits on 0229.  Likely files: `assets/art_source/defences/, assets/art_source/manifest.json, tools/check_tower_art.py, tools/import_art.py`.

The approved searchlight replaces the stand-in 0229 left, and its beam starts from the lamp the art draws.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A041` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A041-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/defences/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_tower_art.py` `FAMILIES`, `ArtPlacement` if needed).
- `buildings/searchlight` and `searchlight_2` x the four states at 32x48 with a `light_xy` point on an opaque pixel in place of the muzzle `check_tower_art.py` demands of a gun; the per-family level count, metadata point and `tower` metadata as 0237 left them (make them here if it has not landed), `gen_sprites.migrated_towers()` still the four legacy families
- The beam stays code and starts from `light_xy`; what is lit is still `Light.is_lit` (0229), never the sprite
- Retire 0229's stand-in from 0120's placeholder registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A041 integrated`.

  - done when: The family checks (`check_tower_art.py`) and the showcase (`python tools/show_art.py --towers --check`) pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of searchlights at both levels lighting a tower line in the real game, opened and looked at, in `implementation/shots/0240/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0242 - Art: hardwood walls and sandbags

Waits on 0231.  Likely files: `assets/art_source/defences/, assets/art_source/manifest.json, tools/check_barrier_art.py`.

The approved hardwood wall and sandbags replace the stand-ins 0231 left.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A043` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A043-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/defences/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_barrier_art.py`, `ArtPlacement` if needed).
- The level-2 wall's modules composed into its join names (the naming 0231 gave `_barrier_name`) for the 16 masks, whole/hurt, plus a wreck; the sandbags as modules or one piece, as 0231 settled, whole/hurt/wreck
- Extend `check_barrier_art.py` with both families and their counts rather than loosening the 84
- Retire 0231's stand-ins from 0120's placeholder registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A043 integrated`.

  - done when: The family checks (`check_barrier_art.py`) and the showcase (`python tools/show_art.py --barriers --check`) pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of a mixed line of stone, hardwood and sandbags in the real game, opened and looked at, in `implementation/shots/0242/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0245 - Art: the dog

Waits on 0185, 0233.  Likely files: `assets/art_source/props/, assets/art_source/manifest.json, tools/check_prop_art.py, src/ui/art_placement.gd`.

The approved farm dog replaces the stand-ins of 0185 by day and of 0233's call-the-dog power at night.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A028` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A028-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/props/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_prop_art.py` `NAMES` and its animal canvas rule, `ArtPlacement` if needed).
- The dog as an animal like the cow and the chicken (24x24 / (12,22) unless the pack's contract says otherwise - read it): day sit, wag, follow-walk (4) and bark (2-3); night run (4) and bite (3); side view mirrored at runtime like the enemies unless the contract bakes directions
- The pet's states of 0185 and the power's run and bite of 0233 pick their frames; retire both stand-ins from 0120's placeholder registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A028 integrated`.

  - done when: The family checks (`check_prop_art.py`) and the showcase (`python tools/show_art.py --props --check`) pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the dog following the farmer and the dog called at night in the real game, opened and looked at, in `implementation/shots/0245/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0252 - The wraith

Waits on 0229, 0218.  Likely files: `src/core/towers.gd, src/core/combat.gd, src/core/game_data.gd, src/ui/world_view.gd, src/ui/wraith_fade.gdshader (new), src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Winter's answer to a defence that only shoots: in the dark it cannot be aimed at. Light - the searchlight, the flare, fire, the porch - becomes a weapon of its own.

- `ENEMIES.wraith` with `# LEVER`s (hp, `ticks_per_tile`, damage, reward, armour; inside `_task_0051_tank`'s non-boss bounds) and a `needs_light` flag
- Light comes only from 0229's core rule - `Light.is_lit(state, cell)` in `src/core/light.gd`, or whatever name 0229's journal gives it (searchlight cells, the flare area, burning cells, the porch) - never from `lighting.gd`; if that rule cannot be asked about one cell, add the query there rather than a second definition here
- `Towers._acquire` (0218's bucketed version) and `Combat.worth_shooting` skip a `needs_light` enemy on an unlit cell; it is a target from the tick it steps into light, and a shot already in the air still lands
- Decide and document what is not aiming - splash landings, mines, the cone, the flare. Recommendation: area damage still hurts it, so the dark has answers that are not light
- Names.KEYS `wraith`, `ENEMY_WRAITH`/`ENEMY_WRAITH.other` (wraith/wraiths, assombração/assombrações); `DESC_NEEDS_LIGHT` ('can only be aimed at in light' / 'só dá para mirar nela na luz'); `Sfx.ENEMY_SOUNDS.wraith` borrows `sfx/groan_walker` until 0284
- On screen: a view-only alpha shader in `src/ui/` reading the same core rule - faint outside light, solid in it, never fully invisible to the player - over 0120's placeholder road with its forecast head until A051 is integrated by 0265 (the pack's art is opaque with binary alpha; transparency is the shader's)
- Hashes: DATA moves; SIM should not; the shader moves neither

  - done when: `_task_0252_wraith` in `src/tools/headless_v1.gd`: a gun tower ignores a wraith walking past it in the dark and shoots it on the first tick it stands in a searchlight cell, a flare's area or a burning cell
  - done when: `_case_0252_wraith_fade` in `src/tools/input_v1.gd`: the wraith's sprite is faint outside light and solid in it
  - done when: `python tools/shot.py 0252 wraith` (a new scenario: one in the beam, one outside it) opened and looked at
  - done when: the Deliverables table of `implementation/backlog/packs/A051-wraith.md` states the final geometry this task settled

### 0253 - The Harvester

Waits on 0246, 0231.  Likely files: `src/core/enemies.gd, src/core/game_data.gd, src/ui/enemy_motion.gd, src/ui/world_view.gd, src/ui/night_hud.gd, src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd`.

Summer's boss: a possessed machine that winds up and charges in a straight line, flattening the walls in its row. It tests defence in depth - one thick wall is a speed bump, layers are a defence.

- `ENEMIES.harvester` with `is_boss` and `# LEVER`s: hp, armour, walking `ticks_per_tile`, damage, reward, `telegraph_ticks`, `charge_every_ticks`, `charge_tiles`, `charge_ticks_per_tile`, `crush_damage`; `check_enemies` refuses a charger missing any of them or with a zero; it passes 0246's 'every boss outlasts every non-boss' asserts
- The charge, in `Enemies` (inside `Enemies.tick`, `PerfNames` unchanged): every `charge_every_ticks` it stops and winds up with the line fixed when the wind-up starts - the row or column towards the house centre along the dominant axis, ties to the row - then moves along it at `charge_ticks_per_tile`, ignoring the flow field. `telegraph_ticks` already times the wind-up before every gnaw and at the house (`_gnaw`, `_swung_at_the_house`): reuse it for the charge or add `charge_windup_ticks`, and say which
- Every structure entered takes `crush_damage` through `Farm.damage`; it carries on through what it destroys and stops at the first that survives, at impassable terrain, at `charge_tiles` or at the house (a bite), then walks and gnaws as usual. Set the numbers so a stone wall falls and the wall's hardwood level (0231's `TOWER_LEVELS` row, read through `Building.entry_at`) holds a charge, and state them
- `Enemies.charge_line(state, id)` returns the telegraphed cells for the view and the tests; the wind-up goes through `is_winding`/`winding_at` so the 0246 bar flashes
- Destroyed walls rebuild the fields at most once a tick (they are rebuilt lazily by `Pathing.refresh`; assert one rebuild after a charge crushes three walls in one tick)
- Summer's day-14 boss: `GameData.SEASON_BOSSES[1]` (0153's table) becomes `&"harvester"`, and any 0153-0160 group or shot scenario that put a Giant on Summer 14 is rewritten in place; its 0246 intro `BOSS_INTRO_HARVESTER`; Names.KEYS `harvester`, `ENEMY_HARVESTER`/`.other` (harvester/harvesters, colheitadeira/colheitadeiras) and `DESC_CHARGES` ('charges in a straight line' / 'investe em linha reta'); `Sfx.ENEMY_SOUNDS.harvester` borrows `sfx/roar_giant` (0246 made `Sfx` boss-generic) until 0284
- On screen: a strip on the telegraphed cells during the wind-up (view only) and the boss through 0120's placeholder road at the Giant's 80x64 pivot (40,60), with its forecast mark, until A052 is integrated by 0266
- Hashes: DATA moves (ENEMIES, SEASON_BOSSES); SIM should not - the determinism night is Spring 1

  - done when: `_task_0253_harvester` in `src/tools/headless_v1.gd`: the line is fixed when the wind-up starts and the wind-up lasts exactly the levers' ticks; three stone layers lose what the levers say and a structure with more hp than `crush_damage` stops the charge; it never leaves the map or crosses water
  - done when: The same group: sealed in, it still reaches the house, and killing it moves `bosses_down_of(state, &"harvester")`
  - done when: `python tools/shot.py 0253 harvester` (wind-up with its strip, and the line after the charge) opened and looked at
  - done when: the Deliverables table of `implementation/backlog/packs/A052-harvester.md` states the final geometry this task settled (80x64, or up to 112x80 if justified)

### 0256 - Fog and rain

Waits on 0158, 0229.  Likely files: `src/core/weather.gd (new), src/core/forecast.gd, src/core/game_data.gd, src/core/towers.gd, src/core/combat.gd, src/core/enemies.gd, src/ui/forecast_panel.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd`.

Nights that are not all alike: some are foggy, some rain. Both are known at dusk, so they change what you build rather than punish you for not guessing.

- `Weather.event(seed, date)` in a new `src/core/weather.gd` (class name `Weather` - `Events` is already the log), keyed on the calendar date (`Calendar.date`, which 0153's hold keeps on 14), not on `day`: a fresh stream mixed like `Endless._stream_for` but salted so it is not the wave table's stream, never `state["rng"]`; at most one event a night; it returns none on date 1 and on `Calendar.is_calm(date)`; no State key, and none may be named `moon_phase`. The one function every reader calls (0270 will let a night record pin or forbid an event through it)
- `GameData.NIGHT_EVENTS` with per-season weights (percent, `# LEVER`) for `fog` and `rain` and their levers, listed in `GameData.digest()` and checked by a new `check_night_events` in `validate()`: weights 0-100, a season's weights summing to at most 100, each lever in range
- Fog: `Towers.reach_of` (which 0229 taught the tower's cell) loses `fog_reach_penalty` (1) down to a floor of 1, except for a tower on a lit cell (`Light.is_lit`, 0229) - the searchlight cancels it; every shape that reads reach gets the same answer
- Rain: `DAMAGE_FIRE` hits and burn ticks deal `rain_fire_percent` (bees are not fire, even if 0226 reused `burning`), and mud slows walkers by `rain_mud_percent` in `Enemies._walk`, composed with the flare's (`Ability.slowed_ticks`) and the garlic's slows by one written rule; flyers (0249's `flies`) are not slowed
- Ask `Weather` once per system tick (`Towers.tick`, `Enemies.tick`, `Combat.tick`), not once per body, so a swarm does not pay for it; `python tools/perf.py --report` stays inside its tolerance
- The `event` slot 0158 left in `Forecast.of(seed, date)` is filled from `Weather.event`; `src/ui/forecast_panel.gd` shows its icon (placeholder until A055 is integrated by 0269) and `FCAST_FOG`/`FCAST_RAIN` (FOG / NEBLINA, RAIN / CHUVA, widths measured), beside 0158's `FCAST_*` rows
- Rules only: fog and rain on screen are 0258's
- Hashes: DATA moves (a new table); SIM should not, since the determinism night is Spring 1 - if it does, the journal says why

  - done when: `_task_0256_fog_rain` in `src/tools/headless_v1.gd`: the event for a (seed, date) is the same however often it is asked and whatever the run RNG did; over seeds 0-49 and dates 1-56 (pure calls, no simulation) each season's share of fog and rain is within 5 points of its weight (printed); date 1 and a calm date have none; `Forecast.of` names the same event
  - done when: The same group: in fog a gun tower reaches one tile less unless its cell is lit; in rain a burn deals `rain_fire_percent` and a walker takes the slower count per tile
  - done when: `python tools/shot.py 0256 forecast_fog --fhd` (a new scenario in `src/tools/shot.gd` that finds a foggy (seed, date) through `Weather.event`, never an override) shows the event in the forecast, opened and looked at

### 0243 - Art: the day tarps

Waits on 0223, 0234.  Likely files: `assets/art_source/defences/, assets/art_source/manifest.json, src/ui/world_view.gd, tools/verify.py`.

The approved tarps cover the defences by day and unveil at nightfall, in place of the code-drawn covers 0223 left.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A044` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A044-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/defences/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (a tarp checker such as `tools/check_tarp_art.py` wired into `tools/verify.py`, or the tower and barrier checkers, `ArtPlacement` if needed).
- One cover per footprint 0234 settled (32x48 towers, 16x32, 16x24) plus its 2 unveil frames; the family list comes from the pack's Deliverables table, and the unveil plays in the transition's wake pass
- A hurt or wrecked defence still reads by day the way 0223 decided
- Retire 0223's code-drawn covers from 0120's placeholder registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A044 integrated`.

  - done when: The family checks (the tarp checks - the new checker, or the tower and barrier checkers that took them) and the showcase (`python tools/show_art.py --towers --check` and `python tools/show_art.py --barriers --check`) pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of covered defences of every footprint and their unveil at nightfall in the real game, opened and looked at, in `implementation/shots/0243/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0244 - Art: power and new weapon icons

Waits on 0233, 0234.  Likely files: `assets/art_source/ui/, assets/art_source/manifest.json, tools/check_ui_art.py`.

The approved icons of the three powers and the nine new defences replace the hotbar and HUD stand-ins 0233 and 0234 left.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A045` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A045-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_ui_art.py`, `ArtPlacement` if needed).
- `ui/icon_*` (16x16) and `ui/hud_*` (10x10) cut from one source each, as the resource icons are, for `farm_bell`, `call_dog`, `emergency_repair` and the decoy, zombie bait, beehive, catapult, garlic braid, searchlight, electric fence, hardwood wall and sandbags (the ids 0231 and 0233 chose)
- The hotbar and the night HUD read them by id; extend `check_ui_art.py`'s counts for the pack
- Retire the icon stand-ins of 0233 and 0234 from 0120's placeholder registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A045 integrated`.

  - done when: The family checks (`check_ui_art.py`) and the showcase (`python tools/show_art.py --ui --check`) pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures by day and by night of the hotbar and the power bar in the real game, opened and looked at, in `implementation/shots/0244/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0249 - The crow

Waits on 0218, 0168, 0233, 0234.  Likely files: `src/core/enemies.gd, src/core/traps.gd, src/core/towers.gd, src/core/farming.gd, src/core/events.gd, src/core/game_data.gd, src/ui/world_view.gd, src/ui/log_panel.gd, src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd`.

The first thing that does not walk: it flies over walls and mines and lands to eat the field. Defending the farm stops being only about the house and starts being about the harvest.

- `ENEMIES.crow` with `# LEVER`s (hp, `ticks_per_tile` in flight, damage, reward, `peck_ticks` to eat one crop) and a `flies` flag; `check_enemies`: a flyer declares neither `ignores_structures` nor `targets_structures` and is left out of the 'fastest kind that stops' comparison (a fast crow counted there would fail the runner). Inside `_task_0051_tank`'s non-boss bounds
- Straight flight, no sweep: it heads for the nearest plot with a crop in `state["plots"]` (Manhattan, ties by the lower cell index) one unit at a time along the dominant axis, like `_walk`'s inner loop, ignoring walls and occupants; with no crop on the farm it flies at the house and bites
- Landed, it waits `peck_ticks`, then the crop is eaten through a `Farming` helper (the plot stays tilled and loses crop and growth - reuse 0155's trampling path if it fits) and it takes off for the next one; a new `Events.KINDS` entry `crop_eaten` with a `LogPanel.SEVERITY` entry and a `line_for` branch (`LOG_CROP_EATEN`, 'a crow ate the %s' / 'um corvo comeu %s')
- Barriers and mines never see it: `Traps.tick` skips flyers, and it never reaches `_gnaw` or the fields; it moves inside `Enemies.tick`, so `PerfNames` is unchanged
- Which defences hit it is data: a `hits_flying` flag on every DEFENCES entry with `reload_ticks` (0224-0231's included), refused by `check_defences` when missing so any later defence must choose; `Towers._acquire`, `_burn_cone`, `_pierce_line` and splash landings (`_land_at`) skip flyers otherwise. Decide the powers too (the flare and 0233's bell and dog) and whether a landed crow counts as on the ground; the table and the reasons go in the journal
- Names.KEYS `crow`, `ENEMY_CROW`/`ENEMY_CROW.other` (crow/crows, corvo/corvos); `DESC_FLIES` in `Describe.enemy`; `Sfx.ENEMY_SOUNDS.crow` borrows `sfx/groan_runner` until 0284
- On screen: drawn above its cell with a code-drawn shadow on the ground (the pack's flying exception), through 0120's placeholder road with its forecast head until A048 is integrated by 0262
- Hashes: DATA moves (ENEMIES and the DEFENCES flags); SIM should not

  - done when: `_task_0249_crow` in `src/tools/headless_v1.gd`: a crow spawned behind a wall line reaches a planted plot in the straight-line tick count, eats it after `peck_ticks`, crosses a mine without setting it off, and is acquired only by `hits_flying` towers
  - done when: With nothing planted it reaches the house and bites, so an empty field never softlocks a night
  - done when: `python tools/shot.py 0249 crow` (a new scenario) opened and looked at: in flight it reads as above the wall, landed as on the field
  - done when: the Deliverables table of `implementation/backlog/packs/A048-crow.md` states the final geometry this task settled

### 0250 - The digger

Waits on 0218, 0234.  Likely files: `src/core/pathing.gd, src/core/enemies.gd, src/core/towers.gd, src/core/game_data.gd, src/ui/world_view.gd, src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/perf_check.gd, tools/perf_baseline.txt, src/tools/shot.gd, src/tools/headless_v1.gd`.

The enemy that makes a fence a different thing from a wall: it tunnels under fences and barricades and comes up on the other side. Only a real wall stops it.

- `ENEMIES.digger` with `# LEVER`s (hp, `ticks_per_tile` slower than the runner's 9 so `check_enemies` holds, damage, reward, armour) and a `burrows` flag; inside `_task_0051_tank`'s non-boss bounds
- A burrow field through 0218's named-field registry, built on first request by a digger, so a night without one never builds it: a barrier flagged `burrowable` costs only the ground under it (`Pathing._through` and `_entry_costs`), everything else as in the flow field
- `check_defences` makes every barrier (`path_cost` > 0) declare `burrowable`: fence and barricade yes, wall no (0231's hardwood wall is the wall's `TOWER_LEVELS` row and inherits it); 0231's sandbag barrier, 0230's electric fence and anything else with a `path_cost` decided and written in the journal
- On a `burrowable` barrier's cell it is underground: in `Enemies._walk` it passes instead of `_gnaw`ing, `Towers._acquire` (0218's bucketed version) cannot target it and the barrier loses nothing; on open ground it surfaces, and walls and the house are gnawed and bitten as a walker does (`_gnaw`, `_bite`)
- The tie-breaks of `Grid.STEPS` and 0049's rule hold: a digger never alternates between two cells for 20 ticks
- A digger case in `src/tools/perf_check.gd` (its own `PERF` line, fifty walls and fences, the burrow field built): its path rebuild stays inside `PATH_BUDGET_US` (33333 us) in `python tools/perf.py --report`, the baseline accepted with the reason in the journal
- Names.KEYS `digger`, `ENEMY_DIGGER`/`ENEMY_DIGGER.other` (digger/diggers, escavador/escavadores); `DESC_BURROWS` ('digs under fences' / 'cava por baixo das cercas'); `Sfx.ENEMY_SOUNDS.digger` borrows `sfx/groan_breaker` until 0284
- On screen through 0120's placeholder road: a tinted stand-in, a code-drawn mound while underground and its forecast head, until A049 is integrated by 0263
- Hashes: DATA moves; SIM should not (no digger in the determinism night, so no field is built)

  - done when: `_task_0250_digger` in `src/tools/headless_v1.gd`: a digger reaches the house through a ring of fences without a fence losing a hit point, a ring of walls makes it gnaw, and a tower cannot target it while it is under a fence
  - done when: The same group asserts the burrow field is never built on a night without a digger
  - done when: `python tools/shot.py 0250 digger` (a new scenario) opened and looked at: the mound reads as under the fence
  - done when: the Deliverables table of `implementation/backlog/packs/A049-digger.md` states the final geometry this task settled

### 0257 - The Blood Moon

Waits on 0256, 0219, 0246.  Likely files: `src/core/weather.gd, src/core/entities.gd, src/core/combat.gd, src/core/game_data.gd, src/core/rewards.gd, src/core/tech.gd, src/ui/forecast_panel.gd, src/ui/result_screen.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd`.

A rare red night from autumn on: the horde comes back stronger and pays in essence. Rare enough to be an occasion, forecast so it is never an ambush.

- `blood_moon` joins `GameData.NIGHT_EVENTS`: weight 0 in spring and summer (refused otherwise by `check_night_events`), a small `# LEVER` weight in autumn and winter; `Weather.event` never returns it when `Calendar.is_boss_night(date)` (an elite boss is another balance problem); decide whether it may fall on `Calendar.is_full_moon(date)` and say why
- Elites: on a Blood Moon night `Entities.spawn` (reading `Weather.event` for `Calendar.date(state)`) scales hp by `blood_moon_hp_percent` (120-200, integers) and writes `max_hp` on the elite only, so ordinary nights are untouched and 0246's `Combat.full_hp` (and any health bar that reads it) uses it
- Extra essence through 0219's earn rules: a `blood_moon_essence` `# LEVER` in `GameData.REWARDS`, its own itemised line in `Tech.would_pay` on a won night, shown in the morning report as a `RES_*` row in both languages; `nights_paid` still stops it paying twice
- In the forecast slot (`Forecast.of`'s `event`, `forecast_panel.gd`): `FCAST_BLOOD_MOON` (BLOOD MOON / LUA DE SANGUE) and the icon placeholder until A055 is integrated by 0269
- `Waves.size_of` and the forecast count do not change: elites are tougher, not more
- Hashes: DATA moves; SIM should not (`max_hp` exists only on elites)

  - done when: `_task_0257_blood_moon` in `src/tools/headless_v1.gd`: over seeds 0-49 and dates 1-56 (pure calls) no Blood Moon falls in spring, summer or on a boss night, and the autumn and winter counts are printed; on one, a walker spawns with the scaled hp and `full_hp` reads it; winning pays the extra essence, once
  - done when: `python tools/shot.py 0257 forecast_blood_moon --fhd` (a new scenario that finds a Blood Moon (seed, date) through `Weather.event`) shows it in the forecast, opened and looked at
  - done when: the Deliverables table of `implementation/backlog/packs/A055-event-icons.md` states the final geometry this task settled (fog, rain and Blood Moon at 16x16 and 10x10)

### 0265 - Art: the wraith

Waits on 0252, 0246.  Likely files: `assets/art_source/enemies/wraith/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_enemy_art.py, tools/gen_sprites.py, src/ui/enemy_motion.gd, src/ui/wraith_fade.gdshader`.

The wraith as Codex drew it, in place of 0252's stand-in, fading in and out of the light through 0252's shader.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A051` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A051-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/enemies/wraith/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`gen_sprites.migrated_enemies()`, `check_enemy_art.FAMILIES`, `EnemyMotion.FAMILIES`/`TRACKED`).
- At 64x48 pivot (32,44): the float loop as `wraith_walk_0..3`, `wraith_attack_0..2`, the dissipate as `wraith_death_0..3`, with the usual aliases and the forecast head; the art is opaque with binary alpha (the checker refuses any partial alpha), transparency is 0252's shader
- Replace 0252's placeholders in 0120's registry and check the shader on the real art: faint in the dark, solid in light
- Set the pack to integrated: `python implementation/backlog/assets.py set A051 integrated`.

  - done when: `python tools/check_enemy_art.py` and `python tools/show_art.py --enemies --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures in the real game by day (the head in the dusk forecast) and by night (one in the searchlight beam, one outside it), opened and looked at, in `implementation/shots/0265/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0266 - Art: the Harvester

Waits on 0253.  Likely files: `assets/art_source/enemies/harvester/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_giant_art.py, tools/gen_sprites.py, src/tools/headless_check.gd, src/tools/giant_showcase.gd, src/ui/enemy_motion.gd`.

The Harvester as Codex drew it, in place of 0253's stand-in: the wind-up you learn to fear and the charge that follows it.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A052` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A052-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/enemies/harvester/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`gen_sprites.migrated_enemies()`, 0246's boss table in `check_giant_art.py`, `ArtPlacement` if the canvas is larger than 80x64).
- At the canvas 0253 settled (80x64 pivot (40,60), or up to 112x80): `harvester` master, `harvester_walk_0..3` (move), `harvester_windup_0..2`, the charge/crush frames, `harvester_death_0..4`, the wreck debris and the forecast mark; 0246's boss path picks the windup on the telegraph and the charge frames while 0253's charge runs
- Replace 0253's placeholders in 0120's registry; the telegraph strip on the ground stays code. The first boss leaf to land (0266-0268, any order) rewrites `_task_0074_zombie_art`'s 'the Giant is the biggest thing on the field' as 'every boss outsizes every non-boss'
- Set the pack to integrated: `python implementation/backlog/assets.py set A052 integrated`.

  - done when: `python tools/check_giant_art.py` and `python tools/show_art.py --boss=harvester --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures in the real game by day (the mark in the dusk forecast) and by night (wind-up with the strip, and mid-charge), opened and looked at, in `implementation/shots/0266/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0283 - The guardian's sounds

Waits on 0233, 0234.  Likely files: `tools/gen_sfx.py, assets/sfx/, src/ui/sfx.gd, src/ui/main.gd, src/app/audio.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

The night is played through the cursor now, so the cursor's work, the START horn, the four powers and the new defences get sounds - heard from where the guardian is looking, not from the farmer asleep in bed. View only: neither hash moves, and no state key is added to be heard.

- The ears: at night `Sfx` calls `listen_at` with the centre of 0130's night camera (`main.gd` owns the `WorldView`; hand it over the way `Music.show_state` gets it), not `_where_the_player_is()` (the sleeping farmer), and `nearest_by_kind` measures from the same point. `Audio` has no getter for its ears today: add one if the checks need it. If 0130 already did this, say so and move on
- The cursor's hand, quieter than the weapons (at most `SOFT_PEAK`) and played at its cell: place (a defence that appears), upgrade (its `level` rising), repair (hp or `house_hp` rising in PREPARATION/NIGHT, not the fill `begin_night` does) and sell. A defence that vanishes leaving rubble (`Farm.rubble_at`) broke and one that leaves none was sold - `_watch_structures` sounds every vanished non-mine as `wall_break` today, and a sale must not; put the decision in a static helper the checks can ask
- The START horn on 0136's PREPARATION -> NIGHT edge: once a night, with no position (`AudioScript.NOWHERE`), on the `DUCKS` list, below `NIGHT_PEAK`
- The powers of 0232/0233 - flare, farm bell, the dog and emergency repair - each heard when its cooldown rises (the reading `_watch_towers` uses for `reload`), at the aimed cell; the bell, which stops every zombie, with no position. The dog's bark and bite are written here (moved from 0281; 0286 leaves the dog out of its animal calls)
- The defences of 0224-0231: a straw rustle when the decoy is hit, the beehive's buzz, the catapult's thunk (and a splat where the pumpkin lands, if the shell is already in the state), the searchlight's hum and the electric fence's zap when it stuns. Buzz and hum are per kind and not per structure - from the nearest stinging hive or lit searchlight, the way groans are - so ten hives are not ten loops
- Replace every borrowed entry 0224-0231 put in `Sfx.TOWER_SOUNDS` to keep `_task_0085_night_sounds` green. That group's rule still holds: `TOWER_SOUNDS` lists exactly the defences with `damage` (their shot), so the rustle, the hum and the zap of defences without it - and the buzz, if it is not the hive's shot - go in a table of their own (e.g. `DEFENCE_SOUNDS`). The house being hit stays the loudest file in `assets/sfx/`, and every new night file stays shorter than the Giant's roar, which that group still asserts is the longest night sound until 0284 rewrites it
- Extend `_night_sound_ids()` in `headless_check.gd` with every new list, because `_task_0084_day_sounds` builds its 'nothing in the folder is unreached' set from it

  - done when: `_task_0283_guardian_sounds` in `src/tools/headless_v1.gd`: every new id is a file under `NIGHT_PEAK`, no two damaging defences share a file, every defence without `damage` is out of `TOWER_SOUNDS`, and the sold/broken/spent helper answers right for a crafted sale, a wreck with rubble and a spent mine
  - done when: `_case_0283_guardian_sounds` in `src/tools/input_v1.gd`: in the build step the cursor places, upgrades and sells a defence and `Audio.last_played()` is place, upgrade, sell (never `sfx/wall_break`); START plays the horn; an aimed flare plays the flare; panning the camera away from a firing tower makes it quieter (`Audio.loudness`)
  - done when: `_task_0084_day_sounds` and `_task_0085_night_sounds` pass; `python tools/gen_sfx.py --report` for the new sounds is in the journal

### 0254 - The Scarecrow King

Waits on 0246, 0249.  Likely files: `src/core/enemies.gd, src/core/game_data.gd, src/ui/enemy_motion.gd, src/ui/world_view.gd, src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd`.

Autumn's boss calls the sky down: it stops, casts, and a flock of crows rises around it. It asks what the crow asked - cover in the air and care for the field - under pressure.

- `ENEMIES.scarecrow_king` with `is_boss` and `# LEVER`s: hp, armour, `ticks_per_tile`, damage, reward, `telegraph_ticks` (the cast), `summon_every_ticks`, `flock_size`, `summon_cap` (crows it may raise in one night, so a long fight cannot flood the farm); it passes 0246's boss-against-non-boss asserts
- Summons on deterministic cells: a fixed list of offsets around its cell (a table in `game_data.gd`, listed in `digest()`), clipped to the map, taken in list order - no RNG draw. They are 0249's `crow` through `Entities.spawn`, flying from there to the field; `check_enemies` refuses a `flock_size` above the offsets, a `summon_cap` below `flock_size`, or a summoned kind that does not fly
- Summoned crows are not wave members: `Waves` counts and the forecast are unchanged, and the night still ends at dawn (0137) or when everything is dead; decide whether they pay bounty (a farmable King is an exploit) and say why
- The cast is the telegraph: it stands for `telegraph_ticks` and is `is_winding` (reusing `winding_at`/`chew_wait`, as `_gnaw` does), so the 0246 bar flashes; otherwise it walks the flow field and bites like a walker, inside `Enemies.tick`
- Autumn's day-14 boss: `GameData.SEASON_BOSSES[2]` becomes `&"scarecrow_king"` (any group that put a Giant on Autumn 14 is rewritten in place); `BOSS_INTRO_SCARECROW_KING`; Names.KEYS `scarecrow_king`, `ENEMY_SCARECROW_KING`/`.other` (scarecrow king/scarecrow kings, rei espantalho/reis espantalhos) and `DESC_SUMMONS` ('calls down crows' / 'chama os corvos'); `Sfx.ENEMY_SOUNDS.scarecrow_king` borrows `sfx/roar_giant` until 0284
- On screen through 0120's placeholder road: a cast pose, the flock rising and its forecast mark at the boss canvas, until A053 is integrated by 0267
- Hashes: DATA moves (ENEMIES, the offsets, SEASON_BOSSES); SIM should not - the determinism night is Spring 1

  - done when: `_task_0254_scarecrow_king` in `src/tools/headless_v1.gd`: each cast raises `flock_size` crows on the listed cells after exactly `telegraph_ticks`, two runs agree cell for cell, and no night raises more than `summon_cap`
  - done when: The same group: a King with a planted field and no `hits_flying` cover costs crops, one with cover over the field costs few - print both counts
  - done when: `python tools/shot.py 0254 scarecrow_king` (mid-cast) opened and looked at
  - done when: the Deliverables table of `implementation/backlog/packs/A053-scarecrow-king.md` states the final geometry this task settled

### 0258 - Fog, rain and a red moon on screen

Waits on 0256, 0257.  Likely files: `src/ui/lighting.gd, src/ui/particles.gd, src/ui/fog.gdshader (new), src/ui/world_view.gd, tools/palette.py, src/ui/palette_data.gd (generated), src/tools/perf_check.gd, tools/perf_baseline.txt, src/tools/shot.gd, src/tools/input_v1.gd`.

Fog that looks like fog, rain you can see, a red moon that makes the farm look wrong - and none of it touches a rule.

- View only, both hashes unchanged: everything reads `Weather.event` (0256, 0257) and `Light.is_lit` (0229), and nothing writes the state
- Fog: a code noise shader over the world (no new PNG), thinner on lit cells so the searchlight visibly cuts it
- Rain: particles in `particles.gd` bounded by the accessibility particle density setting (`a11y/particle_density`), a darker night ramp, and a mud tint on walkable ground
- Blood Moon: a red night ramp. Ramps go the road 0152 used for the Full Moon: `rain` and `blood_moon` entries in `tools/palette.py` `RAMPS`, written into `PaletteData` by `python tools/gen_sprites.py` (never edit `palette_data.gd`), picked by `WorldView._night_ramp()`. Check that the Full Moon still reads brighter than an ordinary night and that the ramps (ordinary, Full Moon, fog, rain, Blood Moon) are told apart at a glance
- Cost: `perf_check.gd`'s view timing (`_view`, today's `view_lighting`/`view_particles`) gains a rain night at 4x as its own `PERF` line (e.g. `view_rain`), inside `tools/perf.py`'s tolerance and accepted with the reason in the journal
- Shot scenarios `fog`, `rain`, `blood_moon` and `full_moon` in `src/tools/shot.gd`, each finding a (seed, date) through `Weather.event` or `Calendar.is_full_moon` rather than an override

  - done when: `_case_0258_event_visuals` in `src/tools/input_v1.gd`: each event turns its layer on with the night and off at dawn, the rain particle count follows the density setting, and a night with the layers on and one with them off end on the same SIM hash
  - done when: `python tools/shot.py 0258 fog rain blood_moon full_moon --fhd` opened and looked at beside `docs/reference-sheet.png`: the farm stays readable in every one

### 0262 - Art: the crow

Waits on 0249, 0246.  Likely files: `assets/art_source/enemies/crow/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_enemy_art.py, tools/gen_sprites.py, src/ui/enemy_motion.gd, src/ui/world_view.gd`.

The crow as Codex drew it, in place of 0249's stand-in: in the air, landing, pecking and falling.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A048` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A048-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/enemies/crow/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`gen_sprites.migrated_enemies()`, `check_enemy_art.FAMILIES`, `EnemyMotion.FAMILIES`/`TRACKED`).
- The flying exception: `crow_fly_0..3` (loop), `crow_land_0`, `crow_peck_0..2`, `crow_death_0..3` (the fall), side view mirrored at runtime; the checker takes this family's motions from its own row (not the fixed walk/attack/death `COUNTS`), exempts flying frames from the ground-contact row and asserts no baked shadow - the shadow stays 0249's code shadow. Keep `crow`, `_walk_b`, `_attack`, `_death` aliases (or teach `_task_0074_zombie_art` the exception) so the suite's art groups still pass
- `EnemyMotion` maps 0249's states (in flight, landed, pecking, falling) to these names and keeps 0249's height offset; replace 0249's placeholders and the forecast head in 0120's registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A048 integrated`.

  - done when: `python tools/check_enemy_art.py` and `python tools/show_art.py --enemies --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures in the real game by day (the head in the dusk forecast) and by night (one over a wall, one pecking a crop), opened and looked at, in `implementation/shots/0262/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0263 - Art: the digger

Waits on 0250, 0246.  Likely files: `assets/art_source/enemies/digger/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_enemy_art.py, tools/gen_sprites.py, src/ui/enemy_motion.gd`.

The digger as Codex drew it, in place of 0250's stand-in: going down, the mound moving under the fence, coming up.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A049` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A049-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/enemies/digger/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`gen_sprites.migrated_enemies()`, `check_enemy_art.FAMILIES` with its extra motions, `EnemyMotion.FAMILIES`/`TRACKED`).
- At 64x48 pivot (32,44): `digger_walk_0..3`, `digger_burrow_0..3` (one-shot), `digger_mound_0..N` (loop, 2-3 frames), `digger_emerge_0..3`, `digger_attack_0..2`, `digger_death_0..3` with the usual aliases, and the forecast head
- `EnemyMotion` plays burrow on the tick 0250 puts it underground, the mound while it stays there and emerge when it surfaces; replace 0250's placeholders in 0120's registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A049 integrated`.

  - done when: `python tools/check_enemy_art.py` and `python tools/show_art.py --enemies --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures in the real game by day (the head in the dusk forecast) and by night (a mound under a fence line), opened and looked at, in `implementation/shots/0263/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0269 - Art: fog, rain and the Blood Moon icons

Waits on 0256, 0257.  Likely files: `assets/art_source/ui/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_ui_art.py, src/ui/forecast_panel.gd`.

The three night events as Codex drew them, in the forecast slot where 0256 and 0257 left placeholders.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A055` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A055-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_ui_art.py` pins the 0018 resource set - add this pack as its own checked block).
- `ui/icon_fog`, `ui/icon_rain`, `ui/icon_blood_moon` at 16x16 pivot (8,8) and the matching `ui/hud_*` at 10x10 pivot (5,5), each pair cut from the same raw source at different nearest scales (visible size at most 14 and 8 px)
- Replace 0256's and 0257's placeholders in the forecast slot (`src/ui/forecast_panel.gd`, 0158) through 0120's registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A055 integrated`.

  - done when: `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures in the real game by day (each event in the dusk forecast) and by night (the build step's forecast), opened and looked at, in `implementation/shots/0269/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0270 - Fifty-six nights as data

Waits on 0151, 0152, 0153, 0154, 0256, 0257, 0234.  Likely files: `src/core/game_data.gd, src/core/waves.gd, src/core/endless.gd, src/core/almanac.gd (new), src/core/weather.gd, src/tools/nights.gd, tools/nights.py, src/tools/headless_check.gd, src/tools/headless_v1.gd`.

The year stops being ten written nights plus a curve and becomes tables a designer can read: a template per season, hand-written key nights (every introduction, every Full Moon) and a seeded generator for the nights in between. Nothing downstream of `Waves.night_of` can tell which is which, so the season tasks after this one edit data (0271 also gives `play_nights` a day range).

- A night is still `{note, opening_ticks, gap_ticks, waves}` with waves `[kind, count, spawn, delay?]`, so `Waves`, `Enemies`, `Rewards`, the forecast (0158) and the HUD need no new case. Two new tables in `src/core/game_data.gd`: `SEASON_NIGHTS` (per season: the sides it deals from - indices open for that season in 0157's `SIDES_BY_SEASON`, never a second copy of that table - each with the day it joins, so a season brings a new side in gently; the kinds of its mix with a weight and the day each joins; a size in hit points - the honest measure 0060 used, `play_nights.gd`'s `_hit_points_of` - at the season's second and thirteenth day; waves and gap from/to; every number a `# LEVER` with a range) and `KEY_NIGHTS` (day of the year 1-56 -> a record)
- Key nights are each kind's introduction and the Full Moons on days 7 and 14 of every season. No record names a boss: 0153's rule in `Waves.night_of` adds the `SEASON_BOSSES` row on day 14 (0253-0255 put theirs there), so a day-14 key night writes only the boss's company. Draft content so all 56 resolve: today's nights 1-9 as spring's days 1-9 and today's 10, without its Giant row, as day 14, their south-east rows moved to the east; delete 0157's commented allowance for today's ten, which nothing needs now (0271 has nothing left to remove). Day 1 stays byte-identical. Summer to winter get drafts that send spring's kinds only; 0271-0274 author them for real
- Days 15, 29 and 43 are 0154's calm dates (`Calendar.is_calm`): `night_of` already returns the calm record for them, so they carry no key night and the generator never makes one
- A node-free generator - `src/core/almanac.gd` with `Almanac.night(seed, day)`, or the home 0150/0158 already gave the calendar lookup (extend it, never a second one) - fills every other day from its season's template with a fresh stream from `(seed, day)` (the `Endless._stream_for` pattern), never `state["rng"]`. The seed orders the waves and picks among the open sides; it never changes the totals per kind (the `Endless` contract)
- `Waves.plain_night(day, seed)` (0150) is where the year comes from - the key night first, else the generator - and `night_of` keeps 0152-0154's rules on top of it, unchanged. `Waves.tonight` keeps caching generated records on `state.wave.tonight`, so no new State key and `remaining()` stays free per frame. `GameData.NIGHTS` retires here (its rows are spring's draft) and `Waves.authored_count()` with it: grep `src/` and `tools/` for both and move every reader. Past day 56 the lookup keeps serving `Endless.night` until 0279 (if its base or step must read something new, the journal says what day 57 sends before and after); `perf_check.gd`'s worst case stays on Spring 14 (0153) until 0275
- Decide in one place whether 0152's Full Moon percent scales an authored Full Moon record or is already written into it - one, never both, and the forecast's count equals what is sent. A key night may pin or forbid an event with an optional `event` field, read by 0256's `Weather` chooser for that `(seed, day)`; a pin still obeys `check_night_events` (no Blood Moon before autumn or on a boss night, nothing on Spring 1 or a calm date)
- `GameData.check_nights(templates, key_nights)` takes its tables as arguments, as it takes `nights` today, so a test can hand it a broken copy. It refuses: a boss in any template or key night (the boss row is 0153's); an unknown kind in a template; a side not open in that season (0157); a size that falls or a gap that grows across a season (0060's curve rules); a key-night day outside 1-56 or on a calm date; a Full Moon day without a key night; a schedule that outlasts the night (0137); an unknown `event`. The per-record rules are one function: `validate()` runs it on seed 0's year only, so loading stays cheap, and 0151's `python tools/nights.py --check` gate runs it on every date for its two seeds
- `GameData.digest()` lists `SEASON_NIGHTS` and `KEY_NIGHTS` and drops `NIGHTS` (0112's coverage assert passes). DATA moves on purpose; SIM should not, day 1 being identical - if it moves, the journal says why. What 0150-0153 left of `_task_0058_giant`, `_task_0059_wave_data`, `_task_0060_ten_nights` and `_task_0070_endless` in `src/tools/headless_check.gd` that reads `GameData.NIGHTS` rows reads the year through `Waves.plain_night` instead, keeping what each asserted
- `python tools/nights.py` prints the year by default: a block per season, each day's kinds, sides, count, hit points, reward and event, with key, Full Moon, boss and calm days marked, then first-seen per kind and the size bars. Its positional arguments change from today's `[count] [seed]` to `[from] [to] [seed]` (`python tools/nights.py 15 28 3` prints a range); `--check` stays; the docstrings of `nights.gd` and `nights.py` say so

  - done when: `_task_0270_year_records` in `src/tools/headless_v1.gd`: for seeds 0-4 every day 1-56 is a key night, a generated record or a calm date; generated records pass the per-record rules an authored one does; two seeds send the same totals per kind on every day; generating day 30 leaves `state["rng"]` untouched; no kind is sent before the day its key night or template introduces it; day 1's record equals the old night 1
  - done when: The same group hands `check_nights` doctored copies - a boss in a key night, an unknown kind in a template's mix, a spring night from the south-east, a key night on day 15 - and each is refused
  - done when: For days 1-56 and two seeds, 0158's forecast counts equal `Waves.size_of`/`kinds_of` for the same day
  - done when: The year from `python tools/nights.py` is in the journal: count, hit points and reward per day, by season

### 0286 - Fog, rain and winter wind

Waits on 0186, 0256, 0257, 0285.  Likely files: `tools/gen_ambience.py, assets/ambience/, tools/gen_music.py, assets/music/, src/ui/ambience.gd, src/ui/music.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

The bed under everything follows the weather and the season: fog and rain on the nights that have them, wind through the winter, the animals heard near their coop and barn, and a short stinger when an event night reaches its build step. View only: neither hash moves. (The animal calls came from 0281 and the stingers from 0284, so those fit one invocation.)

- `tools/gen_ambience.py` writes a fog bed and a rain bed for the night, and a winter bed (wind, no birds, no crickets) for winter's day and night, looped with its `seamless()` and under `BED_PEAK` - the bed stays the quietest thing in the game
- `Ambience.bed_for` stays static and gains the season and tonight's event: an event night's bed beats the season's, and winter's beats the ordinary day and night beds. The event is 0256's `Weather` answer for `(seed, day)` (0257 added the Blood Moon to it) - the function the forecast panel calls, never a second draw and never the view's own `RandomNumberGenerator`
- Touches by season: winter gets its own short lists (no crickets, no songbirds), and no touch is in both a day list and a night list
- Animals near barns, written here (moved from 0281): cluck, moo, baa and oink in `gen_ambience.py` from `gen_sfx`'s primitives (it already imports `gen_sfx`), at most `TOUCH_PEAK`, played at the coop's and the barn's cells through the existing falloff - by day while the building stands with animals of that kind in it (0183's residents), and as a sleepy murmur at night, when they sleep inside (0186). The dog is not here: its bark is 0283's power sound. Decide whether a wrecked-but-standing barn still murmurs
- The beds change on the cue they use today (`Audio.play_bed` with the transition's length); nothing changes the bed in the middle of a night
- Event stingers (moved from 0284): fog, rain, the Blood Moon (0257) and the Full Moon (0152) as short cues in `tools/gen_music.py` beside `sting` - `PIECES` entries, at most `STING_PEAK`, named in 0285's not-loop list - played once through `Audio.play` (the Music bus, because the file is in `assets/music/`) when a night with that event reaches its build step. The event is the same `Weather` answer the bed reads (the Full Moon is 0152's `Calendar.is_full_moon`), never decided in the view
- Rewrite `_task_0087_ambience` in `headless_check.gd` for the new `bed_for`: every file is still asked for, every bed loops (`_loop_seam` at most 1.0) and peaks under 0.3, and the house being hit still stands far above the ducked bed

  - done when: `_task_0286_weather_ambience` in `src/tools/headless_v1.gd`: `bed_for` answers for every season, phase and event; each new bed loops and stays under the old peak; no touch is in both a day and a night list, and winter's hold no cricket and no songbird; animal calls are offered only where a coop or barn with animals stands; each stinger is in `assets/music/`, at most `STING_PEAK` and on 0285's not-loop list
  - done when: `_case_0286_weather_ambience` in `src/tools/input_v1.gd`: a foggy night's build step plays the fog bed (`Audio.bed_playing()`) and the fog stinger once (`Audio.plays_of()`), and a winter morning the winter bed
  - done when: `python tools/gen_ambience.py --report` for the new beds (length, peak, seam) and `gen_music.py --report` for the stingers are in the journal

### 0255 - The Winter Lord

Waits on 0246, 0251, 0160, 0253, 0254.  Likely files: `src/core/enemies.gd, src/core/towers.gd, src/core/game_data.gd, src/ui/world_view.gd, src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd`.

The last night of the year: a lord of ice whose cast freezes every tower around it. It tests the whole build - spread, depth, light and the powers - and its fall is the ending.

- `ENEMIES.winter_lord` with `is_boss` and `# LEVER`s: hp, armour, `ticks_per_tile`, damage, reward, `telegraph_ticks` (the cast), `freeze_every_ticks`, `aura_tiles`, `freeze_ticks` (`check_enemies` refuses a zero); the strongest boss in the table (more hp than the Harvester and the King - asserted)
- The freeze sits beside 0251's chill on the occupant, never through `Farm.touch`: towers within `aura_tiles` when the cast lands stop counting their reload for `freeze_ticks` (a `frozen` countdown in `Towers.tick`/`_cool_down`); refreshed, never stacked, cleared in `Enemies.withdraw` at dawn
- The cast is telegraphed (`is_winding` for `telegraph_ticks`, so the 0246 bar flashes) and the aura's cells are a core query for the view
- Winter's day-14 boss: `GameData.SEASON_BOSSES[3]` becomes `&"winter_lord"`, and 0160's ending fires on it falling: rewrite `_task_0160_year_end` and `_case_0160_ending` to kill a Winter Lord on Winter 14 and see the ending; a Giant on that night no longer ends the year
- `BOSS_INTRO_WINTER_LORD`; Names.KEYS `winter_lord`, `ENEMY_WINTER_LORD`/`.other` (winter lord/winter lords, senhor do inverno/senhores do inverno) and `DESC_FREEZES` ('freezes the towers around it' / 'congela as torres em volta'); `Sfx.ENEMY_SOUNDS.winter_lord` borrows `sfx/roar_giant` until 0284
- On screen through 0120's placeholder road: a cast pose, the aura's reach on the ground during the wind-up, ice on frozen towers (view only) and its forecast mark, until A054 is integrated by 0268
- Hashes: DATA moves; SIM should not

  - done when: `_task_0255_winter_lord` in `src/tools/headless_v1.gd`: a cast freezes exactly the towers inside `aura_tiles` for `freeze_ticks`, `grid_version` does not move, and every tower fires again afterwards
  - done when: Killing it on Winter 14 brings up the year's ending through 0160's path and `bosses_down_of(state, &"winter_lord")` is one
  - done when: `python tools/shot.py 0255 winter_lord` (the aura during a cast) opened and looked at
  - done when: the Deliverables table of `implementation/backlog/packs/A054-winter-lord.md` states the final geometry this task settled

### 0267 - Art: the Scarecrow King

Waits on 0254.  Likely files: `assets/art_source/enemies/scarecrow_king/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_giant_art.py, tools/gen_sprites.py, src/tools/headless_check.gd, src/tools/giant_showcase.gd, src/ui/enemy_motion.gd`.

The Scarecrow King as Codex drew it, in place of 0254's stand-in, raising its arms as the flock comes up.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A053` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A053-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/enemies/scarecrow_king/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`gen_sprites.migrated_enemies()`, 0246's boss table in `check_giant_art.py`, `ArtPlacement` if needed).
- At the canvas 0254 settled: master, `scarecrow_king_walk_0..3`, the summon cast (4 frames) played for 0254's `telegraph_ticks`, `_attack_0..2`, `_death_0..4`, and the forecast mark
- Replace 0254's placeholders in 0120's registry; if no boss leaf has yet, rewrite `_task_0074_zombie_art`'s 'the Giant is the biggest thing on the field' as 'every boss outsizes every non-boss' (see 0266)
- Set the pack to integrated: `python implementation/backlog/assets.py set A053 integrated`.

  - done when: `python tools/check_giant_art.py` and `python tools/show_art.py --boss=scarecrow_king --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures in the real game by day (the mark in the dusk forecast) and by night (mid-cast with the flock rising), opened and looked at, in `implementation/shots/0267/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0271 - Spring's fourteen nights

Waits on 0270, 0157.  Likely files: `src/core/game_data.gd (`KEY_NIGHTS`, spring's `SEASON_NIGHTS`), src/tools/play_nights.gd, tools/play_nights.py, src/tools/headless_v1.gd`.

Spring is the season that teaches: the walker, the runner, the tank and the breaker one at a time, all from the east, a Full Moon on day 7 and the Giant on day 14. Today's ten nights are the raw material, but they were balanced for two sides and a ten-night run, so they are rewritten rather than pasted.

- First the instrument, moved here from 0270: `tools/play_nights.py` forwards its arguments (today it passes none) and `python tools/play_nights.py <from> <to>` plays that range of dates with the scripted build, buying only what each date's season has unlocked (0234's `unlock_season`, money and materials) from a purse that starts where a run would be (what the earlier dates paid plus the income). 0272-0274 author with it
- Every spring night comes from the east only (0157's east region; 0270 already deleted the allowance today's ten had). Today's night 2, 'the same again from two sides', becomes a lesson one side can teach
- The plan's rhythm: days 1-6 grow gently, day 7 is a Full Moon of the kinds already met, days 8-13 grow again with the season's novelty - the breaker, 'Primavera (fim)' - and day 14 is the Full Moon with the Giant (0153's row) in company. A starting map: today's 1-6 to days 1-6, today's 7 (breakers) to day 8, today's 8-9 spread over 9-13, today's 10 to day 14 - change it if the numbers say so
- One new thing a night at most, and the night after an introduction is where it bites (0060's rule): the walker on 1, the runner and the tank in days 2-6, the breaker in 8-13. The introductions, day 7 and day 14 are `KEY_NIGHTS`; the other days come from spring's template
- Day 1 stays the tutorial night: a normal night 1 (the calm night only follows a fallen boss), winnable with what the tutorial (0141) gives; the tutorial asserts of 0041/0141 stay green
- Every night fits the night length (0137) with room for the last wave to be fought before dawn
- Notes in the voice of the authored ten, English, one line each - they are what `tools/nights.py` prints
- Author against `python tools/nights.py 1 14` (count, hit points and reward climb, peaking on 7 and 14) and `python tools/play_nights.py 1 14` at its three incomes
- DATA moves on purpose; SIM moves if day 1 changed, because the determinism scenario fights it - both numbers in `implementation/PROGRESS.md`

  - done when: `_task_0271_spring_nights` in `src/tools/headless_v1.gd`: days 1-14 send only the walker, runner, tank, breaker and the Giant, only from the east; each kind is first sent on its authored introduction day; day 7 is the largest of days 1-7 and day 14 the largest of spring in hit points; the Giant is on day 14 and nowhere else
  - done when: `python tools/play_nights.py 1 14` output is in the journal: night 1 holds at the lowest income, and every night that falls is named with what the curve does there; `python tools/play_nights.py 15 20` runs on 0270's summer draft and buys nothing summer has not unlocked
  - done when: Spring's table from `python tools/nights.py 1 14` is in the journal beside the old ten nights' numbers

### 0259 - Every weapon has its night

Waits on 0234, 0247, 0248, 0249, 0250, 0251, 0252, 0253, 0254, 0255, 0256, 0257.  Likely files: `src/tools/matchups.gd, tools/matchups.py, implementation/MATCHUPS.md`.

The plan's test for phases 4 and 5 turned into numbers: every weapon is the best buy somewhere, and every enemy needs a different answer. The report is what the night authors of 0270-0274 build the year from.

- A headless tool, not a suite group: `src/tools/matchups.gd` run by `tools/matchups.py`, seeded and deterministic, printing its run time, with `--only=<enemy>` for quick reruns; it stays out of `verify.py` (the 120 s per-suite timeout). Keep a full run to about ten minutes by shortening the lane's fight, not by dropping rows of the grid
- The arena: one fixed lane on the real farm map with a fixed base defence; for every `GameData.DEFENCES` entry (the plan's fourteen plus 0225's bait and 0231's sandbags - print the count), the same budget (0234's money plus materials, materials at `SELL_PRICE`) spent on it at the level its season allows, placed by a fixed rule; a fixed group of one enemy kind, and each boss with its season's escort
- Per pair: house damage, kills, ticks to clear and structures lost; the score is house damage prevented per unit of cost against the base alone
- The same grid under fog, rain and the Blood Moon, so the searchlight, fire and the mines get their nights
- Prove: every defence is the top buy against at least one enemy, boss or event (a barrier or a support piece - decoy, garlic, searchlight - may be scored as the best addition to the base line rather than alone; say how); no defence is top against every enemy; every new enemy's top answer differs from the walker's. Where a claim fails, a lever may move here (at most a few, DATA recorded) or the failure goes to 0277 with its numbers
- `implementation/MATCHUPS.md`: the table, each enemy's top three answers, each defence's best night, and a line per enemy for the night authors (e.g. 'rats: mines, flamethrower')

  - done when: `python tools/matchups.py` exits 0 and names, for every `DEFENCES` entry, the enemy or event where it is the best buy, or marks it UNPROVEN with its numbers; every UNPROVEN line is in the journal as handed to 0277
  - done when: Two runs write the same `implementation/MATCHUPS.md` byte for byte
  - done when: The journal answers in one paragraph, with the numbers, whether each enemy asks for a different answer, and lists any lever moved

### 0268 - Art: the Winter Lord

Waits on 0255.  Likely files: `assets/art_source/enemies/winter_lord/, assets/art_source/effects/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_giant_art.py, tools/gen_sprites.py, src/tools/headless_check.gd, tools/check_effect_art.py, src/tools/giant_showcase.gd, src/ui/enemy_motion.gd`.

The Winter Lord as Codex drew it, in place of 0255's stand-in: the last thing the year sends, and the cast that freezes the line.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A054` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A054-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/enemies/winter_lord/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`gen_sprites.migrated_enemies()`, 0246's boss table in `check_giant_art.py`, the effect checker for the shards, `ArtPlacement` if needed).
- At the canvas 0255 settled: master, `winter_lord_walk_0..3`, the freeze cast (4) for 0255's `telegraph_ticks`, `_attack_0..2`, `_death_0..4`, the ice aura shards (4) in the effects family, and the forecast mark
- Replace 0255's placeholders in 0120's registry; the aura's reach on the ground and the ice on frozen towers stay code. If no boss leaf has yet, rewrite `_task_0074_zombie_art`'s 'the Giant is the biggest thing on the field' as 'every boss outsizes every non-boss' (see 0266)
- Set the pack to integrated: `python implementation/backlog/assets.py set A054 integrated`.

  - done when: `python tools/check_giant_art.py`, `python tools/check_effect_art.py` and `python tools/show_art.py --boss=winter_lord --check` pass
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures in the real game by day (the mark in the dusk forecast) and by night (mid-cast, towers freezing), opened and looked at, in `implementation/shots/0268/`
  - done when: the sim and data hashes are unchanged (art never moves them)

### 0284 - The new enemies and bosses, heard

Waits on 0247, 0248, 0250, 0252, 0253, 0254, 0255, 0257.  Likely files: `tools/gen_sfx.py, assets/sfx/, src/ui/sfx.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd`.

Six new enemies and three new bosses each get a voice of their own, so a night heard with your eyes shut still says what is coming. View only: neither hash moves, and no state key is added to be heard. (The night events' stingers moved to 0286, beside the event beds, so this fits one invocation.)

- Recipes for the spitter (the spit, and a splat on the tower 0247's projectile hits), the rat swarm (a squeak), the crow (a caw over wingbeats), the digger (a burrowing rumble and a burst when it surfaces), the frost zombie (a shatter as it dies and a crackle on the towers it chills) and the wraith (a whisper)
- Voices stay per kind and not per body: `nearest_by_kind` keeps a swarm of fifty rats to one voice (0085's promise). Deaths that differ by kind go through a small per-kind table that falls back to `DEATH_SOUND` and keeps `DEATH_GAP`
- The wraith cannot be shot outside light (0252): decide whether its whisper plays with no position (you know they are out, not where) or only from wraiths in light, and write why in the journal
- Three boss voices - the Harvester's engine, the Scarecrow King's call, the Winter Lord's ice - and their specials: the Harvester's charge telegraph and the crunch of the walls it crushes, the King summoning crows, the Winter Lord's freezing aura; each special heard on the edge its telegraph or effect already sets in the state (`is_winding`, 0253's `charge_line`, 0251's `Towers.chill_left`, 0255's `frozen` countdown), read like `reload`
- Every boss is announced like the Giant: on arrival, with no position, ducking the ambience. Wherever `sfx.gd` still tests `kind == &"giant"` (`_watch_bodies`, `nearest_by_kind`, `_ducks`), read `is_boss` instead, unless 0246 already did
- Rewrite `_task_0085_night_sounds`: 'the Giant's roar is the longest sound at night' becomes 'every boss voice is longer than every ordinary night sound'; the house being hit stays the loudest file (bosses at `GIANT_PEAK` or below); replace each borrowed `ENEMY_SOUNDS` entry 0247-0255 left
- Extend `_night_sound_ids()` so every new file in `assets/sfx/` is reached. The event stingers (fog, rain, the Blood Moon, the Full Moon) are not this task's: 0286 writes and plays them

  - done when: `_task_0284_enemy_sounds` in `src/tools/headless_v1.gd`: every enemy in `GameData.ENEMIES` has a voice file of its own, every boss voice is longer than any ordinary night sound and quieter than the alarm, and fifty rats are one entry in `nearest_by_kind`
  - done when: `_case_0284_boss_voices` in `src/tools/input_v1.gd`: a boss spawned in a real scene plays its voice once with no position and ducks the bed (`Audio.duck_gain()`)
  - done when: `_task_0085_night_sounds` (rewritten) passes; `python tools/gen_sfx.py --report` for every new sound is in the journal

### 0287 - Collections and achievements

Waits on 0152, 0155, 0160, 0170, 0182, 0253, 0254, 0255.  Likely files: `src/core/collections.gd, src/core/stats.gd, src/core/farming.gd, src/core/phases.gd, src/core/run.gd, src/core/game_data.gd, src/app/save.gd, src/app/app.gd, src/app/input_actions.gd, project.godot, src/ui/collections_screen.gd, src/ui/title_screen.gd, src/ui/main.gd, scenes/Title.tscn, scenes/Main.tscn, assets/locale/strings.csv, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd, src/tools/shot.gd, implementation/backlog/packs/A056-collections.md`.

The plan's reason to start Year 2: four collections - fish, crops, the bosses' trophies and a year without losing the house - and a short list of achievements, kept in the profile across runs and shown on one screen.

- A node-free `src/core/collections.gd` in the shape of `Stats`: it reads facts other modules already count and keeps no second ledger - fish from 0182's book, trophies from 0246's `Combat.bosses_down_of` (`killed_by_kind_all_run`) for every `is_boss` kind, crops from a harvest tally - and folds them into the profile with the banking of `Stats.fold` (`stats.banked`), so folding twice adds nothing. Call it from inside `Stats.fold`, so every fold site (`main.gd`'s autosaves, `Run.record`) gets it without a second call
- Crops count harvests, not `gained`: everything `Resources.add` brings in (a purchase through `Shop.buy`, a gift, loot) lands in `gained` too. Add `stats.harvested_by_crop` to `Stats.initial()` (inside the `stats` TABLE, so reconcile fills old saves and no version bump is needed), counted in `Farming._harvest` the way `Stats.built` is counted in `Building.place`. SIM moves on purpose (the state gains keys): both numbers in the journal
- 'A year without losing the house' is a run that saw Winter 14's boss fall (0160's `Run.is_over`) with no night on which the house fell; a boss that walks off at dawn (0153's escaped outcome) is not a lost house. Nothing counts lost nights today: add `stats.nights_lost` beside the crop tally, counted in `Phases.enter_result` when the house fell (read how 0153 marks an escape in `last_result` and leave that out)
- About a dozen achievements, decided here, repeating none of the collections - e.g. first night survived, a Full Moon held (0152's `Calendar.is_full_moon`), a legendary landed, every defence in `DEFENCES` built once, a night with nothing destroyed, Year 2 reached - each a pure test of the lifetime stats, the collections and this run's record. A table in `game_data.gd` (thresholds `# LEVER`, a `check_achievements` in `GameData.validate()` that every id it names exists, listed in `GameData.digest()` so DATA moves on purpose) whose entries carry literal `&"ACH_*"` keys for a name and a one-line description: a key built at runtime is invisible to `tools/i18n_check.py`
- The profile: `Save.default_profile()` gains `collections` and `achievements`; `read_profile` already merges the defaults, so an older profile loads with no format bump. No toast for a newly earned badge in this task: the skeleton asks for the screen, and the task has to fit one invocation
- `src/ui/collections_screen.gd`, a sibling of `StatsScreen` (a node in `scenes/Title.tscn` and `scenes/Main.tscn`, as it is): tabs for fish (0182's book view embedded - reuse its pages, do not rebuild them; 0182's own way in keeps working), crops, bosses, the year and achievements, each with a count. Locked trophies and badges are the earned art dimmed by code, so A056 needs no locked state
- Ways in: the title menu (`ENTRIES` gains `collections`, `TITLE_COLLECTIONS`), a `COLLECTIONS` router state in `App.STATES` and `App.NAMES` (update the state count `_task_0092_router` asserts in `headless_check.gd`) and, in a run, a new `collections` action in `InputActions.ACTIONS` (`ACT_COLLECTIONS`, `ACT_GROUP_SCREENS`) with key and pad bindings in `project.godot` (0121's sync and clash checks), opened and closed the way the `stats` key opens `StatsScreen`. Strings in both languages, e.g. `TITLE_COLLECTIONS` (COLLECTIONS / COLEÇÕES), the tabs, every `ACH_*`
- Placeholders until 0288 integrates A056, through 0120's road: the existing crop and fish icons on the tabs, each boss's first frame as its trophy, code-drawn shapes for the badges, the cover and the ornament - never a hand-drawn PNG

  - done when: `_task_0287_collections` in `src/tools/headless_v1.gd`, on crafted states rather than a 56-night run (the 120 s limit): a harvested crop ticks its page and the same crop added through `Resources.add` does not; a boss killed adds its trophy; a run that lost a night never earns the year, one whose boss only escaped still can, and one that lost none and beat Winter 14 does; folding twice adds nothing; a profile without the new keys reads with defaults; `GameData.validate()` refuses an achievement naming an unknown id
  - done when: `_case_0287_collections` in `src/tools/input_v1.gd`: the title menu opens the screen, the tabs move by keyboard and by pad, cancel goes back to the title; in a run the `collections` key opens and closes it
  - done when: FHD captures of every tab with an empty and a full profile in English, and with the full profile in Portuguese (`src/tools/capture_menus.gd` or a new `shot.gd` scenario), opened and looked at, in `implementation/shots/0287/`
  - done when: The Deliverables table of `implementation/backlog/packs/A056-collections.md` states the final geometry this task settled: canvases, pivots and runtime names for the cover, the tab icons, a trophy per boss, one badge per achievement id and the ornament

### 0272 - Summer's fourteen nights

Waits on 0270, 0247, 0248, 0253, 0259, 0271.  Likely files: `src/core/game_data.gd (`KEY_NIGHTS`, summer's `SEASON_NIGHTS`), src/tools/headless_v1.gd`.

Summer opens the second side and brings the first enemies that change what a spring defence is worth: the spitter shoots towers from range, the rats come in numbers that mines and fire love, and on day 28 the Harvester charges straight through the walls.

- Days 16-28 fight; day 15 is 0154's calm night after the Giant. The east and the south-east are open (0157), and the first south-east night is a small one, so the new side is learned before it is tested
- Summer's first fight starts below spring's Full Moons and above spring's day 6, so the year still climbs; spring's four kinds stay in the mix at summer's share
- The spitter and the rat swarm are introduced on different nights - one in days 16-20, the other in days 22-27 - never together; the Full Moon on day 21 sends what is already known; the night after each introduction bites
- Day 28 is the Full Moon with the Harvester in company, so it cannot be focused alone: the Harvester is the row 0153's rule adds from `SEASON_BOSSES` (0253 put it there), and this task writes its company
- Read 0259's `implementation/MATCHUPS.md` first: every night's mix has an answer in what summer's arsenal (0234) has unlocked by that day - the flamethrower, the decoy, the beehive and the bait arrive this season - and the journal says which weapon each new enemy is meant to teach
- Rats are many bodies: print the peak entity count of the largest rat night and compare it with what the swarm scenario of 0218/0248 in `perf_check.gd` measured; the year's worst case is 0275's
- Author against `python tools/nights.py 15 28` and `python tools/play_nights.py 15 28` (0271's range), starting from spring's final numbers; notes in the authored voice; every night fits the night length (0137); DATA moves on purpose, SIM only if a day the determinism scenario fights changed

  - done when: `_task_0272_summer_nights` in `src/tools/headless_v1.gd`: days 16-28 send only kinds introduced by that day, only from the east and the south-east; the spitter and the rats are first sent on their introduction days, on different nights; the Harvester is on day 28 and nowhere else; days 21 and 28 are the largest of their halves in hit points
  - done when: `python tools/nights.py 15 28` and `python tools/play_nights.py 15 28` output in the journal, with the matchup line for each new enemy and the peak rat count

### 0288 - Art: the collection book, trophies and badges

Waits on 0287.  Likely files: `assets/art_source/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_ui_art.py, src/tools/ui_art_showcase.gd, src/ui/placeholder_art.gd, src/ui/collections_screen.gd`.

The book cover, the four boss trophies and the achievement badges Codex drew replace 0287's stand-ins, so the screen a player opens before Year 2 looks like the rest of the game.

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A056` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A056-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/<family>/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_<family>_art.py`, `ArtPlacement` if needed).
- Family `ui`, no text in any of it: names, canvases and pivots exactly as A056's Deliverables table (settled by 0287) - the cover, the tab icons, a trophy per `is_boss` enemy, a badge per achievement id, the ornament. `tools/check_ui_art.py` hard-codes the 0018 resource icons (`len(plans)==15`): give the A056 set its own section and counts rather than loosening that one, and show it in `ui_art_showcase.gd`
- Delete A056's entries from 0120's placeholder registry (`src/ui/placeholder_art.gd`) once the raster outputs land at the same paths, so `collections_screen.gd` draws the real art through the lookup it already uses and `python tools/placeholders.py` no longer lists A056; locked trophies and badges stay the same art dimmed by code
- Set the pack to integrated: `python implementation/backlog/assets.py set A056 integrated`.

  - done when: `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass with the A056 set counted
  - done when: `python tools/import_art.py --check` passes
  - done when: FHD (1920x1080) captures of the collections screen, every tab with a full profile, opened in a run by day and by night, opened and looked at, in `implementation/shots/0288/`
  - done when: The sim and data hashes are unchanged (art never moves them)

### 0273 - Autumn's fourteen nights

Waits on 0270, 0249, 0250, 0254, 0259, 0272.  Likely files: `src/core/game_data.gd (`KEY_NIGHTS`, autumn's `SEASON_NIGHTS`), src/tools/headless_v1.gd`.

Autumn opens the north and brings the two enemies that ignore the shape of a maze: the crow flies over it to eat the crops, the digger goes under the fences and barricades. The Scarecrow King calls his flocks on day 42, and the Blood Moon can rise from now on.

- Days 30-42 fight; day 29 is 0154's calm night after the Harvester. The east, the south-east and the north are open (0157); the first north night is a small one
- The crow and the digger are introduced on different nights - one in days 30-34, the other in days 36-41 - never together; the Full Moon on day 35 sends what is already known; the night after each introduction bites
- Crows eat what is in the ground, and autumn's fields are full (wheat, pumpkin, grape, beet): crow nights are the ones where the farm's layout matters, so their first one is gentle
- Day 42 is the Full Moon with the Scarecrow King in company - 0153's row from `SEASON_BOSSES`, which 0254 set; this task writes the company. The crows he summons come from his rule, not from rows, so the forecast's count leaves them out by design (0254): day 42's note says he calls crows, and the journal gives the peak count of crows alive on day 42 in `play_nights`
- The Blood Moon (0257) may roll from autumn: list which autumn days roll it for seeds 0-4 in `tools/nights.py`, and pin `event` off on an introduction night it would drown (0270's field)
- Read 0259's `implementation/MATCHUPS.md`: every night has an answer in what autumn's arsenal (0234) has unlocked by that day - the mortar, the pumpkin catapult and the garlic braid - and the journal says which weapon each new enemy is meant to teach
- The template keeps climbing from summer's final numbers (`python tools/play_nights.py 29 42`); notes in the authored voice; every night fits the night length (0137); DATA moves on purpose, SIM only if a day the determinism scenario fights changed

  - done when: `_task_0273_autumn_nights` in `src/tools/headless_v1.gd`: days 30-42 send only kinds introduced by that day, only from the east, south-east and north; the crow and the digger are first sent on their introduction days, on different nights; the Scarecrow King is on day 42 and nowhere else; days 35 and 42 are the largest of their halves in hit points
  - done when: `python tools/nights.py 29 42` and `python tools/play_nights.py 29 42` output in the journal, with the Blood Moon days for seeds 0-4 and the matchup line for each new enemy

### 0290 - The 1.0 visual gate

Waits on 0122, 0123, 0124, 0125, 0143, 0144, 0145, 0146, 0147, 0161, 0162, 0163, 0164, 0197, 0198, 0199, 0200, 0201, 0202, 0203, 0204, 0205, 0206, 0207, 0208, 0209, 0210, 0211, 0212, 0213, 0214, 0215, 0216, 0217, 0235, 0236, 0237, 0238, 0239, 0240, 0241, 0242, 0243, 0244, 0245, 0258, 0260, 0261, 0262, 0263, 0264, 0265, 0266, 0267, 0268, 0269, 0288.  Likely files: `src/tools/shot.gd, src/tools/capture_menus.gd, implementation/shots/0290/, implementation/backlog/CATALOGUE.md, implementation/backlog/packs/, tools/backlog/, implementation/prompts/, implementation/PROGRESS.md`.

Before 1.0 ships, look at the whole game in its real frame - every screen, season, family and state at 1920x1080, by day and by night - and prove nothing is still drawn on a stand-in. Like sprite task 0020: no claim of done from one nice farm shot.

- Capture at 1920x1080 by day and by night with `python tools/shot.py 0290 <scenarios> --fhd`, the showcases behind `python tools/show_art.py` and `src/tools/capture_menus.gd`; add the `shot.gd` scenarios that are missing (a night scenario uses 0130's camera hook)
- The world, at least: the four seasons' ground and trees, snow included; the farmer walking, running, every work verb and facing, in bed, passed out, fishing and reacting; the guardian and the cursor; every crop stage, tilled and trampled ground; the animals and their buildings, wrecked-but-standing included; machines, the bin, the peddler, the house tiers; every defence at every level with hurt, fire, wreck and its tarp; every enemy walking, attacking and dying; the four bosses and their telegraphs; effects; fog, rain, the Full and the Blood Moon
- Every screen: title, pause, options, the day HUD with clock and calendar, the forecast, the night HUD with hotbar and powers, the morning report, inventory, stall, workshop and machines, the tech tree by season, the fishing minigame, the fish book and collections, statistics, the year's end and the credits - in English and Portuguese where there are words
- Open every file. Judge scale against Stardew Valley at 1080p and the look against `docs/reference-sheet.png`: one art pixel is 4x4 physical pixels, the farmer about 128 px tall, and no new family drawn at the six legacy fixtures' 2x unless the journal says why
- 0120's placeholder check (`python tools/placeholders.py` and `_task_0120_placeholders` in `headless_v1.gd`) reports nothing on a stand-in, and `python implementation/backlog/assets.py list` shows every pack `integrated`, A057 excepted only if declined. 0289 is not a dependency because A057 is optional: if it is still todo, read the pack's status - declined (`blocked` with the owner's words) means run 0289's decline path here and close it; approved means block this gate until 0289 is done; anything else (todo, generating, review) means block it `waiting for asset A057 (Codex)` - a later decline then needs `python tools/task.py todo 0290` by hand
- Fix here what needs no new art and is small (placement, pivots, scale, sorting, the wrong state shown); a view fix bigger than that, and anything that needs new art (a correction pack in `implementation/backlog/packs/`), becomes a follow-up task in `tools/backlog/` with the next free id. Add each follow-up id to 0297's deps (in `tools/backlog/part13.py` and on the `Depends on:` line of its prompt, which `gen_backlog.py` does not overwrite) so 1.0 cannot ship ahead of it. This task never draws or generates art, and its fixes are view only: neither hash moves
- A 1.0 delivery catalogue, `implementation/backlog/CATALOGUE.md`, modelled on `implementation/sprites/DELIVERY.md`: per family the pack id, canvases, pivots, animation and state coverage, the capture that shows it, and its known limits

  - done when: Every capture in `implementation/shots/0290/` was opened; the journal lists what was looked at per family and per screen, what was wrong and what was done about it
  - done when: 0120's placeholder check prints zero packs pending (A057 excepted only when declined and 0289 closed), quoted in the journal
  - done when: The catalogue names a capture for every family and state in the lists above
  - done when: Every follow-up is filed as a task (and a pack when it needs art) with ids, each one in 0297's deps, none left as prose

### 0274 - Winter's fourteen nights

Waits on 0270, 0251, 0252, 0255, 0259, 0273.  Likely files: `src/core/game_data.gd (`KEY_NIGHTS`, winter's `SEASON_NIGHTS`), src/tools/headless_v1.gd`.

Winter is the exam: every side open, the frost zombie that slows the towers it dies beside, the wraith that cannot be shot outside the light, and the Winter Lord on day 56. Nothing grows, so these nights are fought with what autumn put away.

- Days 44-56 fight; day 43 is 0154's calm night after the Scarecrow King. Every side is open (0157), but the sides new to winter join over several nights through the side join days of winter's template (0270) and key nights - never on an introduction night
- The frost zombie and the wraith are introduced on different nights, never together; the Full Moon on day 49 sends what is already known; the night after each introduction bites
- The first wraith night is small and answerable with the light a farm has without a searchlight - the porch, the flare, burning cells (0229's light rule) - because it is the night that teaches the searchlight
- Day 56 is the Full Moon with the Winter Lord in company - 0153's row from `SEASON_BOSSES`, which 0255 set; this task writes the company - and the largest night of Year 1; 0160's ending hook fires when he falls
- Nothing grows outdoors in winter (the plan; the rule is 0171), so the money for these nights was made in autumn: prefer a climb in variety - sides, kinds, events - over a climb in bodies
- Read 0259's `implementation/MATCHUPS.md`: every night has an answer in what winter's arsenal (0234) has unlocked by that day (`python tools/play_nights.py 43 56`) - the searchlight and the electric fence - and the journal says which weapon each new enemy is meant to teach
- Notes in the authored voice; every night fits the night length (0137); DATA moves on purpose, SIM only if a day the determinism scenario fights changed

  - done when: `_task_0274_winter_nights` in `src/tools/headless_v1.gd`: days 44-56 send only kinds introduced by that day; the frost zombie and the wraith are first sent on their introduction days, on different nights; the Winter Lord is on day 56 and nowhere else; day 56 is the largest night of days 1-56 in hit points
  - done when: `python tools/nights.py 43 56` and `python tools/play_nights.py 43 56` output in the journal, with the matchup line for each new enemy and the night each side first opens
  - done when: `python tools/nights.py` for the whole year, after all four seasons, is in the journal: the year's curve in one table

### 0275 - The worst night of the year, within budget

Waits on 0274, 0234, 0248, 0233.  Likely files: `src/tools/perf_check.gd, src/tools/perf_names.gd, tools/perf.py, tools/perf_baseline.txt, src/tools/headless_v1.gd`.

The benchmark's worst case is still Spring 14, where 0153 moved the MVP's night ten. Move it to the heaviest night 1.0 can produce - Winter 14 with the Winter Lord, a rat swarm and every defence on the farm - and settle the cost profile before 0277 simulates thousands of nights on it.

- `_the_worst_case()` in `src/tools/perf_check.gd` sets the run to Winter 14 (day 56) the way the calendar reads it (0151), not through `nights_won`, and still stops at the busiest moment
- At least one of every `GameData.DEFENCES` entry - the plan's fourteen and whatever 0231 added - at the top `TOWER_LEVELS` level, powered and with ammunition, placed where the fight is through the build-step road of 0119; 0218's swarm scenario is folded in or kept as its own rows - say which
- Every lazily built path field in 0218's registry is built tonight, adding the kinds that force one if day 56 lacks them, so `path_refresh` is timed with all of them; the heaviest event day 56 can roll is on - fog or rain, since 0257 keeps the Blood Moon off boss nights - by picking a seed `Weather` gives it, never an override in core
- `COUNT` lines for each defence family, each enemy kind, the boss and the fields built, so a reader can see the case is the case
- `PerfNames.NIGHT`/`DAY` already have to match `Sim.tick` (`_task_0102_budget`); every one of those names gets its branch in `perf_check._tick_one` (today an unmapped name only `push_error`s and still prints a row), and `_a_busy_day` becomes the 1.0 day: tilled grass, season crops, sprinklers, animals, every machine queued
- The budgets do not move: `TICK_BUDGET_US` 8333 and `PATH_BUDGET_US` 33333 in `tools/perf.py`. If the winter case breaks one, optimise here, hash-neutral, or block with the measured numbers - never raise a budget
- Print the wall time of one winter night simulated end to end as a `COUNT` (not budgeted), because 0277 multiplies it by thousands
- `python tools/perf.py --accept` moves the baseline; every row's old and new number goes in the journal, with why it grew. A benchmark and hash-neutral optimisations only: neither hash moves

  - done when: `python tools/perf.py` passes on the new baseline, with `night_tick` and `path_refresh` under their budgets on the winter case - both numbers, and the old ones, in the journal
  - done when: The `COUNT` lines show one of every `DEFENCES` entry, the Winter Lord, a rat swarm and every named path field built
  - done when: `_task_0275_perf_year` in `src/tools/headless_v1.gd` reads `perf_check.gd` and asserts every name in `PerfNames.NIGHT` and `DAY` has a branch in `_tick_one`, the way `_task_0102_budget` reads `sim.gd`

### 0276 - The autoplayer plays a whole year

Waits on 0142, 0194, 0233, 0234, 0275, 0166, 0171, 0180, 0186, 0191, 0221.  Likely files: `src/tools/autoplay.gd, src/tools/autoplay_run.gd, tools/autoplay.py, src/tools/play_nights.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd`.

0142 taught the robot to sleep; this teaches it the rest of 1.0, so balance can be measured over a whole year: crops by days and season, the fishing minigame, animals and machines, the bin and the peddler, cursor building and repairs, the powers, and carrying on through losses and boss repeats.

- Each policy in `Autoplay.POLICIES` gains a day plan (its earners in order: season crops, fishing, animals, machines, mining, chopping), a night plan (what to place, upgrade and repair by cursor in the build step and during the waves, when each power fires) and a bedtime. `towers`, `walls`, `economy` and `balanced` keep their character; `balanced` is declared the average player 0277 balances against
- Everything goes through the intent road a player uses: tilling and watering through the verbs, fish landed through the minigame's press intents (0180), products collected, goods into the shipping bin, seeds and animals from the peddler in his hours, tool and house tiers bought (0173, 0191), night loot picked up (0221); `build_cell`, `build_place`, `build_upgrade` and `ability_cell` (0135) with 0232's power API at night. Nothing is granted by writing `state`
- Walking is counted from here on (path length at `PLAYER_SPEED`), or the journal measures why not: on an 80x65 farm with an 8-10 minute day (0166), 'walking is free' is no longer close to a player
- `Autoplay.play(seed, policy, days)` follows the calendar, not a night count: calm nights, Full Moons, winter with nothing growing (0171), boss nights repeated until the boss falls - with a cap so a tool run always ends, reported when hit - and losses that move the calendar on. Per night: held or lost, house left, essence and money; per season: losses and boss repeats
- `autoplay_run.gd` prints one machine-readable `RUN` line per run (policy, seed, losses per season, boss repeats, money and essence at each season's start) beside today's lines, so `tools/balance.py` keeps working until 0277 moves its parser onto `RUN` (moved there from here); `python tools/autoplay.py --year [runs]` prints the per-policy table and the dominant-strategy alarm per season
- `play_nights.gd` plays the whole year by default with its scripted floor, following the boss repeat rule
- A year is long: print the wall time per run; if 8 seeds of 4 policies are impractical in one process, split the runs across processes (the data does not change inside a run set) and say how long it took
- `_task_0067_autoplay` and `_task_0068_balance` in `src/tools/headless_check.gd` follow the new policy fields and stay one day and one night; nothing in the suites plays a season. Tools only: neither hash moves

  - done when: `_task_0276_year_autoplay` in `src/tools/headless_v1.gd`, its time measured, printed and under 15 s (over it, the slice's day plan shrinks - bed as soon as it is done - and the cap does not move): from a prepared mid-summer state the `balanced` policy plays one day and one night twice on one seed with the same result; that day landed a fish through the minigame, shipped goods through the bin and collected an animal product; that night placed a defence by cursor in the build step and fired a power
  - done when: `python tools/autoplay.py --year 8` completes for all four policies; its table and wall time are in the journal
  - done when: `python tools/balance.py` with a short sweep still finishes on today's lines and leaves the git tree clean (its move onto `RUN` is 0277's)

### 0277 - Balancing the year

Waits on 0271, 0272, 0273, 0274, 0276, 0259.  Likely files: `tools/balance.py, tools/autoplay.py, src/core/game_data.gd, implementation/BALANCE.md, implementation/PROGRESS.md, src/tools/headless_v1.gd`.

The phase's own target: an average player reaches winter having lost two to four nights, and every boss falls. Measured with the year autoplayer, moved with levers, written down - the way 0068 did it for ten nights.

- The target as numbers: the `balanced` policy loses 2-4 nights before Winter 1 (day 43), averaged over at least 8 seeds, and every boss falls for it on every seed. A boss that walks off at dawn is a repeat, not a loss (0153), and is counted apart
- `tools/balance.py` moves onto 0276's `RUN` lines (its parser, moved here from 0276) and sweeps the year: `NIGHTS = 10` and the win-rate-per-night arithmetic become survival per day and losses per season; `LEVERS` is re-chosen for 1.0 (season sizes, the Full Moon percent, boss hit points, house tiers, the night length, essence and night money), each regex matching exactly one line
- Size the sweep before running it: a year run takes minutes (0276 printed it, 0275 the winter night), so levers x values x 8 seeds x 4 policies is days of wall time. Sweep with the `balanced` policy on 4 seeds, run seeds as parallel processes, and keep the full `--year 8` for all four policies for the before and after tables; each sweep's wall time goes in BALANCE.md
- It keeps its safety: it refuses a dirty `game_data.gd`, holds the lock file and restores the file in a `finally`
- Start with the instrument, as 0068 found: before moving a lever, ask a losing run what it was doing; a fault in the autoplayer is fixed there and named in BALANCE.md, not tuned around
- No policy wins every night of the year by a wide margin (the dominant alarm, per season); no day sits at 0% survival across every policy; a lever that moves nothing across its range is reported as dead weight
- Re-run 0259's matchup tool after the levers move: every weapon is still the best buy somewhere and every enemy still needs a different answer
- Levers move in `src/core/game_data.gd` with their `# LEVER` ranges kept true and `GameData.validate()` passing. DATA moves on purpose; SIM moves too where the determinism scenario reads a moved lever - old and new numbers of both in PROGRESS.md
- A new top section of `implementation/BALANCE.md`, 'The year': losses by season and policy, boss repeats, the sweep tables, every applied change with its old and new value, and what is still off

  - done when: `python tools/autoplay.py --year 8` after the changes: `balanced` loses between 2 and 4 nights before day 43 on average and every boss falls on every seed - the table is in BALANCE.md
  - done when: The sweep's own output in BALANCE.md shows no day at 0% survival across every policy and the dominant alarm silent in every season
  - done when: The season groups of 0271-0274 still pass with the moved levers, or the journal says which asserted relation the data proved wrong and how it was rewritten
  - done when: `python tools/balance.py` reads only `RUN` lines, and a short sweep leaves `game_data.gd` restored, the git tree clean and no `.balance-lock` behind

### 0278 - The economy across a year

Waits on 0277.  Likely files: `src/core/game_data.gd, src/core/shop.gd, src/tools/autoplay.gd, src/tools/autoplay_run.gd, tools/autoplay.py, implementation/BALANCE.md, src/tools/headless_v1.gd`.

The plan's rule of thumb, checked in every season and not only the first: a good day buys about one new defence, a boss costs five to seven focused days, and winter - when nothing grows - lives off what autumn put away.

- Measure first, with the year autoplayer: per season, what a focused day earns by earner (crops, fish, animals, machines, mining), the price of each of that season's new defences (0234's money and materials, at stall prices), and what was standing on the night each boss fell - `python tools/autoplay.py --economy` or an equivalent report
- Rule of thumb: one well-worked day at the start of each season buys about one of that season's new defences - the ratio per season in BALANCE.md, each within 0.7-1.5 or the journal says why
- A boss costs 5-7 focused days: the value of the build that beat it, less what stood at the season's start, divided by that season's focused-day income
- Winter: nothing grows (0171), so the `balanced` policy enters day 43 with autumn's stock, and its winter income (fish, mining, machines, animals) plus that stock pays for winter's defences and repairs to day 56 without running out of food or ammunition - reported per run
- Costs before prices: prefer moving defence costs, machine times and yields, starting from 0234's day-to-defence table in BALANCE.md; if prices must differ by season, one `# LEVER` table (a percent per resource group per season) read through `Shop.sell_price` (it takes only an id today: it gains the season, and every caller follows) and so by the bin, listed in `digest()`
- `GameData.check_stall` and `check_chain` already take the prices as an argument: `validate()` runs them at every season's prices, so markups stay above prices and every recipe still adds value in every season
- DATA moves on purpose, SIM too if the determinism scenario's shop visit reads a moved price - both in PROGRESS.md; re-check 0277's target after the changes

  - done when: BALANCE.md 'The economy across a year': per season the focused-day income by earner, the day-to-defence ratio, the days each boss cost, and winter's stock from day 43 to day 56, all measured
  - done when: `_task_0278_season_economy` in `src/tools/headless_v1.gd`: the stall and chain checks pass at every season's prices, and a doctored price that breaks the chain in one season only is refused
  - done when: 0277's target still holds: the `--year 8` table after the changes is in the journal

### 0279 - Year 2

Waits on 0160, 0277.  Likely files: `src/core/game_data.gd, src/core/almanac.gd, src/core/endless.gd, src/core/waves.gd, src/core/run.gd, src/ui/result_screen.gd, assets/locale/strings.csv, src/tools/nights.gd, tools/nights.py, src/tools/perf_check.gd, tools/perf.py, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd`.

After the Winter Lord the farm carries on, and today that means the MVP's endless curve. Replace it with the calendar: Year 2 and every year after replay the four seasons from 0270's templates, heavier each year, with the bosses back on every day 14.

- Days past 56 resolve through 0270's generator (wherever it lives): the year and the season from 0149's `Calendar` helpers, the season's template scaled by a per-year growth `# LEVER` that is added, not compounded (the `ENDLESS.growth_percent` lesson), with the mix allowed to lean heavier each year. The plan wants Year 2 heavier 'a cada estação': the journal compares Year 2's spring with Year 1's winter, and a drop between them stands only with its reason written down
- Every season's day 14 sends its boss again (0153's row), with hit points scaled per year by a `# LEVER` through the `max_hp` road 0257's elites use, read by `Combat.full_hp` (0246); the boss-repeat rule (0153) and the calm night after a fallen boss (0154) hold every year, so Spring 1 of Year 2 is calm
- Later years have no introductions; the Full Moons on 7 and 14 stay - Year 1's records scaled, or generated with the Full Moon percent: decide one and assert it
- Sides and events keep to their season as in Year 1, so each season keeps its character; the Blood Moon comes earlier only if a lever says so
- Retire the MVP curve: `Endless` and the `ENDLESS` table, `giant_every` levers included (0153 left them to this task), leave `plain_night`, `check_nights` and `digest()` (a reader of `Endless._stream_for`, such as 0256's `Weather`, keeps the helper in its new home); `_task_0070_endless` in `src/tools/headless_check.gd` is rewritten over the later years or removed with the reason in the journal; 0160's carry-on lands in Year 2 of the calendar, and `Run`'s `endless` flag means 'past Year 1' or goes. A saved key that changes meaning gets a `State.VERSION` bump, a migration and a golden (never a key named `moon_phase`); otherwise no bump. `validate()` checks the new levers' ranges
- 0160's ending screen shows once, after Year 1; a later Winter Lord ends his year with a line in the morning report (`result_screen.gd`): a new `RES_YEAR_SURVIVED` row (key,width,en,pt_BR: YEAR %d SURVIVED / ANO %d SOBREVIVIDO, width measured). The HUD's 'SPRING 3  YEAR 2' is already 0149's `DHUD_DATE_YEAR`; add a `year_two` scenario (a Year 2 day) to `src/tools/shot.gd` to see it
- `python tools/nights.py --years 3` prints Years 1-3 by season with sizes, bosses and events; generation stays a fresh `(seed, day)` stream
- The curve stays sane to Year 3: `perf_check.gd` takes a date (e.g. `--date=<n>`, forwarded by `tools/perf.py`, which compares and accepts nothing on such a run) and times 0275's case on Year 3's heaviest night; the `balanced` policy plays into Year 2 on one seed with `Autoplay.play(seed, policy, days)`
- Hashes: DATA moves (the new levers; `ENDLESS` leaves the digest). SIM should not - the determinism night is day 1 - unless a state key goes (e.g. `endless`), which moves it on purpose; both numbers in `implementation/PROGRESS.md`

  - done when: `_task_0279_year_two` in `src/tools/headless_v1.gd`: day 57 is Spring 1 of Year 2 and calm; a Giant spawned on day 70 has more `Combat.full_hp` than one spawned on day 14; on every day of the year but Spring 1 (Year 1's is the tutorial night), Year 2 sends at least Year 1's hit points on the same day and Year 3 at least Year 2's; days 57-168 resolve for seeds 0-2 without touching `state["rng"]`
  - done when: Year 3's heaviest night is inside `TICK_BUDGET_US` and `PATH_BUDGET_US` (`python tools/perf.py --date=<it>`) - the numbers in the journal
  - done when: The `python tools/nights.py --years 3` summary and where the `balanced` policy fell in Year 2 are in the journal
  - done when: `python tools/shot.py 0279 year_two --fhd` opened: the year label fits, in English and in Portuguese

### 0280 - Checkpoint: do fifty-six nights tire?

Waits on 0277, 0278, 0279, 0159, 0258.  Likely files: `implementation/PROGRESS.md, implementation/shots/0280/, src/tools/shot.gd, src/tools/nights.gd, implementation/prompts/ (later prompts, if the answer needs it), tools/backlog/ (new tasks, if any)`.

The plan's Phase 6 question, answered honestly: 'as 56 noites cansam?' A checkpoint like 0027, 0066 and 0148, not a feature - a 'yes' found here is worth more than every polish task after it.

- Play, not only measure: the year autoplayer for all four policies, `python tools/nights.py` for the year, and at least one night of each season and each boss night driven through the real game with the cursor, by mouse and by pad (a real pad if one is attached; say honestly if it was synthetic), and looked at
- Captures at 1920x1080 (`python tools/shot.py 0280 <scenarios> --fhd`): each season by day and at night mid-wave, a Full Moon, a fog or rain night, a Blood Moon, and the four bosses mid-fight. Reuse what exists - 0159's `season_*`, 0258's `fog`, `rain`, `blood_moon` and `full_moon`, 0246's `boss` and the boss scenarios of 0253-0255 - and add to `src/tools/shot.gd` only what is missing (a tool change, hashes untouched)
- Look for sameness with numbers, computed by a tool rather than by eye (a `--sameness` report in `src/tools/nights.gd`): per season, how many nights share a mix of kinds and sides; the longest run of nights that bring nothing new (no new enemy, side, weapon, event or boss); how often the forecast says the same thing two nights running
- Answer in the journal: do the fifty-six nights tire, where and why, with the stretches named by day - then what would fix it (more events, fewer generated nights, new key nights, shorter seasons) and what each fix costs
- Fixes that fit go into the later prompts (P16-P17), or into new tasks in `tools/backlog/part*.py` run through `python tools/gen_backlog.py` - each with a free id and added to 0295's deps, so the playtest waits for it; anything that changes an owner decision (14 days a season, Normal only) is a recommendation to the owner in the journal, not an edit made here
- If the honest answer is that the year tires and the cure is bigger than prompt edits, mark this task blocked with the reason (`python tools/task.py blocked 0280 "<why>"`), so 0295 (the playtest of the year) waits for the owner
- No rule changes here: nothing in `src/core/` moves, and neither hash moves

  - done when: `implementation/shots/0280/` holds the FHD captures listed above, every one opened and looked at; the journal names what is wrong in any of them
  - done when: The journal has the year's autoplayer table, the sameness numbers and the longest stretch with nothing new, by day
  - done when: The journal answers 'do the fifty-six nights tire?' in plain words and lists every prompt edited and every task added because of it

### 0291 - Saves into 1.0

Waits on 0151, 0156, 0165, 0279, 0287.  Likely files: `src/app/save.gd, src/tools/make_goldens.gd, src/tools/play_goldens.gd (new), tools/verify.py, tools/goldens/, src/ui/title_screen.gd, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/headless_check.gd, assets/locale/strings.csv`.

Somebody who played the 0.1 prototype opens 1.0 and finds their farm in the calendar, or is told plainly where it went - never a crash and never an empty title. This is the last look at every save shape before a stranger's save depends on it.

- An inventory first, in the journal: every `State.VERSION` from 1 to now, the task that bumped it, its step in `Save.migrations()` and its golden in `tools/goldens/`. A version with no step is fixed here. Only the 0.1 shape (State 4) was ever in a player's hands, so the versions in between need their step, not a golden each
- The real 0.1 golden is 0151's `run-v4.sav` (made from the MVP commit `bea89a88`: State 4, BuildInfo 0.1.0). If it is missing, make it the same way: check that commit out in a `git worktree` outside the repository, `--import` it, run `make_goldens.gd` there with `GODOT` set, copy back only the v4 goldens and remove the worktree. A golden that exists is never regenerated
- Two declared shapes beside it, made by `make_goldens.gd` from `run-v4.sav`'s raw payload (no migration, no reconcile - read underneath `Save.read_run_at` the way `headless_check`'s `_payload_of` does), each consistent with itself the way the MVP moved its counters (`day`, `night`, `nights_won`, `nights_paid`, the bosses down), and declared as shapes in the script's header like `run-v1-newer.sav`: `run-v4-endless.sav`, a run carried on past night 10 (`endless` true, `nights_won` 11, in DAY), and `run-v4-finished.sav`, a won MVP run (`nights_won` 10, `endless` false, in RESULT with `last_result.run_over` true)
- A written rule, per shape, migrate or archive, decided by one pure function in `Save` (e.g. `Save.verdict(state)`, asked of the migrated state): a run inside nights 1-10 migrates to its calendar day through 0151's step; the endless and finished shapes migrate only if they land on a day whose night resolves and whose boss bookkeeping (0153's hold at day 14) is consistent, and are archived otherwise. The rule and why go in the journal and in `Save`'s doc comment
- Archiving never deletes, and only the player's run moves: `Save.read_run()` (`RUN_PATH`) moves an archived run to `user://archive/run-v<N>-<k>.sav` (never over a file already there) and reports a new `Save.ARCHIVED` trouble; `read_run_at` gives the same verdict and moves nothing, so a golden in `res://` is never touched. CONTINUE is absent and the title says so once, the `SAVE_ARCHIVED` line on its own rather than under `SAVE_UNREADABLE`/`SAVE_KEPT` (nothing was unreadable), a row with a real width - e.g. 'Your 0.1 run is kept in the archive folder. 1.0 starts a new year.' / 'Sua partida da 0.1 ficou guardada no arquivo. A 1.0 começa um ano novo.'
- The profile is kept: a 0.1 profile (`runs_started`, `runs_won`, `best_night`, `stats`) loads through `Save.read_profile` with its numbers, and every 1.0 key (the fish book of 0182, the collections and achievements of 0287) at its default. 0160 left `best_night` to this task: decide and record whether it still means 'most nights won in one run'. A key whose meaning moved gets a named step in a profile version of its own (e.g. `Save.PROFILE_VERSION` and a `profile_migrations()` table run through `Save.step_up` in `read_profile`; `FORMAT_VERSION` is the file header's, not the profile's), never a silent reread. A `profile-v1.sav` shape goes in `tools/goldens/` (add `Save.read_profile_at`/`write_profile_at` if the pair is missing). The 0.1 `settings.cfg` is 0293's, beside its `Settings.VERSION` bump
- Fix `_task_0104_saves` in `headless_check.gd`: `_goldens()` lists only `run-v*.sav` (the profile golden and any settings fixture are not runs); a shape the rule archives is asserted refused with `Save.ARCHIVED`, not 'loads'; and 'a farm somebody built on' compares against the occupant count of `State.create(seed)` in this build, not the MVP's 106 - since 0156 a fresh farm can pass that number on its own
- A day and a night for every golden is a tool, not the suite (a dozen goldens times a night to dawn is minutes of ticks): `src/tools/play_goldens.gd` loads every run golden the rule migrates, plays 600 day ticks, goes to bed and through 0118's road (START, the night runner to dawn, `confirm_result`), and checks it wakes on the next calendar date in DAY with no enemy left on the farm; `tools/verify.py` runs it as a `goldens` row through `check_script`. The suite keeps load + 600 ticks per golden
- Saves never touch the determinism scenario: SIM and DATA stay where they are

  - done when: `_task_0291_saves` in `src/tools/headless_v1.gd`: each 0.1 shape (`run-v4.sav`, `-endless`, `-finished`) gets the rule's verdict; a migrated one lands on the date the rule says and plays 600 ticks; an archived one, copied to `Save.RUN_PATH` and read through `Save.read_run()`, ends byte for byte under `user://archive/`, `Save.can_continue()` is false and the title's `trouble_says()` holds the `SAVE_ARCHIVED` line (the group removes the files it made)
  - done when: the same group: the 0.1 profile golden loads through `Save.read_profile_at` with its numbers (and `best_night` as the journal decided) and every 1.0 key at its default
  - done when: verify prints the `goldens` row passing: every migrated golden woke on its next date in DAY with no enemy on the farm - the dates and the row's time in the journal
  - done when: the title with the archive line captured at 1920x1080 in both languages (`python tools/shot.py 0291 --title --fhd` and `--title --fhd --pt_BR`, staging an archived run in `shot.gd` the way the crash dialogue is staged, and putting back any real `user://run.sav` afterwards) and opened: the line fits and sits clear of the menu

### 0294 - Every new word in Portuguese

Waits on 0287, 0293, 0291, 0292.  Likely files: `assets/locale/strings.csv, tools/i18n_check.py, src/ui/names.gd, src/tools/headless_v1.gd`.

Portuguese is the owner's language and most of the audience's. Every line 1.0 added gets read again as a whole: one name for each thing, sentences that agree in gender and number, and nothing running off its button.

- Read every row added since 0112 (`git log -p -- assets/locale/strings.csv` from 0112's commit on) in both languages, then on screen. The journal lists every pt_BR change with the before and the after
- One name per thing, and the plan's: its names become a glossary in `tools/i18n_check.py` (key to expected pt_BR, compared without case) that fails a row which drifts - the seasons, Lua Cheia, Lua de Sangue, neblina, chuva, essência, caixa de envio, mascate, banca, guardião, COMEÇAR, the crops of §3.1, the fish of §3.2, the machines of §3.5, the defences of §5, the enemies and bosses of §6, ossos, farinha de osso, pedras da lua
- Three MVP names disagree with the plan today: `DEF_FLAME_TOWER` 'torre de fogo' (plan: lança-chamas), `ENEMY_BREAKER` 'quebrador' (destruidor) and `ENEMY_TANK` 'brutamontes' (tanque). The plan wins unless the journal records the owner choosing otherwise; the plurals and every sentence that uses them move with them
- Counted names have plurals: every enemy, fish, crop and item a line counts (the forecast's '34 andarilhos', the morning report, the fish book) has its `.other` row in both languages - the bare key is the singular, and a `.one` row exists only where the counted singular differs from the name, as `I18n.plural` documents
- Agreement: a pt_BR line that puts a name into a sentence agrees with it ('a Colheitadeira caiu', 'o Gigante caiu'). Where one template cannot agree with every name, rewrite it so the name stands alone ('Caiu: %s') rather than adding gender data to the rules
- Widths: every row added since 0112 that is drawn in a fixed control (HUD label, button, hotbar tooltip, option row) and still has `width` 0 - which means unchecked - is measured and given its real width. `python tools/i18n_check.py --report` names the widest lines, and the widest pt_BR ones are looked at on screen. `i18n_check` already refuses a glyph the font lacks; look at the accented ones in use (ã, õ, ç, ê, á, and capitals on buttons such as COMEÇAR) at 1920x1080 too
- `Names.KEYS` covers every id 1.0 added and `Names.NOTES` every tech node (already asserted); `ITEM_TECH` reads essence / essência (0219's rename, the id stays `tech`) and the glossary holds it there. Text only: neither hash moves

  - done when: `python tools/i18n_check.py` passes with the glossary enforced, and fails when one glossary row is changed by hand (tried once, reverted, said in the journal)
  - done when: `_task_0294_names` in `src/tools/headless_v1.gd`: every id in `CROPS`, `RESOURCES`, `DEFENCES`, `ENEMIES`, `BUILDINGS`, `RECIPES`, `TECH_TREE` and the fish species of 0179 has a `Names.KEYS` key whose row is non-empty in `en` and in `pt_BR` read straight from the table (no English fallback, no key printed as itself), and its pt_BR text differs from its English one unless the glossary marks the word as the same in both
  - done when: pt_BR captures at 1920x1080 of both HUDs, the forecast, the hotbar, the morning report, the fish book, the collections and every options page (`python tools/shot.py 0294 --fhd --pt_BR` and `capture_menus.gd -- --out=res://implementation/shots/0294/ --pt_BR`), opened one by one: no clipped, overlapping or English word

### 0295 - A playtest build of the year

Waits on 0280, 0291, 0292, 0293, 0294.  Likely files: `src/app/playtest.gd, src/ui/main.gd, tools/playtest.py, docs/PLAYTEST.md, src/tools/headless_v1.gd, src/tools/headless_check.gd`.

Put the year in front of somebody and learn from it: a build that says it is a playtest, a log of what 1.0 is about - bedtimes, the build step, dawn, seasons, lost nights - and a reader that answers 1.0's questions instead of the MVP's. It goes out with the art that has arrived, placeholders and all.

- The log learns the calendar: `Playtest.watch` writes the season and day when a day begins ('Spring 3 began'), the hour he went to bed or that he passed out at 02:00, how long the build step ran before START, how the night ended (dawn, all killed, the house fell) and when a boss night repeats - all in the `  m:ss  what` shape the reader parses
- A lost night no longer ends the session: today `watch` calls `run_ended` on `night_lost` ('the house fell on night N'), which in 1.0 is a setback inside a run. A session ends at the end of the year (0160's ending), at Abandon (`main.gd`) or when the window closes. `run_ended`'s 'reached night' reads the calendar date - 0151 named `playtest.gd` among the `nights_won + 1` readers; finish it here if it did not
- `tools/playtest.py` asks 1.0's questions: did they reach the first night; how long was Spring 1 in real minutes (the plan wants 8-10 for the day and 3-5 for the night); bed or pass-out, night by night; how long the build step ran; how far into the year they got and how many nights they lost per season (the plan's target is 2-4 lost before winter); where the notes cluster. `--self-check` gets a 1.0 sample log and fails when any answer comes back empty
- `docs/PLAYTEST.md` rewritten for 1.0 (it still says ten nights and a night you send for; 0117 only corrected what happens after night ten): what the game is now; the most useful stretch to play (Spring 1 to the Giant on day 14); what to try (bed early and late, the cursor by mouse and by pad, START, the bin, the rod); what to ignore, including the placeholders still on screen as `python tools/placeholders.py` (0120) lists them; the same F1 and local-log promises
- `_task_0105_playtest` in `headless_check.gd` stays true: if a line it reads has moved, rewrite it in the same change
- The build: `python tools/release.py --playtest` writes `build/playtest/` with `READ ME FIRST.md` beside it, and the badge says playtest. It builds only the Windows playtest preset, so no web budget is weighed here - `PACK_BUDGET` and `WIRE_BUDGET` are 0297's
- Nothing is sent: the build is made and checked and the journal says where it is. Handing it to a tester is the owner's call. Playtest code is `src/app/` and only reads the state: neither hash moves
- Questions the loop cannot answer - whether a stranger reads the week's lines (0293), whether a night is long enough - go into PLAYTEST.md's 'what to report', not into a guess in the journal

  - done when: `_task_0295_playtest_log` in `src/tools/headless_v1.gd`: a short scripted run through bed, START, dawn, a lost night and the next morning writes, in order, the lines the reader parses, and the session is still open after the lost night - the lost night parked through 0118's road with the house set to fall, so the group takes seconds, not two whole nights
  - done when: `python tools/playtest.py --self-check` passes with the 1.0 sample, and `python tools/playtest.py <folder>` on the log that group wrote answers every question
  - done when: `python tools/release.py --playtest` succeeds, including its 400-frame boot of the playtest build; `python tools/shot.py 0295 --title --playtest --fhd` shows the badge on the first screen - opened
  - done when: no 'ten nights' or 'night ten' is left in `docs/PLAYTEST.md`, in any case

### 0296 - The store page and trailer for 1.0

Waits on 0290, 0294.  Likely files: `docs/STORE.md, tools/gen_marketing.py, src/tools/shot.gd, tools/devlog.py, docs/devlog/the-trailer.gif, implementation/shots/trailer/, src/tools/headless_v1.gd, src/tools/headless_check.gd`.

The store page still sells the prototype: ten nights, about an hour, sixteen crops and a night you send for. Make it describe the year - seasons, going to bed, the guardian on the porch, dawn - in pictures from the real game and words the data can check.

- `docs/STORE.md` rewritten in both languages: a year of four fourteen-day seasons, the night that starts when he goes to bed (or passes out at 02:00), the guardian's cursor, dawn at 06:00, four bosses, what the days pay for; 'What is in it' with real counts; 'What is not' honest (nothing online, one farm, no stamina, no greenhouse, one difficulty); a length worked out from the day and night levers times 56, not hoped for. The pitch stays `design.md` §20 verbatim, which `gen_marketing.py --check` and `_task_0107_store` enforce
- Words the data can check: each count is a digit before a fixed noun in both sections ('12 crops' / '12 culturas'), and `_task_0296_store_copy` in `src/tools/headless_v1.gd` reads `docs/STORE.md` (the way `_task_0106_release` reads `CHANGELOG.md`) and fails when a count it states - crops, defences, enemies, bosses (`is_boss`), days in a season - disagrees with `GameData`
- Screenshots at 1920x1080 through `gen_marketing.py`'s `SCREENSHOTS`, its `capture()` passing `--fhd`: a spring day, the same farm in winter, going to bed, the guardian's build step with cursor and route, a wave holding, dawn with the survivors walking off, and the tech tree or the collections. Reuse the scenarios earlier tasks added (`python tools/shot.py --list`), add only the missing ones. Capsules keep `capsule()`'s rule - a whole-number `NEAREST` scale or a crop, never a smoothed resample - with `HUD_ROWS` scaled to the capture; if the header capsule comes out a close-up, pick a wider source shot and say so
- Rewrite `_task_0107_store` in `headless_check.gd` in place: the five picture names it looks for in `gen_marketing.py` become the new list; its pitch, `NEAREST`, `SWITCH_FRAMES` and no-`HTTPRequest` asserts stay
- The switch GIF and its stills come from `shot.gd --switch`, which 0129 opened with the bed beat: check it is 1.0's switch - he lies down and the farm goes dark - and fix the strip if it still sends for the night
- The trailer's four beats in `shot.gd` (`BEAT_DAY`, `BEAT_SWITCH`, `BEAT_NIGHT`, `BEAT_FALL` - names kept, `_task_0108_devlog` reads them) tell the 1.0 story: a day's work, going to bed, the guardian placing a defence and pressing START, a wave held until dawn. They still sum to `TRAILER_SECONDS * TRAILER_FPS`, and `devlog.py`'s `clip_caption` (EN and PT) says the new story
- The trailer goes through the devlog tool, and never bare (the bare command deletes the tracked frames before capturing): capture with `python tools/shot.py trailer --trailer`, look at the frames, assemble with `python tools/devlog.py --keep`. If a capture fails, `git checkout HEAD -- implementation/shots/trailer` puts the frames back. `python tools/devlog.py --check` (verify's devlog row) passes at the end. The devlog's 'what is not in it' list is 0297's, beside the Known issues it sits with
- `python tools/gen_marketing.py` makes the set in `build/store/`; nothing is uploaded. Captures and copy only: neither hash moves

  - done when: `python tools/gen_marketing.py` builds the set and `--check` passes; every screenshot and capsule is opened at full size and named in the journal
  - done when: `_task_0296_store_copy` passes, and fails when one count in the copy is changed (tried once, reverted, said in the journal); the rewritten `_task_0107_store` passes
  - done when: `docs/devlog/the-trailer.gif` is remade (its size in the journal) and watched start to finish: the bed, the cursor, START and dawn are all in it
  - done when: `python tools/devlog.py --check` passes and `git status` shows the trailer frames replaced, not missing

### 0297 - Releasing 1.0

Waits on 0290, 0291, 0292, 0293, 0294, 0295, 0296.  Likely files: `src/core/build_info.gd, CHANGELOG.md, implementation/RELEASE.md, export_presets.cfg, tools/release.py, tools/devlog.py, docs/devlog/, tools/goldens/, src/tools/headless_v1.gd`.

Run the checklist 0106 wrote, for 1.0: one version everywhere, a changelog a player would recognise, both builds made and proven, the known issues told honestly - and then stop, because publishing is the owner's.

- Every task below 0297 is done (`python tools/task.py stats`). One that is not - an optional art leaf such as 0289 the owner declined, or a blocked task - is closed by the owner's word or listed under Known issues with why. No release over a todo nobody explained
- One version: `BuildInfo.VERSION` becomes `1.0.0` and `STAGE` stops saying prototype; `CHANGELOG.md` gets a 1.0.0 section on top (`_task_0106_release` requires one); both Windows presets in `export_presets.cfg` (Windows Desktop and Windows Playtest) get `application/file_version` and `application/product_version` (four numbers, `1.0.0.0`). `_task_0297_release` in `src/tools/headless_v1.gd` fails when any of them disagrees with `BuildInfo.VERSION`
- The changelog in sentences a player would recognise: a year of seasons, going to bed, the guardian, dawn, the new crops, fishing, animals, machines, defences, enemies and bosses, collections, the new options - and what happens to a 0.1 save (0291's rule)
- The save the next version must read: if `tools/goldens/run-v<State.VERSION>.sav` is missing, `make_goldens.gd` writes it from this build, and nobody regenerates it after
- `implementation/RELEASE.md` brought to 1.0 and run top to bottom: the tag says `v1.0.0`; step 3 names 0291's 0.1 goldens; Known issues rewritten from the journal (0280's answer, 0295's playtest, anything still on a placeholder, 0290's follow-ups, the perf and wire numbers); Rollback says a 0.1 run is migrated or archived, never eaten. Keep the commands and headings `_task_0106_release` looks for
- The devlog describes 1.0 (moved here from 0296): `devlog.py`'s 'What is not in it' stops reading `design.md` §15 and lists what is not in 1.0 from the plan (the greenhouse of §3.1, stamina in §3.9, the Nightmare mode of §11, the one-farm pillar of §3.3 and §12) on both pages, keeping the heading `_task_0108_devlog` reads; its 'still wrong' list is the Known issues above. `docs/devlog/preamble.md` is the owner's opinion and is left alone - the journal asks for a 1.0 paragraph
- `python tools/release.py` - verify, stamp, both exports, the pack check, the budgets, the 400-frame boot - passes. If `PACK_BUDGET` or `WIRE_BUDGET` fails, find what grew from the pack listing and move it once, deliberately, with the old and new number and the biggest files in the journal - the way a hash moves. Version, words and builds only: neither hash moves
- Step 6's smoke test by hand is the owner's wherever the loop cannot do it (the Web build in a browser, a pad in the hand): the journal says what the tools checked and what is left for a person, and never claims a hand test that did not happen
- Nothing leaves the machine: no `git push`, no `git push --tags`, no upload. Commit the release (the runner loop's step 6) and only then, `release.py` having passed, make the annotated tag `v1.0.0` on that commit, so it holds the stamped `BuildInfo.BUILT`; the journal ends with the push and upload commands for the owner

  - done when: `python tools/release.py` passes and prints both builds against their budgets; the numbers are in the journal
  - done when: the title screen shows the 1.0.0 `BuildInfo.short()` - captured with `python tools/shot.py 0297 --title --fhd` and opened
  - done when: `_task_0297_release` fails on a preset whose version disagrees (tried once, reverted) and passes on the real ones; `python tools/devlog.py --check` passes with the 1.0 list
  - done when: `git tag -l v1.0.0` lists the local annotated tag on the commit holding this task's changes, `git status` shows nothing of this task uncommitted, and nothing was pushed

## 0 - Foundation  (12/12)

- [x] **0001** [Godot project scaffold](prompts/0001-project-scaffold.md)
- [x] **0002** [Fixed-timestep deterministic simulation](prompts/0002-sim-tick.md)
- [x] **0003** [game_data.gd, the one file of levers](prompts/0003-game-data.md)
- [x] **0004** [Harden the headless check harness](prompts/0004-headless-check.md)
- [x] **0005** [verify.py and the determinism guard](prompts/0005-verify-and-hash.md)
- [x] **0006** [The phase machine: day, preparation, night, result](prompts/0006-phase-machine.md)
- [x] **0007** [The resource ledger](prompts/0007-resource-ledger.md)
- [x] **0008** [The farm grid](prompts/0008-farm-grid.md)
- [x] **0009** [Settings singleton](prompts/0009-settings.md)
- [x] **0010** [Save the profile and the run](prompts/0010-save.md)
- [x] **0011** [input_check harness](prompts/0011-input-check.md)
- [x] **0012** [Debug overlay](prompts/0012-debug-overlay.md)

## 1 - The first playable build  (15/15)

- [x] **0013** [The world renders](prompts/0013-world-render.md)
- [x] **0014** [Sprites generated from ASCII maps](prompts/0014-sprite-pipeline.md)
- [x] **0015** [The player walks and interacts](prompts/0015-player.md)
- [x] **0016** [Trees and wood](prompts/0016-wood.md)
- [x] **0017** [Rocks and stone](prompts/0017-stone.md)
- [x] **0018** [Wheat: till, plant, grow, harvest](prompts/0018-wheat.md)
- [x] **0019** [The workshop and its first recipe](prompts/0019-workshop.md)
- [x] **0020** [The shop: sell and buy](prompts/0020-shop.md)
- [x] **0021** [The day HUD](prompts/0021-day-hud.md)
- [x] **0022** [Switching reality](prompts/0022-reality-switch.md)
- [x] **0023** [Build mode](prompts/0023-build-mode.md)
- [x] **0024** [The shooting tower](prompts/0024-tower-gun.md)
- [x] **0025** [Zombies walk to the house](prompts/0025-zombies-walk.md)
- [x] **0026** [The tower kills the zombie](prompts/0026-combat.md)
- [x] **0027** [Three waves, a result screen, and back to the farm](prompts/0027-first-loop.md)

## 2 - The full day  (14/14)

- [x] **0028** [Corn and carrot](prompts/0028-three-crops.md)
- [x] **0029** [Growth stages and watering](prompts/0029-growth-stages.md)
- [x] **0030** [Fishing](prompts/0030-fishing.md)
- [x] **0031** [Iron from the rock face](prompts/0031-iron.md)
- [x] **0032** [Oil](prompts/0032-oil.md)
- [x] **0033** [The generator and energy](prompts/0033-generator.md)
- [x] **0034** [Cooking: food and meat](prompts/0034-cooking.md)
- [x] **0035** [Gunpowder and ammunition](prompts/0035-ammunition.md)
- [x] **0036** [The inventory](prompts/0036-inventory.md)
- [x] **0037** [The workshop queue](prompts/0037-craft-queue.md)
- [x] **0038** [Production runs while you are elsewhere](prompts/0038-idle-production.md)
- [x] **0039** [The day clock and dusk](prompts/0039-day-clock.md)
- [x] **0040** [The shop grows](prompts/0040-shop-full.md)
- [x] **0041** [The first day teaches itself](prompts/0041-tutorial-day.md)

## 3 - The full night  (17/17)

- [x] **0042** [Data-driven defences](prompts/0042-defence-data.md)
- [x] **0043** [The flamethrower tower](prompts/0043-tower-flame.md)
- [x] **0044** [The mortar](prompts/0044-tower-mortar.md)
- [x] **0045** [The auto-crossbow](prompts/0045-tower-crossbow.md)
- [x] **0046** [Fences and walls](prompts/0046-walls.md)
- [x] **0047** [Barricades](prompts/0047-barricades.md)
- [x] **0048** [Mines and traps](prompts/0048-traps.md)
- [x] **0049** [Zombies path around walls](prompts/0049-pathing-walls.md)
- [x] **0050** [The runner](prompts/0050-enemy-runner.md)
- [x] **0051** [The tank](prompts/0051-enemy-tank.md)
- [x] **0052** [The breaker](prompts/0052-enemy-breaker.md)
- [x] **0053** [Repair during the night](prompts/0053-repair.md)
- [x] **0054** [The player's ability](prompts/0054-ability.md)
- [x] **0055** [Double speed and skipping the night](prompts/0055-speed-controls.md)
- [x] **0056** [The night HUD](prompts/0056-night-hud.md)
- [x] **0057** [Structures take damage and die](prompts/0057-structure-damage.md)
- [x] **0058** [The Giant](prompts/0058-boss-giant.md)

## 4 - Ten nights and progression  (12/12)

- [x] **0059** [Waves as data](prompts/0059-wave-data.md)
- [x] **0060** [The ten nights, authored](prompts/0060-ten-nights.md)
- [x] **0061** [Night rewards](prompts/0061-rewards.md)
- [x] **0062** [Technology points](prompts/0062-tech-points.md)
- [x] **0063** [The tech tree](prompts/0063-tech-tree.md)
- [x] **0064** [Tower I, II, automatic](prompts/0064-tower-upgrades.md)
- [x] **0065** [Losing a night costs you](prompts/0065-defeat.md)
- [x] **0066** [Night 10 and the end of the run](prompts/0066-run-end.md)
- [x] **0067** [The autoplayer](prompts/0067-autoplayer.md)
- [x] **0068** [A balance sweep over the ten nights](prompts/0068-balance-sweep.md)
- [x] **0069** [Run statistics](prompts/0069-stats.md)
- [x] **0070** [Endless nights past ten](prompts/0070-endless.md)

## 5 - Art and visual direction  (13/13)

- [x] **0071** [The two palettes](prompts/0071-palettes.md)
- [x] **0072** [The farm tileset](prompts/0072-tileset.md)
- [x] **0073** [The player sprite](prompts/0073-player-art.md)
- [x] **0109** [The character reacts](prompts/0109-player-emotes.md)
- [x] **0074** [Zombie sprites](prompts/0074-zombie-art.md)
- [x] **0075** [Buildings and towers](prompts/0075-building-art.md)
- [x] **0076** [Night lighting](prompts/0076-lighting.md)
- [x] **0077** [Particles](prompts/0077-particles.md)
- [x] **0078** [The reality transition](prompts/0078-transition.md)
- [x] **0079** [Resource icons and the UI kit](prompts/0079-ui-kit.md)
- [x] **0080** [A pixel font](prompts/0080-font.md)
- [x] **0081** [The UI theme](prompts/0081-theme.md)
- [x] **0082** [Screenshots, and actually looking at them](prompts/0082-screenshots.md)

## 6 - Sound and juice  (8/8)

- [x] **0083** [Audio buses and a sound manager](prompts/0083-audio-buses.md)
- [x] **0084** [The sounds of the day](prompts/0084-sfx-day.md)
- [x] **0085** [The sounds of the night](prompts/0085-sfx-night.md)
- [x] **0086** [Two pieces of music](prompts/0086-music.md)
- [x] **0087** [Ambience](prompts/0087-ambience.md)
- [x] **0088** [Juice: shake, hit stop, damage numbers](prompts/0088-juice.md)
- [x] **0089** [Tooltips](prompts/0089-tooltips.md)
- [x] **0090** [The log panel](prompts/0090-log-panel.md)

## 7 - Shell and product  (11/11)

- [x] **0091** [The title screen](prompts/0091-title-screen.md)
- [x] **0092** [The main menu and the router](prompts/0092-main-menu.md)
- [x] **0093** [Options: video](prompts/0093-options-video.md)
- [x] **0094** [Options: audio](prompts/0094-options-audio.md)
- [x] **0095** [Options: controls](prompts/0095-options-controls.md)
- [x] **0096** [The pause menu](prompts/0096-pause-menu.md)
- [x] **0097** [English and Portuguese](prompts/0097-i18n.md)
- [x] **0098** [Accessibility](prompts/0098-accessibility.md)
- [x] **0099** [An icon and a boot ident](prompts/0099-icon-ident.md)
- [x] **0100** [Exports: Windows and Web](prompts/0100-exports.md)
- [x] **0110** [Refusals in two languages](prompts/0110-refusals.md)

## 8 - Ship the MVP  (8/8)

- [x] **0101** [Onboarding in seven lines](prompts/0101-onboarding.md)
- [x] **0102** [A performance budget](prompts/0102-perf-budget.md)
- [x] **0103** [Crash and error reporting](prompts/0103-error-report.md)
- [x] **0104** [Saves survive an update](prompts/0104-save-compat.md)
- [x] **0105** [A playtest build](prompts/0105-playtest-build.md)
- [x] **0106** [The release checklist](prompts/0106-release-checklist.md)
- [x] **0107** [Store assets](prompts/0107-store-assets.md)
- [x] **0108** [The devlog and a trailer clip](prompts/0108-devlog.md)

## 9 - v1.0 groundwork  (0/14)

- [ ] **0112** [Room in the test suites](prompts/0112-suite-headroom.md)
- [ ] **0113** [Repairs mend to the real maximum](prompts/0113-repairs-full-max.md) - needs 0112
- [ ] **0114** [Untouched means the house the night started with](prompts/0114-untouched-house.md) - needs 0112, 0113
- [ ] **0115** [Spawn ground that cannot be built shut](prompts/0115-spawn-room.md) - needs 0112
- [ ] **0116** [The mortar and the flamethrower, empty and upgraded](prompts/0116-mortar-flame-ammo.md) - needs 0112
- [ ] **0117** [Three stale documents](prompts/0117-stale-docs.md)
- [ ] **0118** [One road into the waves](prompts/0118-one-road-into-night.md) - needs 0112
- [ ] **0119** [Tests and tools build in the build step](prompts/0119-build-in-preparation.md) - needs 0118
- [ ] **0120** [One road for art that has not arrived](prompts/0120-placeholder-road.md) - needs 0112
- [ ] **0121** [A controller for every action](prompts/0121-gamepad-bindings.md) - needs 0112
- [ ] **0122** [Art: the farmer's run](prompts/0122-art-farmer-run.md) - needs 0120 - waits for art A006
- [ ] **0123** [Art: the farmer tilling, planting, watering and harvesting](prompts/0123-art-farmer-field-work.md) - needs 0120 - waits for art A007
- [ ] **0124** [Art: the farmer chopping, mining, collecting and carrying](prompts/0124-art-farmer-gather-work.md) - needs 0120 - waits for art A008
- [ ] **0125** [Art: the farmer crafting, trading and repairing](prompts/0125-art-farmer-make-work.md) - needs 0120 - waits for art A009

## 10 - Sleep is the night  (0/23)

- [ ] **0126** [The clock: 06:00 to 02:00](prompts/0126-clock.md) - needs 0118
- [ ] **0127** [Going to bed starts the night](prompts/0127-bed.md) - needs 0126
- [ ] **0128** [Passing out at 02:00](prompts/0128-pass-out.md) - needs 0127
- [ ] **0129** [He stays in bed all night](prompts/0129-asleep-all-night.md) - needs 0127, 0120, 0128
- [ ] **0130** [The night camera](prompts/0130-night-camera.md) - needs 0129, 0121
- [ ] **0131** [The guardian's cursor](prompts/0131-guardian-cursor.md) - needs 0130, 0121, 0120
- [ ] **0132** [Defences go down only at night](prompts/0132-defences-at-night.md) - needs 0131, 0119
- [ ] **0133** [The hotbar of defences](prompts/0133-hotbar.md) - needs 0132
- [ ] **0134** [Repairing by cursor](prompts/0134-repair-by-cursor.md) - needs 0131, 0113, 0133
- [ ] **0135** [The flare goes where you aim it](prompts/0135-aimed-flare.md) - needs 0131
- [ ] **0136** [The build step waits for START](prompts/0136-start-button.md) - needs 0118, 0132, 0128
- [ ] **0137** [The night ends at 06:00](prompts/0137-dawn-ends-night.md) - needs 0136
- [ ] **0138** [Waking up: the morning report](prompts/0138-morning-report.md) - needs 0137
- [ ] **0139** [The night HUD for the guardian](prompts/0139-night-hud-guardian.md) - needs 0133, 0134, 0135, 0136, 0137
- [ ] **0140** [The day HUD: the hour and bedtime](prompts/0140-day-hud-clock.md) - needs 0126, 0127, 0128
- [ ] **0141** [Teaching the new night](prompts/0141-tutorial-sleep.md) - needs 0139, 0140
- [ ] **0142** [The autoplayer sleeps too](prompts/0142-autoplay-sleep.md) - needs 0137, 0132, 0138
- [ ] **0143** [Art: going to bed, sleeping, waking, passing out](prompts/0143-art-farmer-bed.md) - needs 0129, 0128 - waits for art A001
- [ ] **0144** [Art: the farmer's reactions and Zzz](prompts/0144-art-reactions.md) - needs 0129 - waits for art A002
- [ ] **0145** [Art: the porch guardian](prompts/0145-art-guardian.md) - needs 0131, 0133 - waits for art A003
- [ ] **0146** [Art: the guardian's cursor](prompts/0146-art-cursor.md) - needs 0131 - waits for art A004
- [ ] **0147** [Art: the night hotbar and HUD icons](prompts/0147-art-night-icons.md) - needs 0133, 0139 - waits for art A005
- [ ] **0148** [Checkpoint: is the night better with him asleep?](prompts/0148-checkpoint-sleep.md) - needs 0137, 0138, 0139, 0140, 0141, 0142

## 11 - Calendar and seasons  (0/16)

- [ ] **0149** [The calendar: four seasons of fourteen days](prompts/0149-calendar.md) - needs 0148
- [ ] **0150** [Nights looked up by the calendar](prompts/0150-calendar-lookup.md) - needs 0149
- [ ] **0151** [The night is the calendar day](prompts/0151-night-is-calendar.md) - needs 0150
- [ ] **0152** [Full Moon nights](prompts/0152-full-moon.md) - needs 0151
- [ ] **0153** [Boss nights repeat until the boss falls](prompts/0153-boss-nights.md) - needs 0151, 0137
- [ ] **0154** [The calm night after a boss](prompts/0154-calm-night.md) - needs 0153
- [ ] **0155** [Losing a night when the calendar moves on](prompts/0155-losing-calendar.md) - needs 0151, 0153
- [ ] **0156** [The 1.0 farm map](prompts/0156-farm-map-v1.md) - needs 0151
- [ ] **0157** [A new side every season](prompts/0157-attack-sides.md) - needs 0156, 0115
- [ ] **0158** [The forecast](prompts/0158-forecast.md) - needs 0151, 0152, 0153, 0154, 0157
- [ ] **0159** [Seasons on screen](prompts/0159-seasons-on-screen.md) - needs 0149
- [ ] **0160** [The end of the year](prompts/0160-year-end.md) - needs 0153, 0151, 0154
- [ ] **0161** [Art: seasons and moons](prompts/0161-art-calendar-icons.md) - needs 0158 - waits for art A010
- [ ] **0162** [Art: forecast heads](prompts/0162-art-forecast-heads.md) - needs 0158 - waits for art A011
- [ ] **0163** [Art: winter ground](prompts/0163-art-winter-ground.md) - needs 0159 - waits for art A012
- [ ] **0164** [Art: trees through the seasons](prompts/0164-art-seasonal-trees.md) - needs 0159, 0156 - waits for art A013

## 12 - The day that pays  (0/53)

- [ ] **0165** [Crops grow by days](prompts/0165-crops-by-days.md) - needs 0149, 0151, 0156
- [ ] **0166** [A day of eight to ten minutes](prompts/0166-longer-day.md) - needs 0165
- [ ] **0167** [Any grass can be tilled](prompts/0167-till-grass.md) - needs 0165
- [ ] **0168** [Nine new crops](prompts/0168-crop-data.md) - needs 0165
- [ ] **0169** [An inventory for many things](prompts/0169-inventory.md) - needs 0168
- [ ] **0170** [Crops keep to their seasons](prompts/0170-crop-seasons.md) - needs 0168, 0149, 0169
- [ ] **0171** [Winter: nothing grows outside](prompts/0171-winter-rules.md) - needs 0170, 0159
- [ ] **0172** [Crops that grow back](prompts/0172-regrowing-crops.md) - needs 0168
- [ ] **0173** [Five tools, three tiers](prompts/0173-tool-tiers.md) - needs 0148, 0126
- [ ] **0174** [The can and the hoe by tier](prompts/0174-can-and-hoe.md) - needs 0173, 0167
- [ ] **0175** [The axe and the pickaxe by tier](prompts/0175-axe-pickaxe.md) - needs 0173
- [ ] **0176** [Copper, coal and gold](prompts/0176-copper-coal-gold.md) - needs 0175, 0156
- [ ] **0177** [Hardwood](prompts/0177-hardwood.md) - needs 0175, 0156
- [ ] **0178** [Sprinklers](prompts/0178-sprinklers.md) - needs 0176, 0165
- [ ] **0179** [Fish by pond, season and hour](prompts/0179-fish-species.md) - needs 0126, 0149, 0156, 0165
- [ ] **0180** [The fishing minigame](prompts/0180-fishing-minigame.md) - needs 0179, 0121, 0173
- [ ] **0181** [Rods and bait](prompts/0181-rods-bait.md) - needs 0179, 0173, 0167
- [ ] **0182** [Legendary fish and the fish book](prompts/0182-legendary-book.md) - needs 0181
- [ ] **0183** [The coop and the barn](prompts/0183-coop-barn.md) - needs 0126, 0156
- [ ] **0184** [Feeding, eggs and milk](prompts/0184-feeding-products.md) - needs 0183, 0168
- [ ] **0185** [Sheep, pigs and the dog](prompts/0185-sheep-pigs-dog.md) - needs 0184
- [ ] **0186** [Barns at night](prompts/0186-barns-at-night.md) - needs 0183, 0137
- [ ] **0187** [Days in a barrel: the keg and the preserves jar](prompts/0187-keg-and-jar.md) - needs 0184, 0168, 0149, 0186
- [ ] **0188** [The dairy, the loom and the mill](prompts/0188-dairy-loom-mill.md) - needs 0187, 0185
- [ ] **0189** [The shipping bin](prompts/0189-shipping-bin.md) - needs 0148, 0138, 0156
- [ ] **0190** [The peddler and his hours](prompts/0190-peddler.md) - needs 0126, 0170, 0183, 0185, 0173
- [ ] **0191** [The house in three tiers](prompts/0191-house-tiers.md) - needs 0148, 0114
- [ ] **0192** [Cooking with the new harvest](prompts/0192-cooking-v2.md) - needs 0188, 0184
- [ ] **0193** [Every season can make what it needs](prompts/0193-seasonal-supply.md) - needs 0170, 0176, 0188, 0190, 0192
- [ ] **0194** [The day's economy](prompts/0194-day-economy.md) - needs 0193, 0189, 0171, 0172, 0174, 0177, 0178, 0180, 0182, 0186, 0191
- [ ] **0195** [Teaching the new day](prompts/0195-day-tutorial.md) - needs 0194
- [ ] **0196** [Checkpoint: is the day good on its own?](prompts/0196-checkpoint-day.md) - needs 0194, 0195
- [ ] **0197** [Art: trampled crops and tilled ground](prompts/0197-art-crop-ground.md) - needs 0167, 0155, 0171 - waits for art A014
- [ ] **0198** [Art: spring crops](prompts/0198-art-spring-crops.md) - needs 0170, 0172 - waits for art A015
- [ ] **0199** [Art: summer crops](prompts/0199-art-summer-crops.md) - needs 0170, 0172 - waits for art A016
- [ ] **0200** [Art: autumn crops](prompts/0200-art-autumn-crops.md) - needs 0170, 0172 - waits for art A017
- [ ] **0201** [Art: sprinklers](prompts/0201-art-sprinklers.md) - needs 0178 - waits for art A018
- [ ] **0202** [Art: tool icons](prompts/0202-art-tool-icons.md) - needs 0173, 0176, 0190 - waits for art A019
- [ ] **0203** [Art: material icons](prompts/0203-art-material-icons.md) - needs 0176, 0177, 0184 - waits for art A020
- [ ] **0204** [Art: copper, coal, gold and hardwood](prompts/0204-art-ore-hardwood.md) - needs 0176, 0177 - waits for art A021
- [ ] **0205** [Art: fish](prompts/0205-art-fish-icons.md) - needs 0182 - waits for art A022
- [ ] **0206** [Art: fishing gear and the minigame](prompts/0206-art-fishing-gear.md) - needs 0180, 0181, 0182 - waits for art A023
- [ ] **0207** [Art: the farmer fishing](prompts/0207-art-farmer-fishing.md) - needs 0180 - waits for art A024
- [ ] **0208** [Art: the farmer tending animals](prompts/0208-art-farmer-care.md) - needs 0184, 0185 - waits for art A025
- [ ] **0209** [Art: sheep and pigs](prompts/0209-art-farm-animals.md) - needs 0185 - waits for art A026
- [ ] **0210** [Art: the cow and the chicken redrawn](prompts/0210-art-cow-chicken.md) - needs 0185 - waits for art A027
- [ ] **0211** [Art: animal goods](prompts/0211-art-animal-goods.md) - needs 0185 - waits for art A029
- [ ] **0212** [Art: the coop and the barn](prompts/0212-art-coop-barn.md) - needs 0186 - waits for art A030
- [ ] **0213** [Art: the artisan machines](prompts/0213-art-machines.md) - needs 0188 - waits for art A031
- [ ] **0214** [Art: artisan goods](prompts/0214-art-artisan-goods.md) - needs 0188, 0192 - waits for art A032
- [ ] **0215** [Art: the shipping bin](prompts/0215-art-shipping-bin.md) - needs 0189 - waits for art A033
- [ ] **0216** [Art: the peddler](prompts/0216-art-peddler.md) - needs 0190 - waits for art A034
- [ ] **0217** [Art: the house in three tiers](prompts/0217-art-house-tiers.md) - needs 0191 - waits for art A035

## 13 - Weapons of the night  (0/28)

- [ ] **0218** [Room for more fields and more bodies](prompts/0218-perf-groundwork.md) - needs 0196
- [ ] **0219** [Essence](prompts/0219-essence.md) - needs 0196, 0137, 0152
- [ ] **0220** [The technology tree by season](prompts/0220-tech-by-season.md) - needs 0219, 0149
- [ ] **0221** [What the night leaves behind](prompts/0221-night-loot.md) - needs 0219, 0152
- [ ] **0222** [Bone meal](prompts/0222-bone-meal.md) - needs 0221, 0165
- [ ] **0223** [Defences sleep under tarps](prompts/0223-defence-tarps.md) - needs 0196, 0132, 0120
- [ ] **0224** [The scarecrow decoy](prompts/0224-decoy.md) - needs 0218, 0132
- [ ] **0225** [Zombie bait](prompts/0225-zombie-bait.md) - needs 0224, 0179
- [ ] **0226** [The beehive](prompts/0226-beehive.md) - needs 0218, 0132, 0168
- [ ] **0227** [The pumpkin catapult](prompts/0227-catapult.md) - needs 0196, 0132, 0168
- [ ] **0228** [The garlic braid](prompts/0228-garlic-braid.md) - needs 0218, 0132, 0168
- [ ] **0229** [The searchlight](prompts/0229-searchlight.md) - needs 0196, 0132, 0226
- [ ] **0230** [The electric fence](prompts/0230-electric-fence.md) - needs 0196, 0132, 0176
- [ ] **0231** [Hardwood walls and sandbags](prompts/0231-strong-walls.md) - needs 0196, 0177, 0188, 0132, 0226
- [ ] **0232** [Powers as a list](prompts/0232-powers-refactor.md) - needs 0196, 0135
- [ ] **0233** [Three new powers](prompts/0233-new-powers.md) - needs 0232, 0185, 0220, 0230
- [ ] **0234** [The arsenal grows with the seasons](prompts/0234-arsenal-by-season.md) - needs 0224, 0225, 0226, 0227, 0228, 0229, 0230, 0231, 0149, 0220, 0223
- [ ] **0235** [Art: bones, moon stones and essence](prompts/0235-art-night-loot.md) - needs 0221, 0222, 0219 - waits for art A036
- [ ] **0236** [Art: the scarecrow decoy and zombie bait](prompts/0236-art-decoy.md) - needs 0224, 0225 - waits for art A037
- [ ] **0237** [Art: the beehive](prompts/0237-art-beehive.md) - needs 0226 - waits for art A038
- [ ] **0238** [Art: the pumpkin catapult](prompts/0238-art-catapult.md) - needs 0227 - waits for art A039
- [ ] **0239** [Art: the garlic braid](prompts/0239-art-garlic.md) - needs 0228 - waits for art A040
- [ ] **0240** [Art: the searchlight](prompts/0240-art-searchlight.md) - needs 0229 - waits for art A041
- [ ] **0241** [Art: the electric fence](prompts/0241-art-electric-fence.md) - needs 0230 - waits for art A042
- [ ] **0242** [Art: hardwood walls and sandbags](prompts/0242-art-strong-walls.md) - needs 0231 - waits for art A043
- [ ] **0243** [Art: the day tarps](prompts/0243-art-tarps.md) - needs 0223, 0234 - waits for art A044
- [ ] **0244** [Art: power and new weapon icons](prompts/0244-art-power-icons.md) - needs 0233, 0234 - waits for art A045
- [ ] **0245** [Art: the dog](prompts/0245-art-dog.md) - needs 0185, 0233 - waits for art A028

## 14 - Enemies and bosses  (0/24)

- [ ] **0246** [Bosses in general](prompts/0246-bosses-general.md) - needs 0153, 0196
- [ ] **0247** [The spitter](prompts/0247-spitter.md) - needs 0218, 0132
- [ ] **0248** [The rat swarm](prompts/0248-rat-swarm.md) - needs 0218, 0132
- [ ] **0249** [The crow](prompts/0249-crow.md) - needs 0218, 0168, 0233, 0234
- [ ] **0250** [The digger](prompts/0250-digger.md) - needs 0218, 0234
- [ ] **0251** [The frost zombie](prompts/0251-frost-zombie.md) - needs 0218
- [ ] **0252** [The wraith](prompts/0252-wraith.md) - needs 0229, 0218
- [ ] **0253** [The Harvester](prompts/0253-harvester.md) - needs 0246, 0231
- [ ] **0254** [The Scarecrow King](prompts/0254-scarecrow-king.md) - needs 0246, 0249
- [ ] **0255** [The Winter Lord](prompts/0255-winter-lord.md) - needs 0246, 0251, 0160, 0253, 0254
- [ ] **0256** [Fog and rain](prompts/0256-fog-and-rain.md) - needs 0158, 0229
- [ ] **0257** [The Blood Moon](prompts/0257-blood-moon.md) - needs 0256, 0219, 0246
- [ ] **0258** [Fog, rain and a red moon on screen](prompts/0258-event-visuals.md) - needs 0256, 0257
- [ ] **0259** [Every weapon has its night](prompts/0259-matchups.md) - needs 0234, 0247, 0248, 0249, 0250, 0251, 0252, 0253, 0254, 0255, 0256, 0257
- [ ] **0260** [Art: the spitter](prompts/0260-art-spitter.md) - needs 0247, 0246 - waits for art A046
- [ ] **0261** [Art: the rat swarm](prompts/0261-art-rats.md) - needs 0248, 0246 - waits for art A047
- [ ] **0262** [Art: the crow](prompts/0262-art-crow.md) - needs 0249, 0246 - waits for art A048
- [ ] **0263** [Art: the digger](prompts/0263-art-digger.md) - needs 0250, 0246 - waits for art A049
- [ ] **0264** [Art: the frost zombie](prompts/0264-art-frost-zombie.md) - needs 0251, 0246 - waits for art A050
- [ ] **0265** [Art: the wraith](prompts/0265-art-wraith.md) - needs 0252, 0246 - waits for art A051
- [ ] **0266** [Art: the Harvester](prompts/0266-art-harvester.md) - needs 0253 - waits for art A052
- [ ] **0267** [Art: the Scarecrow King](prompts/0267-art-scarecrow-king.md) - needs 0254 - waits for art A053
- [ ] **0268** [Art: the Winter Lord](prompts/0268-art-winter-lord.md) - needs 0255 - waits for art A054
- [ ] **0269** [Art: fog, rain and the Blood Moon icons](prompts/0269-art-event-icons.md) - needs 0256, 0257 - waits for art A055

## 15 - Fifty-six nights and balance  (0/11)

- [ ] **0270** [Fifty-six nights as data](prompts/0270-night-records-v2.md) - needs 0151, 0152, 0153, 0154, 0256, 0257, 0234
- [ ] **0271** [Spring's fourteen nights](prompts/0271-spring-nights.md) - needs 0270, 0157
- [ ] **0272** [Summer's fourteen nights](prompts/0272-summer-nights.md) - needs 0270, 0247, 0248, 0253, 0259, 0271
- [ ] **0273** [Autumn's fourteen nights](prompts/0273-autumn-nights.md) - needs 0270, 0249, 0250, 0254, 0259, 0272
- [ ] **0274** [Winter's fourteen nights](prompts/0274-winter-nights.md) - needs 0270, 0251, 0252, 0255, 0259, 0273
- [ ] **0275** [The worst night of the year, within budget](prompts/0275-perf-year.md) - needs 0274, 0234, 0248, 0233
- [ ] **0276** [The autoplayer plays a whole year](prompts/0276-autoplay-year.md) - needs 0142, 0194, 0233, 0234, 0275, 0166, 0171, 0180, 0186, 0191, 0221
- [ ] **0277** [Balancing the year](prompts/0277-balance-year.md) - needs 0271, 0272, 0273, 0274, 0276, 0259
- [ ] **0278** [The economy across a year](prompts/0278-economy-seasons.md) - needs 0277
- [ ] **0279** [Year 2](prompts/0279-year-two.md) - needs 0160, 0277
- [ ] **0280** [Checkpoint: do fifty-six nights tire?](prompts/0280-checkpoint-year.md) - needs 0277, 0278, 0279, 0159, 0258

## 16 - Sound, collections and polish  (0/10)

- [ ] **0281** [The new day's sounds](prompts/0281-sfx-day-v2.md) - needs 0196
- [ ] **0282** [The sounds of the fishing minigame](prompts/0282-sfx-fishing.md) - needs 0180, 0182, 0196
- [ ] **0283** [The guardian's sounds](prompts/0283-sfx-night-v2.md) - needs 0233, 0234
- [ ] **0284** [The new enemies and bosses, heard](prompts/0284-sfx-enemies-v2.md) - needs 0247, 0248, 0250, 0252, 0253, 0254, 0255, 0257
- [ ] **0285** [Music for four seasons](prompts/0285-music-seasons.md) - needs 0160, 0282
- [ ] **0286** [Fog, rain and winter wind](prompts/0286-ambience-v2.md) - needs 0186, 0256, 0257, 0285
- [ ] **0287** [Collections and achievements](prompts/0287-collections.md) - needs 0152, 0155, 0160, 0170, 0182, 0253, 0254, 0255
- [ ] **0288** [Art: the collection book, trophies and badges](prompts/0288-art-collections.md) - needs 0287 - waits for art A056
- [ ] **0289** [Art: the morning report](prompts/0289-art-morning.md) - needs 0138 - waits for art A057
- [ ] **0290** [The 1.0 visual gate](prompts/0290-visual-gate-v1.md) - needs 0122, 0123, 0124, 0125, 0143, 0144, 0145, 0146, 0147, 0161, 0162, 0163, 0164, 0197, 0198, 0199, 0200, 0201, 0202, 0203, 0204, 0205, 0206, 0207, 0208, 0209, 0210, 0211, 0212, 0213, 0214, 0215, 0216, 0217, 0235, 0236, 0237, 0238, 0239, 0240, 0241, 0242, 0243, 0244, 0245, 0258, 0260, 0261, 0262, 0263, 0264, 0265, 0266, 0267, 0268, 0269, 0288

## 17 - Ship 1.0  (0/7)

- [ ] **0291** [Saves into 1.0](prompts/0291-saves-v1.md) - needs 0151, 0156, 0165, 0279, 0287
- [ ] **0292** [Options for the new controls](prompts/0292-options-v1.md) - needs 0131, 0180, 0158
- [ ] **0293** [The first week, taught](prompts/0293-onboarding-v1.md) - needs 0195, 0141, 0158, 0180
- [ ] **0294** [Every new word in Portuguese](prompts/0294-translation-v1.md) - needs 0287, 0293, 0291, 0292
- [ ] **0295** [A playtest build of the year](prompts/0295-playtest-v1.md) - needs 0280, 0291, 0292, 0293, 0294
- [ ] **0296** [The store page and trailer for 1.0](prompts/0296-store-v1.md) - needs 0290, 0294
- [ ] **0297** [Releasing 1.0](prompts/0297-release-v1.md) - needs 0290, 0291, 0292, 0293, 0294, 0295, 0296
