# 0173 - Five tools, three tiers

- **Phase:** 12 - The day that pays
- **Status:** todo
- **Depends on:** 0148, 0126
- **Likely files:** src/core/tool_tiers.gd (new), src/core/state.gd, src/core/game_data.gd, src/core/crafting.gd, src/core/phases.gd, src/ui/workshop_panel.gd, src/ui/player_work.gd, src/ui/names.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

Hoe, watering can, axe, pickaxe and rod, each in three tiers bought at the workshop with money and ore: the first thing day money buys that makes every later day better (plan section 3.7).

## Art

What this task puts on screen will be dressed by Codex art pack(s) A019
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- `TOOLS` in `game_data.gd`: hoe, can, axe and pickaxe at basic/iron/gold, the rod at bamboo/fibre/iron, as tiers 0/1/2 of one ladder; each tier's cost (money + ore) and the effect fields 0174, 0175 and 0181 read, all `# LEVER`
- The tiers held and any pending upgrade live in a `tools` dictionary (keys from code: `State.TABLES`, through a new `initial()` - e.g. `src/core/tool_tiers.gd` - and one `_adopt` line), all tier 0 in a new game. **Tools are not resources**: `Rewards._loss` iterates `RESOURCES` and must never take one
- An upgrade is a workshop recipe whose output names a tool tier: a new branch in `Crafting._deliver` (and in `check_recipes`, which accepts only resources and defences today) records it as pending, and `Phases.begin_day` hands it over - ready the next morning. The tool keeps its old tier until then, so no day is spent without a can
- This task ships tier 1 for all five (iron hoe, can, axe and pickaxe; fibre rod) and the rod's tier 2 (iron). The gold costs arrive with 0176; until then gold is listed and refused with a reason
- Rebalance the tech nodes that did a tool's job: 'sharp tools' (`gather_percent`) and 'full cans' (`water_can_bonus`) keep their ids, get smaller numbers or a new role, and their `note` and `TECHNOTE_*` rows change in both languages; arithmetic in the journal. `_task_0063_tech_tree` asserts 'sharp tools' makes chopping quicker: keep that true or rewrite it in place
- The tool in the farmer's hand is not tiered by art (decision): the work frames keep one fixed head ramp and `player_work.gd` tints it per tier, view only. Tool icons in the workshop panel and the inventory use the placeholder road until A019 is integrated by 0202
- Names and strings for every tool and tier, and a `Names.KEYS` entry with a `REC_*` row for every upgrade recipe (every `RECIPES` id needs one), in both languages; `validate()` checks every tier cost names a real resource; `TOOLS` goes into `digest()`
- DATA moves (TOOLS, TECH_TREE). SIM moves on purpose: the new `tools` key is in the state and `State.hash_of` folds every key - record both

## Done when

- [ ] `_task_0173_tools` in `src/tools/headless_v1.gd`: an iron axe queued with the money and iron is still basic that evening and iron the next morning; a lost night takes 25% of the iron and no tool
- [ ] `_case_0173_upgrade` in `src/tools/input_v1.gd`: open the workshop and order an upgrade with the keyboard and with the mouse; it shows as pending
- [ ] A new `tool_upgrades` scenario: `python tools/shot.py 0173 tool_upgrades --fhd` shows the upgrade list and the farmer chopping with a tinted iron head; opened and looked at
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
