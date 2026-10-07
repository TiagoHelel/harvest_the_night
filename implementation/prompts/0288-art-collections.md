# 0288 - Art: the collection book, trophies and badges

- **Phase:** 16 - Sound, collections and polish
- **Status:** todo
- **Depends on:** 0287
- **Likely files:** assets/art_source/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_ui_art.py, src/tools/ui_art_showcase.gd, src/ui/placeholder_art.gd, src/ui/collections_screen.gd
- **Art packs:** A056

## Goal

The book cover, the four boss trophies and the achievement badges Codex drew replace 0287's stand-ins, so the screen a player opens before Year 2 looks like the rest of the game.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A056` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A056-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/<family>/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_<family>_art.py`, `ArtPlacement` if needed).
- Family `ui`, no text in any of it: names, canvases and pivots exactly as A056's Deliverables table (settled by 0287) - the cover, the tab icons, a trophy per `is_boss` enemy, a badge per achievement id, the ornament. `tools/check_ui_art.py` hard-codes the 0018 resource icons (`len(plans)==15`): give the A056 set its own section and counts rather than loosening that one, and show it in `ui_art_showcase.gd`
- Delete A056's entries from 0120's placeholder registry (`src/ui/placeholder_art.gd`) once the raster outputs land at the same paths, so `collections_screen.gd` draws the real art through the lookup it already uses and `python tools/placeholders.py` no longer lists A056; locked trophies and badges stay the same art dimmed by code
- Set the pack to integrated: `python implementation/backlog/assets.py set A056 integrated`.

## Done when

- [ ] `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass with the A056 set counted
- [ ] `python tools/import_art.py --check` passes
- [ ] FHD (1920x1080) captures of the collections screen, every tab with a full profile, opened in a run by day and by night, opened and looked at, in `implementation/shots/0288/`
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
