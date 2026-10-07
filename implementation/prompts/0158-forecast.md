# 0158 - The forecast

- **Phase:** 11 - Calendar and seasons
- **Status:** todo
- **Depends on:** 0151, 0152, 0153, 0154, 0157
- **Likely files:** src/core/forecast.gd (new), src/ui/forecast_panel.gd (new), src/ui/day_hud.gd, src/ui/night_hud.gd, src/ui/names.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

At dusk the farmer learns what is coming: from which sides, how many and of what kind, and whether it is a Full Moon, a boss or a calm night. The forecast is never wrong, because it is the night.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A010, A011
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- `src/core/forecast.gd` (`class_name Forecast`): `Forecast.of(seed, date)` returns `{date, season, day_of_season, full_moon, boss, calm, sides, waves, kinds, count, event}`, pure, built only from `Waves.night_of(date, seed)` - the record the night will fight, flags included - and `Calendar`; `Forecast.tonight(state)` asks it for `Calendar.date(state)`
- Never the run's stream: it reads `state["seed"]`, never `state["rng"]`, and anything random in it comes from a fresh `(seed, date)` stream like `Endless._stream_for`
- `event` is an empty slot (`&""`) that 0256 fills from `(seed, date)`; the panel draws nothing for it until then
- `src/ui/forecast_panel.gd`: shown in the day HUD from 18:00 (0126's dusk, `Phases.is_dusk`) and on the night HUD in the build step, hidden at noon and once the waves start. It shows the date, the season and moon marks, the sides in words, the waves, and one head and count per kind; a calm night says so and nothing else
- Strings in both languages, widths measured: `FCAST_TITLE` (TONIGHT / ESTA NOITE), `FCAST_FROM` (from the %s / pelo %s), `SIDE_EAST`, `SIDE_SOUTH_EAST`, `SIDE_NORTH`, `SIDE_WEST`, `SIDE_SOUTH` (EAST / LESTE, SOUTH-EAST / SUDESTE, NORTH / NORTE, WEST / OESTE, SOUTH / SUL), `FCAST_EVERY_SIDE` (from every side / por todos os lados), `FCAST_WAVES.one`/`.other` (%d WAVE / %d WAVES; %d ONDA / %d ONDAS), `FCAST_FULL_MOON` (FULL MOON / LUA CHEIA), `FCAST_BOSS` (%s IS COMING / %s ESTÁ VINDO), `FCAST_CALM` (A CALM NIGHT / NOITE CALMA). 0157's side ids get literal `Names.KEYS` entries (`east` -> `SIDE_EAST`, ...) so the panel names a side with `Names.of` and `tools/i18n_check.py` sees the keys; kinds through `Names.of` and the plural enemy keys
- Stand-ins through 0120's placeholder road until A010 is integrated by 0161 and A011 by 0162: each enemy's first walk frame cropped into a 16x16 head box, and code-drawn moon, boss and season marks at 16x16 and 10x10
- No new input path: the panel is information, and showing it all day is an option of 0292's
- Moved here from 0151: the night HUD's top strip (0139) names the date beside its night label with 0149's helper and `DHUD_DATE`/`DHUD_DATE_YEAR` (`SPRING 3`), through the waves too, so the plan's 'season, night and wave' is on screen
- Pure functions and view only: SIM and DATA must not move

## Done when

- [ ] `_task_0158_forecast` in `src/tools/headless_v1.gd`: for a plain, a Full Moon and a calm date, the forecast's kinds, count and sides equal what the night sends (count `Enemies.spawn` through a parked run that only steps until every wave is out, keeping the group to a few seconds), and a boss date names the season's boss; 1000 calls to `Forecast.tonight` leave `state["rng"]` and the state hash unchanged
- [ ] `_case_0158_panel` in `src/tools/input_v1.gd`: hidden at noon, shown at 18:00 and in the build step, hidden once START is pressed
- [ ] `forecast_dusk` and `forecast_build` shot scenarios: `python tools/shot.py 0158 forecast_dusk forecast_build --fhd` and with `--pt_BR`, opened - every line fits, the night HUD names the date, and the heads read as the enemies
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
