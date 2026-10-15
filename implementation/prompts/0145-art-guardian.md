# 0145 - Art: the porch guardian

- **Phase:** 10 - Sleep is the night
- **Status:** done
- **Depends on:** 0131, 0133
- **Likely files:** assets/art_source/guardian/, assets/art_source/manifest.json, assets/art_source/ownership.json, src/ui/raster_art.gd, src/ui/placeholder_art.gd, src/ui/guardian_view.gd, src/ui/lighting.gd, tools/check_prop_art.py, tools/show_art.py, tools/verify.py
- **Art packs:** A003

## Goal

The porch scarecrow that becomes the guardian at night, from Codex pack A003, replacing 0131's placeholder.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A003` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A003-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/guardian/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`. It is a new family: extend `tools/check_prop_art.py`'s `NAMES` or add a `tools/check_guardian_art.py` wired into `tools/verify.py`, with a showcase
- Runtime: the day, wake, night and point states with the canvas, pivot and timings 0131 wrote into the pack's Deliverables table, at draw scale 1.0 (`ArtPlacement`'s 2x list is not extended); the eyes' light points become emission metadata, like `light_xy`, that `lighting.gd` reads - nothing else on the scarecrow emits
- Replace 0131's placeholder by deleting A003's entries from 0120's placeholder registry (runtime names `guardian_<anim>_<i>`, as 0131 registered them); the wake still plays at the reality switch and the point (0133) when something is placed
- Set the pack to integrated: `python implementation/backlog/assets.py set A003 integrated`.

## Done when

- [ ] The guardian's checker and showcase pass; `python tools/import_art.py --check` passes; `python tools/placeholders.py` no longer lists A003
- [ ] FHD (1920x1080) captures by day and by night of the art in the real game - still by day, awake with its eyes lit at night, pointing at a placement - opened and looked at, in `implementation/shots/0145/`
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
