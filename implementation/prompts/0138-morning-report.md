# 0138 - Waking up: the morning report

- **Phase:** 10 - Sleep is the night
- **Status:** done
- **Depends on:** 0137
- **Likely files:** src/core/phases.gd, src/core/house.gd, src/ui/result_screen.gd, src/ui/house_view.gd, src/ui/main.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/autoplay.gd, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd, implementation/backlog/packs/A057-morning-report.md

## Goal

Every night, won or lost, closes on a morning report, and confirming it starts the day with the farmer getting out of bed at 06:00.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A057
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- `begin_day` wakes him in bed: `House.wake(state)` puts him inside on the floor cell beside the bed - `inside` true, `asleep` and `passed_out` false, `outside_pos` the porch - so he walks out of the door into the day, and the clock reads 06:00. The wake animation 0129 registered plays (A001 stand-in until 0143)
- Tests and tools that walk the farmer outside after a night step him out with `House.leave` or a helper (the determinism scenario's second day, `Autoplay._a_day`, the suites' `_to_the_next_night`-style helpers); list the ones touched in the journal. The autoplayer keeps working
- `result_screen.gd` becomes the morning report: a heading with the day, what came in (the `Rewards` lines), what was lost (stock taken on a loss, structures lost), how many walked off at dawn, a line when the night began with a pass-out, and a leftovers line that says nothing is on the farm yet (phase 13's bones and moon stones fill it). Confirming is the same `confirm_result` intent. The ending and endless branches stay as they are (0160 reworks them)
- An optional header, a sunrise over the farmhouse, through the placeholder road (a code-drawn band is enough) until A057 is integrated by 0289; if the owner declines A057 the band stays
- `main._bank_if_a_night_ended` banks every night's end, won or lost (key it on `day` or `last_result`, not `nights_won`), without `Stats.fold` counting a night twice
- Strings in both languages, and the report fits 480x270 in both; a row nothing prints any more leaves strings.csv. The input cases that read `ResultScreen` keep passing: `_case_0027_the_loop` (~1303), `_case_0070_endless` (~3616) and `_case_0082_shots`' crowding check (~4466). SIM moves on purpose (where `begin_day` leaves the farmer): record both numbers

## Done when

- [ ] `_task_0138_morning` in `headless_v1.gd`: after a won and after a lost night, `confirm_result` leaves him inside beside the bed, awake, at `day_tick` 0 and 06:00; a state saved and loaded in RESULT confirms into the same
- [ ] `_case_0138_morning` in `input_v1.gd`: the report shows its lines; confirming brings up the house view; a lost night writes the run save (the saved `day` matches)
- [ ] The Deliverables table of `implementation/backlog/packs/A057-morning-report.md` states the final geometry this task settled
- [ ] `python tools/shot.py 0138 result` opened, also with `--pt_BR`: nothing clipped or overlapping
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
