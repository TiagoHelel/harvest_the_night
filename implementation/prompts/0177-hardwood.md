# 0177 - Hardwood

- **Phase:** 12 - The day that pays
- **Status:** done
- **Depends on:** 0175, 0156
- **Likely files:** src/core/game_data.gd, src/core/gathering.gd, src/core/interact.gd, src/core/farm.gd, src/ui/world_view.gd, src/ui/names.gd, src/ui/placeholder_art.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd

## Goal

Big stumps give hardwood to an iron axe: a reason to upgrade early, and the stuff of the strong wall (0231).

## Art

What this task puts on screen will be dressed by Codex art pack(s) A020, A021
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- The 2x2 stumps 0156 put on the map (`hardwood_stump`, or the id its journal names) become a `GATHERING` node with `min_tier` 1 (iron axe), more swings than a tree, a `HARDWOOD` yield and a `regrow_ticks` (`# LEVER`) - nothing on the farm is exhausted for good - and an `Interact.OCCUPANT_VERBS` entry (`chop`). One occupant over four cells with an anchor, like the stations: a swing at any of its cells strikes it. `Gathering.strike`, `Farm.remove`/`restore` and the regrowth in `Gathering.tick` all work one cell at a time today: the stump leaves all four cells when it falls and comes back only when all four are clear (the anchor's entry in `regrowing`), asserted
- A chipped look after the first swing, until it falls (view, from `Gathering.swings_left`)
- `HARDWOOD` in `RESOURCES`, `SELL_PRICE`, the materials group, names and strings in both languages; its icon is a tinted stand-in until A020 is integrated by 0203
- Its use is 0231's strong wall; here it only sells, and the journal says so. DATA moves; SIM moves on purpose (a new resource in `held`/`gained`) - record both
- `check_reachable`: every stump has a cell to stand on beside it; the flow field treats it like a tree
- A scaled stand-in of today's `stump` at 32x32 through the placeholder road until A021 is integrated by 0204

## Done when

- [ ] `_task_0177_hardwood` in `src/tools/headless_v1.gd`: a basic axe is refused at a big stump; an iron axe fells it in the swings, for the hardwood, the levers say, from any of its four cells; it is back on all four after `regrow_ticks`, and not while one of them is built on
- [ ] A new `hardwood` scenario: `python tools/shot.py 0177 hardwood --fhd` shows a whole and a chipped stump beside a tree; opened and looked at
- [ ] the Deliverables table of `implementation/backlog/packs/A021-ore-hardwood.md` states the final geometry this task settled (the node canvas and variants, the stump's canvas, pivot and states)
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
