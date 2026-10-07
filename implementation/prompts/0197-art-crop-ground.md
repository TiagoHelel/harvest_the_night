# 0197 - Art: trampled crops and tilled ground

- **Phase:** 12 - The day that pays
- **Status:** todo
- **Depends on:** 0167, 0155, 0171
- **Likely files:** assets/art_source/crops/, assets/art_source/manifest.json, tools/check_crop_art.py, src/ui/world_view.gd
- **Art packs:** A014

## Goal

The trampled crop of 0155, the withered crop of 0171 and the tilled-grass edges of 0167 get their approved art in place of their stand-ins.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A014` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A014-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/crops/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_crop_art.py`, which checks `tilled`/`tilled_wet` today).
- Runtime names: the trampled and withered crops (16x16, pivot (8,14)) and the edge pieces under the mask names 0167 wrote into the pack's table; ground pieces keep the soil conventions (pivot (8,16), wet at least 20 RGB darker)
- Replace the stand-ins in `world_view.gd`'s plot drawing left by 0155, 0167 and 0171, and flip A014's placeholder-registry entries to raster so 0120's check stops listing it
- Set the pack to integrated: `python implementation/backlog/assets.py set A014 integrated`.

## Done when

- [ ] `python tools/check_crop_art.py` and `python tools/show_art.py --crops --check` pass
- [ ] `python tools/import_art.py --check` passes
- [ ] FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0197/`
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
