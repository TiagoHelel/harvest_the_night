# 0152 - Full Moon nights

- **Phase:** 11 - Calendar and seasons
- **Status:** done
- **Depends on:** 0151
- **Likely files:** src/core/calendar.gd, src/core/waves.gd, src/core/rewards.gd, src/core/game_data.gd, tools/palette.py, src/ui/palette_data.gd (generated), src/ui/world_view.gd, src/ui/day_hud.gd, src/ui/result_screen.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

Days 7 and 14 of every season are Full Moon nights: a bigger horde, double the pay, and a night you can see further into. The player sees one coming days ahead.

## Requirements

- `FULL_MOON_DAYS: Array = [7, 14]  # LEVER: days of the season`, `FULL_MOON_HORDE_PERCENT := 150  # LEVER: percent of the night's count, 120-200` and `FULL_MOON_REWARD_PERCENT := 200  # LEVER: percent of the night's pay, 150-300`; `check_calendar` refuses a Full Moon day outside the season and a percent under 100; all go into `digest()`
- `Calendar.is_full_moon(date)` and `days_to_full_moon(date)` (0 on the night itself), pure
- In `Waves.night_of`, over `plain_night`: a Full Moon date's record has each non-boss wave's count scaled by `FULL_MOON_HORDE_PERCENT` (integer arithmetic, never below the plain count), boss rows untouched, and carries `"full_moon": true` - the flag 0158's forecast reads. Authored and generated nights alike, and no RNG. A scaled record must still fit 0137's night length (`python tools/nights.py --check` resolves Full Moons too): if one does not, the Full Moon record tightens its own pacing (its gaps first), never the check
- `Waves.tonight()` is asked every frame by the night HUD: cache a record a rule changed the way generated ones are cached (`wave.tonight`), and only then, so night 1 stays the authored row and nothing new enters its state
- `Rewards`: a won Full Moon night pays `FULL_MOON_REWARD_PERCENT` of its money and materials, itemised as its own line for the morning report. Essence is not doubled here (0219 reads this helper for that) and moon stones are 0221's
- View only, a brighter night ramp: a `full_moon` entry in `tools/palette.py` `RAMPS` with the five fields `night` has (tint, lift, saturation, warm_keep, warm_edge), which `python tools/gen_sprites.py` writes into `PaletteData` as `FULL_MOON_TINT`, `_LIFT`, `_SATURATION`, ... (never edit `palette_data.gd`); `WorldView._night_ramp()` (static today) picks them when tonight is a Full Moon, and it still reads as night
- The day HUD's date line gains `FULL MOON IN 4 DAYS` / `FULL MOON TONIGHT` (plan section 9) through `I18n.plural`: `DHUD_FULL_MOON_IN.one`/`.other` (FULL MOON IN %d DAY(S) / LUA CHEIA EM %d DIA(S)), `DHUD_FULL_MOON_TONIGHT` (FULL MOON TONIGHT / LUA CHEIA HOJE), and the morning report's `RES_FULL_MOON` (FULL MOON BONUS / BÔNUS DE LUA CHEIA - no 'double', since the percent is a lever)
- `_task_0060`'s 'every curve climbs' and `_task_0070`'s 'it grows' keep reading `plain_night` (0150); if anything else in the suites assumed day 7 or 14 is a plain night, point it at the plain record
- Hashes: DATA moves (new levers). SIM should not, because the determinism night is day 1 - if it moves, explain it

## Done when

- [ ] `_task_0152_full_moon` in `src/tools/headless_v1.gd`: days 7, 14, 21 and 56 are Full Moons and 6, 8 and 15 are not; a Full Moon record sends the lever's percent of its plain record per wave with the boss count unchanged; a won Full Moon night's money and materials are the lever's percent of what the same state would be paid with the flag off (same kills), with the difference on its own line; `Waves.tonight` hands back the same record over 100 ticks; `python tools/nights.py --check` still passes
- [ ] `_case_0152_moon_line` in `src/tools/input_v1.gd` reads the line on day 3 (`FULL MOON IN 4 DAYS`), day 6 (`... IN 1 DAY`) and day 7 (`FULL MOON TONIGHT`), in both languages
- [ ] A new shot scenario `full_moon` (the `wave` scene on day 7): `python tools/shot.py 0152 wave full_moon --fhd`, opened side by side - brighter, and still night
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
