# 0251 - The frost zombie

- **Phase:** 14 - Enemies and bosses
- **Status:** todo
- **Depends on:** 0218
- **Likely files:** src/core/combat.gd, src/core/towers.gd, src/core/enemies.gd, src/core/game_data.gd, src/ui/world_view.gd, src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd

## Goal

An enemy whose death is the attack: it bursts into ice and the towers near it reload slowly for a while. Killing it right under the line now costs something.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A050
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- `ENEMIES.frost_zombie` with `# LEVER`s (hp, `ticks_per_tile`, damage, reward, armour; inside `_task_0051_tank`'s non-boss bounds) plus `chill_tiles` (radius, 1-3), `chill_ticks` and `chill_reload_percent` (reload speed while chilled, 25-75: fifty is twice as slow); `check_enemies` refuses a chill field of zero or a percent outside 1-99
- The hook is `Combat._kill`: every tower within `chill_tiles` (Chebyshev, from `Towers`' cached tower cells, sorted) gets a countdown on its occupant dictionary (`tower["chill"]`) - never through `Farm.touch`, so `grid_version` and every field stay put
- Refreshed, never stacked (the `Combat.set_alight` rule); `Towers.tick` and `_cool_down` count it down; while it lasts the reload set after a shot is scaled by `chill_reload_percent` in integers
- No chill outlives the night: cleared in `Enemies.withdraw`, which `Phases.begin_day` already calls; a save made mid-night keeps it, since occupants are RUN_DATA
- `Towers.chill_left(state, cell)` for the view and for the Winter Lord, whose freeze (0255) sits beside this chill
- Names.KEYS `frost_zombie`, `ENEMY_FROST_ZOMBIE`/`.other` (frost zombie/frost zombies, zumbi de gelo/zumbis de gelo); `DESC_CHILLS` ('slows towers when it dies' / 'deixa as torres lentas ao morrer'); `Sfx.ENEMY_SOUNDS.frost_zombie` borrows `sfx/groan_tank` until 0284
- On screen through 0120's placeholder road: the zombie, a code-drawn ice burst on death, a frost tint on chilled towers (view only) and its forecast head, until A050 is integrated by 0264
- Hashes: DATA moves; SIM should not

## Done when

- [ ] `_task_0251_frost` in `src/tools/headless_v1.gd`: one killed beside two towers makes their next reload `chill_reload_percent` slower for exactly `chill_ticks`, a tower outside `chill_tiles` is untouched, `grid_version` does not move, and the chill is gone the next morning
- [ ] Two deaths beside one tower refresh rather than stack - asserted on the reload number
- [ ] `python tools/shot.py 0251 frost` (a new scenario) opened and looked at: a chilled tower is visibly different
- [ ] the Deliverables table of `implementation/backlog/packs/A050-frost-zombie.md` states the final geometry this task settled
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
