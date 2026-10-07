# 0257 - The Blood Moon

- **Phase:** 14 - Enemies and bosses
- **Status:** todo
- **Depends on:** 0256, 0219, 0246
- **Likely files:** src/core/weather.gd, src/core/entities.gd, src/core/combat.gd, src/core/game_data.gd, src/core/rewards.gd, src/core/tech.gd, src/ui/forecast_panel.gd, src/ui/result_screen.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd

## Goal

A rare red night from autumn on: the horde comes back stronger and pays in essence. Rare enough to be an occasion, forecast so it is never an ambush.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A055
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- `blood_moon` joins `GameData.NIGHT_EVENTS`: weight 0 in spring and summer (refused otherwise by `check_night_events`), a small `# LEVER` weight in autumn and winter; `Weather.event` never returns it when `Calendar.is_boss_night(date)` (an elite boss is another balance problem); decide whether it may fall on `Calendar.is_full_moon(date)` and say why
- Elites: on a Blood Moon night `Entities.spawn` (reading `Weather.event` for `Calendar.date(state)`) scales hp by `blood_moon_hp_percent` (120-200, integers) and writes `max_hp` on the elite only, so ordinary nights are untouched and 0246's `Combat.full_hp` (and any health bar that reads it) uses it
- Extra essence through 0219's earn rules: a `blood_moon_essence` `# LEVER` in `GameData.REWARDS`, its own itemised line in `Tech.would_pay` on a won night, shown in the morning report as a `RES_*` row in both languages; `nights_paid` still stops it paying twice
- In the forecast slot (`Forecast.of`'s `event`, `forecast_panel.gd`): `FCAST_BLOOD_MOON` (BLOOD MOON / LUA DE SANGUE) and the icon placeholder until A055 is integrated by 0269
- `Waves.size_of` and the forecast count do not change: elites are tougher, not more
- Hashes: DATA moves; SIM should not (`max_hp` exists only on elites)

## Done when

- [ ] `_task_0257_blood_moon` in `src/tools/headless_v1.gd`: over seeds 0-49 and dates 1-56 (pure calls) no Blood Moon falls in spring, summer or on a boss night, and the autumn and winter counts are printed; on one, a walker spawns with the scaled hp and `full_hp` reads it; winning pays the extra essence, once
- [ ] `python tools/shot.py 0257 forecast_blood_moon --fhd` (a new scenario that finds a Blood Moon (seed, date) through `Weather.event`) shows it in the forecast, opened and looked at
- [ ] the Deliverables table of `implementation/backlog/packs/A055-event-icons.md` states the final geometry this task settled (fog, rain and Blood Moon at 16x16 and 10x10)
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
