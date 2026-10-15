# 0260 - Art: the spitter

- **Phase:** 14 - Enemies and bosses
- **Status:** done
- **Depends on:** 0247, 0246
- **Likely files:** assets/art_source/enemies/spitter/, assets/art_source/effects/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_enemy_art.py, tools/gen_sprites.py, tools/check_effect_art.py, src/ui/enemy_motion.gd
- **Art packs:** A046

## Goal

The spitter as Codex drew it, in place of 0247's stand-in: its walk, the spit, the splat and its forecast head.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A046` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A046-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/enemies/spitter/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`gen_sprites.migrated_enemies()`, `check_enemy_art.FAMILIES` and its pinned generation task `'0015'`, the effect checker's pinned 0017 set, `EnemyMotion.FAMILIES`/`TRACKED`) with a block for this pack rather than loosening the old counts.
- Runtime names as the ordinary enemies at 64x48 pivot (32,44): `enemies/spitter`, `spitter_walk_0..3` (0.125 s, loop), `spitter_attack_0..2` (the spit), `spitter_death_0..3`, with the `_walk_b`/`_attack`/`_death` aliases; the spit (8x8, 2 frames) and the splat (3) in the effects family; the 16x16 forecast head where 0158 put the others
- Replace 0247's placeholders in 0120's registry (the leaf flips ownership to raster) and drive the attack pose from the real spit, not a bite.
- Set the pack to integrated: `python implementation/backlog/assets.py set A046 integrated`.

## Done when

- [ ] `python tools/check_enemy_art.py`, `python tools/check_effect_art.py` and `python tools/show_art.py --enemies --check` pass
- [ ] `python tools/import_art.py --check` passes
- [ ] FHD (1920x1080) captures in the real game by day (its head in the dusk forecast) and by night (spitting at a tower), opened and looked at, in `implementation/shots/0260/`
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
