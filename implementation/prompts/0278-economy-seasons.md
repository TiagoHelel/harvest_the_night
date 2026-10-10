# 0278 - The economy across a year

- **Phase:** 15 - Fifty-six nights and balance
- **Status:** todo
- **Depends on:** 0277
- **Likely files:** src/core/game_data.gd, src/core/shop.gd, src/tools/autoplay.gd, src/tools/autoplay_run.gd, tools/autoplay.py, implementation/BALANCE.md, src/tools/headless_v1.gd

## Goal

The plan's rule of thumb, checked in every season and not only the first: a good day buys about one new defence, a boss costs five to seven focused days, and winter - when nothing grows - lives off what autumn put away.

## Requirements

- Measure first, with the year autoplayer: per season, what a focused day earns by earner (crops, fish, animals, machines, mining), the price of each of that season's new defences (0234's money and materials, at stall prices), and what was standing on the night each boss fell - `python tools/autoplay.py --economy` or an equivalent report
- A real day is the field and then a second earner (0196): the tour's field took two to two and a half game hours, and the rest of the day went to the pond and the cliff. Measure each season against that mixed day - the field, then the best earner for the hours left - beside the focused ones, and say in BALANCE.md which of the two the rule of thumb is held to
- The hens' clock (0196): a hen holds one egg and its clock waits until it is collected, 4h10m a lay, so the tour's second round, four hours after its first, found nothing. Report eggs a day at one, two and three visits, and keep `holds` at 1 only if the journal says why that is the pressure the plan wants and not a chore
- Rule of thumb: one well-worked day at the start of each season buys about one of that season's new defences - the ratio per season in BALANCE.md, each within 0.7-1.5 or the journal says why
- A boss costs 5-7 focused days: the value of the build that beat it, less what stood at the season's start, divided by that season's focused-day income
- Winter: nothing grows (0171), so the `balanced` policy enters day 43 with autumn's stock, and its winter income (fish, mining, machines, animals) plus that stock pays for winter's defences and repairs to day 56 without running out of food or ammunition - reported per run
- Costs before prices: prefer moving defence costs, machine times and yields, starting from 0234's day-to-defence table in BALANCE.md; if prices must differ by season, one `# LEVER` table (a percent per resource group per season) read through `Shop.sell_price` (it takes only an id today: it gains the season, and every caller follows) and so by the bin, listed in `digest()`
- `GameData.check_stall` and `check_chain` already take the prices as an argument: `validate()` runs them at every season's prices, so markups stay above prices and every recipe still adds value in every season
- DATA moves on purpose, SIM too if the determinism scenario's shop visit reads a moved price - both in PROGRESS.md; re-check 0277's target after the changes

## Done when

- [ ] BALANCE.md 'The economy across a year': per season the focused-day income by earner, the day-to-defence ratio, the days each boss cost, and winter's stock from day 43 to day 56, all measured
- [ ] `_task_0278_season_economy` in `src/tools/headless_v1.gd`: the stall and chain checks pass at every season's prices, and a doctored price that breaks the chain in one season only is refused
- [ ] 0277's target still holds: the `--year 8` table after the changes is in the journal
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
