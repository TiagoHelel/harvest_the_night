# 0238 - Art: the pumpkin catapult

- **Phase:** 13 - Weapons of the night
- **Status:** todo
- **Depends on:** 0227
- **Likely files:** assets/art_source/defences/, assets/art_source/effects/, assets/art_source/manifest.json, tools/check_tower_art.py, tools/check_effect_art.py, tools/import_art.py
- **Art packs:** A039

## Goal

The approved catapult, its pumpkin and its splat replace the stand-ins 0227 left.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A039` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A039-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/defences/` and `assets/art_source/effects/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_tower_art.py` `FAMILIES`, `check_effect_art.py`, `ArtPlacement` if needed).
- `buildings/catapult`, `catapult_2` and `catapult_3` x the four states at 32x48 with `muzzle_xy`/`muzzles_xy` on opaque pixels; the `tower` metadata in `import_art.py` for this pack; the per-family checks 0237 made in `check_tower_art.py` (if 0237 has not landed, make them here), with `gen_sprites.migrated_towers()` still the four legacy families
- The pumpkin shot (8x8) drawn where the view draws a mortar shell, and the splat (4 frames, one-shot) as an effect family in `check_effect_art.py` - its own checked block, leaving task 0017's count of 25 frames alone
- Retire 0227's stand-ins from 0120's placeholder registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A039 integrated`.

## Done when

- [ ] The family checks (`check_tower_art.py`, `check_effect_art.py`) and the showcase (`python tools/show_art.py --towers --check` and `python tools/show_art.py --effects --check`) pass
- [ ] `python tools/import_art.py --check` passes
- [ ] FHD (1920x1080) captures by day and by night of each level firing and a pumpkin landing in the real game, opened and looked at, in `implementation/shots/0238/`
- [ ] The sim and data hashes are unchanged (art never moves them)
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
