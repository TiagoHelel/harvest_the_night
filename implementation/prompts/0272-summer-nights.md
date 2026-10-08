# 0272 - Summer's fourteen nights

- **Phase:** 15 - Fifty-six nights and balance
- **Status:** todo
- **Depends on:** 0270, 0247, 0248, 0253, 0259, 0271
- **Likely files:** src/core/game_data.gd (`KEY_NIGHTS`, summer's `SEASON_NIGHTS`), src/tools/headless_v1.gd

## Goal

Summer opens the second side and brings the first enemies that change what a spring defence is worth: the spitter shoots towers from range, the rats come in numbers that mines and fire love, and on day 28 the Harvester charges straight through the walls.

## Requirements

- Days 16-28 fight; day 15 is 0154's calm night after the Giant. The east and the south-east are open (0157), and the first south-east night is a small one, so the new side is learned before it is tested
- Summer's first fight starts below spring's Full Moons and above spring's day 6, so the year still climbs; spring's four kinds stay in the mix at summer's share
- The spitter and the rat swarm are introduced on different nights - one in days 16-20, the other in days 22-27 - never together; the Full Moon on day 21 sends what is already known; the night after each introduction bites
- Day 28 is the Full Moon with the Harvester in company, so it cannot be focused alone: the Harvester is the row 0153's rule adds from `SEASON_BOSSES` (0253 put it there), and this task writes its company
- Read 0259's `implementation/MATCHUPS.md` first: every night's mix has an answer in what summer's arsenal (0234) has unlocked by that day - the flamethrower, the decoy, the beehive and the bait arrive this season - and the journal says which weapon each new enemy is meant to teach
- Rats are many bodies: print the peak entity count of the largest rat night and compare it with what the swarm scenario of 0218/0248 in `perf_check.gd` measured; the year's worst case is 0275's
- Author against `python tools/nights.py 15 28` and `python tools/play_nights.py 15 28` (0271's range), starting from spring's final numbers; notes in the authored voice; every night fits and fills the night (0137, 0271's `NIGHT_FILL_TICKS`); DATA moves on purpose, SIM only if a day the determinism scenario fights changed

## Done when

- [ ] `_task_0272_summer_nights` in `src/tools/headless_v1.gd`: days 16-28 send only kinds introduced by that day, only from the east and the south-east; the spitter and the rats are first sent on their introduction days, on different nights; the Harvester is on day 28 and nowhere else; days 21 and 28 are the largest of their halves in hit points
- [ ] `python tools/nights.py 15 28` and `python tools/play_nights.py 15 28` output in the journal, with the matchup line for each new enemy and the peak rat count
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
