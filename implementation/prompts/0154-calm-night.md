# 0154 - The calm night after a boss

- **Phase:** 11 - Calendar and seasons
- **Status:** done
- **Depends on:** 0153
- **Likely files:** src/core/calendar.gd, src/core/waves.gd, src/core/rewards.gd, src/core/game_data.gd, src/ui/day_hud.gd, src/ui/result_screen.gd, src/tools/nights.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

After a boss falls the horde regroups: the first night of the next season sends nothing, the farmer sleeps through it, and something is waiting on the porch in the morning. Spring 1 of Year 1 is still the tutorial's night 1.

## Requirements

- `Calendar.is_calm(date)`: the first day of a season, except the first day of the game. With 0153's hold the calendar reaches a new season only once its boss has fallen, so this is a pure function of the date and the forecast cannot be wrong about it - in every year, Spring 1 of Year 2 included
- `Waves.night_of` returns a calm record for those dates: `{note, opening_ticks: 0, waves: [], calm: true}`. `check_nights` refuses an empty wave list unless the record says calm; `Waves.summary_of` and `tools/nights.py --check` print and accept it as calm
- The night still happens and takes no special road: the build step opens as on any night (decision #4: the only time defences go down), START - or 0128's 30 s after passing out - starts a night with nothing in it, and `Waves.begin`'s empty table wins it on the first tick
- A calm night pays only the gift: `CALM_NIGHT_GIFT: Dictionary = {WOOD: 20, STONE: 20, FOOD: 10}  # LEVER: units each, 0-60` - no night money, materials or technology, since nothing was defended; `nights_paid` still records the date; `validate()` allows only known resources and never money or `tech`; in `digest()`
- The day HUD's date line says `CALM NIGHT` on a calm date (`DHUD_CALM_TONIGHT`: CALM NIGHT / NOITE CALMA); the morning report says `RES_CALM_NIGHT` (A CALM NIGHT - THE HORDE REGROUPED / NOITE CALMA - A HORDA SE REAGRUPOU) and `RES_GIFT` (A GIFT ON THE PORCH / UM PRESENTE NA VARANDA); 0158's forecast reads the record's flag
- Anything in the suites or tools that reads dates 15, 29, 43 or 57 through `night_of` and expects a fight (a size, a kind, a side) reads `plain_night` instead, or skips calm dates; 0137's night-length sample and `tools/nights.py` accept a calm record
- Hashes: SIM should not move (day 1 is not calm); DATA moves (the gift lever)

## Done when

- [ ] `_task_0154_calm` in `src/tools/headless_v1.gd`: dates 15, 29, 43 and 57 are calm and 1, 14 and 16 are not; a calm night ends won on its first tick after START with no entity spawned; it pays exactly `CALM_NIGHT_GIFT` and no technology
- [ ] `_case_0154_calm` in `src/tools/input_v1.gd`: to bed on Summer 1, START, and the morning report shows the calm and the gift - once by keyboard, once by pad
- [ ] A `calm_morning` shot scenario: `python tools/shot.py 0154 calm_morning --fhd` and `--pt_BR`, opened
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
