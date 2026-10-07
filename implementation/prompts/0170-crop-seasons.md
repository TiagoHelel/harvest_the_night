# 0170 - Crops keep to their seasons

- **Phase:** 12 - The day that pays
- **Status:** todo
- **Depends on:** 0168, 0149
- **Likely files:** src/core/game_data.gd, src/core/farming.gd, src/core/shop.gd, src/ui/day_hud.gd, src/ui/shop_panel.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/autoplay.gd, src/tools/determinism.gd, src/tools/make_goldens.gd, src/tools/perf_check.gd, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

Each crop keeps to its season, so spring, summer and autumn fields look and pay differently, and seeds are bought at the stall when their season comes round (plan sections 3.1 and 3.6).

## Requirements

- `CROPS` gains `seasons` (`# LEVER`): carrot, potato, garlic, strawberry in spring; corn, pepper, sunflower, melon in summer; wheat, pumpkin, grape, beet in autumn. No crop lists winter. The season is `Calendar.season_of(Calendar.date(state))` (0149). What a change of season does to a planted field, winter included, is 0171's
- Seeds become items, as the plan's stall and the seed packets of A015-A017 expect: a `<crop>_seed` resource per crop with a price, the seeds group, a `Names.KEYS` entry and an `ITEM_<CROP>_SEED` row in both languages (0169's check wants all four). `Farming._plant` spends one packet of the selected crop instead of `seed_cost` in money (its own comment names it as the one function this changes); `selected_seed` still holds a crop id; `STARTING_RESOURCES` gives a few spring packets so day 1 still plants
- `seed_cost` stays the number `check_crops` balances on and is what a packet costs at the stall; the packet's sell-back stays below it so `check_stall`'s no-profit loop holds
- The stall stocks this season's seeds only (a seasonal stock table read by `Shop.restock`/`buyable`, in `digest()`); `check_stall` covers every season
- The seed strip lists this season's crops with the packets held, inside the six `SEED_ACTIONS`; an off-season crop cannot be selected. Packet icons draw through the placeholder road (the crop's icon, tinted) until A015/A016/A017 are integrated by 0198/0199/0200
- Move what plants with money: `_task_0018_wheat`, `_task_0028_crops`, `_case_0028_seeds`, the autoplayer (it buys packets), `determinism.gd`, `make_goldens.gd`, `perf_check.gd` and `shot.gd` (they sow on a fresh farm). Correct `TUT_PLANT`/`TUT_SELL` and any line that says seeds are paid at the furrow, in both languages
- SIM and DATA move on purpose (twelve packet resources in `held`/`gained`, the stall's seasonal stock in the state, the planting rule); record both

## Done when

- [ ] `_task_0170_seasons` in `src/tools/headless_v1.gd`: a spring stall stocks only spring seeds and a summer one only summer's; planting spends one packet and no money; an off-season crop cannot be selected
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
