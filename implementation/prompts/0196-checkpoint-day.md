# 0196 - Checkpoint: is the day good on its own?

- **Phase:** 12 - The day that pays
- **Status:** todo
- **Depends on:** 0194, 0195
- **Likely files:** implementation/PROGRESS.md, implementation/shots/0196/, src/tools/autoplay.gd, implementation/prompts/

## Goal

**The plan's Phase 3 checkpoint.** A spring day and a summer day earn money in different ways, and the day is fun even without thinking about the night. Phase 13 and everything after it waits on this answer.

## Requirements

- Play a spring day and a summer day in the real game, and run the autoplayer through the same days; compare where the money came from
- FHD captures of both days at morning, noon and dusk in `implementation/shots/0196/`, opened and looked at
- Answer honestly in the journal: is the day fun even without thinking about the night? What drags, what is busywork, what is missing
- If the answer changes the plan, edit the later prompts (0197 on) before they run, and say which
- If the answer is no, mark this task blocked with the reason, so phase 13 does not start on a day that does not work
- Change no rule here: fixes go into later prompts or new tasks

## Done when

- [ ] The journal says, with numbers, how a spring day and a summer day each made their money - and that they differ
- [ ] The journal answers the question in one paragraph a reader could disagree with
- [ ] The captures are in `implementation/shots/0196/` and the journal says what each one shows
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
