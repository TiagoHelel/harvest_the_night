# 0170 - Crops keep to their seasons

- **Phase:** 12 - The day that pays
- **Status:** todo
- **Depends on:** 0168, 0149, 0169
- **Likely files:** src/core/game_data.gd, src/core/farming.gd, src/core/shop.gd, src/ui/day_hud.gd, src/ui/shop_panel.gd, src/ui/describe.gd, src/ui/title_screen.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/autoplay.gd, src/tools/determinism.gd, src/tools/make_goldens.gd, src/tools/perf_check.gd, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

Each crop keeps to its season, so spring, summer and autumn fields look and pay differently, and seeds become packets bought at the stall (plan sections 3.1 and 3.6). Which packets the stall puts out in which season is 0190's, with the peddler.

## Requirements

- `CROPS` gains `seasons` (`# LEVER`): carrot, potato, garlic, strawberry in spring; corn, pepper, sunflower, melon in summer; wheat, pumpkin, grape, beet in autumn. No crop lists winter. The season is `GameData.SEASONS[Calendar.season_of(Calendar.date(state))]` (0149; `season_of` returns 0-3). `check_crops` refuses a crop with no season, an unknown one or winter, and may narrow 'no crop dominates' to crops sharing a season (0168 left it open) - say which. What a change of season does to a planted field, winter included, is 0171's
- Seeds become items, as the plan's stall and the seed packets of A015-A017 expect: a `<crop>_seed` resource per crop with a price, the seeds group, a `Names.KEYS` entry and an `ITEM_<CROP>_SEED` row in both languages (0169's check wants all four). `Farming._plant` spends one packet of the selected crop instead of `seed_cost` in money (its own comment names it as the one function this changes); `selected_seed` still holds a crop id; `STARTING_RESOURCES` gives a few spring packets so day 1 still plants. An old save holds no packets and buys them: no `State.VERSION` bump - say so
- The price: `Shop.buy_price` is `ceil(SELL_PRICE * BUY_MARKUP)`, so a packet costs either `seed_cost` through a branch there or a packet `SELL_PRICE` the markup turns into about the seed cost - decide. `check_crops` balances on what a packet really costs, and `check_stall`'s buy-and-sell-back loss still holds
- The stall sells every packet all year for now: they join today's flat `DAILY_STOCK`, so `Shop.buyable()` lists them and the buy rows show them with no new UI; the `SHOP_SEEDS` rows of `shop_panel.gd` stop meaning 'pay at the furrow' (fold them into the buy rows or keep them as the seed picker - say which). **Moved to 0190:** the seasonal stock (this season's packets only, none in winter), because 0190 reworks `Shop.buyable`/`restock` for the peddler anyway
- Only in-season crops can be chosen: a `Farming.in_season(state)` list feeds the seed strip (with the packets held), `select_seed_at` and the six `SEED_ACTIONS`; `select_seed` refuses an off-season crop. `Farming.initial()` retains carrot as the cheap starting crop since 0168; a new game must still select a spring crop, and a selection that falls out of season moves to the first in-season crop (none in winter). Packet icons draw through the placeholder road (the crop's icon, tinted) until A015/A016/A017 are integrated by 0198/0199/0200
- Move what plants (grep `Farming.act`, `select_seed`, `Farming.seeds()` and `seed_cost` in the suites and tools): wheat and corn sown on day 1 - Spring 1 - are now refused (`_task_0018_wheat`, `_task_0028_crops`, `_task_0029_watering`, `_case_0028_seeds`); fields sown round-robin over every crop run out of season and of packets (`_a_busy_day`, `_a_full_farm`, `_task_0109_reactions`, `_task_0111_house`, `determinism.gd`, `make_goldens.gd`, `perf_check.gd`, `shot.gd`, `title_screen.gd`'s backdrop); the autoplayer plants corn and must buy packets. Give the suites one shared helper (in the helper script 0112 made) that sets a date in a crop's season and hands over packets, and route them through it; `_case_0040_shop`'s seed rows follow the stall's change
- Correct `TUT_PLANT`, `DESC_SEED_COST` (`describe.gd`) and any line that says seeds are paid at the furrow, in both languages
- SIM and DATA move on purpose (twelve packet resources in `held`/`gained`, the starting packets, the planting rule); record both

## Done when

- [ ] `_task_0170_seasons` in `src/tools/headless_v1.gd`: planting spends one packet and no money, and with no packet plants nothing; an off-season crop can be neither selected nor planted, and a summer date offers only summer crops; a new game selects a spring crop; the stall sells a carrot packet at the price the journal states
- [ ] `_case_0170_seeds` in `src/tools/input_v1.gd`: buy potato packets at the stall, pick them on a slot key, plant one
- [ ] New `spring_field` and `summer_field` scenarios: `python tools/shot.py 0170 spring_field summer_field --fhd`; opened and looked at
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
