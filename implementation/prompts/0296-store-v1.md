# 0296 - The store page and trailer for 1.0

- **Phase:** 17 - Ship 1.0
- **Status:** todo
- **Depends on:** 0290, 0294
- **Likely files:** docs/STORE.md, tools/gen_marketing.py, src/tools/shot.gd, tools/devlog.py, docs/devlog/the-trailer.gif, implementation/shots/trailer/, src/tools/headless_v1.gd, src/tools/headless_check.gd

## Goal

The store page still sells the prototype: ten nights, about an hour, sixteen crops and a night you send for. Make it describe the year - seasons, going to bed, the guardian on the porch, dawn - in pictures from the real game and words the data can check.

## Requirements

- `docs/STORE.md` rewritten in both languages: a year of four fourteen-day seasons, the night that starts when he goes to bed (or passes out at 02:00), the guardian's cursor, dawn at 06:00, four bosses, what the days pay for; 'What is in it' with real counts; 'What is not' honest (nothing online, one farm, no stamina, no greenhouse, one difficulty); a length worked out from the day and night levers times 56, not hoped for. The pitch stays `design.md` §20 verbatim, which `gen_marketing.py --check` and `_task_0107_store` enforce
- Words the data can check: each count is a digit before a fixed noun in both sections ('12 crops' / '12 culturas'), and `_task_0296_store_copy` in `src/tools/headless_v1.gd` reads `docs/STORE.md` (the way `_task_0106_release` reads `CHANGELOG.md`) and fails when a count it states - crops, defences, enemies, bosses (`is_boss`), days in a season - disagrees with `GameData`
- Screenshots at 1920x1080 through `gen_marketing.py`'s `SCREENSHOTS`, its `capture()` passing `--fhd`: a spring day, the same farm in winter, going to bed, the guardian's build step with cursor and route, a wave holding, dawn with the survivors walking off, and the tech tree or the collections. Reuse the scenarios earlier tasks added (`python tools/shot.py --list`), add only the missing ones. Capsules keep `capsule()`'s rule - a whole-number `NEAREST` scale or a crop, never a smoothed resample - with `HUD_ROWS` scaled to the capture; if the header capsule comes out a close-up, pick a wider source shot and say so
- Rewrite `_task_0107_store` in `headless_check.gd` in place: the five picture names it looks for in `gen_marketing.py` become the new list; its pitch, `NEAREST`, `SWITCH_FRAMES` and no-`HTTPRequest` asserts stay
- The switch GIF and its stills come from `shot.gd --switch`, which 0129 opened with the bed beat: check it is 1.0's switch - he lies down and the farm goes dark - and fix the strip if it still sends for the night
- The trailer's four beats in `shot.gd` (`BEAT_DAY`, `BEAT_SWITCH`, `BEAT_NIGHT`, `BEAT_FALL` - names kept, `_task_0108_devlog` reads them) tell the 1.0 story: a day's work, going to bed, the guardian placing a defence and pressing START, a wave held until dawn. They still sum to `TRAILER_SECONDS * TRAILER_FPS`, and `devlog.py`'s `clip_caption` (EN and PT) says the new story
- The trailer goes through the devlog tool, and never bare (the bare command deletes the tracked frames before capturing): capture with `python tools/shot.py trailer --trailer`, look at the frames, assemble with `python tools/devlog.py --keep`. If a capture fails, `git checkout HEAD -- implementation/shots/trailer` puts the frames back. `python tools/devlog.py --check` (verify's devlog row) passes at the end. The devlog's 'what is not in it' list is 0297's, beside the Known issues it sits with
- `python tools/gen_marketing.py` makes the set in `build/store/`; nothing is uploaded. Captures and copy only: neither hash moves

## Done when

- [ ] `python tools/gen_marketing.py` builds the set and `--check` passes; every screenshot and capsule is opened at full size and named in the journal
- [ ] `_task_0296_store_copy` passes, and fails when one count in the copy is changed (tried once, reverted, said in the journal); the rewritten `_task_0107_store` passes
- [ ] `docs/devlog/the-trailer.gif` is remade (its size in the journal) and watched start to finish: the bed, the cursor, START and dawn are all in it
- [ ] `python tools/devlog.py --check` passes and `git status` shows the trailer frames replaced, not missing
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
