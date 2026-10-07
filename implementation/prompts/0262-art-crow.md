# 0262 - Art: the crow

- **Phase:** 14 - Enemies and bosses
- **Status:** todo
- **Depends on:** 0249, 0246
- **Likely files:** assets/art_source/enemies/crow/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_enemy_art.py, tools/gen_sprites.py, src/ui/enemy_motion.gd, src/ui/world_view.gd
- **Art packs:** A048

## Goal

The crow as Codex drew it, in place of 0249's stand-in: in the air, landing, pecking and falling.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A048` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A048-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/enemies/crow/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`gen_sprites.migrated_enemies()`, `check_enemy_art.FAMILIES`, `EnemyMotion.FAMILIES`/`TRACKED`).
- The flying exception: `crow_fly_0..3` (loop), `crow_land_0`, `crow_peck_0..2`, `crow_death_0..3` (the fall), side view mirrored at runtime; the checker takes this family's motions from its own row (not the fixed walk/attack/death `COUNTS`), exempts flying frames from the ground-contact row and asserts no baked shadow - the shadow stays 0249's code shadow. Keep `crow`, `_walk_b`, `_attack`, `_death` aliases (or teach `_task_0074_zombie_art` the exception) so the suite's art groups still pass
- `EnemyMotion` maps 0249's states (in flight, landed, pecking, falling) to these names and keeps 0249's height offset; replace 0249's placeholders and the forecast head in 0120's registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A048 integrated`.

## Done when

- [ ] `python tools/check_enemy_art.py` and `python tools/show_art.py --enemies --check` pass
- [ ] `python tools/import_art.py --check` passes
- [ ] FHD (1920x1080) captures in the real game by day (the head in the dusk forecast) and by night (one over a wall, one pecking a crop), opened and looked at, in `implementation/shots/0262/`
- [ ] the sim and data hashes are unchanged (art never moves them)
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
