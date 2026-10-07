# 0183 - The coop and the barn

- **Phase:** 12 - The day that pays
- **Status:** todo
- **Depends on:** 0126, 0156
- **Likely files:** src/core/game_data.gd, src/core/livestock.gd, src/core/building.gd, src/core/interact.gd, src/core/state.gd, src/ui/world_view.gd, src/ui/transition.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_check.gd, src/tools/input_check.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

Animals get homes: a coop and a barn, built by day, that hold them, shelter them at night and - from 0184 - make them worth feeding (plan section 3.4).

## Art

What this task puts on screen will be dressed by Codex art pack(s) A030
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- Coop and barn are `BUILDINGS` entries (hp, cost in wood, stone and money, `size`, an animal `capacity`, all `# LEVER`), built by day on 0156's `MAP_SITES` (room for up to 7x4) or anywhere buildable, with `Names.KEYS` entries and `BLD_*` rows in both languages. Decide the footprints and capacities here
- Animals live in their building: a record per building of who lives there (kind, produce waiting, ticks left), inside `livestock` or under a new key listed in `State.RUN_DATA`; `Livestock` produces for housed animals and the `collect` verb (already in `Sfx.VERB_SOUNDS`) moves from the animal to the building's door
- The map's cow and chickens move in: until a coop or barn exists they stand where `FARM_MAP` put them and behave as today; the first one built takes the loose animals of its kind in (removed as occupants, one `Farm.touch`). A save with loose animals keeps working
- `check_livestock` is reworked: every kind names the building it lives in, and the map or the stall (0190) is its source - 'every animal stands on the map' stops being a rule
- Buying animals is 0190's; here the map or a test supplies them
- Housed animals stand by their building by day (view only; wandering is 0185's) and are hidden at night; the buildings draw as scaled station stand-ins at their footprint through the placeholder road until A030 is integrated by 0212
- Update the animal parts of `_task_0034_cooking` and `_case_0034_livestock` if they rely on loose animals. DATA moves; SIM moves if the state gains a key or a station, or the scenario builds one - say which

## Done when

- [ ] `_task_0183_barns` in `src/tools/headless_v1.gd`: building a coop moves the map's chickens in and their produce still comes; a full coop refuses another chicken; a barn holds its capacity
- [ ] `_case_0183_barn` in `src/tools/input_v1.gd`: place a coop by day and collect at its door
- [ ] A new `coop_barn` scenario: `python tools/shot.py 0183 coop_barn --fhd` shows the coop and the barn with their animals by day; opened and looked at
- [ ] the Deliverables table of `implementation/backlog/packs/A030-coop-barn.md` states the footprints, capacities and door/window points this task settled
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
