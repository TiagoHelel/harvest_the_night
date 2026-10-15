# 0216 - Art: the peddler

- **Phase:** 12 - The day that pays
- **Status:** done
- **Depends on:** 0190
- **Likely files:** assets/art_source/npc/, assets/art_source/props/, assets/art_source/manifest.json, tools/check_station_art.py, tools/check_npc_art.py (new), tools/verify.py
- **Art packs:** A034

## Goal

The peddler at the stall and the stall's closed state get their approved art.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A034` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A034-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/npc` and `assets/art_source/props/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`check_station_art.FAMILY` for the closed stall; a new `tools/check_npc_art.py` wired into `tools/verify.py` for the peddler, saying why in the journal).
- Runtime names: idle (2-4), talk/wave (2-4) and the walk in/out side cycle (4-8, mirrored at runtime) at the farmer's scale and the pivot 0190 settled; the closed stall matches today's `shop` (32x40, pivot (16,36))
- Replace 0190's stand-ins and flip A034's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A034 integrated`.

## Done when

- [ ] `python tools/check_station_art.py`, `python tools/check_npc_art.py` and `python tools/show_art.py --stations --check` pass
- [ ] `python tools/import_art.py --check` passes
- [ ] FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0216/`
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
