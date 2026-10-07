# 0295 - A playtest build of the year

- **Phase:** 17 - Ship 1.0
- **Status:** todo
- **Depends on:** 0280, 0291, 0292, 0293, 0294
- **Likely files:** src/app/playtest.gd, src/ui/main.gd, tools/playtest.py, docs/PLAYTEST.md, src/tools/headless_v1.gd, src/tools/headless_check.gd

## Goal

Put the year in front of somebody and learn from it: a build that says it is a playtest, a log of what 1.0 is about - bedtimes, the build step, dawn, seasons, lost nights - and a reader that answers 1.0's questions instead of the MVP's. It goes out with the art that has arrived, placeholders and all.

## Requirements

- The log learns the calendar: `Playtest.watch` writes the season and day when a day begins ('Spring 3 began'), the hour he went to bed or that he passed out at 02:00, how long the build step ran before START, how the night ended (dawn, all killed, the house fell) and when a boss night repeats - all in the `  m:ss  what` shape the reader parses
- A lost night no longer ends the session: today `watch` calls `run_ended` on `night_lost` ('the house fell on night N'), which in 1.0 is a setback inside a run. A session ends at the end of the year (0160's ending), at Abandon (`main.gd`) or when the window closes. `run_ended`'s 'reached night' reads the calendar date - 0151 named `playtest.gd` among the `nights_won + 1` readers; finish it here if it did not
- `tools/playtest.py` asks 1.0's questions: did they reach the first night; how long was Spring 1 in real minutes (the plan wants 8-10 for the day and 3-5 for the night); bed or pass-out, night by night; how long the build step ran; how far into the year they got and how many nights they lost per season (the plan's target is 2-4 lost before winter); where the notes cluster. `--self-check` gets a 1.0 sample log and fails when any answer comes back empty
- `docs/PLAYTEST.md` rewritten for 1.0 (it still says ten nights and a night you send for; 0117 only corrected what happens after night ten): what the game is now; the most useful stretch to play (Spring 1 to the Giant on day 14); what to try (bed early and late, the cursor by mouse and by pad, START, the bin, the rod); what to ignore, including the placeholders still on screen as `python tools/placeholders.py` (0120) lists them; the same F1 and local-log promises
- `_task_0105_playtest` in `headless_check.gd` stays true: if a line it reads has moved, rewrite it in the same change
- The build: `python tools/release.py --playtest` writes `build/playtest/` with `READ ME FIRST.md` beside it, and the badge says playtest. It builds only the Windows playtest preset, so no web budget is weighed here - `PACK_BUDGET` and `WIRE_BUDGET` are 0297's
- Nothing is sent: the build is made and checked and the journal says where it is. Handing it to a tester is the owner's call. Playtest code is `src/app/` and only reads the state: neither hash moves
- Questions the loop cannot answer - whether a stranger reads the week's lines (0293), whether a night is long enough - go into PLAYTEST.md's 'what to report', not into a guess in the journal

## Done when

- [ ] `_task_0295_playtest_log` in `src/tools/headless_v1.gd`: a short scripted run through bed, START, dawn, a lost night and the next morning writes, in order, the lines the reader parses, and the session is still open after the lost night - the lost night parked through 0118's road with the house set to fall, so the group takes seconds, not two whole nights
- [ ] `python tools/playtest.py --self-check` passes with the 1.0 sample, and `python tools/playtest.py <folder>` on the log that group wrote answers every question
- [ ] `python tools/release.py --playtest` succeeds, including its 400-frame boot of the playtest build; `python tools/shot.py 0295 --title --playtest --fhd` shows the badge on the first screen - opened
- [ ] no 'ten nights' or 'night ten' is left in `docs/PLAYTEST.md`, in any case
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
