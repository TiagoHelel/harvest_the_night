# 0269 - Art: fog, rain and the Blood Moon icons

- **Phase:** 14 - Enemies and bosses
- **Status:** todo
- **Depends on:** 0256, 0257
- **Likely files:** assets/art_source/ui/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_ui_art.py, src/ui/forecast_panel.gd
- **Art packs:** A055

## Goal

The three night events as Codex drew them, in the forecast slot where 0256 and 0257 left placeholders.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A055` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A055-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_ui_art.py` pins the 0018 resource set - add this pack as its own checked block).
- `ui/icon_fog`, `ui/icon_rain`, `ui/icon_blood_moon` at 16x16 pivot (8,8) and the matching `ui/hud_*` at 10x10 pivot (5,5), each pair cut from the same raw source at different nearest scales (visible size at most 14 and 8 px)
- Replace 0256's and 0257's placeholders in the forecast slot (`src/ui/forecast_panel.gd`, 0158) through 0120's registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A055 integrated`.

## Done when

- [ ] `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass
- [ ] `python tools/import_art.py --check` passes
- [ ] FHD (1920x1080) captures in the real game by day (each event in the dusk forecast) and by night (the build step's forecast), opened and looked at, in `implementation/shots/0269/`
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
