# 0213 - Art: the artisan machines

- **Phase:** 12 - The day that pays
- **Status:** done
- **Depends on:** 0188
- **Likely files:** assets/art_source/buildings/, assets/art_source/props/, assets/art_source/manifest.json, tools/check_station_art.py
- **Art packs:** A031

## Goal

The keg, the preserves jar, the dairy, the loom and the mill get their approved art, idle and working.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A031` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A031-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/buildings/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_station_art.FAMILY`).
- Runtime names: `<id>`, `<id>_active` and `<id>_hurt` (and the wreck if 0187 chose it) for the five, at the sizes 0188 settled, with `light_xy`/`smoke_xy` on opaque active pixels; full density, not in `ArtPlacement.visual_scale`'s 2.0 list
- Replace the stand-ins of 0187 and 0188 and flip A031's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A031 integrated`.

## Done when

- [ ] `python tools/check_station_art.py` and `python tools/show_art.py --stations --check` pass
- [ ] `python tools/import_art.py --check` passes
- [ ] FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0213/`
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
