# 0114 - Untouched means the house the night started with

- **Phase:** 9 - v1.0 groundwork
- **Status:** done
- **Depends on:** 0112, 0113
- **Likely files:** src/core/rewards.gd, src/core/tech.gd, src/core/sim.gd, src/core/enemies.gd, src/ui/night_hud.gd, src/ui/result_screen.gd, src/tools/play_nights.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd, src/tools/input_check.gd

## Goal

With 'stout timbers' the house starts the night at 140, yet four rules still measure it against 100: it can lose 40 and still pay the untouched bonus, and the skip refusal and the danger bar read the wrong share. Every 'how whole is the house' question is asked of the house the night started with.

## Requirements

- Route through `Phases.house_full(state)`: the 'the house untouched' line in `rewards.gd` (`house_hp >= GameData.HOUSE_HP`), `Tech._earned` `&"house untouched"`, the percentage `Sim.why_not_skip` compares with `SKIP_MIN_HOUSE_PERCENT`, and `Enemies.house_fraction`
- The view reads the same number: the night HUD house bar, its text and its `HOUSE_DANGER_PERCENT` pulse (`night_hud.gd`, `full := maxi(GameData.HOUSE_HP, 1)`), the result screen's `RES_HOUSE` line, and `play_nights.gd`'s report
- If the tree can change between the night and its result screen, `Rewards.settle` records the full value in the payout and the screen prints that instead of recomputing it - check and say which
- `GameData.HOUSE_HP` outside `game_data.gd` is left only in `Phases.house_full` and `Farm.initial` (a new run's house, before any tree); 0113 (a dependency) has already taken it out of `repair.gd`. `_task_0114_untouched` in `headless_v1` reads the code lines of `src/core/` and `src/ui/` as text and keeps it so, the way `_task_0095_controls` scans for raw keys
- Update `input_check`'s house-bar case (~l.3350, it reads `str(GameData.HOUSE_HP)`) only if it now fails; its no-tree house is still 100
- No new number: 0191's house tiers build on `house_full`. The determinism scenario owns no tech, so the comparisons give the same answers and SIM should not move - but a new key in the payout (above) is hashed and moves it if the scenario's night settles; if SIM moves, say which and accept it with both numbers. DATA does not move

## Done when

- [ ] `_task_0114_untouched`: with 'stout timbers', a night ending at 120 of 140 pays no 'the house untouched' money and earns no 'house untouched' tech; one ending at 140 earns both
- [ ] `Sim.why_not_skip` with 'stout timbers' allows a skip at 75 of 140 (53 %) and refuses at 65 of 140 with `[&"WHY_HOUSE_LOW", 46]`
- [ ] `_case_0114_house_bar` in `input_v1`: a 140 house reads `140/140` on the night HUD with no danger pulse
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
