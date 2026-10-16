# 0266 - Art: the Harvester

- **Phase:** 14 - Enemies and bosses
- **Status:** done
- **Depends on:** 0253
- **Likely files:** assets/art_source/enemies/harvester/, assets/art_source/manifest.json, assets/art_source/ownership.json, tools/check_giant_art.py, tools/gen_sprites.py, src/tools/headless_check.gd, src/tools/giant_showcase.gd, src/ui/enemy_motion.gd
- **Art packs:** A052

## Goal

The Harvester as Codex drew it, in place of 0253's stand-in: the wind-up you learn to fear and the charge that follows it.

## Requirements

- `python tools/task.py next` only offers this task once `python implementation/backlog/assets.py status A052` says `approved`. Check it again first; if it does not, stop and change nothing (the task stays todo and waits). This task never draws, generates or substitutes art.
- Use only the folder named in the pack's `CLAUDE-A052-PROMPT.txt` handoff; check every file against its `contract.json` sha256 before promoting; never resample, regenerate, or cut from previews or GIFs.
- Promote through the raster pipeline: versioned sources under `assets/art_source/enemies/harvester/`, manifest entries with prompt/approval provenance, `assets/art_source/ownership.json`, then `python tools/import_art.py`; extend the hard-coded family lists the art checks use (`gen_sprites.migrated_enemies()`, 0246's boss table in `check_giant_art.py`, `ArtPlacement` if the canvas is larger than 80x64).
- At the canvas 0253 settled (80x64 pivot (40,60), or up to 112x80): `harvester` master, `harvester_walk_0..3` (move), `harvester_windup_0..2`, the charge/crush frames, `harvester_death_0..4`, the wreck debris and the forecast mark; 0246's boss path picks the windup on the telegraph and the charge frames while 0253's charge runs
- Replace 0253's placeholders in 0120's registry; the telegraph strip on the ground stays code. The first boss leaf to land (0266-0268, any order) rewrites `_task_0074_zombie_art`'s 'the Giant is the biggest thing on the field' as 'every boss outsizes every non-boss'
- Set the pack to integrated: `python implementation/backlog/assets.py set A052 integrated`.

## Done when

- [ ] `python tools/check_giant_art.py` and `python tools/show_art.py --boss=harvester --check` pass
- [ ] `python tools/import_art.py --check` passes
- [ ] FHD (1920x1080) captures in the real game by day (the mark in the dusk forecast) and by night (wind-up with the strip, and mid-charge), opened and looked at, in `implementation/shots/0266/`
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
