# 0117 - Three stale documents

- **Phase:** 9 - v1.0 groundwork
- **Status:** done
- **Depends on:** nothing
- **Likely files:** CHANGELOG.md, docs/PLAYTEST.md, assets/locale/strings.csv

## Goal

Three places tell a player something the game does not do. Fix the words and nothing else.

## Requirements

- `CHANGELOG.md` 0.1.0 says 'Sixteen crops'; there are three (`GameData.CROPS`: wheat, corn, carrot). Say three, and read the rest of that section against the game while there
- `docs/PLAYTEST.md` 'What to ignore' says 'Anything after night ten. It stops.' - it does not: the run carries on into generated endless nights (`Endless`, `Run.go_endless`). Say what really happens. Keep the headings `_task_0105_playtest` looks for ('What to try', 'What to ignore', 'What to report') and the line that names the note key
- `TUT_SELL` says the stall 'sells seeds'; it does not - seeds are paid for at planting (`CROPS[...]["seed_cost"]`) and `DAILY_STOCK` has none. Rewrite the line in English and Brazilian Portuguese, about as long as today's: its `width` column is 0, so `tools/i18n_check.py` checks that both languages are there and agree on `%` specifiers, and `MAX_TUTORIAL_LINE_LENGTH` measures the key, not the words
- Words only, no rule changes: the day-barricade allowance is 0132's, the can's '/8' is 0174's, and seeds sold by season arrive with 0170 (the line moves again then). `TUTORIAL` holds the key, not the text, so neither hash moves

## Done when

- [ ] A grep of `CHANGELOG.md` and `docs/PLAYTEST.md` finds no 'Sixteen' and no 'It stops'
- [ ] `python tools/i18n_check.py` passes with the new `TUT_SELL` in both languages
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
