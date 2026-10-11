# 0247 - The spitter

- **Phase:** 14 - Enemies and bosses
- **Status:** done
- **Depends on:** 0218, 0132
- **Likely files:** src/core/enemies.gd, src/core/game_data.gd, src/ui/world_view.gd, src/ui/describe.gd, src/ui/names.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd

## Goal

The first enemy that hurts what you built without touching it: it stops at range and spits at a tower. A tower line in the open becomes something to cover, not only something to build.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A046
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- `ENEMIES.spitter` with `# LEVER`s: hp, `ticks_per_tile`, damage to the house, reward, `spit_range` (tiles, 3-5), `spit_damage` (to a structure), `spit_every_ticks`, `spit_tiles_per_second`; `check_enemies` refuses a spit range of zero or one that reaches as far as the gun tower's base `range` (5), so a tower can always answer it. Keep it inside `_task_0051_tank`'s non-boss bounds (less hp and armour than the tank, faster than it) and `_task_0058_giant`'s
- In `Enemies._walk`: with a tower (a DEFENCES entry with `reload_ticks`) within `spit_range` - Chebyshev, nearest first, ties by the lower cell index - it stands and spits; with none it walks the flow field and bites like a walker
- Enemy projectiles are new and kept apart from the towers' `projectiles`, which `Combat.incoming` and `worth_shooting` read: a top-level `enemy_shots` Array (only Dictionaries need a TABLES/RUN_DATA line), integer positions, aimed at a cell when fired, landing through `Farm.damage` after its flight
- Advance them inside `Enemies.tick` so `PerfNames.NIGHT` stays true; if a new `X.tick` goes into `Sim._tick_night` instead, add it to `src/tools/perf_names.gd` and `perf_check.gd` in this task
- `Enemies.withdraw` clears `enemy_shots` at dawn; a spit landing on an empty cell does nothing; a tower it destroys leaves rubble and a `structure_lost` event like a bite
- Names.KEYS `spitter`, rows `ENEMY_SPITTER` and `ENEMY_SPITTER.other` (spitter/spitters, cuspidor/cuspidores) and a `Describe.enemy` line `DESC_SPITS` ('spits at towers from %d tiles' / 'cospe nas torres a %d ladrilhos'); `Sfx.ENEMY_SOUNDS.spitter` borrows the nearest generated voice (`sfx/groan_walker`) so `_task_0085_night_sounds` passes, until 0284 gives it its own
- On screen through 0120's placeholder road: the spitter at 64x48 pivot (32,44), the spit in flight (8x8) and a code-drawn splat, plus its forecast head - placeholders until A046 is integrated by 0260
- The first kind past the MVP's five breaks the art groups that count `ENEMIES`: rewrite in place `_task_0074_zombie_art` (`kinds.size() == 5`, a file per pose, the silhouette and biggest-Giant tests) and `_task_0088_juice` (a death body per kind) to check the kinds with raster art, leaving stand-ins to 0120's `_task_0120_placeholders`; `_case_0074_zombie_art` in `input_check.gd` counts a stand-in through 0120's lookup as drawn. If `_task_0059_wave_data` still wants every `ENEMIES` kind in the authored nights, exempt the kinds no night sends yet in one named list (0270-0274 put them in the year). Later enemy tasks only add to what this leaves
- Hashes: DATA moves (a new ENEMIES entry); SIM moves once, because the state gains `enemy_shots` - nothing else in the determinism scenario may change, and the journal says so

## Done when

- [ ] `_task_0247_spitter` in `src/tools/headless_v1.gd`: with a gun tower inside `spit_range` it stops and lands `spit_damage` every `spit_every_ticks` (measured); with none it walks to the house; two runs of one seed land the same spits on the same ticks; nothing is left in `enemy_shots` after dawn
- [ ] The same group: a tower whose reach covers it kills it before losing the tower, and a tower that cannot reach it is worn down - print both numbers
- [ ] `python tools/shot.py 0247 spitter` (a new scenario: a spitter working on a tower line) opened and looked at; the rewritten `_task_0074_zombie_art`, `_task_0088_juice` and `_case_0074_zombie_art` pass with the spitter on its stand-in
- [ ] the Deliverables table of `implementation/backlog/packs/A046-spitter.md` states the final geometry this task settled
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
