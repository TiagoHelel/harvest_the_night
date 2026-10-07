# 0162 - Art: forecast heads

- **Phase:** 11 - Calendar and seasons
- **Status:** todo
- **Depends on:** 0158
- **Likely files:** assets/art_source/ui/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_ui_art.py, src/ui/raster_art.gd (generated), src/ui/placeholder_art.gd, src/ui/forecast_panel.gd
- **Art packs:** A011

## Goal

The forecast names what is coming with the enemies' own faces: the approved heads of the walker, runner, tank, breaker and Giant replace the cropped walk frames.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A011` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A011-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_ui_art.py`, `ArtPlacement` if needed).
- Runtime names: `ui/head_<kind>` 16x16, pivot (8,8), for `walker`, `runner`, `tank`, `breaker` and `giant`, binary alpha, matching each enemy's sprite. `tools/check_ui_art.py` gains a heads family that requires a head for each of these five; later enemies bring theirs in their own packs and add themselves to the list
- Replace 0158's cropped walk-frame heads by deleting their entries from `src/ui/placeholder_art.gd`; the panel asks for `ui/head_<kind>` and nothing else changes; `python tools/placeholders.py` no longer lists A011
- Set the pack to integrated: `python implementation/backlog/assets.py set A011 integrated`.

## Done when

- [ ] `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass, and `python tools/import_art.py --check` passes
- [ ] FHD (1920x1080) captures by day and by night of the heads in the real game - `python tools/shot.py 0162 forecast_dusk forecast_build --fhd`, with the scenarios moved to a date whose forecast lists all five kinds (Spring 14 does while it is Endless-generated with the Giant's row; check it on the day) - in `implementation/shots/0162/`, opened and looked at
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
