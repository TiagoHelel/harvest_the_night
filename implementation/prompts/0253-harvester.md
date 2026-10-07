# 0253 - The Harvester

- **Phase:** 14 - Enemies and bosses
- **Status:** todo
- **Depends on:** 0246, 0231
- **Likely files:** src/core/enemies.gd, src/core/game_data.gd, src/ui/enemy_motion.gd, src/ui/world_view.gd, src/ui/night_hud.gd, src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd

## Goal

Summer's boss: a possessed machine that winds up and charges in a straight line, flattening the walls in its row. It tests defence in depth - one thick wall is a speed bump, layers are a defence.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A052
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- `ENEMIES.harvester` with `is_boss` and `# LEVER`s: hp, armour, walking `ticks_per_tile`, damage, reward, `telegraph_ticks`, `charge_every_ticks`, `charge_tiles`, `charge_ticks_per_tile`, `crush_damage`; `check_enemies` refuses a charger missing any of them or with a zero; it passes 0246's 'every boss outlasts every non-boss' asserts
- The charge, in `Enemies` (inside `Enemies.tick`, `PerfNames` unchanged): every `charge_every_ticks` it stops and winds up with the line fixed when the wind-up starts - the row or column towards the house centre along the dominant axis, ties to the row - then moves along it at `charge_ticks_per_tile`, ignoring the flow field. `telegraph_ticks` already times the wind-up before every gnaw and at the house (`_gnaw`, `_swung_at_the_house`): reuse it for the charge or add `charge_windup_ticks`, and say which
- Every structure entered takes `crush_damage` through `Farm.damage`; it carries on through what it destroys and stops at the first that survives, at impassable terrain, at `charge_tiles` or at the house (a bite), then walks and gnaws as usual. Set the numbers so a stone wall falls and the wall's hardwood level (0231's `TOWER_LEVELS` row, read through `Building.entry_at`) holds a charge, and state them
- `Enemies.charge_line(state, id)` returns the telegraphed cells for the view and the tests; the wind-up goes through `is_winding`/`winding_at` so the 0246 bar flashes
- Destroyed walls rebuild the fields at most once a tick (they are rebuilt lazily by `Pathing.refresh`; assert one rebuild after a charge crushes three walls in one tick)
- Summer's day-14 boss: `GameData.SEASON_BOSSES[1]` (0153's table) becomes `&"harvester"`, and any 0153-0160 group or shot scenario that put a Giant on Summer 14 is rewritten in place; its 0246 intro `BOSS_INTRO_HARVESTER`; Names.KEYS `harvester`, `ENEMY_HARVESTER`/`.other` (harvester/harvesters, colheitadeira/colheitadeiras) and `DESC_CHARGES` ('charges in a straight line' / 'investe em linha reta'); `Sfx.ENEMY_SOUNDS.harvester` borrows `sfx/roar_giant` (0246 made `Sfx` boss-generic) until 0284
- On screen: a strip on the telegraphed cells during the wind-up (view only) and the boss through 0120's placeholder road at the Giant's 80x64 pivot (40,60), with its forecast mark, until A052 is integrated by 0266
- Hashes: DATA moves (ENEMIES, SEASON_BOSSES); SIM should not - the determinism night is Spring 1

## Done when

- [ ] `_task_0253_harvester` in `src/tools/headless_v1.gd`: the line is fixed when the wind-up starts and the wind-up lasts exactly the levers' ticks; three stone layers lose what the levers say and a structure with more hp than `crush_damage` stops the charge; it never leaves the map or crosses water
- [ ] The same group: sealed in, it still reaches the house, and killing it moves `bosses_down_of(state, &"harvester")`
- [ ] `python tools/shot.py 0253 harvester` (wind-up with its strip, and the line after the charge) opened and looked at
- [ ] the Deliverables table of `implementation/backlog/packs/A052-harvester.md` states the final geometry this task settled (80x64, or up to 112x80 if justified)
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
