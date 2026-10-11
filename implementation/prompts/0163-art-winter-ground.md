# 0163 - Art: winter ground

- **Phase:** 11 - Calendar and seasons
- **Status:** done
- **Depends on:** 0159
- **Likely files:** assets/art_source/terrain/, assets/art_source/crops/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_terrain_art.py, tools/check_crop_art.py, tools/gen_sprites.py, src/ui/world_view.gd, src/ui/season_view.gd, src/ui/placeholder_art.gd
- **Art packs:** A012

## Goal

Winter gets real snow on the ground: the approved snowy grass, path, soil, tilled ground, edges and shores replace the remapped stand-in of 0159.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A012` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A012-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/terrain/` (and `crops/` for the tilled tiles), manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_terrain_art.py`, `tools/check_crop_art.py`, `ArtPlacement` if needed).
- Runtime names: `terrain/<name>_winter` for `grass`, `grass_b`-`grass_d`, `path` and `soil`, the winter `edge_*`/`shore_*` sides and corners, and `crops/tilled_winter` / `tilled_wet_winter` - 16x16, opaque, seamless, the same set as today's (the wet tile still at least 20 RGB darker, `check_crop_art.py`). The 256x80 atlas is ASCII-owned and built by `tools/gen_sprites.py` from the raster recipes (and asserted against it): build the winter atlas there the way the handoff says (new rows or a second atlas) and let 0159's hook swap it in
- Winter's ground stops going through 0159's remap (the remap stays for anything this pack does not cover); delete the stand-in entries from `src/ui/placeholder_art.gd`, so `python tools/placeholders.py` no longer lists A012
- Set the pack to integrated: `python implementation/backlog/assets.py set A012 integrated`.

## Done when

- [ ] `python tools/check_terrain_art.py`, `python tools/check_crop_art.py` and `python tools/show_art.py --check` pass, and `python tools/import_art.py --check` passes
- [ ] FHD (1920x1080) captures by day and by night in the real game - `python tools/shot.py 0163 season_winter season_winter_night --fhd` - in `implementation/shots/0163/`, opened and looked at: no seam, edge or shore breaks the snow
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
