# 0189 - The shipping bin

- **Phase:** 12 - The day that pays
- **Status:** todo
- **Depends on:** 0148, 0138, 0156
- **Likely files:** src/core/shipping.gd (new), src/core/interact.gd, src/core/phases.gd, src/core/state.gd, src/core/farm.gd, src/core/game_data.gd, src/app/save.gd, src/ui/shop_panel.gd, src/ui/result_screen.gd, src/ui/sfx.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/make_goldens.gd, tools/goldens/, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

A shipping bin like Stardew's: drop things in at any hour of the day and be paid the next morning, so selling no longer waits on the stall's hours (plan section 3.6).

## Art

What this task puts on screen will be dressed by Codex art pack(s) A033
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- The bin is an occupant with a `ship` verb in `Interact.OCCUPANT_VERBS` (and `DAY_ONLY`, `all_verbs`, and an `Sfx.VERB_SOUNDS` entry - borrow `sfx/sell` until 0281 - or `_task_0084_day_sounds` fails), on the bin site 0156 kept clear by the porch (`MAP_SITES`)
- Fixture or building - decide and say why. A fixture (`Farm.FIXTURES`, never sold or wrecked) laid by `FARM_MAP` reaches new farms only: old saves need a `State.VERSION` bump with a step that places it on the site when that cell is empty, in the style of 0156's, and a golden at the new version. A cheap day building needs no bump
- What waits is a `shipping` dictionary in the state (resource -> count; keys come from play: `State.RUN_DATA`); putting a stack in takes it out of `held` at once
- The morning report (0138's, shown in RESULT before `begin_day`) prints what the bin will pay, worked out with `Shop.paid_for` (the sell price and the `sell_percent` bonus) from what waits; the money lands at `Phases.begin_day` and the bin empties. The line and the ledger agree, asserted
- A panel to choose what goes in, reusing the stall's sell rows (`shop_panel.gd`); decide whether it stops the clock like the stall (`open_panel`) and say why; keyboard, mouse and pad. `ship` opens a panel, so it joins `Interact.ONE_SHOT` beside `trade` - a repeating verb reopens its panel on the tick after it closes
- Decide what a lost night does to the bin (the horde takes 25% of the stock): what is in the bin is sold, not stock, or it is taken - write it down and assert it
- Names and strings in both languages; the bin draws through the placeholder road until A033 is integrated by 0215
- DATA moves; SIM moves on purpose (the `shipping` key, and the bin if it is on the map) - record both

## Done when

- [ ] `_task_0189_bin` in `src/tools/headless_v1.gd`: ten carrots shipped by day leave `held` at once and are paid the next morning at the sell price with the tech bonus; the report line names the total
- [ ] `_case_0189_bin` in `src/tools/input_v1.gd`: open the bin, put one stack in with the keyboard and one with the mouse, close it
- [ ] A new `shipping_bin` scenario: `python tools/shot.py 0189 shipping_bin --fhd` shows the bin and the morning line; opened and looked at
- [ ] the Deliverables table of `implementation/backlog/packs/A033-shipping-bin.md` states the final geometry this task settled
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
