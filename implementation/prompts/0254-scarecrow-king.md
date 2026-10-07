# 0254 - The Scarecrow King

- **Phase:** 14 - Enemies and bosses
- **Status:** todo
- **Depends on:** 0246, 0249
- **Likely files:** src/core/enemies.gd, src/core/game_data.gd, src/ui/enemy_motion.gd, src/ui/world_view.gd, src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd

## Goal

Autumn's boss calls the sky down: it stops, casts, and a flock of crows rises around it. It asks what the crow asked - cover in the air and care for the field - under pressure.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A053
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- `ENEMIES.scarecrow_king` with `is_boss` and `# LEVER`s: hp, armour, `ticks_per_tile`, damage, reward, `telegraph_ticks` (the cast), `summon_every_ticks`, `flock_size`, `summon_cap` (crows it may raise in one night, so a long fight cannot flood the farm); it passes 0246's boss-against-non-boss asserts
- Summons on deterministic cells: a fixed list of offsets around its cell (a table in `game_data.gd`, listed in `digest()`), clipped to the map, taken in list order - no RNG draw. They are 0249's `crow` through `Entities.spawn`, flying from there to the field; `check_enemies` refuses a `flock_size` above the offsets, a `summon_cap` below `flock_size`, or a summoned kind that does not fly
- Summoned crows are not wave members: `Waves` counts and the forecast are unchanged, and the night still ends at dawn (0137) or when everything is dead; decide whether they pay bounty (a farmable King is an exploit) and say why
- The cast is the telegraph: it stands for `telegraph_ticks` and is `is_winding` (reusing `winding_at`/`chew_wait`, as `_gnaw` does), so the 0246 bar flashes; otherwise it walks the flow field and bites like a walker, inside `Enemies.tick`
- Autumn's day-14 boss: `GameData.SEASON_BOSSES[2]` becomes `&"scarecrow_king"` (any group that put a Giant on Autumn 14 is rewritten in place); `BOSS_INTRO_SCARECROW_KING`; Names.KEYS `scarecrow_king`, `ENEMY_SCARECROW_KING`/`.other` (scarecrow king/scarecrow kings, rei espantalho/reis espantalhos) and `DESC_SUMMONS` ('calls down crows' / 'chama os corvos'); `Sfx.ENEMY_SOUNDS.scarecrow_king` borrows `sfx/roar_giant` until 0284
- On screen through 0120's placeholder road: a cast pose, the flock rising and its forecast mark at the boss canvas, until A053 is integrated by 0267
- Hashes: DATA moves (ENEMIES, the offsets, SEASON_BOSSES); SIM should not - the determinism night is Spring 1

## Done when

- [ ] `_task_0254_scarecrow_king` in `src/tools/headless_v1.gd`: each cast raises `flock_size` crows on the listed cells after exactly `telegraph_ticks`, two runs agree cell for cell, and no night raises more than `summon_cap`
- [ ] The same group: a King with a planted field and no `hits_flying` cover costs crops, one with cover over the field costs few - print both counts
- [ ] `python tools/shot.py 0254 scarecrow_king` (mid-cast) opened and looked at
- [ ] the Deliverables table of `implementation/backlog/packs/A053-scarecrow-king.md` states the final geometry this task settled
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
