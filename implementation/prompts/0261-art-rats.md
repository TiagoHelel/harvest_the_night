# 0261 - Art: the rat swarm

- **Phase:** 14 - Enemies and bosses
- **Status:** done
- **Depends on:** 0248, 0246
- **Likely files:** assets/art_source/enemies/rat/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_enemy_art.py, tools/gen_sprites.py, src/ui/enemy_motion.gd, src/ui/enemy_deaths.gd
- **Art packs:** A047

## Goal

The rats as Codex drew them, in place of 0248's stand-in: small enough to read as a swarm and still read as rats.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A047` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A047-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/enemies/rat/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`gen_sprites.migrated_enemies()`, `check_enemy_art.FAMILIES`, `EnemyMotion.FAMILIES`/`TRACKED`).
- The rat is not 64x48: `check_enemy_art.py` takes canvas, pivot, contact row and motion counts per family (rat: walk 4, attack 3 from the pack's bite, death 3, at the canvas 0248 settled, ~24x16) instead of asserting `[64,48]` for everyone, and `EnemyDeaths` plays three death frames for it
- Runtime names `enemies/rat`, `rat_walk_0..3`, `rat_attack_0..2`, `rat_death_0..2` with the usual aliases, and the forecast head; replace 0248's placeholders in 0120's registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A047 integrated`.

## Done when

- [ ] `python tools/check_enemy_art.py` and `python tools/show_art.py --enemies --check` pass
- [ ] `python tools/import_art.py --check` passes
- [ ] FHD (1920x1080) captures in the real game by day (the head in the dusk forecast) and by night (a cluster crossing a mine), opened and looked at, in `implementation/shots/0261/`
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
