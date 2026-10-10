# 0182 - Legendary fish and the fish book

- **Phase:** 12 - The day that pays
- **Status:** done
- **Depends on:** 0181
- **Likely files:** src/core/fishing.gd, src/core/game_data.gd, src/core/stats.gd, src/core/state.gd, src/ui/fish_book.gd (new), src/ui/inventory_panel.gd, src/ui/names.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

Four legendary fish, one a season, each with its own conditions, and a fish book with a page per species - the first collection that makes a player come back.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A022, A023
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- Four legendaries in `FISH_SPECIES` - the Old Catfish, the Golden Queen, the Ghost Pike and the Ice Sturgeon (ids `old_catfish`, `golden_queen`, `ghost_pike`, `ice_sturgeon`, as A022 names them), one per season - each with a pond, hours and a condition (`# LEVER`s, bounded by `check_fishing`), catchable only on the iron rod and with the hardest bar of 0180
- Decide whether a legendary can be caught once per run; if so the draw skips it once the book has it
- The book: a `fish_book` dictionary in the state (keys come from play: `State.RUN_DATA`), species -> times caught and the first day; folded into the profile through `Stats` so it outlives the run
- A book view (an inventory tab or its own panel) with a page per species, unknown ones as silhouettes with a hint, and a collection count (n of every species, legendaries included); portraits through the placeholder road until A022's are integrated by 0205, the tab icon until A023's by 0206
- Names and strings for the legendaries and the book in both languages; every hint fits its control (`tools/i18n_check.py`)
- SIM moves (new draws, four new resources and the `fish_book` key); DATA moves

## Done when

- [ ] `_task_0182_legendary` in `src/tools/headless_v1.gd`: the spring legendary never bites on the bamboo or fibre rod and does under its conditions on the iron rod; a catch writes the book and the profile
- [ ] `_case_0182_book` in `src/tools/input_v1.gd`: open the book and turn pages with the keyboard, the mouse and the pad
- [ ] A new `fish_book` scenario: `python tools/shot.py 0182 fish_book --fhd` shows a page and the count; opened and looked at
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
