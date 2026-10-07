# 0141 - Teaching the new night

- **Phase:** 10 - Sleep is the night
- **Status:** todo
- **Depends on:** 0139, 0140
- **Likely files:** src/core/game_data.gd, src/core/tutorial.gd, src/core/sim.gd, src/ui/tutorial_prompt.gd, src/tools/perf_names.gd, assets/locale/strings.csv, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

Day one teaches the new night - go to bed, build with the cursor, press START, hold until dawn - by watching the state and never gating anything.

## Requirements

- `TUTORIAL` has seven steps today (chop, plant, water, sell, craft, then 0132's night and build) and `MAX_TUTORIAL_LINES := 7` with a 3-9 range, so seven plus three does not fit: the `night` step becomes the bed step (`TUT_NIGHT` - 'N, or the button' - is replaced by `TUT_BED` and its row leaves strings.csv), START and dawn follow the night `build` step, and the lever goes to 9 - or two day steps merge; say which. `check_tutorial` still passes
- `Tutorial._happened` arms that read the state only: asleep seen, a defence placed in a build step, NIGHT reached, a night that ended at dawn or by a win
- `Tutorial.tick` runs on its beat in NIGHT too (0132 added PREPARATION; never indoors). `PerfNames.NIGHT` gains `Tutorial`: `_task_0102_budget` only compares the union of the two lists, so it would not notice a night system the benchmark does not time. `points_at` aims each step at something real: the bed (in the house view), a cell between the house and the spawn, the START button, the dawn countdown
- `TUT_BED`, `TUT_BUILD` (rewritten), `TUT_START` and `TUT_DAWN` in both languages, inside the widths `tools/i18n_check.py` measures - practical lines, not a description of the reality switch
- Rewrite `_task_0041_tutorial` and `_case_0041_tutorial` for the new steps
- DATA moves (`TUTORIAL`); SIM moves only if the tutorial state differs in the determinism scenario - say which

## Done when

- [ ] `_task_0141_tutorial` in `headless_v1.gd` (jump `day_tick` and `dawn_at` rather than playing whole spans): a scripted first day and night completes every step in order; ignoring the prompts reaches the same night with the same state apart from `tutorial`
- [ ] `_case_0141_tutorial` in `input_v1.gd`: the bed line shows on day one after the day steps, the START line in the build step
- [ ] Captures of the bed, START and dawn prompts, opened
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
