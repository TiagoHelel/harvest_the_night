# 0143 - Art: going to bed, sleeping, waking, passing out

- **Phase:** 10 - Sleep is the night
- **Status:** todo
- **Depends on:** 0129, 0128
- **Likely files:** assets/art_source/player-fhd/, assets/art_source/manifest.json, assets/art_source/ownership.json, src/ui/player_frames.gd, src/ui/raster_art.gd, src/ui/placeholder_art.gd, src/ui/house_view.gd, src/ui/player_view.gd, tools/verify.py
- **Art packs:** A001

## Goal

The farmer's night in his own art - getting into bed, the sleep loop, waking and stretching, passing out on the farm - from Codex pack A001, replacing 0129's stand-ins.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A001` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A001-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/player-fhd/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`. The farmer has no `check_*_art.py`: its gates are a hash-checking promoter with a `--check` mode wired into `tools/verify.py` (like `implementation/fhd-player/pilots/2026-10-04/palette-variants/promote_blue_walk.py`) and the `show_art.py` showcases
- Runtime: the canvas, pivot and `draw_scale` the pack's contract states, one per animation; the get-in, sleep and wake strips play in `house_view.gd` sitting exactly on the bed (`FURNITURE_OFFSETS` for the bed), the pass-out in `player_view.gd` where he fell, over the shared shadow; the one-shots stay one-shots and the sleep loop loops
- Delete A001's entries from 0120's placeholder registry: the raster outputs land under the names 0129 registered, so no view code changes (`python tools/placeholders.py --check` fails on an entry left for an integrated pack). Extend the `--house-visit` and `--work` showcases with the four animations
- Set the pack to integrated: `python implementation/backlog/assets.py set A001 integrated`.

## Done when

- [ ] `python tools/show_art.py --house-visit --check`, `python tools/show_art.py --work --check` and the farmer's promoter check pass; `python tools/import_art.py --check` passes; `python tools/placeholders.py` no longer lists A001
- [ ] FHD (1920x1080) captures by day and by night of the art in the real game - going to bed, asleep, waking, a pass-out - opened and looked at, in `implementation/shots/0143/`
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
