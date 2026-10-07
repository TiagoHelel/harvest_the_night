# 0297 - Releasing 1.0

- **Phase:** 17 - Ship 1.0
- **Status:** todo
- **Depends on:** 0290, 0291, 0292, 0293, 0294, 0295, 0296
- **Likely files:** src/core/build_info.gd, CHANGELOG.md, implementation/RELEASE.md, export_presets.cfg, tools/release.py, tools/devlog.py, docs/devlog/, tools/goldens/, src/tools/headless_v1.gd

## Goal

Run the checklist 0106 wrote, for 1.0: one version everywhere, a changelog a player would recognise, both builds made and proven, the known issues told honestly - and then stop, because publishing is the owner's.

## Requirements

- Every task below 0297 is done (`python tools/task.py stats`). One that is not - an optional art leaf such as 0289 the owner declined, or a blocked task - is closed by the owner's word or listed under Known issues with why. No release over a todo nobody explained
- One version: `BuildInfo.VERSION` becomes `1.0.0` and `STAGE` stops saying prototype; `CHANGELOG.md` gets a 1.0.0 section on top (`_task_0106_release` requires one); both Windows presets in `export_presets.cfg` (Windows Desktop and Windows Playtest) get `application/file_version` and `application/product_version` (four numbers, `1.0.0.0`). `_task_0297_release` in `src/tools/headless_v1.gd` fails when any of them disagrees with `BuildInfo.VERSION`
- The changelog in sentences a player would recognise: a year of seasons, going to bed, the guardian, dawn, the new crops, fishing, animals, machines, defences, enemies and bosses, collections, the new options - and what happens to a 0.1 save (0291's rule)
- The save the next version must read: if `tools/goldens/run-v<State.VERSION>.sav` is missing, `make_goldens.gd` writes it from this build, and nobody regenerates it after
- `implementation/RELEASE.md` brought to 1.0 and run top to bottom: the tag says `v1.0.0`; step 3 names 0291's 0.1 goldens; Known issues rewritten from the journal (0280's answer, 0295's playtest, anything still on a placeholder, 0290's follow-ups, the perf and wire numbers); Rollback says a 0.1 run is migrated or archived, never eaten. Keep the commands and headings `_task_0106_release` looks for
- The devlog describes 1.0 (moved here from 0296): `devlog.py`'s 'What is not in it' stops reading `design.md` §15 and lists what is not in 1.0 from the plan (the greenhouse of §3.1, stamina in §3.9, the Nightmare mode of §11, the one-farm pillar of §3.3 and §12) on both pages, keeping the heading `_task_0108_devlog` reads; its 'still wrong' list is the Known issues above. `docs/devlog/preamble.md` is the owner's opinion and is left alone - the journal asks for a 1.0 paragraph
- `python tools/release.py` - verify, stamp, both exports, the pack check, the budgets, the 400-frame boot - passes. If `PACK_BUDGET` or `WIRE_BUDGET` fails, find what grew from the pack listing and move it once, deliberately, with the old and new number and the biggest files in the journal - the way a hash moves. Version, words and builds only: neither hash moves
- Step 6's smoke test by hand is the owner's wherever the loop cannot do it (the Web build in a browser, a pad in the hand): the journal says what the tools checked and what is left for a person, and never claims a hand test that did not happen
- Nothing leaves the machine: no `git push`, no `git push --tags`, no upload. Commit the release (the runner loop's step 6) and only then, `release.py` having passed, make the annotated tag `v1.0.0` on that commit, so it holds the stamped `BuildInfo.BUILT`; the journal ends with the push and upload commands for the owner

## Done when

- [ ] `python tools/release.py` passes and prints both builds against their budgets; the numbers are in the journal
- [ ] the title screen shows the 1.0.0 `BuildInfo.short()` - captured with `python tools/shot.py 0297 --title --fhd` and opened
- [ ] `_task_0297_release` fails on a preset whose version disagrees (tried once, reverted) and passes on the real ones; `python tools/devlog.py --check` passes with the 1.0 list
- [ ] `git tag -l v1.0.0` lists the local annotated tag on the commit holding this task's changes, `git status` shows nothing of this task uncommitted, and nothing was pushed
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
