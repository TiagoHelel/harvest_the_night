# 0289 - Art: the morning report

- **Phase:** 16 - Sound, collections and polish
- **Status:** todo
- **Depends on:** 0138
- **Likely files:** assets/art_source/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_ui_art.py, src/tools/ui_art_showcase.gd, src/ui/placeholder_art.gd, src/ui/result_screen.gd
- **Art packs:** A057

## Goal

A small sunrise over the farmhouse heads 0138's morning report. Optional: if the owner declines the pack, the header 0138 drew becomes the shipped look and this task closes with a note.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A057` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- The one exception, because A057 is optional: if its status is `blocked` with the owner's decline in the note, do not wait. Delete A057's entries from 0120's placeholder registry (`src/ui/placeholder_art.gd`) and draw 0138's code-drawn band directly in `result_screen.gd`, so it is the final look and no longer a stand-in (or drop the header if it only made sense as art), quote the decline in the journal and close with `python tools/task.py done 0289`. `task.py next` never offers a task whose pack is not approved, so this path is run by hand or by 0290
- Use only the folder named in the pack's `CLAUDE-A057-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/<family>/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_<family>_art.py`, `ArtPlacement` if needed).
- Family `ui`: one header at the canvas and pivot 0138 settled in A057's Deliverables table, drawn by `result_screen.gd` above the report through the lookup it already uses, replacing 0138's stand-in (delete A057's registry entries in `src/ui/placeholder_art.gd` once the raster lands at the same path); no text in it (the report's words stay strings), checked in its own section of `tools/check_ui_art.py` and shown in `ui_art_showcase.gd`
- Set the pack to integrated: `python implementation/backlog/assets.py set A057 integrated`.

## Done when

- [ ] `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass with the header counted
- [ ] `python tools/import_art.py --check` passes
- [ ] FHD (1920x1080) captures of the morning report after a won and after a lost night, and of the farm around it by day and by night, opened and looked at, in `implementation/shots/0289/`
- [ ] The sim and data hashes are unchanged (art never moves them)
- [ ] On the decline path instead: `python tools/placeholders.py` no longer lists A057, a capture of the morning report shows the band drawn directly, and the journal quotes the owner's words
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
