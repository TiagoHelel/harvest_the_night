# 0241 - Art: the electric fence

- **Phase:** 13 - Weapons of the night
- **Status:** todo
- **Depends on:** 0230
- **Likely files:** assets/art_source/defences/, assets/art_source/effects/, assets/art_source/manifest.json, tools/check_barrier_art.py, tools/check_effect_art.py
- **Art packs:** A042

## Goal

The approved electric fence, joined on all sixteen masks, and its zap replace the stand-ins 0230 left.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A042` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A042-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/defences/` and `assets/art_source/effects/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_barrier_art.py`, `check_effect_art.py`, `ArtPlacement` if needed).
- Source modules `buildings/modules/electric_fence_{post,horizontal,vertical}` (and `_hurt`) composed into `electric_fence_join_<mask>` for the 16 N1/E2/S4/W8 masks and `_hurt`, plus `_wreck`, at 16x32 / (8,28) like the fence. `check_barrier_art.py` checks `('wall', 'fence')` and 84 entries of task 0014: add the family and its count
- `WorldView.connected_barrier` reads the `connected` flag the importer writes from `join_mask`, so the joined art replaces 0230's placeholder joins with no view change - check it. The zap (3 frames, one-shot) is an effect family played when the stun lands, its own checked block in `check_effect_art.py` beside task 0017's 25 frames
- Retire 0230's stand-ins from 0120's placeholder registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A042 integrated`.

## Done when

- [ ] The family checks (`check_barrier_art.py`, `check_effect_art.py`) and the showcase (`python tools/show_art.py --barriers --check` and `python tools/show_art.py --effects --check`) pass
- [ ] `python tools/import_art.py --check` passes
- [ ] FHD (1920x1080) captures by day and by night of a joined run of electric fence zapping a biter in the real game, opened and looked at, in `implementation/shots/0241/`
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
