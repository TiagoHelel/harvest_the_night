# 0293 - The first week, taught

- **Phase:** 17 - Ship 1.0
- **Status:** todo
- **Depends on:** 0195, 0141, 0158, 0180
- **Likely files:** src/core/game_data.gd, src/core/tutorial.gd, src/ui/tutorial_prompt.gd, src/app/settings.gd, tools/goldens/, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

A stranger learns 1.0 the way they learned the MVP's first day - one short line, on the thing it is about, gone when it is done - but spread over Spring 1 to 7, so the first morning is not a lecture and the forecast, the bin and the rod arrive when they first matter.

## Requirements

- Start from what 0141 and 0195 left in `GameData.TUTORIAL` and write the week down as data: each step gains the Spring date it may first show (e.g. `from_day`, read against `Calendar.date`), in the order a week happens - day 1 chop, plant, water, the bed, the cursor, START and dawn; the bin and the stall once there is something to sell; the forecast at 18:00 of the first night with something new in it; the rod and the minigame mid-week; the season and the Full Moon by day 7. Where a 0195 tip already teaches a lesson (the bin, the first bite, a new season), the week takes it over or leaves it to the tip - one line per lesson, never both. The schedule is the task's to justify in the journal
- It still watches and never gates (the `Tutorial` header): `Tutorial.tick` keeps checking every step, a step done early by a player who found it alone is done, and `current()` and `points_at()` only offer steps whose day has come. Keep 0141's assert that ignoring the prompts reaches the same night with the same state apart from `tutorial` - one day and night in the suite, never Spring 1-7
- Every step finishes on something the state shows: the forecast step is done when the night it forecast begins, not when a panel was looked at - the rules cannot see the screen
- Short, per day: `check_tutorial` counts the week's lines per day against a new `# LEVER` `MAX_TUTORIAL_LINES_PER_DAY` (3-7, start at 5) and the week against `MAX_TUTORIAL_LINES`, whose comment and range are raised only as far as the week needs, with the reason in the journal (0195's tips keep their own check and do not count per day). `MAX_TUTORIAL_LINE_LENGTH` is unchanged, and no line describes the switch of reality - the bed and the fade show it
- Never twice, but the new lessons still reach a returning player: `gameplay/tutorial_seen` is one bool, so whoever finished the 0.1 day one would never see the bed or the cursor. Unless 0141 or 0195 already changed it, make it the list of step ids seen, with a `Settings.VERSION` bump whose `Settings._migrate` turns `true` into the 0.1 steps. The bump gets its golden: a 0.1 `settings.cfg` fixture in `tools/goldens/` (e.g. `settings-v1.cfg`, in the format `git show bea89a88:src/app/settings.gd` saves, with a non-default language, volumes, a rebind and `tutorial_seen` true) - the fixture goes in even if 0141 or 0195 already changed the key
- Each line sits on its thing through `tutorial_prompt.gd`: the bed, the cursor's cell, the START button, the forecast panel, the bin, the pond. At night the line follows the camera, not the sleeping farmer
- Rewrite in place what assumed every step shows on day one: `_task_0041_tutorial` in `headless_check.gd`, 0141's `_task_0141_tutorial`/`_case_0141_tutorial` and 0195's tip groups in `headless_v1.gd`/`input_v1.gd`
- Every line is a `TUT_*` row in both languages with a real width. `TUTORIAL` is in `GameData.digest()`, so DATA moves on purpose; SIM moves only if the done list in the determinism scenario changes - say which, both numbers in the journal
- What the loop cannot know - whether a stranger reads them - becomes a question in 0295's tester note, not a guess here

## Done when

- [ ] `check_tutorial` passes, and the journal has the week as a table: day, steps, lines
- [ ] `_task_0293_first_week` in `src/tools/headless_v1.gd`: a scripted player that only does what `Tutorial.current()` and `points_at()` ask gets from Spring 1 at 06:00 to Spring 2's morning with the house standing and every day-1 step done (going to bed early, so the group stays a few seconds); no step is offered before its day
- [ ] the same group: the 0.1 `settings.cfg` fixture loads with its language, volumes and rebind kept, every key it lacks at its `Settings.DEFAULTS` value, and its `tutorial_seen` of `true` migrated to the 0.1 step ids, so only the new steps are offered
- [ ] 1920x1080 captures of the bed line, the cursor line at night and the forecast line at dusk, in both languages (new scenarios such as `tut_bed`, `tut_cursor`, `tut_forecast`: `python tools/shot.py 0293 tut_bed tut_cursor tut_forecast --fhd` and again with `--pt_BR`), opened: each line is on its thing and nothing on screen covers it
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
