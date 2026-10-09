# 0181 - Rods and bait

- **Phase:** 12 - The day that pays
- **Status:** done
- **Depends on:** 0179, 0173, 0167
- **Likely files:** src/core/fishing.gd, src/core/farming.gd, src/core/game_data.gd, src/ui/day_hud.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

The rod's tiers change what bites: fibre brings bites sooner and rare fish more often, iron adds a bait slot and is the only rod a legendary takes.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A023
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- Rod effects read from `TOOLS` (`# LEVER`s): the fibre rod shortens the bite range and raises rare weights; the iron rod opens a bait slot and is the gate 0182 checks
- Worms: tilling (`Farming._till`) finds a `WORM` one time in `WORM_IN` (`# LEVER`, in `digest()`), drawn from the run RNG - SIM moves on purpose (the determinism scenario tills) and the journal records it
- A fish-scrap bait recipe (a `RECIPES` entry, so a `Names.KEYS` entry and a `REC_*` row): a common fish into several `BAIT` at the workshop or the kitchen - decide. Bait has a sale price like every resource since 0169, and the recipe passes `check_chain`
- With the iron rod, a held bait is spent at the cast and shortens the wait or raises rarity (`# LEVER`s); which bait is on is a choice the HUD shows, kept in the state (say where; a nested dictionary goes in `State.TABLES`); no bait means no effect, not a refusal
- `WORM` and `BAIT` with prices, a group, names and strings in both languages. Zombie bait is 0225's, not here
- Icons through the placeholder road until A023 is integrated by 0206. DATA moves (`WORM_IN`, the rod levers, the recipe) and SIM moves on purpose (the worm draw, the bait choice): record both

## Done when

- [ ] `_task_0181_rods` in `src/tools/headless_v1.gd`: on a fixed seed the fibre rod's mean wait is shorter than bamboo's by what the levers say; bait is spent at an iron-rod cast and not at a bamboo one; tilling finds worms at the rate claimed
- [ ] `_case_0181_bait` in `src/tools/input_v1.gd`: choose a bait and cast with it
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
