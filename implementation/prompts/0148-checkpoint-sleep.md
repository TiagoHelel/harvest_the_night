# 0148 - Checkpoint: is the night better with him asleep?

- **Phase:** 10 - Sleep is the night
- **Status:** todo
- **Depends on:** 0137, 0138, 0139, 0140, 0141, 0142
- **Likely files:** implementation/PROGRESS.md, implementation/shots/0148/, implementation/prompts/

## Goal

**The plan's Phase 1 test.** Play the new night - the farmer asleep, the cursor, START, dawn - with a mouse and with a pad, and answer honestly whether it is better than the MVP's night. Every later phase waits on the answer.

## Requirements

- Play at least three whole days and nights by hand with mouse and keyboard and at least one with only a pad (a real one if attached; say honestly if it was synthetic): bed, cursor building, START, a repair, a flare, an upgrade and a sale by cursor, speed and skip, dawn, the morning report - and one night that follows a pass-out
- Run the autoplayer for every policy over ten nights and note how the nights end: at dawn, with everything dead, or with the house down
- FHD captures of one night from START to dawn - the build step with the cursor and the hotbar, the first wave, a repair, the flare aimed, the walk-off at dawn, the morning report - in `implementation/shots/0148/`, opened and looked at
- Answer the plan's question in the journal, 'is the night better with him asleep?', against the MVP's night: what is better, what is worse, what is missing, and what is slow or fiddly (the camera, the cursor, the pad)
- Fix here only what is small and inside this phase's rules; anything bigger becomes an edit to a later prompt or a note for the phase it belongs to
- Every later phase depends on this task. If the answer is no, run `python tools/task.py blocked 0148 "<the reason>"` and edit the later prompts that must change before any content is produced; never tick or untick a box by hand

## Done when

- [ ] The journal has the answer, the nights played (device, how each ended, house left), the autoplayer's numbers, and every later prompt edited and why
- [ ] The captures in `implementation/shots/0148/` exist and were opened
- [ ] Either the task is done on a yes, or it is blocked with the reason and the later prompts are edited
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
