# 0124 - Art: the farmer chopping, mining, collecting and carrying

- **Phase:** 9 - v1.0 groundwork
- **Status:** todo
- **Depends on:** 0120
- **Likely files:** assets/art_source/player-fhd/, assets/art_source/manifest.json, assets/art_source/ownership.json, src/ui/player_art.gd, src/ui/placeholder_art.gd, src/tools/art_showcase.gd, src/tools/headless_check.gd, src/tools/shot.gd
- **Art packs:** A008

## Goal

Chopping and mining are what a first day is made of, and they still play the old 48x48 farmer. Put in A008's chop, mine, collect and carry in the 32px body.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A008` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A008-PROMPT.txt` handoff (under `implementation/backlog/deliveries/`); check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/player-fhd/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend `art_showcase.gd --work` for the new strips
- Runtime names `<verb>_<dir>_0..3` for chop, mine, collect and carry x south, north, west, east mirrored at runtime, at the pack's canvas, pivot and draw scale. `carry` is a view cue (`PlayerArt.COSMETIC`), not a core verb, and maps the same way
- If 0123 has not yet made `PlayerArt.pose` choose a strip by facing, do it here as the one path for every verb. The axe and pickaxe heads keep the pack's fixed ramp, recorded for 0173's tint, drawn untinted
- Retire the legacy `chop_*`, `mine_*`, `collect_*`, `carry_*` 48x48 outputs and their `SECONDS` rows; update `_task_0073_player_art` and the `--work` checks for the new names; delete A008's registry entry
- Set the pack to integrated: `python implementation/backlog/assets.py set A008 integrated`.

## Done when

- [ ] `python tools/show_art.py --work --check` and `python tools/import_art.py --check` pass
- [ ] `python tools/placeholders.py` no longer lists A008
- [ ] FHD captures (`python tools/shot.py 0124 --fhd`, with an earlier leaf's mid-verb scenario or a new one) of each verb in four facings, by day and in the dark, in `implementation/shots/0124/`, opened: the axe meets the tree and the pick meets the rock on the contact frame
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
