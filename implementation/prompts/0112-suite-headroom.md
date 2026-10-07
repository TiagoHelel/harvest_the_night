# 0112 - Room in the test suites

- **Phase:** 9 - v1.0 groundwork
- **Status:** todo
- **Depends on:** nothing
- **Likely files:** src/tools/headless_v1.gd, src/tools/input_v1.gd, tools/verify.py, src/core/game_data.gd

## Goal

`headless_check` and `input_check` already take about 74 s each of the 120 s verify allows a script, and some 180 tasks are coming. Give 1.0 its own pair of suites, so a new rule never has to choose between being tested and the suite finishing.

## Requirements

- `src/tools/headless_v1.gd` copies `headless_check`'s harness: `expect()`, `passed`/`failed`, its own `GROUPS` constant with `_completed += 1` as each group's last line and `_finish()` failing a short count, the `_process()` watchdog (`WATCHDOG_SECONDS`) for an `_initialize()` that never returns, and a last line `N asserts, M failed` with a non-zero exit on any failure
- `src/tools/input_v1.gd` does the same for `input_check`: `MAIN_SCENE`, its own `CASES`, the 20 s stall watchdog that every `expect()` resets, the last line `N cases, M failed`; its first case boots Main and presses one real action, so the harness itself is tested
- Wire both into `tools/verify.py` through `check_script()` with the same patterns as the old suites (`\d+ asserts?, \d+ failed`, `\d+ cases?, \d+ failed`), skipped by `--hashes` like them, each run bounded by `SCRIPT_TIMEOUT_S` as the old two are
- Move nothing: every existing `_task_NNNN_*` group and `_case_NNNN_*` case stays put and `GROUPS := 103` / `CASES := 61` do not change. A plain helper the new files need (`_stand_the_farmer`, `_moved`, ...) is shared, not copied: move it into one small static script under `src/tools/` that both suites call - moving a helper is allowed, a group is not. An input helper that needs the running tree (`click_control`, `until`) takes the tree as an argument, or `input_v1` reuses `input_check`'s script some other way that keeps the two counters apart; say which
- Say in both new file headers that every group and case from task 0112 on lives here (`00-RUNNER-LOOP.md` already says so), and that a defence a test puts down, upgrades or sells is handled in PREPARATION, never by day (0132 forbids it by day and 0119 moves the old suites the same way)
- `_task_0112_digest` in `headless_v1`: read `src/core/game_data.gd` as text, collect every top-level `const` whose value is a Dictionary or Array literal (typed ones too, `const X: Array[Vector2i] = [`), and fail on any that is neither named inside `GameData.digest()` nor in an exemption list in the assert with a one-line reason each (derived enum lists such as `TARGETING`, `SHAPES`, `AIMS`, `DAMAGE_TYPES`; geometry helpers such as `NEIGHBOUR_STEPS`; view-only data). Scalar consts are not its business
- Run it on today's file before deciding: `MAP_LEGEND`, for one, is not in the digest. A table that is balance goes into `digest()` - DATA then moves on purpose: `python tools/verify.py --accept` and both numbers in the journal; one that is not gets its exemption and its reason. SIM does not move: this task changes no rule and no state key
- Write the four suite rows' times and the whole run against `BUDGET_S` in the journal

## Done when

- [ ] verify prints a `headless_v1` row ending `N asserts, 0 failed` and an `input_v1` row ending `N cases, 0 failed`, each timed, while `headless_check` still finishes 103 groups and `input_check` 61 cases
- [ ] A scratch `const TEST_TABLE := {}` in `game_data.gd` makes `_task_0112_digest` fail and removing it passes again - tried and said so in the journal
- [ ] A deliberate early `return` before `_completed += 1` in a `headless_v1` group makes verify fail on the group count; then put back
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
