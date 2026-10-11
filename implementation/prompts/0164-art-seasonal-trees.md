# 0164 - Art: trees through the seasons

- **Phase:** 11 - Calendar and seasons
- **Status:** done
- **Depends on:** 0159, 0156
- **Likely files:** assets/art_source/props/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_prop_art.py, src/ui/world_view.gd, src/ui/season_view.gd, src/ui/placeholder_art.gd
- **Art packs:** A013

## Goal

Blossom in spring, colour in autumn, bare branches under snow in winter: the approved seasonal trees and snow caps replace the remapped stand-ins of 0159.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A013` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A013-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/props/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_prop_art.py`, `ArtPlacement` if needed).
- Runtime names: `props/tree_spring`, `tree_autumn` and `tree_winter`, and the same for `tree_b` - 40x48, pivot (20,44), sharing canvas, pivot, scale and palette with the base tree (`variant_of` rules); summer is today's tree. The tree wind motion (`tree_wind_showcase.gd`) still applies
- Generic 16x16 snow caps drawn over each stump, rock, seam and ore node in winter, and over 0156's new nodes and stumps (one per 2x2 cell); the caps are an overlay in the view, never a change to the occupant. 0159's lookup finds the seasonal frames, and the remap leaves them alone
- Delete the stand-in entries from `src/ui/placeholder_art.gd`; `python tools/placeholders.py` no longer lists A013
- Set the pack to integrated: `python implementation/backlog/assets.py set A013 integrated`.

## Done when

- [ ] `python tools/check_prop_art.py` and `python tools/show_art.py --check` pass, and `python tools/import_art.py --check` passes
- [ ] FHD (1920x1080) captures by day and by night in the real game - `python tools/shot.py 0164 noon season_autumn season_winter season_winter_night --fhd` - in `implementation/shots/0164/`, opened and looked at: the trees change with the season and every cap sits on its node
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
