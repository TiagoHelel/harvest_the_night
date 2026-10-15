# 0240 - Art: the searchlight

- **Phase:** 13 - Weapons of the night
- **Status:** done
- **Depends on:** 0229
- **Likely files:** assets/art_source/defences/, assets/art_source/manifest.json, tools/check_tower_art.py, tools/import_art.py
- **Art packs:** A041

## Goal

The approved searchlight replaces the stand-in 0229 left, and its beam starts from the lamp the art draws.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A041` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A041-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/defences/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_tower_art.py` `FAMILIES`, `ArtPlacement` if needed).
- `buildings/searchlight` and `searchlight_2` x the four states at 32x48 with a `light_xy` point on an opaque pixel in place of the muzzle `check_tower_art.py` demands of a gun; the per-family level count, metadata point and `tower` metadata as 0237 left them (make them here if it has not landed), `gen_sprites.migrated_towers()` still the four legacy families
- The beam stays code and starts from `light_xy`; what is lit is still `Light.is_lit` (0229), never the sprite
- Retire 0229's stand-in from 0120's placeholder registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A041 integrated`.

## Done when

- [ ] The family checks (`check_tower_art.py`) and the showcase (`python tools/show_art.py --towers --check`) pass
- [ ] `python tools/import_art.py --check` passes
- [ ] FHD (1920x1080) captures by day and by night of searchlights at both levels lighting a tower line in the real game, opened and looked at, in `implementation/shots/0240/`
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
