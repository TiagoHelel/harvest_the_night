# 0263 - Art: the digger

- **Phase:** 14 - Enemies and bosses
- **Status:** todo
- **Depends on:** 0250, 0246
- **Likely files:** assets/art_source/enemies/digger/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_enemy_art.py, tools/gen_sprites.py, src/ui/enemy_motion.gd
- **Art packs:** A049

## Goal

The digger as Codex drew it, in place of 0250's stand-in: going down, the mound moving under the fence, coming up.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A049` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A049-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/enemies/digger/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`gen_sprites.migrated_enemies()`, `check_enemy_art.FAMILIES` with its extra motions, `EnemyMotion.FAMILIES`/`TRACKED`).
- At 64x48 pivot (32,44): `digger_walk_0..3`, `digger_burrow_0..3` (one-shot), `digger_mound_0..N` (loop, 2-3 frames), `digger_emerge_0..3`, `digger_attack_0..2`, `digger_death_0..3` with the usual aliases, and the forecast head
- `EnemyMotion` plays burrow on the tick 0250 puts it underground, the mound while it stays there and emerge when it surfaces; replace 0250's placeholders in 0120's registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A049 integrated`.

## Done when

- [ ] `python tools/check_enemy_art.py` and `python tools/show_art.py --enemies --check` pass
- [ ] `python tools/import_art.py --check` passes
- [ ] FHD (1920x1080) captures in the real game by day (the head in the dusk forecast) and by night (a mound under a fence line), opened and looked at, in `implementation/shots/0263/`
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
