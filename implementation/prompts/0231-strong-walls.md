# 0231 - Hardwood walls and sandbags

- **Phase:** 13 - Weapons of the night
- **Status:** todo
- **Depends on:** 0196, 0177, 0188, 0132, 0226
- **Likely files:** src/core/game_data.gd, src/core/building.gd, src/core/pathing.gd, src/core/repair.gd, src/ui/world_view.gd, src/ui/names.gd, src/ui/describe.gd, assets/locale/strings.csv, src/tools/headless_v1.gd

## Goal

Two more ways to hold a line: the stone wall upgraded with hardwood into something a breaker has to work at, and sandbags from the loom as a cheap barrier that soaks more than a fence (plan sections 3.3 and 3.5).

## Art

What this task puts on screen will be dressed by Codex art pack(s) A043
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- A `TOWER_LEVELS` row for `wall`: level 2 paid in hardwood (0177), more `hp` and `path_cost`, upgraded by cursor like a tower (0226's fix refuses a third level). `Building.entry_at` already lays a level over any id, but the field does not read it: `Pathing._through` prices an occupant from `Building.entry_of` (the base row), so `_entry_costs` must price a levelled occupant from its levelled entry, and `check_pathing` must read `TOWER_LEVELS`' `path_cost` too, so the level stays within `WIDEST_STEP`
- Sandbags: 0188 planned `SANDBAG` as a material (read what it actually made). A material means the barrier gets its own id (e.g. `sandbag_wall`) paid in sandbags, because `Names.KEYS` is keyed by id; if 0188 made a kit instead, it becomes the `DEFENCES` row that kit places. Its `hp` and `path_cost` LEVERs sit between the fence and the wall, and its `season` (0193's field) is decided here and confirmed by 0234. Neither has `damage`, so no `Sfx.TOWER_SOUNDS` entry
- A level-2 wall mends to its levelled HP (0113) and costs what that level is made of - assert it
- Joins: `WorldView.barrier_mask` decides who meets whom - a hardwood wall joins stone walls, sandbags join sandbags (decide whether they meet walls) - and `_barrier_name` learns the wall's level
- `Names.KEYS` and strings in both languages for the new id and the upgrade; drawn through the placeholder road (level-2 wall modules for the 16 masks, whole/hurt/wreck; the sandbag pieces) until A043 is integrated by 0242
- DATA moves (a level row, a new barrier). SIM must not move for the determinism scenario's level-1 walls; if pricing levelled occupants moves it, say why - record both numbers

## Done when

- [ ] `_task_0231_strong_walls` in `src/tools/headless_v1.gd` asserts a level-2 wall takes the LEVER's longer to chew through and costs the field its levelled `path_cost`, a third upgrade is refused, sandbags sit between fence and wall on hit points and path cost, and repair restores the level-2 maximum
- [ ] The Deliverables table of `implementation/backlog/packs/A043-strong-walls.md` states the final geometry this task settled (and whether sandbags are modules or one piece)
- [ ] `python tools/shot.py 0231` captures of a mixed line - stone, hardwood, sandbags - opened and looked at
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
