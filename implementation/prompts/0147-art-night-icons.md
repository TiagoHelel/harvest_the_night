# 0147 - Art: the night hotbar and HUD icons

- **Phase:** 10 - Sleep is the night
- **Status:** todo
- **Depends on:** 0133, 0139
- **Likely files:** assets/art_source/ui/, assets/art_source/manifest.json, assets/art_source/ownership.json, src/ui/raster_art.gd, src/ui/placeholder_art.gd, src/ui/hotbar.gd, src/ui/night_hud.gd, tools/check_ui_art.py, tools/show_art.py
- **Art packs:** A005

## Goal

The icons of the night - the eight defences, the flare, START, speed and the moon of the dawn countdown - from Codex pack A005, replacing the hotbar's and the night HUD's placeholders.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A005` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A005-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded lists of `tools/check_ui_art.py` and the `--ui` showcase
- Runtime: one raw source each, cut into a 16x16 `icon_<id>` and a 10x10 `hud_<id>` (visible at most 14 and 8 px) for `gun_tower`, `auto_crossbow`, `flame_tower`, `mortar`, `mine`, `fence`, `wall`, `barricade`, the flare, START, speed and the dawn moon
- The hotbar (0133) takes the 16x16 cuts and the night HUD (0139) the 10x10 ones, replacing their placeholders by deleting A005's entries from 0120's placeholder registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A005 integrated`.

## Done when

- [ ] `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass; `python tools/import_art.py --check` passes; `python tools/placeholders.py` no longer lists A005
- [ ] FHD (1920x1080) captures by day and by night of the art in the real game - the hotbar and the night HUD in the build step and mid-wave - opened and looked at, in `implementation/shots/0147/`
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
