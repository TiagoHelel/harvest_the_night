# 0274 - Winter's fourteen nights

- **Phase:** 15 - Fifty-six nights and balance
- **Status:** done
- **Depends on:** 0270, 0251, 0252, 0255, 0259, 0273
- **Likely files:** src/core/game_data.gd (`KEY_NIGHTS`, winter's `SEASON_NIGHTS`), src/tools/headless_v1.gd

## Goal

Winter is the exam: every side open, the frost zombie that slows the towers it dies beside, the wraith that cannot be shot outside the light, and the Winter Lord on day 56. Nothing grows, so these nights are fought with what autumn put away.

## Requirements

- Days 44-56 fight; day 43 is 0154's calm night after the Scarecrow King. Every side is open (0157), but the sides new to winter join over several nights through the side join days of winter's template (0270) and key nights - never on an introduction night
- The frost zombie and the wraith are introduced on different nights, never together; the Full Moon on day 49 sends what is already known; the night after each introduction bites
- The first wraith night is small and answerable with the light a farm has without a searchlight - the porch, the flare, burning cells (0229's light rule) - because it is the night that teaches the searchlight
- Day 56 is the Full Moon with the Winter Lord in company - 0153's row from `SEASON_BOSSES`, which 0255 set; this task writes the company - and the largest night of Year 1; 0160's ending hook fires when he falls
- Nothing grows outdoors in winter (the plan; the rule is 0171), so the money for these nights was made in autumn: prefer a climb in variety - sides, kinds, events - over a climb in bodies
- Read 0259's `implementation/MATCHUPS.md`: every night has an answer in what winter's arsenal (0234) has unlocked by that day (`python tools/play_nights.py 43 56`) - the searchlight and the electric fence - and the journal says which weapon each new enemy is meant to teach
- Notes in the authored voice; every night fits and fills the night (0137, 0271's `NIGHT_FILL_TICKS`); DATA moves on purpose, SIM only if a day the determinism scenario fights changed
- With all four seasons authored, `GameData.check_nights` refuses a night whose last wave is sent before 0271's fill line (`NIGHT_FILL_TICKS`), for every date `python tools/nights.py --check` resolves: 0148 found a night that is over in a minute leaves dawn nothing to do

## Done when

- [ ] `_task_0274_winter_nights` in `src/tools/headless_v1.gd`: days 44-56 send only kinds introduced by that day; the frost zombie and the wraith are first sent on their introduction days, on different nights; the Winter Lord is on day 56 and nowhere else; day 56 is the largest night of days 1-56 in hit points; a copy of a night with its last wave moved before 0271's fill line is refused by `check_nights`
- [ ] `python tools/nights.py 43 56` and `python tools/play_nights.py 43 56` output in the journal, with the matchup line for each new enemy and the night each side first opens
- [ ] `python tools/nights.py` for the whole year, after all four seasons, is in the journal: the year's curve in one table
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
