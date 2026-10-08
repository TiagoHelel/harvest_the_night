# 0155 - Losing a night when the calendar moves on

- **Phase:** 11 - Calendar and seasons
- **Status:** done
- **Depends on:** 0151, 0153
- **Likely files:** src/core/rewards.gd, src/core/farming.gd, src/core/pathing.gd, src/core/phases.gd, src/core/run.gd, src/core/game_data.gd, src/ui/world_view.gd, src/ui/placeholder_art.gd, src/ui/result_screen.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd

## Goal

Losing costs what the plan says and nothing more: the calendar moves on, the horde takes a quarter of the stock, tramples the crops it walked through, and what it broke stays broken. Only a boss night comes back.

## Art

What this task puts on screen will be dressed by Codex art pack(s) A014
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- The calendar moving on after a loss is 0151's rule; assert it here beside 0153's exception: an ordinary lost night is never fought again, a lost boss night is
- Stock loss stays `Rewards._loss` (`DEFEAT_LOSS_PERCENT`, money and technology kept by the `DEFEAT_KEEPS_*` levers): no change, an assert
- Trampling, new and deterministic: when the house falls, every plot on the horde's routes loses its crop. The routes are cells, never randomness - from each spawn region tonight used (`Waves.spawns_of`), follow the flow field (`Pathing.step_from`) from every spawn cell to the house, add every cell an enemy stands on when the house falls, widen by `TRAMPLE_REACH := 0  # LEVER: tiles either side of a route, 0-2` (in `digest()`; `validate()` refuses one outside 0-2), and walk the cells sorted
- A trampled plot (`plots`, RUN_DATA) stays tilled, loses its crop and growth, and keeps a `trampled` marker naming the crop for the view until something is planted there; `Farming` treats it as empty tilled ground. No migration: a missing marker means nothing was trampled
- Destroyed defences stay destroyed (the rubble is swept, nothing refunded): an assert, not a change
- The morning report lists it: `RES_TRAMPLED.one`/`.other` (%d CROP TRAMPLED / %d CROPS TRAMPLED; %d PLANTA PISOTEADA / %d PLANTAS PISOTEADAS)
- Find and remove what still says the same night comes back (doc comments in `phases.gd` and `run.gd`, any tutorial or report text); 0153's boss hold is the only repeat left. `_task_0065` is 0151's and is not touched here
- The trampled crop is drawn through 0120's placeholder road (`src/ui/placeholder_art.gd`: the crop's first stage frame, flattened and darkened in code) until A014 is integrated by 0197
- Hashes: SIM moves only if the determinism night is lost (it is not); DATA moves (the lever)

## Done when

- [ ] `_task_0155_losing` in `src/tools/headless_v1.gd`: a lost night on day 5 leads to night 6 and a lost Spring 14 with the boss alive to Spring 14 again; a quarter of each stock is taken as before; on a farm planted across and beside the east route, every plot on the route cells (worked out in the test the same way) is trampled and none off them; a won night tramples nothing; a wall destroyed that night is still gone the next morning
- [ ] Two copies of the same state lose the same night and trample the same cells
- [ ] A `trampled` shot scenario (the morning after a loss, by the field): `python tools/shot.py 0155 trampled --fhd`, opened - trampled plots read as damaged, the rest as untouched
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
