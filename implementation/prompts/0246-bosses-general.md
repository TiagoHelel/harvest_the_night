# 0246 - Bosses in general

- **Phase:** 14 - Enemies and bosses
- **Status:** todo
- **Depends on:** 0153, 0196
- **Likely files:** src/core/combat.gd, src/ui/night_hud.gd, src/ui/log_panel.gd, src/ui/enemy_motion.gd, src/ui/enemy_deaths.gd, src/ui/pixel_effects.gd, src/ui/world_view.gd, src/ui/sfx.gd, assets/locale/strings.csv, tools/check_giant_art.py, tools/show_art.py, src/tools/giant_showcase.gd, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

Three more bosses are coming, and everything that knows about a boss today knows about the Giant by name. Make the bar, the counters, the arrival line, the sounds and the art checks work for anything with `is_boss`, so 0253-0255 are a data entry and a behaviour each.

## Requirements

- `Combat.boss_here` stays the lowest-id boss on the farm; add `Combat.bosses_here(state)` (sorted ids) and `Combat.full_hp(state, id)` (the table's `hp` today), so the boss bar (`NightHud._refresh_boss` reads `ENEMIES[kind]["hp"]` today) reads a body's full health from the one place 0257's elites will change; `Describe.enemy` describes a kind and keeps the table's number
- Per-boss counters without a new State key: `Combat.bosses_down_of(state, kind)` reads `killed_by_kind_all_run` (RUN_DATA) for `is_boss` kinds; `bosses_down` stays the run total `Run` reports. Raising `boss_arrived` for any `is_boss` is 0153's, not this task's
- The night HUD's boss bar (`NightHud._refresh_boss`, or wherever 0139 moved it) names whichever boss is up, adds `x2` when more than one is alive (Endless already sends two Giants) and keeps the wind-up flash for any boss with `telegraph_ticks`
- A boss intro line: `LOG_BOSS` ('the giant is coming') becomes one literal key per boss in a const map in the view (`BOSS_INTRO_GIANT` first; key,width,en,pt_BR rows in `assets/locale/strings.csv`), shown as a banner on `boss_arrived` and as the log line; delete the `LOG_BOSS` row, since `tools/i18n_check.py` fails on unused keys
- View hard-codes on the Giant's id become boss-generic where the art follows the Giant's pose names (`EnemyMotion.TRACKED` and `_giant_pose`, the five death frames in `EnemyDeaths`, the impact offset in `PixelEffects`, the `giant_windup_` test in `WorldView`): a boss with no authored poses falls back to the ordinary path, and the Giant draws exactly as before. `Sfx` too: `_watch_bodies` announces any `is_boss` on arrival with no position, `nearest_by_kind` leaves every boss out and `_ducks` ducks for any boss voice - so 0253-0255 borrow `sfx/roar_giant` in `ENEMY_SOUNDS` until 0284 voices them
- `tools/check_giant_art.py` becomes table-driven (family -> motion counts, canvas, pivot, generation task; only the Giant today) and its exact `migrated_enemies() == {five}` becomes a subset check, so a new enemy family cannot fail it; `giant_showcase.gd` takes the family and `tools/show_art.py` routes a new `--boss=<family>` to it (`--giant` unchanged) for the leaves 0266-0268
- Rewrite `_task_0058_giant`'s 'the only boss in the table' and 'outlasts every other enemy' asserts as every boss against every non-boss (hp, armour, walking `ticks_per_tile`), because 0247-0255 add both kinds
- Hashes unchanged: helpers, view and tests only

## Done when

- [ ] `_task_0246_bosses` in `src/tools/headless_v1.gd`: two Giants on the farm give `bosses_here` both ids in order; killing one moves `bosses_down_of(state, &"giant")` and `bosses_down` by one each; every `is_boss` entry has an intro key in the map and in the strings table
- [ ] `_case_0246_boss_bar` in `src/tools/input_v1.gd`: a spawned Giant raises the bar and the banner, `Sfx.nearest_by_kind()` has no entry for it, and the bar goes when it dies
- [ ] `python tools/check_giant_art.py` and `python tools/show_art.py --giant --check` pass and report the Giant as before
- [ ] `python tools/shot.py 0246 boss` (a new scenario: a Giant winding up) opened and looked at: bar, name and banner overlap neither the hotbar nor the time to dawn
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
