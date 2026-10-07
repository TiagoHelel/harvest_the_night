# 0168 - Nine new crops

- **Phase:** 12 - The day that pays
- **Status:** todo
- **Depends on:** 0165
- **Likely files:** src/core/game_data.gd, src/ui/names.gd, assets/locale/strings.csv, src/ui/day_hud.gd, src/ui/placeholder_art.gd, src/tools/shot.gd, src/tools/headless_v1.gd

## Goal

The plan's twelve crops exist as data: potato, garlic, strawberry, pepper, sunflower, melon, pumpkin, grape and beet join carrot, corn and wheat, each with the role section 3.1 gives it.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A015, A016, A017
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- Data only: nine `CROPS` entries with `growth_days`, `seed_cost`, `yield` and `stages` from the plan's table (potato 5, garlic 4, strawberry 8, pepper 5, sunflower 7, melon 10, pumpkin 10, grape 8, beet 6 days), plus `RESOURCES`, `SELL_PRICE` and the existing `crops` group of `RESOURCE_GROUPS`, every number a `# LEVER`
- Seasons are 0170's and regrowth 0172's: add neither field here
- Ids are the plain crop names; the defences that share a crop word keep their own ids (`garlic_braid`, `catapult`, `decoy`)
- `Names.KEYS` and `ITEM_POTATO`..`ITEM_BEET` rows in `assets/locale/strings.csv` (key,width,en,pt_BR: batata, alho, morango, pimenta, girassol, melancia, abóbora, uva, beterraba); `tools/i18n_check.py` clean
- `check_crops` keeps 'no crop dominates on money, visits and seed cost at once' across all twelve: seed costs that rise with value per day are enough. Put the table in the journal; 0170 may narrow the comparison to one season
- Twelve rows overflow the `DayHud` seed strip and its six `SEED_ACTIONS`. Until 0170 filters it by season, keep it legible (page it, or six rows around the selection - view only) and capture it
- Every new crop draws through the placeholder road: a tinted stand-in of an existing crop's four stages at the final canvas (the art contract's 16x16, pivot (8,14); sunflower and the grape trellis very tall at 16x32, pivot (8,30)) until A015/A016/A017 are integrated by 0198/0199/0200
- DATA moves (the tables). SIM moves on purpose: nine new keys in `held`/`gained`, which `State.hash_of` folds, and the determinism scenario sows `Farming.seeds()` in sorted order, so its field changes. Record both

## Done when

- [ ] `_task_0168_crops` in `src/tools/headless_v1.gd`: all twelve validate, each has a price, a group and a name in both languages, and each reaches its ready stage in its plan days of watered mornings
- [ ] A new `twelve_crops` scenario: `python tools/shot.py 0168 twelve_crops --fhd` shows every crop at its four stages; opened and looked at
- [ ] the Deliverables tables of `implementation/backlog/packs/A015-spring-crops.md`, `A016-summer-crops.md` and `A017-autumn-crops.md` state the final geometry this task settled (canvas, pivot, stages, which crops are tall)
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
