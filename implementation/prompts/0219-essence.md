# 0219 - Essence

- **Phase:** 13 - Weapons of the night
- **Status:** todo
- **Depends on:** 0196, 0137, 0152
- **Likely files:** src/core/rewards.gd, src/core/tech.gd, src/core/game_data.gd, src/ui/night_hud.gd, src/ui/result_screen.gd, src/ui/tech_panel.gd, assets/locale/strings.csv, implementation/BALANCE.md, src/tools/headless_check.gd, src/tools/headless_v1.gd

## Goal

The night stops paying like a day. It hands over essence - today's technology points under a new name - for holding the farm, and a smaller purse, so money is what the day earns and the night spends (plan section 4.6).

## Art

What this task puts on screen will be dressed by Codex art pack(s) A036
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- Keep the id `tech` (`GameData.TECH`, `Rewards._is_tech`, the saves): only the words change, so no `State.VERSION` bump. `ITEM_TECH` becomes essence / essência and every line that names the currency follows (`DESC_TECH_COST`, `TECH_HELD`'s 'points', any result or HUD line); the tree itself may stay the technology tree (`TECH_TITLE`)
- Earn rules as LEVERs in `GameData.REWARDS` and `TECH_BONUSES`: a night won pays `tech_points`; the three bonuses stay (house untouched measured against `Phases.house_full`, as 0114 left it); a Full Moon night (`Calendar.is_full_moon`, 0152) multiplies the night's essence by a percent LEVER (100-300), its own line in `Tech.would_pay`; `GameData.validate()` refuses a percent under 100. `nights_paid` still stops a night paying twice
- The night's money shrinks: `base_money`, `money_per_night` and the material handout (`resources`, `resources_per_night`), read through 0150's `Rewards.night_step`, come down to numbers argued against 0194's money-per-day targets in `implementation/BALANCE.md`; the journal says what a spring night paid before and after
- The bounty is paid for kills only. `Rewards._money_from` already reads `killed_by_kind`; assert that survivors who walk off at dawn (0137, `Enemies.withdraw`) pay nothing and are not counted as killed
- Essence on screen: the night HUD shows what is held (plan section 9) and the morning report of 0138 has a '+N essence' line itemised from the lines `Tech.would_pay` gave inside `Rewards.settle`, kept in `payout` for the screen - after `Tech.award` the night is paid and `would_pay` answers empty. The icon is the existing tech icon through the placeholder road until A036 is integrated by 0235
- Asserts that pin night money or technology (`_task_0061`, `_task_0062`, `_task_0068` and whatever 0150 left of them) are rewritten in place in `src/tools/headless_check.gd` to read the LEVERs rather than literals; `tools/i18n_check.py` is clean in both languages
- SIM and DATA both move on purpose (the payout and the REWARDS table): record the old and the new numbers in `implementation/PROGRESS.md`

## Done when

- [ ] `_task_0219_essence` in `src/tools/headless_v1.gd` asserts a won night pays `tech_points` plus each bonus earned, a Full Moon night pays the multiplied amount, a replayed night pays no essence, and a dawn win with survivors pays bounty for the kills only
- [ ] `python tools/shot.py 0219` captures of the night HUD and the morning report say essence, opened and looked at
- [ ] The BALANCE.md section sets a spring night's money and essence beside a spring day's money
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
