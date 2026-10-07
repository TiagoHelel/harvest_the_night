# 0217 - Art: the house in three tiers

- **Phase:** 12 - The day that pays
- **Status:** todo
- **Depends on:** 0191
- **Likely files:** assets/art_source/buildings/, assets/art_source/manifest.json, tools/check_house_art.py, src/ui/art_placement.gd, src/ui/house_view.gd
- **Art packs:** A035

## Goal

House tiers I, II and III get their approved exteriors, whole and hurt; tier III reads as a small fortified farmhouse.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A035` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A035-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/buildings/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_house_art.py`, which hard-codes `house`/`house_hurt` and their window points today - extend it per tier).
- Runtime names: `house`, `house_hurt`, `house_2`, `house_2_hurt`, `house_3`, `house_3_hurt` with their slices (`house_<c>_<r>`, `house_2_<c>_<r>`...), `windows_xy`, `window_rects_xywh`, `light_xy` and `smoke_xy` on the same 6x4 footprint as today's house. The pack draws them at full density (128x128, pivot (64,120): today's 64x64 at 2.0), so take `house` out of `ArtPlacement.visual_scale`'s 2.0 list - it matches every file whose name starts `house_`, the tiers too - unless 0191 wrote a different density into the pack
- Replace 0191's code-marked stand-ins and flip A035's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A035 integrated`.

## Done when

- [ ] `python tools/check_house_art.py` and `python tools/show_art.py --house --check` pass
- [ ] `python tools/import_art.py --check` passes
- [ ] FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0217/`
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
