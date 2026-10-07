# 0123 - Art: the farmer tilling, planting, watering and harvesting

- **Phase:** 9 - v1.0 groundwork
- **Status:** todo
- **Depends on:** 0120
- **Likely files:** assets/art_source/player-fhd/, assets/art_source/manifest.json, assets/art_source/ownership.json, src/ui/player_art.gd, src/ui/placeholder_art.gd, src/tools/art_showcase.gd, src/tools/headless_check.gd, src/tools/shot.gd
- **Art packs:** A007

## Goal

The field verbs still play the older, stockier 48x48 farmer next to the 32px walk. Put in A007's till, plant, water and harvest, drawn facing south, north and west, so the farmer is one person whatever he is doing.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A007` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A007-PROMPT.txt` handoff (under `implementation/backlog/deliveries/`); check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/player-fhd/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend `art_showcase.gd --work` (and the FHD player sources check if the pack is exact-source) for the new strips
- Runtime names `<verb>_<dir>_0..3` for till, plant, water and harvest x south, north, west - anticipation, contact, follow-through, recovery - at the canvas, pivot and draw scale the pack's contract states; east is west mirrored at runtime
- `PlayerArt.pose` picks a verb's strip by facing (today `VERBS` maps a verb to one west strip, drawn for every facing), `flip` only for `Player.EAST`; one code path for every verb, with verbs not yet converted keeping their one legacy strip, which 0124 and 0125 reuse if this lands first. The contact frame still meets the rules' completion (`player_work.gd`)
- The tool in hand is not tiered by art: keep the pack's fixed head ramp as delivered and record which colours it is (manifest metadata or a constant beside `PlayerArt`) so 0173 can tint it per tier; this task draws it untinted
- Retire the legacy `till_*`, `plant_*`, `water_*`, `harvest_*` 48x48 outputs from the manifest and `ownership.json`, and their `PlayerArt.SECONDS` rows; rewrite `_task_0073_player_art` (its verb loops, ~l.13253-13276, and 'a verb is drawn even while a direction is held') and `art_showcase.gd`'s `--work` checks (`_work_frame` and `_work_cycles`, ~l.1491-1530, which pin `PlayerFrames.FEET`/`CANVAS` 48x48 and `pose(...)["name"] == verb` for north and south); delete A007's registry entry
- Set the pack to integrated: `python implementation/backlog/assets.py set A007 integrated`.

## Done when

- [ ] `python tools/show_art.py --work --check` passes with the four verbs in three directions; `python tools/import_art.py --check` passes
- [ ] `python tools/placeholders.py` no longer lists A007
- [ ] FHD captures (`python tools/shot.py 0123 --fhd`; add a scenario that holds the farmer mid-verb if none does) of each verb facing south, north, west and east, by day and in the dark, in `implementation/shots/0123/`, opened: feet planted, the same body height as the walk
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
