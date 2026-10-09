# 0179 - Fish by pond, season and hour

- **Phase:** 12 - The day that pays
- **Status:** todo
- **Depends on:** 0126, 0149, 0156, 0165
- **Likely files:** src/core/fishing.gd, src/core/game_data.gd, src/core/crafting.gd, src/app/save.gd, src/core/state.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/make_goldens.gd, tools/goldens/, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd

## Goal

The one pond becomes three with about twelve species, each with its place, season, hours and rarity, so fishing asks where and when as well as whether (plan section 3.2).

## Art

What this task puts on screen will be dressed by Codex art pack(s) A022
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- `FISH_SPECIES` in `game_data.gd`: about twelve species (carp, perch, catfish, tilapia; trout, pike, eel; dorado, salmon, sturgeon; two more to fill the seasons) with ponds (the ids of 0156's `PONDS` table, found from a cell by `Farm.pond_of`; use 0156's names, not the plan's), seasons, hours (0126's `Phases.clock_minute`), a rarity weight and a value, all `# LEVER`, in `digest()`. Legendaries are 0182's
- `Fishing.begin` draws the species at the cast from the run RNG, among those the pond, the season and the hour allow, weighted by rarity; the bite-delay draw stays. `Fishing.reel` gives that species and `last_catch` names it. SIM moves on purpose (the draw, the new resources, the version) and DATA moves (`FISH_SPECIES`, `FISHING`, the recipes): record both
- Each species is a resource: `RESOURCES`, `SELL_PRICE`, a fish group, `Names.KEYS`, `ITEM_*` rows in both languages
- **Recipes that took `fish` accept any species**, as a rule: a recipe input may name the fish group, and `Crafting` pays it from the species held in a fixed order (cheapest first, then by name). `check_recipes`, `check_chain` (value it at the cheapest member) and `Crafting.missing` understand it; `press_fish_oil` and `cook_fish` use it
- The old `fish` resource goes: bump `State.VERSION` by one (8, after 0165's 7) with a migration that moves `fish` in `held` (and `gained`) into the commonest species, plus a golden at the new version - reconcile alone would drop it. Every other reader follows (`GameData.FISH` - a dozen uses in `headless_check.gd` and four in `input_check.gd`, e.g. the press and kitchen groups -, `SELL_PRICE`, the fish inventory group (since 0169), `Names.KEYS`/`ITEM_FISH` - `tools/i18n_check.py` flags an unused key); the `fish` verb keeps its id
- `FISHING.common_yield`/`rare_yield` give way to the table; `check_fishing` is rewritten: every species names real ponds, seasons and hours, and every pond has a catch in every season at every hour of the day
- Rewrite `_task_0030_fishing` and `_case_0030_fishing` (the triple 'rare' fish is gone)
- Icons draw as tinted `icon_fish` stand-ins through the placeholder road until A022 is integrated by 0205

## Done when

- [ ] `_task_0179_species` in `src/tools/headless_v1.gd`: the same seed casts the same species; a summer species never bites in spring; two of 0156's ponds yield different sets; `cook_fish` takes the cheapest species held
- [ ] A migrated golden's old fish arrive as the commonest species, asserted
- [ ] the Deliverables table of `implementation/backlog/packs/A022-fish-icons.md` states the final species list and sizes this task settled
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
