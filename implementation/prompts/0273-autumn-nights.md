# 0273 - Autumn's fourteen nights

- **Phase:** 15 - Fifty-six nights and balance
- **Status:** done
- **Depends on:** 0270, 0249, 0250, 0254, 0259, 0272
- **Likely files:** src/core/game_data.gd (`KEY_NIGHTS`, autumn's `SEASON_NIGHTS`), src/tools/headless_v1.gd

## Goal

Autumn opens the north and brings the two enemies that ignore the shape of a maze: the crow flies over it to eat the crops, the digger goes under the fences and barricades. The Scarecrow King calls his flocks on day 42, and the Blood Moon can rise from now on.

## Requirements

- Days 30-42 fight; day 29 is 0154's calm night after the Harvester. The east, the south-east and the north are open (0157); the first north night is a small one
- The crow and the digger are introduced on different nights - one in days 30-34, the other in days 36-41 - never together; the Full Moon on day 35 sends what is already known; the night after each introduction bites
- Crows eat what is in the ground, and autumn's fields are full (wheat, pumpkin, grape, beet): crow nights are the ones where the farm's layout matters, so their first one is gentle
- Day 42 is the Full Moon with the Scarecrow King in company - 0153's row from `SEASON_BOSSES`, which 0254 set; this task writes the company. The crows he summons come from his rule, not from rows, so the forecast's count leaves them out by design (0254): day 42's note says he calls crows, and the journal gives the peak count of crows alive on day 42 in `play_nights`
- The Blood Moon (0257) may roll from autumn: list which autumn days roll it for seeds 0-4 in `tools/nights.py`, and pin `event` off on an introduction night it would drown (0270's field)
- Read 0259's `implementation/MATCHUPS.md`: every night has an answer in what autumn's arsenal (0234) has unlocked by that day - the mortar, the pumpkin catapult and the garlic braid - and the journal says which weapon each new enemy is meant to teach
- The template keeps climbing from summer's final numbers (`python tools/play_nights.py 29 42`); notes in the authored voice; every night fits and fills the night (0137, 0271's `NIGHT_FILL_TICKS`); DATA moves on purpose, SIM only if a day the determinism scenario fights changed

## Done when

- [ ] `_task_0273_autumn_nights` in `src/tools/headless_v1.gd`: days 30-42 send only kinds introduced by that day, only from the east, south-east and north; the crow and the digger are first sent on their introduction days, on different nights; the Scarecrow King is on day 42 and nowhere else; days 35 and 42 are the largest of their halves in hit points
- [ ] `python tools/nights.py 29 42` and `python tools/play_nights.py 29 42` output in the journal, with the Blood Moon days for seeds 0-4 and the matchup line for each new enemy
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
