# 0255 - The Winter Lord

- **Phase:** 14 - Enemies and bosses
- **Status:** done
- **Depends on:** 0246, 0251, 0160, 0253, 0254
- **Likely files:** src/core/enemies.gd, src/core/towers.gd, src/core/game_data.gd, src/ui/world_view.gd, src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd

## Goal

The last night of the year: a lord of ice whose cast freezes every tower around it. It tests the whole build - spread, depth, light and the powers - and its fall is the ending.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A054
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- `ENEMIES.winter_lord` with `is_boss` and `# LEVER`s: hp, armour, `ticks_per_tile`, damage, reward, `telegraph_ticks` (the cast), `freeze_every_ticks`, `aura_tiles`, `freeze_ticks` (`check_enemies` refuses a zero); the strongest boss in the table (more hp than the Harvester and the King - asserted)
- The freeze sits beside 0251's chill on the occupant, never through `Farm.touch`: towers within `aura_tiles` when the cast lands stop counting their reload for `freeze_ticks` (a `frozen` countdown in `Towers.tick`/`_cool_down`); refreshed, never stacked, cleared in `Enemies.withdraw` at dawn
- The cast is telegraphed (`is_winding` for `telegraph_ticks`, so the 0246 bar flashes) and the aura's cells are a core query for the view
- Winter's day-14 boss: `GameData.SEASON_BOSSES[3]` becomes `&"winter_lord"`, and 0160's ending fires on it falling: rewrite `_task_0160_year_end` and `_case_0160_ending` to kill a Winter Lord on Winter 14 and see the ending; a Giant on that night no longer ends the year
- `BOSS_INTRO_WINTER_LORD`; Names.KEYS `winter_lord`, `ENEMY_WINTER_LORD`/`.other` (winter lord/winter lords, senhor do inverno/senhores do inverno) and `DESC_FREEZES` ('freezes the towers around it' / 'congela as torres em volta'); `Sfx.ENEMY_SOUNDS.winter_lord` borrows `sfx/roar_giant` until 0284
- On screen through 0120's placeholder road: a cast pose, the aura's reach on the ground during the wind-up, ice on frozen towers (view only) and its forecast mark, until A054 is integrated by 0268
- Hashes: DATA moves; SIM should not

## Done when

- [ ] `_task_0255_winter_lord` in `src/tools/headless_v1.gd`: a cast freezes exactly the towers inside `aura_tiles` for `freeze_ticks`, `grid_version` does not move, and every tower fires again afterwards
- [ ] Killing it on Winter 14 brings up the year's ending through 0160's path and `bosses_down_of(state, &"winter_lord")` is one
- [ ] `python tools/shot.py 0255 winter_lord` (the aura during a cast) opened and looked at
- [ ] the Deliverables table of `implementation/backlog/packs/A054-winter-lord.md` states the final geometry this task settled
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
