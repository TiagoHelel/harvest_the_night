# 0193 - Every season can make what it needs

- **Phase:** 12 - The day that pays
- **Status:** todo
- **Depends on:** 0170, 0176, 0188, 0190, 0192
- **Likely files:** src/core/game_data.gd, src/core/shop.gd, src/ui/names.gd, assets/locale/strings.csv, src/tools/headless_v1.gd

## Goal

No defence, round, repair meal or feed may depend on a crop whose season has not come yet: every season can make what it needs.

## Requirements

- `check_seasonal_supply()` in `GameData.validate()`: for each season S, everything unlocked in S - defence kits, ammunition, repair food, animal feed - is makeable from the crops of seasons up to S plus fish, ore, wood, stone and what the stall sells in S; it walks the recipe graph, and a test shows it a broken table
- What 'unlocked in S' means: a `season` field on `DEFENCES` entries, default spring. Plan section 5 puts the flamethrower in summer and the mortar in autumn, but moving them is 0234's (with the new defences), so today's eight stay spring here
- Fix the known breaks: gunpowder in spring (a recipe from coal and oil pressed from fish by `press_fish_oil`, since corn is summer), a meal in spring (0192's, checked here), straw and hay sold by the peddler before autumn
- Pepper and sunflower get their plan roles: pepper makes incendiary rounds at a better yield than wood (a recipe, not a new ammunition rule), and sunflower is pressed into oil
- Every new recipe passes `check_chain` and `check_ammo` and has a `Names.KEYS` entry and a `REC_*` row in both languages
- DATA moves; SIM moves if the stall's stock or a station's default recipe (both in the state) changes - say which

## Done when

- [ ] `_task_0193_supply` in `src/tools/headless_v1.gd`: the real tables pass for all four seasons; taking out the coal gunpowder recipe makes spring fail by name
- [ ] The journal lists, season by season, the route to each kit, round, meal and feed
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
