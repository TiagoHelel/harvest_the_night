# 0190 - The peddler and his hours

- **Phase:** 12 - The day that pays
- **Status:** done
- **Depends on:** 0126, 0170, 0183, 0185, 0173
- **Likely files:** src/core/shop.gd, src/core/interact.gd, src/core/game_data.gd, src/core/livestock.gd, src/ui/shop_panel.gd, src/ui/world_view.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/autoplay.gd, src/tools/determinism.gd, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

The stall gets a peddler who keeps hours, 08:00 to 17:00, whose seed packets change with the season (plan section 3.6), and who sells what the farm cannot make for itself: animals and tool upgrades.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A034
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- `trade` is offered only from `STALL_OPENS` to `STALL_CLOSES` (`# LEVER`s in game minutes, 08:00 and 17:00, read through 0126's `Phases.clock_minute`; in `digest()`; `validate()` keeps them in order inside 0126's day); outside them the stall shows a closed state and the verb is refused with a reason in both languages. Gate the verb, not `Shop.buy`/`sell`: an open panel stops the clock, so the stall never closes under the player
- **Moved here from 0170:** the stock becomes seasonal. A per-season stock table (`# LEVER`, in `digest()`) puts out this season's packets only (0170 left all twelve in the flat `DAILY_STOCK`; none in winter) beside the materials; `Shop._fresh_stock`/`restock` read the date's season and `Shop.buyable()` takes the state (move its callers: `shop_panel.gd`, the autoplayer, the suites). `check_stall` covers every season. 0193 adds straw and hay before autumn
- Animals and upgrades: chickens, cows, sheep and pigs, delivered into a coop or barn with room (refused, money kept, without one), and 0173's tool upgrades at the same money + ore price through the same order path, so the rule exists once. Neither is a resource: `Shop.buy`, the stall's stock and `check_stall` (resources only today) get a branch, and `check_stall` gives each animal a price with no buy-and-sell-back profit. The four animals get `Names.KEYS` entries and `ANIMAL_*` rows in both languages (the stall lists them by name)
- Move what trades through the verb before 08:00 to opening hours: `_task_0020_shop`, `_task_0040_shop`, `_case_0020_shop`, `_case_0040_shop`, the autoplayer - grep the suites and `shot.gd` for `trade` and `Shop.open`. The determinism scenario calls `Shop.open` at `day_tick` 1500, before 08:00 on 0166's clock: leave `Shop.open` ungated or accept the SIM move, and say which
- The peddler stands at the stall in open hours, walking in and out at the edges (view only), through the placeholder road; the closed stall is a dimmed stand-in until A034 is integrated by 0216
- DATA moves; SIM moves on purpose (the stall's stock in the state turns seasonal and gains animals and upgrades) - record both

## Done when

- [ ] `_task_0190_peddler` in `src/tools/headless_v1.gd` (hours by a rigged `day_tick`): trade is refused at 07:59 and at 17:00 and offered at 08:00; a spring stall stocks only spring packets, a summer one only summer's and a winter one none; a cow bought with a barn arrives in it, and without one is refused with the money kept
- [ ] `_case_0190_peddler` in `src/tools/input_v1.gd`: buy a chicken in hours; the closed stall refuses
- [ ] A new `peddler` scenario: `python tools/shot.py 0190 peddler --fhd` shows the stall open with the peddler and closed at dusk; opened and looked at
- [ ] the Deliverables table of `implementation/backlog/packs/A034-peddler.md` states the final geometry and states this task settled
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
