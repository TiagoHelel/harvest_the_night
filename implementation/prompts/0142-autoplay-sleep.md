# 0142 - The autoplayer sleeps too

- **Phase:** 10 - Sleep is the night
- **Status:** todo
- **Depends on:** 0137, 0132, 0138
- **Likely files:** src/tools/autoplay.gd, src/tools/autoplay_run.gd, src/tools/nights.gd, src/tools/play_nights.gd, tools/autoplay.py, tools/nights.py, tools/balance.py, tools/play_nights.py, implementation/BALANCE.md, src/tools/headless_check.gd

## Goal

The autoplayer plays the game as it now is - a day, bed, building by cursor, START, the night to dawn - and keeps playing after a loss, so the balance tools measure the real loop again.

## Requirements

- `Autoplay.play`, per night: `_a_day` (gathering, crafting and production buildings by day only, starting from 0138's wake in bed); the `sleep` intent at a policy hour or when the day's plan is done, never passing out by accident (0128 only made it stop short of 02:00); the policy's defences in PREPARATION through the intent road (`build_cell` with `build_place`, `build_upgrade`, `repair_cell`); `start_waves`; ticks until RESULT, capped at `NIGHT_TICKS` plus a margin; then `confirm_result`
- It carries on after a loss instead of stopping; the per-night report adds how the night ended (dawn, everything dead, house down), the house left and how many walked off
- Policies keep their lists; nothing is placed by day (it would be refused)
- `tools/autoplay.py`, `tools/nights.py`, `tools/balance.py` and `tools/play_nights.py` still run; `balance.py` still restores `game_data.gd` and still refuses a dirty tree
- `_task_0067_autoplay` and `_task_0068_balance` are rewritten to the new loop and kept inside the suite's time (one day and one night per policy); report the group times
- A note in `implementation/BALANCE.md`: survival per night for the four policies over the same seeds before and after the new loop, and what changed
- Tools only: neither hash moves

## Done when

- [ ] `_task_0067_autoplay` and `_task_0068_balance` pass, with their times in the journal
- [ ] `python tools/autoplay.py` plays ten nights for every policy and prints the table; the numbers are in the journal and in BALANCE.md
- [ ] `python tools/balance.py` with a short sweep finishes and leaves the git tree clean
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
