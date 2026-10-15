# 0146 - Art: the guardian's cursor

- **Phase:** 10 - Sleep is the night
- **Status:** done
- **Depends on:** 0131
- **Likely files:** assets/art_source/ui/, assets/art_source/manifest.json, assets/art_source/ownership.json, src/ui/raster_art.gd, src/ui/placeholder_art.gd, src/ui/guardian_cursor.gd, tools/check_ui_art.py, tools/show_art.py
- **Art packs:** A004

## Goal

The cursor's seven states in drawn pixels, from Codex pack A004, replacing 0131's code-drawn outline.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A004` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A004-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded lists of `tools/check_ui_art.py` and the `--ui` showcase
- Runtime: neutral, can place, blocked, upgrade, sell, repair and aim as one-cell 16x16 frames with a 2-frame pulse each, under the names 0131 registered; no text; readable over the night ramp on grass, soil and a wall
- Replace 0131's placeholder by deleting A004's entries from 0120's placeholder registry, so the states 0132, 0134 and 0135 switched on all show the new art
- Set the pack to integrated: `python implementation/backlog/assets.py set A004 integrated`.

## Done when

- [ ] `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass; `python tools/import_art.py --check` passes; `python tools/placeholders.py` no longer lists A004
- [ ] FHD (1920x1080) captures by day and by night of the art in the real game - the cursor in each state over dark ground - opened and looked at, in `implementation/shots/0146/`
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
