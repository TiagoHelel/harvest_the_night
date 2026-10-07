# 0176 - Copper, coal and gold

- **Phase:** 12 - The day that pays
- **Status:** todo
- **Depends on:** 0175, 0156
- **Likely files:** src/core/game_data.gd, src/core/gathering.gd, src/core/interact.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd

## Goal

The quarry gets copper and coal - for sprinklers, tools and the generator - and gold from autumn for the top tier (plan section 3.3).

## Art

What this task puts on screen will be dressed by Codex art pack(s) A020, A021
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- The copper, coal and gold nodes 0156 put on `FARM_MAP` under their final ids (e.g. `copper_ore`, `coal_seam`, `gold_ore`; its journal names them and the legend characters) become `GATHERING` entries with swings, yield and `regrow_ticks` (`# LEVER`), dearer than stone on the dials the way `check_iron` holds iron, and `Interact.OCCUPANT_VERBS` entries (`mine`, so `Sfx.VERB_SOUNDS` already covers them); gold has `min_tier` 1 (an iron pickaxe, 0175)
- Gold from autumn: a gold node offers no verb before the first autumn, through 0149's calendar helpers; say whether it stays open in winter
- `COPPER`, `COAL` and `GOLD` in `RESOURCES`, `SELL_PRICE`, the materials group, `Names.KEYS` and `ITEM_*` rows in both languages (0169's check wants all four)
- Coal is fuel (plan section 3.3): the generator may burn it instead of oil - decide and say so; 0193 uses coal for spring gunpowder
- The gold tier's costs for the hoe, can, axe and pickaxe (money + gold, `# LEVER`), so 0173's refused tier opens
- Nodes draw through the placeholder road (tinted `ore`/`ore_b`, 16x16, pivot (8,14)) and icons as tinted stand-ins until A021 (0204) and A020 (0203) are integrated
- DATA moves. SIM moves on purpose: three new resources are new keys in `held`/`gained`, which the state hash folds - record both

## Done when

- [ ] `_task_0176_ores` in `src/tools/headless_v1.gd`: each new node yields its resource and regrows; gold refuses before autumn and with a basic pickaxe and yields after; a gold hoe can be ordered and arrives the next morning
- [ ] A new `quarry` scenario: `python tools/shot.py 0176 quarry --fhd` shows the quarry with the new nodes by day and by night; opened and looked at
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
