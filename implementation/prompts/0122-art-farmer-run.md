# 0122 - Art: the farmer's run

- **Phase:** 9 - v1.0 groundwork
- **Status:** done
- **Depends on:** 0120
- **Likely files:** assets/art_source/player-fhd/, assets/art_source/manifest.json, assets/art_source/ownership.json, src/ui/player_art.gd, src/ui/placeholder_art.gd, src/tools/art_showcase.gd, src/tools/headless_check.gd, implementation/fhd-player/pilots/2026-10-04/palette-variants/promote_blue_walk.py, tools/verify.py, src/tools/shot.gd
- **Art packs:** A006

## Goal

**Cancelled by the owner on 2026-10-08: the farmer does not run.** A006 is retired
(`implementation/backlog/deliveries/A006-farmer-run/RUN-REMOVAL.txt`), so this
closes on its decline path: A006's stand-ins leave the 0120 registry and the
run key keeps playing the walk, faster, as it always did. What follows was the
plan before the cancellation.

Running is the walk played faster. Put in the eight-direction run Codex drew for A006 at the approved 32px detail, so holding run looks like running.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A006` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A006-PROMPT.txt` handoff (under `implementation/backlog/deliveries/`); check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/player-fhd/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`. The farmer's checks are `art_showcase.gd --locomotion` and the FHD player sources check (`promote_blue_walk.py --check`), which knows only walk and idle: extend it, or give the run its own promoter with a `--check` wired into `tools/verify.py`
- Runtime names `run_<dir>_0..7` for the eight directions of `PlayerArt.HEADINGS`: 80x80, pivot (40,72), `draw_scale` 0.5, `exact-source` inside the 12-colour blue garment ramp; `01.png` is frame 0, seconds and loop from the pack's contract, mirrors exactly as the handoff says (never flip a baked mirror again)
- `PlayerArt.pose` plays `run_<direction>` while running instead of `walk_<direction>` at `RUN_FRAME_SECONDS` (0120 left it naming the walk), its seconds from `PlayerFrames.SECONDS`; retire `RUN_FRAME_SECONDS` if nothing else reads it. Rewrite what pinned the stand-in: `_task_0073_player_art`'s running pose (~l.13300, 'runs its eight walking poses at a faster pace') and `art_showcase.gd`'s `_locomotion` (~l.1245-1290: the expected name and the seconds check)
- Delete A006's entry from the 0120 placeholder registry
- Set the pack to integrated: `python implementation/backlog/assets.py set A006 integrated`.

## Done when

- [ ] `python tools/show_art.py --locomotion --check` and the FHD player sources check pass with the run in them; `python tools/import_art.py --check` passes
- [ ] `python tools/placeholders.py` no longer lists A006
- [ ] FHD captures (`python tools/shot.py 0122 --fhd`, with the farmer running; add a scenario if none shows it) by day and in the dark, in `implementation/shots/0122/`, opened: feet on the ground line, body as tall as the walk, no blue drift
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
