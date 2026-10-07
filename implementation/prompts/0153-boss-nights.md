# 0153 - Boss nights repeat until the boss falls

- **Phase:** 11 - Calendar and seasons
- **Status:** todo
- **Depends on:** 0151, 0137
- **Likely files:** src/core/waves.gd, src/core/phases.gd, src/core/calendar.gd, src/core/rewards.gd, src/core/sim.gd, src/core/game_data.gd, src/ui/result_screen.gd, src/ui/night_hud.gd, assets/locale/strings.csv, src/tools/perf_check.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/shot.gd

## Goal

Day 14 of every season is the season's boss night, and the season does not end until that boss is down. A boss alive at dawn walks off with the rest and is back the next night - without the loss penalty, and without the farm losing a day of crops and animals.

## Requirements

- `SEASON_BOSSES: Array = [&"giant", &"giant", &"giant", &"giant"]` (one per season; 0253-0255 put in the Harvester, the Scarecrow King and the Winter Lord); `check_calendar` requires each to be an `is_boss` enemy; in `digest()`
- `Calendar.is_boss_night(date)` is the season's last day. In `Waves.night_of`: a boss date's record gets one row of the season's boss, third from last like `Endless._put_the_giants_in`, from spawn 0 (the east, open in every season - 0157); every other date loses its `is_boss` rows (today's night 10 loses its Giant; Endless's every-fifth-night Giants stop reaching the calendar, and the `giant_every` levers stay for 0279 to decide)
- `Waves.boss_fell(state)`: every `is_boss` body in tonight's record was killed (from `killed_by_kind`). `Waves.tick` raises `boss_arrived` from `is_boss`, not from `&"giant"`
- 0137's interim goes (dawn waiting while `Combat.boss_here`, the night HUD's dawn countdown holding at 0:00, and the `_task_0137_dawn` assert of it, rewritten in place in `headless_v1` as the escape below). At dawn (`dawn_at`) on a boss night, boss alive and house standing: a third outcome, escaped, through `Rewards.settle` and `Phases.enter_result` - the boss and the survivors walk off as on any dawn, no `_loss`, no night pay or technology, `nights_won` unchanged. The house falling is a loss as on any night. The season holds whenever the boss did not fall, however the night ended
- The hold is a counter, not a frozen `day`: `day` still moves every night (the stall restocks on it, the report and stats count it, every day system runs) and a new Phases key `days_held` grows by one; `Calendar.date(state)` becomes `day - days_held`, so the date stays on 14 and tonight is the boss again. A new top-level int only: reconcile fills 0 for old saves, no version bump
- `nights_paid` is keyed by the date, so a repeated boss night pays its technology once, when the boss falls
- The morning report says it: `RES_BOSS_ESCAPED` (%s GOT AWAY - IT COMES BACK TONIGHT / %s FUGIU - VOLTA HOJE À NOITE), the boss named through `Names.of`
- Whatever assumed the Giant on night 10 looks for the boss on Spring 14: `_task_0058_giant` (`Waves.table(...)` of the last night), the 'one new thing a night' asserts of `_task_0059`/`_task_0060` and `_task_0070_endless`'s Giant counts if any still read `night_of` rather than `plain_night`, and `perf_check.gd`'s worst case (0275 later makes it the winter boss night)
- Hashes: SIM moves on purpose (a new key, the boss rows); DATA moves (a new table) - both in the journal

## Done when

- [ ] `_task_0153_boss_nights` in `src/tools/headless_v1.gd`: for dates 1-112 and two seeds, `is_boss` rows appear only on dates 14, 28, 42, 56, 70, 84, 98 and 112, once each, with the season's boss; `python tools/nights.py --check` still passes with the boss rows in
- [ ] The same group, from Spring 14 fixtures started through 0118's `NightRoad` (its park, with dawn brought close rather than played out): boss alive at dawn -> no stock taken, `nights_won` unchanged, `day` +1, the date still 14, the stall restocked, tonight's record the boss night again; boss killed -> the next date is 15; house down with the boss alive -> the loss and the hold; house down after the boss fell -> the loss and no hold
- [ ] `boss_arrived` is raised for the Giant through `is_boss`, and `src/core/waves.gd` no longer names `&"giant"`
- [ ] A `boss_escaped` shot scenario: `python tools/shot.py 0153 boss_escaped --fhd`, opened - the morning report names the boss and says it comes back
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
