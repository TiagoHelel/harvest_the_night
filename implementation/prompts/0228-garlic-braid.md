# 0228 - The garlic braid

- **Phase:** 13 - Weapons of the night
- **Status:** todo
- **Depends on:** 0218, 0132, 0168
- **Likely files:** src/core/game_data.gd, src/core/pathing.gd, src/core/enemies.gd, src/core/phases.gd, src/ui/names.gd, src/ui/describe.gd, assets/locale/strings.csv, src/tools/perf_check.gd, src/tools/headless_v1.gd

## Goal

Hung on a post, it makes the ground around it somewhere zombies would rather walk round, and slows the ones that come through anyway (plan sections 3.1 and 5).

## Art

What this task puts on screen will be dressed by Codex art pack(s) A040
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- Id `garlic_braid` (never `garlic`, the crop), paid in garlic and a little wood, `season` autumn (0193's field, per the plan's table). Walkable like a trap through `walked_over`, 0178's flag that 0225 put on the bait's `DEFENCES` row: `Pathing._through` gives it the ground's cost and `Pathing.is_prey` and `breaks_through` leave it out, and `check_defences` refuses it with a `path_cost`; it is not `one_shot`, so `Traps` never sees it. No `damage`, so no `Sfx.TOWER_SOUNDS` entry
- Repelling is a cost: cells within N tiles (LEVER 1-3) cost a LEVER more in `Pathing._entry_costs`, in the shared and the open field, never more than one braid's worth however many overlap. Every step stays within `WIDEST_STEP` (32): extend `check_pathing` to add the garlic extra to the worst terrain and the worst `path_cost`
- Slowing: inside the area an enemy walks at a percent of its speed (LEVER) in `Enemies._walk`, worked out like `Ability.slowed_ticks`; with a flare too, the stronger of the two applies, not both. Build the area as a per-cell array with the field (the pass over the occupants is already there) so `_walk` reads one entry, never a search per zombie per tick
- It wears out: full strength the first night, wilted (a LEVER share) the second, spent after - kept on the occupant, moved on at `Phases.begin_night`. The strength is part of the path costs, so a night that changes any braid bumps the grid once (`Farm.touch`) and the fields rebuild; the no-touch rule is for per-tick status. A spent braid does nothing and stays until sold, or goes (decide). The states match A040: fresh, wilted, spent
- Perf: the area cost is part of `_entry_costs`, so measure `path_refresh` with ten braids; it stays inside `PATH_BUDGET_US`
- `Names.KEYS` `DEF_GARLIC_BRAID`, a `Describe.defence` line, strings in both languages; drawn through the placeholder road (16x24, fresh/wilted/spent) until A040 is integrated by 0239
- SIM and DATA: record both

## Done when

- [ ] `_task_0228_garlic` in `src/tools/headless_v1.gd` asserts a route with a cheap way round avoids the braid, a crowd forced through walks at the LEVER's speed, the braid wilts and is spent on the nights it says (driven through `Phases.begin_night`, not whole played nights), and `GameData.validate()` refuses a garlic extra that would pass `WIDEST_STEP`
- [ ] The Deliverables table of `implementation/backlog/packs/A040-garlic-braid.md` states the final geometry this task settled
- [ ] `python tools/shot.py 0228` captures of the route bending round a braid (0130's camera hook), opened and looked at
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
