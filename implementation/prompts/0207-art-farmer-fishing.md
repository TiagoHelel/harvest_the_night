# 0207 - Art: the farmer fishing

- **Phase:** 12 - The day that pays
- **Status:** todo
- **Depends on:** 0180
- **Likely files:** assets/art_source/player-fhd/, assets/art_source/manifest.json, src/ui/player_work.gd, src/ui/player_frames.gd
- **Art packs:** A024

## Goal

The farmer casts, waits, strikes, reels and shows the catch at the 32px detail, replacing the legacy fish and reel strips (0180's poses).

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A024` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A024-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/player-fhd/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (the work-verb list `player_work.gd` and the showcase read).
- Runtime names and timings: cast, wait, strike, reel (loop) and show the catch (2) for S, N and W, with E mirrored at runtime (not baked), on the art contract's work canvas (48x48, pivot (24,44), draw scale 0.5); if a farmer work leaf (0123-0125) has landed, reuse its `PlayerArt.pose` work-strip path; the poses follow 0180's bar stages
- Retire the legacy 48x48 `fish`/`reel` strips from the manifest and `ownership.json` once nothing reads them, and flip A024's placeholder-registry entries to raster
- Set the pack to integrated: `python implementation/backlog/assets.py set A024 integrated`.

## Done when

- [ ] `python tools/show_art.py --work --check` pass
- [ ] `python tools/import_art.py --check` passes
- [ ] FHD (1920x1080) captures by day and by night of the art in the real game, opened and looked at, in `implementation/shots/0207/`
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
