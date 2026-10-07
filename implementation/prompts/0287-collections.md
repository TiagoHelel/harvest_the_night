# 0287 - Collections and achievements

- **Phase:** 16 - Sound, collections and polish
- **Status:** todo
- **Depends on:** 0152, 0155, 0160, 0170, 0182, 0253, 0254, 0255
- **Likely files:** src/core/collections.gd, src/core/stats.gd, src/core/farming.gd, src/core/phases.gd, src/core/run.gd, src/core/game_data.gd, src/app/save.gd, src/app/app.gd, src/app/input_actions.gd, project.godot, src/ui/collections_screen.gd, src/ui/title_screen.gd, src/ui/main.gd, scenes/Title.tscn, scenes/Main.tscn, assets/locale/strings.csv, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd, src/tools/shot.gd, implementation/backlog/packs/A056-collections.md

## Goal

The plan's reason to start Year 2: four collections - fish, crops, the bosses' trophies and a year without losing the house - and a short list of achievements, kept in the profile across runs and shown on one screen.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A056
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- A node-free `src/core/collections.gd` in the shape of `Stats`: it reads facts other modules already count and keeps no second ledger - fish from 0182's book, trophies from 0246's `Combat.bosses_down_of` (`killed_by_kind_all_run`) for every `is_boss` kind, crops from a harvest tally - and folds them into the profile with the banking of `Stats.fold` (`stats.banked`), so folding twice adds nothing. Call it from inside `Stats.fold`, so every fold site (`main.gd`'s autosaves, `Run.record`) gets it without a second call
- Crops count harvests, not `gained`: everything `Resources.add` brings in (a purchase through `Shop.buy`, a gift, loot) lands in `gained` too. Add `stats.harvested_by_crop` to `Stats.initial()` (inside the `stats` TABLE, so reconcile fills old saves and no version bump is needed), counted in `Farming._harvest` the way `Stats.built` is counted in `Building.place`. SIM moves on purpose (the state gains keys): both numbers in the journal
- 'A year without losing the house' is a run that saw Winter 14's boss fall (0160's `Run.is_over`) with no night on which the house fell; a boss that walks off at dawn (0153's escaped outcome) is not a lost house. Nothing counts lost nights today: add `stats.nights_lost` beside the crop tally, counted in `Phases.enter_result` when the house fell (read how 0153 marks an escape in `last_result` and leave that out)
- About a dozen achievements, decided here, repeating none of the collections - e.g. first night survived, a Full Moon held (0152's `Calendar.is_full_moon`), a legendary landed, every defence in `DEFENCES` built once, a night with nothing destroyed, Year 2 reached - each a pure test of the lifetime stats, the collections and this run's record. A table in `game_data.gd` (thresholds `# LEVER`, a `check_achievements` in `GameData.validate()` that every id it names exists, listed in `GameData.digest()` so DATA moves on purpose) whose entries carry literal `&"ACH_*"` keys for a name and a one-line description: a key built at runtime is invisible to `tools/i18n_check.py`
- The profile: `Save.default_profile()` gains `collections` and `achievements`; `read_profile` already merges the defaults, so an older profile loads with no format bump. No toast for a newly earned badge in this task: the skeleton asks for the screen, and the task has to fit one invocation
- `src/ui/collections_screen.gd`, a sibling of `StatsScreen` (a node in `scenes/Title.tscn` and `scenes/Main.tscn`, as it is): tabs for fish (0182's book view embedded - reuse its pages, do not rebuild them; 0182's own way in keeps working), crops, bosses, the year and achievements, each with a count. Locked trophies and badges are the earned art dimmed by code, so A056 needs no locked state
- Ways in: the title menu (`ENTRIES` gains `collections`, `TITLE_COLLECTIONS`), a `COLLECTIONS` router state in `App.STATES` and `App.NAMES` (update the state count `_task_0092_router` asserts in `headless_check.gd`) and, in a run, a new `collections` action in `InputActions.ACTIONS` (`ACT_COLLECTIONS`, `ACT_GROUP_SCREENS`) with key and pad bindings in `project.godot` (0121's sync and clash checks), opened and closed the way the `stats` key opens `StatsScreen`. Strings in both languages, e.g. `TITLE_COLLECTIONS` (COLLECTIONS / COLEÇÕES), the tabs, every `ACH_*`
- Placeholders until 0288 integrates A056, through 0120's road: the existing crop and fish icons on the tabs, each boss's first frame as its trophy, code-drawn shapes for the badges, the cover and the ornament - never a hand-drawn PNG

## Done when

- [ ] `_task_0287_collections` in `src/tools/headless_v1.gd`, on crafted states rather than a 56-night run (the 120 s limit): a harvested crop ticks its page and the same crop added through `Resources.add` does not; a boss killed adds its trophy; a run that lost a night never earns the year, one whose boss only escaped still can, and one that lost none and beat Winter 14 does; folding twice adds nothing; a profile without the new keys reads with defaults; `GameData.validate()` refuses an achievement naming an unknown id
- [ ] `_case_0287_collections` in `src/tools/input_v1.gd`: the title menu opens the screen, the tabs move by keyboard and by pad, cancel goes back to the title; in a run the `collections` key opens and closes it
- [ ] FHD captures of every tab with an empty and a full profile in English, and with the full profile in Portuguese (`src/tools/capture_menus.gd` or a new `shot.gd` scenario), opened and looked at, in `implementation/shots/0287/`
- [ ] The Deliverables table of `implementation/backlog/packs/A056-collections.md` states the final geometry this task settled: canvases, pivots and runtime names for the cover, the tab icons, a trophy per boss, one badge per achievement id and the ornament
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
