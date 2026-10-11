# 0227 - The pumpkin catapult

- **Phase:** 13 - Weapons of the night
- **Status:** done
- **Depends on:** 0196, 0132, 0168
- **Likely files:** src/core/game_data.gd, src/core/towers.gd, src/core/ammo.gd, src/ui/names.gd, src/ui/describe.gd, src/ui/sfx.gd, assets/locale/strings.csv, src/tools/shot.gd, src/tools/headless_v1.gd

## Goal

A lobbed splash that burns pumpkins instead of gunpowder, so an autumn harvest becomes an autumn defence (plan section 5).

## Art

What this task puts on screen will be dressed by Codex art pack(s) A039
(`implementation/backlog/packs/`). Draw it through the placeholder road of
task 0120 until each pack is integrated - or with the pack's art if
`python implementation/backlog/assets.py status <pack>` already says
`integrated`. Never wait for art and never draw or generate PNGs here.

## Requirements

- Id `catapult` (never `pumpkin`, which is the crop): `shape` splash, `aim` ballistic with `flight_ticks`, `ammo` {pumpkin: 1}, a cost in wood and pumpkins, `season` autumn (0193's field - pumpkins are autumn's, so `check_seasonal_supply` fails it as spring). Not a cheaper mortar: shorter reach, no gunpowder, a reason of its own - the journal says when it is the better buy
- It has `damage`, so `_task_0085_night_sounds` wants a `Sfx.TOWER_SOUNDS` entry: borrow `sfx/mortar` until 0283 gives it a thunk
- `check_ammo` refuses ammunition no recipe makes. Allow what a crop yields (the `CROPS` table) as well as recipe outputs, or add a recipe - decide, and keep the rule's intent: a tower must be able to fire a proper shot
- An empty pumpkin pool gives the weak shot every tower has (`Ammo.weak_damage`, `Ammo.weak_reload`), never a silent catapult
- `TOWER_LEVELS` 1-3 for `catapult`, gated on the same tree nodes as the other towers (`true sights`, `oiled works`)
- `Names.KEYS` `DEF_CATAPULT`, a `Describe.defence` line, strings in both languages; drawn through the placeholder road (a tinted 32x48 tower per level and state, an 8x8 pumpkin shot, a 4-frame splat) until A039 is integrated by 0238
- DATA moves (a row, its levels, the ammunition rule); SIM moves only if a state key appears or the scenario builds one - record both numbers

## Done when

- [ ] `_task_0227_catapult` in `src/tools/headless_v1.gd` asserts a pumpkin lands where it was aimed with the splash falloff the LEVER claims, an empty pool still fires weakly, and levels 1-3 read through `Building.entry_at`
- [ ] The Deliverables table of `implementation/backlog/packs/A039-catapult.md` states the final geometry this task settled (levels, states, muzzle points, the shot, the splat)
- [ ] `python tools/shot.py 0227` captures of a volley landing, opened and looked at
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
