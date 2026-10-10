# 0186 - Barns at night

- **Phase:** 12 - The day that pays
- **Status:** done
- **Depends on:** 0183, 0137
- **Likely files:** src/core/farm.gd, src/core/livestock.gd, src/core/repair.gd, src/core/pathing.gd, src/core/run.gd, src/core/crafting.gd, src/core/interact.gd, src/core/game_data.gd, src/ui/world_view.gd, src/ui/placeholder_art.gd, src/tools/shot.gd, src/tools/headless_v1.gd

## Goal

At night the animals sleep inside and the barn becomes something to defend: breakers go for it, and a wrecked barn stands useless until it is mended. No animal ever dies.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A030
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- Animals sleep in their building at night (the view hides them; livestock already ticks only by day)
- Breakers hunt coops and barns: `Pathing.is_prey` counts a `BUILDINGS` entry with no `path_cost` already - assert it
- A wrecked-but-standing state: an entry that declares it (e.g. `wrecks: true` on coop and barn) is not removed by `Farm.damage` at 0 HP; it stays an occupant marked wrecked, still impassable, no longer prey (`Pathing.prey_cells` already skips 0 HP), with no rubble; decide whether `Run.lost_a_structure` counts it and assert that. The hunt field is cached on `grid_version` and only `Farm.remove` bumps it today: wrecking (and mending back above 0) must `Farm.touch`, or breakers stand at a 0-HP barn all night - the bug `prey_cells`' own comment records
- A wrecked building produces nothing and offers only `repair` (by day, by the farmer, as 0134 left it); any HP above 0 brings it back; its animals stay inside, alive, throughout
- `Crafting.forget_cell` and `Livestock`'s cache must not forget a wrecked building's residents or queue
- Hurt and wrecked looks are tints of the stand-in through the placeholder road until A030 is integrated by 0212
- DATA moves (the new flag); SIM moves only if the scenario has a barn at night - say so

## Done when

- [ ] `_task_0186_barns_night` in `src/tools/headless_v1.gd` (a short night with breakers set down beside the barn, mornings by `Phases.begin_day`): breakers reach a barn and wreck it, then leave it for other prey; it stands, produces nothing the next day, keeps every animal, and works again after a day repair
- [ ] A new `barn_night` scenario: `python tools/shot.py 0186 barn_night --fhd` shows a hurt and a wrecked barn at night and the next morning; opened and looked at
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
