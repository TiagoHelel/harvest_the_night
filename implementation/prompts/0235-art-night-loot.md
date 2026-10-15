# 0235 - Art: bones, moon stones and essence

- **Phase:** 13 - Weapons of the night
- **Status:** done
- **Depends on:** 0221, 0222, 0219
- **Likely files:** assets/art_source/props/, assets/art_source/crops/, assets/art_source/ui/, assets/art_source/manifest.json, tools/check_prop_art.py, tools/check_crop_art.py, tools/check_ui_art.py
- **Art packs:** A036

## Goal

The approved bones, moon stones, fertilised soil and night-loot icons go into the game in place of the stand-ins 0219, 0221 and 0222 left - essence's icon included.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A036` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A036-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/props/`, `assets/art_source/crops/` and `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_prop_art.py` `NAMES`, `check_crop_art.py`'s soil names, `check_ui_art.py`, `ArtPlacement` if needed).
- Runtime names: the bone pile and the moon stone as 16x16 props on a ground pivot (the stone's 2-frame shimmer an animation, its glow left in code); the fertilised ground dry and wet beside `tilled`/`tilled_wet` (the wet one at least 20 RGB darker, as `check_crop_art.py` holds soil to); `icon_`/`hud_` for `bones`, `bone_meal` and `moon_stone`, and the essence art as `ui/icon_tech` and `ui/hud_tech`, since the id stays `tech`
- `check_ui_art.py` counts the resource icons by `generation_task` (15 plans, 30 entries today, `tech` among them): extend it to the pack's entries rather than loosening the count, and move `tech` out of task 0018's set on purpose (the plan list and the count, with the reason) since the essence icon replaces it
- Retire the stand-ins of 0219, 0221 and 0222 from 0120's placeholder registry, so its check no longer lists A036
- Set the pack to integrated: `python implementation/backlog/assets.py set A036 integrated`.

## Done when

- [ ] The family checks (`check_prop_art.py`, `check_crop_art.py`, `check_ui_art.py`) and the showcase (`python tools/show_art.py --props --check`, `python tools/show_art.py --crops --check` and `python tools/show_art.py --ui --check`) pass
- [ ] `python tools/import_art.py --check` passes
- [ ] FHD (1920x1080) captures by day and by night of bone piles, a moon stone, a fertilised plot and the essence counter in the real game, opened and looked at, in `implementation/shots/0235/`
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
