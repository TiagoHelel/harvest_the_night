# 0202 - Art: tool icons

- **Phase:** 12 - The day that pays
- **Status:** done
- **Depends on:** 0173, 0176, 0190
- **Likely files:** assets/art_source/ui/, assets/art_source/manifest.json, tools/check_ui_art.py, src/ui/workshop_panel.gd
- **Art packs:** A019

## Goal

Fifteen tool icons - four tools in three tiers and the three rods - replace 0173's stand-ins wherever a tool is shown.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A019` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A019-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/ui/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`tools/check_ui_art.py`, which counts only task 0018's icons today - give it the new family).
- Runtime names `ui/icon_<tool>_<tier>` (16x16, pivot (8,8)) and `ui/hud_<tool>_<tier>` (10x10, pivot (5,5)) cut from one source, for hoe, can, axe and pickaxe at basic/iron/gold and the rod at bamboo/fibre/iron, as 0173 named the tiers
- Replace the stand-ins in the workshop panel, the inventory and the stall (0190) and flip A019's placeholder-registry entries to raster. The tool in the farmer's hand stays code-tinted
- Set the pack to integrated: `python implementation/backlog/assets.py set A019 integrated`.

## Done when

- [ ] `python tools/check_ui_art.py` and `python tools/show_art.py --ui --check` pass
- [ ] `python tools/import_art.py --check` passes
- [ ] FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0202/`
- [ ] the sim and data hashes are unchanged (art never moves them)
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
