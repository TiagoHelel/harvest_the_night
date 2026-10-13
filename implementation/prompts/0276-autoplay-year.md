# 0276 - The autoplayer plays a whole year

- **Phase:** 15 - Fifty-six nights and balance
- **Status:** done
- **Depends on:** 0142, 0194, 0233, 0234, 0275, 0166, 0171, 0180, 0186, 0191, 0221
- **Likely files:** src/tools/autoplay.gd, src/tools/autoplay_run.gd, tools/autoplay.py, src/tools/play_nights.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd

## Goal

0142 taught the robot to sleep; this teaches it the rest of 1.0, so balance can be measured over a whole year: crops by days and season, the fishing minigame, animals and machines, the bin and the peddler, cursor building and repairs, the powers, and carrying on through losses and boss repeats.

## Requirements

- Each policy in `Autoplay.POLICIES` gains a day plan (its earners in order: season crops, fishing, animals, machines, mining, chopping), a night plan (what to place, upgrade and repair by cursor in the build step and during the waves, when each power fires) and a bedtime. `towers`, `walls`, `economy` and `balanced` keep their character; `balanced` is declared the average player 0277 balances against
- Everything goes through the intent road a player uses: tilling and watering through the verbs, fish landed through the minigame's press intents (0180), products collected, goods into the shipping bin, seeds and animals from the peddler in his hours, tool and house tiers bought (0173, 0191), night loot picked up (0221); `build_cell`, `build_place`, `build_upgrade` and `ability_cell` (0135) with 0232's power API at night. Nothing is granted by writing `state`
- Walking is counted from here on (path length at `PLAYER_SPEED`), or the journal measures why not: on an 80x65 farm with an 8-10 minute day (0166), 'walking is free' is no longer close to a player
- `Autoplay.play(seed, policy, days)` follows the calendar, not a night count: calm nights, Full Moons, winter with nothing growing (0171), boss nights repeated until the boss falls - with a cap so a tool run always ends, reported when hit - and losses that move the calendar on. Per night: held or lost, house left, essence and money; per season: losses and boss repeats
- `autoplay_run.gd` prints one machine-readable `RUN` line per run (policy, seed, losses per season, boss repeats, money and essence at each season's start) beside today's lines, so `tools/balance.py` keeps working until 0277 moves its parser onto `RUN` (moved there from here); `python tools/autoplay.py --year [runs]` prints the per-policy table and the dominant-strategy alarm per season
- `play_nights.gd` plays the whole year by default with its scripted floor, following the boss repeat rule
- A year is long: print the wall time per run; if 8 seeds of 4 policies are impractical in one process, split the runs across processes (the data does not change inside a run set) and say how long it took
- `_task_0067_autoplay` and `_task_0068_balance` in `src/tools/headless_check.gd` follow the new policy fields and stay one day and one night; nothing in the suites plays a season. Tools only: neither hash moves

## Done when

- [ ] `_task_0276_year_autoplay` in `src/tools/headless_v1.gd`, its time measured, printed and under 15 s (over it, the slice's day plan shrinks - bed as soon as it is done - and the cap does not move): from a prepared mid-summer state the `balanced` policy plays one day and one night twice on one seed with the same result; that day landed a fish through the minigame, shipped goods through the bin and collected an animal product; that night placed a defence by cursor in the build step and fired a power
- [ ] `python tools/autoplay.py --year 8` completes for all four policies; its table and wall time are in the journal
- [ ] `python tools/balance.py` with a short sweep still finishes on today's lines and leaves the git tree clean (its move onto `RUN` is 0277's)
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
