# 0165 - Crops grow by days

- **Phase:** 12 - The day that pays
- **Status:** done
- **Depends on:** 0149, 0151, 0156
- **Likely files:** src/core/farming.gd, src/core/phases.gd, src/core/sim.gd, src/core/game_data.gd, src/app/save.gd, src/core/state.gd, src/ui/day_hud.gd, src/ui/describe.gd, src/ui/shop_panel.gd, assets/locale/strings.csv, src/tools/perf_names.gd, src/tools/perf_check.gd, tools/perf_baseline.txt, src/tools/make_goldens.gd, tools/goldens/, src/tools/autoplay.gd, src/tools/art_showcase.gd, src/tools/effect_showcase.gd, src/tools/house_check.gd, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd

## Goal

Crops grow by days, the way the plan and Stardew have it: each morning a plot that was watered the day before moves one day along. A field becomes something you plan a week around, not a minute.

## Requirements

- `CROPS` entries trade `growth_ticks` for `growth_days` (`# LEVER`, plan section 3.1: carrot 3, wheat 4, corn 8; the other nine crops are 0168's). `stages` stays 4 and `Farming.stage()` maps days onto it in integer arithmetic
- The credit: `Farming.dry_out()` (called by `Phases.begin_preparation`) first records which planted plots were watered, then dries them; `Phases.begin_day` calls a new `Farming.morning(state)` that adds one day to each recorded plot and raises `crop_ready`. One credit per morning, so a boss night that repeats (0153) still grows the field and a farmer who passed out (0128) is credited like one who went to bed
- Dry is not dead: an unwatered plot waits a day and loses nothing (`TUT_WATER` - 'come up sooner watered' - is rewritten to say so, both languages). `WATER_GROWTH_BONUS` and the `soak` bank go, nothing grows per tick any more: take `Farming.tick` out of `Sim._tick_day` and `Farming` out of `PerfNames.DAY` (`_task_0102_budget` compares the two), its arm out of `perf_check.gd`'s `_tick_one`, and the `day_farming` row out of `tools/perf_baseline.txt` (`python tools/perf.py --accept`)
- `value_per_day`, `harvests_per_day`, `seconds_to_grow` and `GameData._crop_offer`/`check_crops` work in days: harvests per season of 0149's season length, value per harvest as today; the seed strip (`DHUD_SEED_ROW` and its `DHUD_SEED_HEADING` 'TIME /DAY', `day_hud.gd`), the stall's seed rows (`SHOP_SEED_ROW`, `shop_panel.gd`) and the tooltip (`DESC_GROWS_IN`, `describe.gd`) say days, in both languages
- A saved plot's `growth` changes units: `State.VERSION` 7 (after 0156's 6) with a step in `Save.migrations()` that turns tick growth into whole days (rounded down, a ready crop stays ready - the step carries the old `growth_ticks` per crop as literals, the table no longer has them) and drops `soak`, plus `run-v7*.sav` through `src/tools/make_goldens.gd`; every older golden still loads
- Rewrite `_task_0028_crops` and `_task_0029_watering` (headless_check) and `_case_0028_seeds`/`_case_0029_watering` (input_check) to the new rule, and every other reader of tick growth: `_task_0018_wheat`, `_task_0020_shop` and `_task_0039_clock` (growth paused by a panel, a crop ripe after a day), `_task_0038_idle` (`_a_busy_day` asserts 'the crops grew' within one idle day), `_task_0109_reactions` ('a crop coming ready nearby puts a note up' within 12000 day ticks - `crop_ready` now fires at the morning credit, with him waking indoors: decide what the note means now), `_case_0040_shop` (its seed labels print `seconds_to_grow`), `art_showcase.gd` (it calls `Farming.tick`; `show_art.py --check` runs in verify), `effect_showcase.gd`, `house_check.gd`, the autoplayer's field plan - grep `growth`, `is_ready` and `Farming.tick` for the rest
- Tests credit mornings by calling `Farming.morning` or `Phases.begin_day`, never by advancing whole days of ticks - a day is about to become some sixteen thousand of them (0166)
- SIM moves on purpose (the determinism scenario plants crops) and DATA moves (the CROPS table); record both numbers

## Done when

- [ ] `_task_0165_days` in `src/tools/headless_v1.gd`: a watered and an unwatered carrot planted together are a day apart after one morning; a carrot watered three days running is ready on the third morning; passing out credits the field like going to bed
- [ ] The migration turns a golden's half-grown plot into the matching whole days, asserted
- [ ] `python tools/shot.py 0165 noon --fhd` shows the field at several stages (the `noon` scenario gives its plots growth days directly - a first morning is all stage 0); opened and looked at
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
