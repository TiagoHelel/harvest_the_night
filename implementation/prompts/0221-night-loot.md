# 0221 - What the night leaves behind

- **Phase:** 13 - Weapons of the night
- **Status:** done
- **Depends on:** 0219, 0152
- **Likely files:** src/core/combat.gd, src/core/loot.gd (new), src/core/phases.gd, src/core/player.gd, src/core/state.gd, src/core/game_data.gd, src/core/tech.gd, src/ui/names.gd, src/ui/world_view.gd, src/ui/result_screen.gd, assets/locale/strings.csv, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

The night leaves something for the morning: bones where zombies fell and, after a Full Moon, moon stones along the road the horde came by - picked up on the morning round and worth money, essence or fertiliser (plan sections 3.3 and 4.6).

## Art

What this task puts on screen will be dressed by Codex art pack(s) A036
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- Loot is a RUN_DATA dictionary (cell index -> {item: count}) listed in `State.RUN_DATA` and adopted through an `initial()` (a small `src/core/loot.gd`). It is not an occupant - nothing walks round it or builds on it - and it survives `Farm.clear_rubble` at `begin_day`. Never name a key `moon_phase`
- Bones drop in `Combat._kill` on the cell the enemy died on: a per-kind count in `ENEMIES` (`bones`, LEVER 0-6, the Giant more; a row without `bones` drops none, so the enemies of phase 14 opt in), piled per cell up to a cap LEVER, no RNG. Survivors that walk off at dawn drop nothing. A pile on a cell the farmer cannot stand on (a wall, water) goes to the nearest walkable cell by a fixed rule - decide and assert
- Moon stones: the morning after a Full Moon night (0152), a LEVER number (2-8) lies on cells of the horde's route - e.g. every Kth cell of the flow field from tonight's spawn regions toward the house - chosen deterministically or from a fresh `(seed, day)` stream like `Endless._stream_for`, never the run stream
- Picked up by day only, when the farmer steps onto the cell in `Player.tick` (no verb, no tool); the pile goes into the ledger and the cell is cleared. Uncollected loot stays, or fades after a LEVER of days - decide and say so
- `bones` and `moon_stone` are resources: `RESOURCES`, `SELL_PRICE`, a leftovers group in `RESOURCE_GROUPS`, `Names.KEYS` (`ITEM_BONES`, `ITEM_MOON_STONE`) and both languages. Moon stones sell at the stall or trade for essence by day at a LEVER rate through one core function (e.g. `Tech.trade_moon_stones`), offered where an input path already exists - a button in the tech panel, or a station recipe through the workshop panel if `check_chain` can value essence (a recipe needs its `REC_*` key). Every new constant goes into `GameData.digest()` (0112's coverage assert) and `validate()` refuses a cap, a stone count or a rate of zero
- The morning report's leftovers line (0138) says what is lying on the farm: N bones, M moon stones to collect
- Drawn through the placeholder road until A036 is integrated by 0235: a code-drawn bone pile and a moon stone with a 2-frame shimmer (the glow is code, view only)
- SIM moves on purpose (drops in `_kill`, a new state key) and DATA moves (new resources and prices): record both

## Done when

- [ ] `_task_0221_night_loot` in `src/tools/headless_v1.gd` asserts a killed walker leaves its bones on its cell, the pile survives `begin_day`, stepping on it by day collects it and at night does not, a Full Moon morning lays its stones on the same cells for the same seed, and a traded stone pays the essence LEVER
- [ ] `_case_0221_collect` in `src/tools/input_v1.gd` walks the farmer over a bone pile and sees the count rise, then trades a moon stone for essence through the panel that offers it
- [ ] `python tools/shot.py 0221` morning captures show the piles on the road, opened and looked at
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
