# 0236 - Art: the scarecrow decoy and zombie bait

- **Phase:** 13 - Weapons of the night
- **Status:** todo
- **Depends on:** 0224, 0225
- **Likely files:** assets/art_source/defences/, assets/art_source/ui/, assets/art_source/manifest.json, tools/check_barrier_art.py, tools/check_ui_art.py, tools/verify.py
- **Art packs:** A037

## Goal

The approved straw decoy and rotten-fish bait replace the stand-ins 0224 and 0225 left.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A037` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A037-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/defences/` and `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_barrier_art.py`, `check_ui_art.py`, `ArtPlacement` if needed).
- Runtime names follow the one-cell pieces: `buildings/decoy`, `_hurt` and `_wreck` at 16x32 on the ground pivot, the hit sway (2-3 frames) as a short one-shot the view plays when it is struck; the bait on the ground at 16x16 like the mine; `icon_`/`hud_` for the bait kit
- `check_barrier_art.py` counts task 0014's 84 entries and checks the mine's single pieces: extend it for the pack's entries, or add a `check_decoy_art.py` wired into `tools/verify.py` if the shape does not fit
- Retire the stand-ins of 0224 and 0225 from 0120's placeholder registry; if 0223/0234 gave the decoy a tarp, check it still unveils
- Set the pack to integrated: `python implementation/backlog/assets.py set A037 integrated`.

## Done when

- [ ] The family checks (`check_barrier_art.py`, `check_ui_art.py`) and the showcase (`python tools/show_art.py --barriers --check` and `python tools/show_art.py --ui --check`) pass
- [ ] `python tools/import_art.py --check` passes
- [ ] FHD (1920x1080) captures by day and by night of a decoy whole, hurt and struck, and a bait on the ground in the real game, opened and looked at, in `implementation/shots/0236/`
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
