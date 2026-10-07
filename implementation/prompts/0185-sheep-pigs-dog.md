# 0185 - Sheep, pigs and the dog

- **Phase:** 12 - The day that pays
- **Status:** todo
- **Depends on:** 0184
- **Likely files:** src/core/livestock.gd, src/core/game_data.gd, src/core/interact.gd, src/core/phases.gd, src/core/state.gd, src/ui/animal_view.gd (new), src/ui/world_view.gd, src/ui/transition.gd, src/ui/sfx.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd, src/tools/input_v1.gd

## Goal

The barn fills out: sheep give wool, pigs dig truffles, and a dog follows the farmer by day - the farm feels alive between the chores.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A025, A026, A027, A028
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- Sheep live in the barn, eat hay and give `WOOL` (`# LEVER`s)
- Pigs find truffles: each morning a housed pig marks dig spots on open grass near its barn (a `RUN_DATA` cell -> item record, deterministic - run RNG or a `(seed, day)` stream, decide; SIM moves); the farmer collects `TRUFFLE` by day with a verb in `Interact`; a spot never sits on a plot, a path or an occupied cell, and is gone at night. A spot is on open grass, where 0167 offers `till`: the spot's verb wins there. A new verb goes in `DAY_ONLY`, `all_verbs` and an `Interact.complete` arm with an `Sfx.VERB_SOUNDS` entry (borrow `sfx/collect` until 0281), or `_task_0084_day_sounds` fails
- The dog is a pet from day 1 that follows the farmer by day and sleeps by the porch at night. **View only**: no state key, no occupant, nothing in `src/core/`, so the hash cannot see it; petting it is a view-only gesture (a heart). Its night power is 0233's
- View-only wander, eat and sleep states for every animal (cow, chicken, sheep, pig, dog) near its building, in `src/ui/animal_view.gd`, never touching the state; at night `transition.gd`'s `DAY_ONLY` (today cow and chicken: add sheep and pig) hides them as it does today
- `WOOL` and `TRUFFLE` with prices, groups, names and strings in both languages; `check_livestock` covers sheep and pig. SIM moves on purpose (new resources, the dig-spot key); DATA moves
- Stand-ins through the placeholder road (tinted cow/chicken for sheep and pig, a small one for the dog, tinted icons and a code-drawn dig spot) until A026 (0209), A027 (0210), A028 (0245), the tend pose A025 (0208) and the icons and dig spot of A029 (0211) are integrated
- Settle the art: scales against the 32px farmer, states and frame counts into A025, A026 and A027

## Done when

- [ ] `_task_0185_animals` in `src/tools/headless_v1.gd` (mornings by `Phases.begin_day`, never a whole day of ticks): a sheep gives wool; a pig's dig spot can be collected and is never on a plot or a path; a text scan finds no dog in `src/core/`, so the hash cannot depend on it
- [ ] `_case_0185_truffle` in `src/tools/input_v1.gd`: walk to a dig spot and collect a truffle
- [ ] A new `barnyard` scenario: `python tools/shot.py 0185 barnyard --fhd` shows the barnyard with every animal and the dog following; opened and looked at
- [ ] the Deliverables tables of `implementation/backlog/packs/A026-farm-animals.md` and `A027-cow-chicken.md` state the scales, states and frames this task settled, and so does `A025-farmer-care.md` for the tend and pet poses - that pack file does not exist yet: if it is still missing, write the settled poses into the journal under an `A025` heading for its author, create no pack, and say so
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
