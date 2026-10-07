# 0195 - Teaching the new day

- **Phase:** 12 - The day that pays
- **Status:** todo
- **Depends on:** 0194
- **Likely files:** src/core/game_data.gd, src/ui/tips.gd (new, e.g.), src/ui/tutorial_prompt.gd, src/ui/main.gd, src/app/save.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

The new day explains itself once: tilling grass, the seasons, the shipping bin, the fishing bar and the animals each get one tip, at the moment they first matter.

## Requirements

- Tips, not day-one lines: `MAX_TUTORIAL_LINES` still caps the first day. A tip fires from the state (the first stand on open grass with the hoe, the first morning of a new season, the first stand by the bin, the first bite, the first animal bought) and is remembered in the profile so it never shows twice
- Tips live in the view: `src/ui/` reads the state for the trigger and the profile (`Save.read_profile`/`write_profile`) for what was shown, through a pure `due(state, profile)` the headless group can call. No rule in `src/core/` reads them (their table may sit in `game_data.gd` beside `TUTORIAL`, as data), so SIM must not move; they never gate or pause anything. The day-one lines remember themselves in the `gameplay/tutorial_seen` Settings key (`tutorial_prompt.gd`): say why the tips use the profile instead, or use Settings too
- `check_tutorial` (or a new check) covers the tip table in `game_data.gd`: unique, short, naming a string key that exists. List it in `digest()` (DATA moves) or exempt it in `_task_0112_digest` as view text - say which
- Strings in both languages, each fitting its control (`tools/i18n_check.py`); a tip sits on the thing it describes (`tutorial_prompt.gd`)
- The guided Spring 1-7 is 0293's, not here

## Done when

- [ ] `_task_0195_tips` in `src/tools/headless_v1.gd`: each tip fires once on its trigger and never again with the profile flag set
- [ ] `_case_0195_tips` in `src/tools/input_v1.gd`: a tip appears on the first bite and is dismissed
- [ ] A new `tips` scenario: `python tools/shot.py 0195 tips --fhd` shows two tips in place; opened and looked at
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
