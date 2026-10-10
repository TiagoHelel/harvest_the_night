# 0220 - The technology tree by season

- **Phase:** 13 - Weapons of the night
- **Status:** done
- **Depends on:** 0219, 0149
- **Likely files:** src/core/game_data.gd, src/core/tech.gd, src/core/calendar.gd, src/ui/tech_panel.gd, src/ui/names.gd, assets/locale/strings.csv, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

Each season opens a new floor of the tree, so summer's essence buys something spring could not and the tree grows with the year instead of being finished in the first fortnight (plan section 7).

## Requirements

- `TECH_TREE` rows gain a `season` (0 spring to 3 winter, the calendar of 0149). Today's twelve nodes are spring's floor; summer, autumn and winter each add one node per branch (production, defence, survival) - nine new nodes with notes
- The gate is the seasons the run has reached, not the season it is in: a winter node stays available in Year 2's spring. Put that question in one pure helper beside 0149's, e.g. `Calendar.season_reached(state, season)` (every season from Year 2 on) - 0233 and 0234 reuse it. `Tech.why_not_buy` refuses an unreached season with a new key (e.g. `WHY_NOT_YET_SEASON` and the season name, a `strings.csv` row in both languages), checked before the price
- Every new node gives a number a system already reads, or a new `Tech.bonus` key read by the one system that owns it. `Tech.bonus` returns the first owned node that gives a key, so a later tier improving an existing key needs a rule (best value wins, or a key of its own): decide, write it in `tech.gd` and assert it
- Price it the way task 0063 did: every node reachable in a year, not all of them, against `Tech.total_available()` over the calendar (0150); the arithmetic goes in the journal
- Leave the powers to 0233, which adds one survival node per season from summer; nothing here gives a power
- `tech_panel.gd` pages the tree by season (keyboard, mouse and pad), greys an unreached season with its reason and still fits 480x270. `Names.KEYS`, `Names.NOTES` and `TECH_*`/`TECHNOTE_*` rows in `assets/locale/strings.csv` for every new node, in both languages
- A `GameData.validate()` rule: every `season` is 0-3, `needs` never points at a later season, and each branch has a node in every season. DATA moves on purpose (the tree is in `GameData.digest()`): record it. SIM must not move - no state key is added and the determinism scenario buys nothing

## Done when

- [ ] `_task_0220_tree_seasons` in `src/tools/headless_v1.gd` asserts a summer node is refused in spring with the season reason, is buyable once summer is reached and still in Year 2's spring, and the stacking rule for a repeated bonus key holds
- [ ] `_case_0220_tree_pages` in `src/tools/input_v1.gd` pages to summer and buys a node with the keyboard and with the pad
- [ ] `python tools/shot.py 0220` captures of the tree in spring and in autumn, opened and looked at: no node cut off, no two labels on top of each other
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
